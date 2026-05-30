<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StaffRequest;
use App\Http\Resources\UserResource;
use App\Mail\PasswordChangedMail;
use App\Mail\PasswordResetCodeMail;
use App\Mail\WelcomeNewUserMail;
use App\Models\PasswordReset;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class StaffController extends Controller
{
    public function index(): JsonResponse
    {
        $staff = User::where('role', 'staff')->with('showroom')->get();
        return UserResource::collection($staff)->toResponse(request());
    }

    public function store(StaffRequest $request): JsonResponse
    {
        $data = $request->validated();
        $plainPassword    = $data['password'];
        $data['role']     = 'staff';
        $data['password'] = Hash::make($plainPassword);

        $user = User::create($data);
        $user->load('showroom');

        $showroomName = $user->showroom?->name ?? 'N/A';
        $appUrl       = config('app.url', 'https://moneymanager.app');
        $emailSent    = true;

        try {
            Mail::to($user->email)->send(
                new WelcomeNewUserMail($user->name, $user->email, $plainPassword, $showroomName, $appUrl)
            );
        } catch (\Throwable $e) {
            Log::error('Failed to queue welcome email', [
                'user_id' => $user->id,
                'email'   => $user->email,
                'error'   => $e->getMessage(),
            ]);
            $emailSent = false;
        }

        $message = $emailSent
            ? 'Staff member created successfully. Login credentials have been sent to their email.'
            : 'Staff member created successfully, but the welcome email could not be sent. Please share the credentials manually.';

        return response()->json([
            'message'    => $message,
            'email_sent' => $emailSent,
            'data'       => new UserResource($user),
        ], 201);
    }

    public function show(User $staff): JsonResponse
    {
        abort_if($staff->role !== 'staff', 404);
        return response()->json(new UserResource($staff->load('showroom')));
    }

    public function update(StaffRequest $request, User $staff): JsonResponse
    {
        abort_if($staff->role !== 'staff', 404);
        $data = $request->validated();

        $plainPassword = null;
        if (isset($data['password'])) {
            $plainPassword    = $data['password'];
            $data['password'] = Hash::make($plainPassword);
        }

        $staff->update($data);

        if ($plainPassword !== null) {
            try {
                Mail::to($staff->email)->send(new PasswordChangedMail($staff->name, $plainPassword));
            } catch (\Throwable $e) {
                Log::error('Failed to queue password changed email', [
                    'user_id' => $staff->id,
                    'email'   => $staff->email,
                    'error'   => $e->getMessage(),
                ]);
            }
        }

        return response()->json(new UserResource($staff->load('showroom')));
    }

    public function destroy(User $staff): JsonResponse
    {
        abort_if($staff->role !== 'staff', 404);
        $staff->delete();
        return response()->json(['message' => 'Staff member deleted.']);
    }

    public function sendResetEmail(User $staff): JsonResponse
    {
        abort_if($staff->role !== 'staff', 404);

        PasswordReset::where('email', $staff->email)->delete();

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        PasswordReset::create([
            'email'      => $staff->email,
            'code'       => $code,
            'expires_at' => now()->addMinutes(15),
        ]);

        try {
            Mail::to($staff->email)->send(new PasswordResetCodeMail($staff->name, $code));
        } catch (\Throwable $e) {
            Log::error('Failed to queue staff reset email', [
                'user_id' => $staff->id,
                'email'   => $staff->email,
                'error'   => $e->getMessage(),
            ]);
            return response()->json(['message' => 'Failed to send reset email. Please try again later.'], 500);
        }

        return response()->json(['message' => "Password reset code sent to {$staff->email}."]);
    }

    public function toggleActive(User $staff): JsonResponse
    {
        abort_if($staff->role !== 'staff', 404);
        $staff->update(['is_active' => ! $staff->is_active]);
        return response()->json(new UserResource($staff->load('showroom')));
    }
}
