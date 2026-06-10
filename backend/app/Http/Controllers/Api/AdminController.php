<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function index(): JsonResponse
    {
        $admins = User::where('role', 'admin')->get();
        return UserResource::collection($admins)->toResponse(request());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'      => ['required', 'string', 'max:255'],
            'email'     => ['required', 'email', 'unique:users,email'],
            'password'  => ['required', 'string', 'min:8'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
        $data['role']     = 'admin';
        $data['password'] = Hash::make($data['password']);
        $user = User::create($data);
        return (new UserResource($user))->response()->setStatusCode(201);
    }

    public function update(Request $request, User $admin): JsonResponse
    {
        abort_if($admin->role !== 'admin', 404);
        $data = $request->validate([
            'name'      => ['sometimes', 'string', 'max:255'],
            'email'     => ['sometimes', 'email', 'unique:users,email,' . $admin->id],
            'password'  => ['sometimes', 'string', 'min:8'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }
        $admin->update($data);
        return response()->json(new UserResource($admin));
    }

    public function destroy(User $admin): JsonResponse
    {
        abort_if($admin->role !== 'admin', 404);
        $admin->delete();
        return response()->json(['message' => 'Admin deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);
        $count = User::whereIn('id', $request->ids)->where('role', 'admin')->delete();
        return response()->json(['message' => "Deleted {$count} admins."]);
    }

    public function toggleActive(User $admin): JsonResponse
    {
        abort_if($admin->role !== 'admin', 404);
        $admin->update(['is_active' => ! $admin->is_active]);
        return response()->json(new UserResource($admin));
    }
}
