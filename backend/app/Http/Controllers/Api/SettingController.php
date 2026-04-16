<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SettingRequest;
use App\Http\Resources\SettingResource;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;

class SettingController extends Controller
{
    public function index(): JsonResponse
    {
        return SettingResource::collection(Setting::all())->toResponse(request());
    }

    public function update(SettingRequest $request, Setting $setting): JsonResponse
    {
        $setting->update($request->validated());
        return response()->json(new SettingResource($setting));
    }

    public function editWindow(): JsonResponse
    {
        return response()->json([
            'edit_window_start' => Setting::get('edit_window_start', '00:00'),
            'edit_window_end'   => Setting::get('edit_window_end', '23:59'),
            'is_within_window'  => Setting::isWithinEditWindow(),
            'server_time'       => now()->format('H:i'),
        ]);
    }
}
