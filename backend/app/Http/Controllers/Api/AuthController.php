<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChangePasswordRequest;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Resources\UserResource;
use App\Mail\PasswordChangedConfirmationMail;
use App\Mail\PasswordResetCodeMail;
use App\Models\AuditLog;
use App\Models\PasswordReset;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'The provided credentials are incorrect.'], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Your account has been deactivated.'], 403);
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => new UserResource($user->load('showroom')),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();

        // Verify current password
        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'errors' => ['current_password' => ['The current password is incorrect.']],
            ], 422);
        }

        // Ensure new password differs from current
        if (Hash::check($request->new_password, $user->password)) {
            return response()->json([
                'errors' => ['new_password' => ['The new password must be different from your current password.']],
            ], 422);
        }

        $user->update(['password' => Hash::make($request->new_password)]);

        // Revoke all other tokens for security
        $user->tokens()->where('id', '!=', $request->user()->currentAccessToken()->id)->delete();

        // Audit log
        AuditLog::create([
            'user_id'    => $user->id,
            'action'     => 'password_changed',
            'table_name' => 'users',
            'record_id'  => $user->id,
            'old_values' => null,
            'new_values' => null,
        ]);

        // Confirmation email (failure does not block the response)
        try {
            Mail::to($user->email)->send(
                new PasswordChangedConfirmationMail(
                    $user->name,
                    now()->format('F j, Y \a\t g:i A')
                )
            );
        } catch (\Throwable $e) {
            Log::error('Failed to send password changed confirmation email', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);
        }

        return response()->json(['message' => 'Password changed successfully.']);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();
        if (! $user) {
            // Return same message to avoid email enumeration
            return response()->json(['message' => 'A password reset code has been sent to your email address.']);
        }

        PasswordReset::where('email', $request->email)->delete();

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        PasswordReset::create([
            'email'      => $request->email,
            'code'       => $code,
            'expires_at' => now()->addMinutes(15),
        ]);

        try {
            Mail::to($user->email)->send(new PasswordResetCodeMail($user->name, $code));
        } catch (\Throwable $e) {
            Log::error('Failed to queue password reset email', [
                'email' => $user->email,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['message' => 'Failed to send reset email. Please try again later.'], 500);
        }

        return response()->json(['message' => 'A password reset code has been sent to your email address.']);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $reset = PasswordReset::where('email', $request->email)
            ->where('code', $request->code)
            ->latest()
            ->first();

        if (! $reset || $reset->isExpired()) {
            return response()->json(['message' => 'Invalid or expired reset code.'], 422);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $user->update(['password' => Hash::make($request->password)]);

        PasswordReset::where('email', $request->email)->delete();

        return response()->json(['message' => 'Password reset successfully.']);
    }
}
