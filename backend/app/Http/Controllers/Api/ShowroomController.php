<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ShowroomRequest;
use App\Http\Resources\ShowroomResource;
use App\Models\Showroom;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowroomController extends Controller
{
    public function index(): JsonResponse
    {
        $showrooms = Showroom::with('cardAccounts')->get();
        return ShowroomResource::collection($showrooms)->toResponse(request());
    }

    public function store(ShowroomRequest $request): JsonResponse
    {
        $showroom = Showroom::create($request->validated());
        return response()->json(new ShowroomResource($showroom), 201);
    }

    public function show(Showroom $showroom): JsonResponse
    {
        return response()->json(new ShowroomResource($showroom->load('cardAccounts')));
    }

    public function update(ShowroomRequest $request, Showroom $showroom): JsonResponse
    {
        $showroom->update($request->validated());
        return response()->json(new ShowroomResource($showroom->load('cardAccounts')));
    }

    public function destroy(Showroom $showroom): JsonResponse
    {
        $showroom->delete();
        return response()->json(['message' => 'Showroom deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);
        $count = Showroom::whereIn('id', $request->ids)->delete();
        return response()->json(['message' => "Deleted {$count} showrooms."]);
    }
}
