<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ReviewEditRequestRequest;
use App\Http\Requests\StoreEditRequestRequest;
use App\Http\Resources\EditRequestResource;
use App\Models\DailyCardEntry;
use App\Models\DailyCashEntry;
use App\Models\EditRequest;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EditRequestController extends Controller
{
    // -------------------------------------------------------
    // Staff: submit a new edit request
    // -------------------------------------------------------
    public function store(StoreEditRequestRequest $request): JsonResponse
    {
        $user = $request->user();

        [$model, $typeName] = $this->resolveModel($request->entry_type, $request->entry_id);

        // Entry must belong to the staff's showroom
        if ($model->showroom_id !== $user->showroom_id) {
            return response()->json(['message' => 'Entry does not belong to your showroom.'], 403);
        }

        if (! Setting::isWithinEditWindow()) {
            return response()->json(['message' => 'Editing is not allowed outside the edit window.'], 422);
        }

        // No duplicate pending request for the same entry
        $exists = EditRequest::where('requestable_type', $typeName)
            ->where('requestable_id', $model->id)
            ->where('status', 'pending')
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'An edit request is already pending for this entry.'], 422);
        }

        // Capture original values
        $originalValues = $this->captureOriginal($model, $request->entry_type, $request->requested_changes);

        $editRequest = EditRequest::create([
            'requestable_type'  => $typeName,
            'requestable_id'    => $model->id,
            'user_id'           => $user->id,
            'showroom_id'       => $user->showroom_id,
            'status'            => 'pending',
            'requested_changes' => $request->requested_changes,
            'original_values'   => $originalValues,
            'reason'            => $request->reason,
        ]);

        return response()->json(
            new EditRequestResource($editRequest->load('user', 'showroom', 'reviewer')),
            201
        );
    }

    // -------------------------------------------------------
    // Staff: view own edit requests
    // -------------------------------------------------------
    public function myRequests(Request $request): JsonResponse
    {
        $user = $request->user();

        $requests = EditRequest::where('user_id', $user->id)
            ->with('requestable', 'user', 'showroom', 'reviewer')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json(EditRequestResource::collection($requests)->response()->getData(true));
    }

    // -------------------------------------------------------
    // Staff: cancel own pending request
    // -------------------------------------------------------
    public function cancel(Request $request, EditRequest $editRequest): JsonResponse
    {
        $user = $request->user();

        if ($editRequest->user_id !== $user->id) {
            return response()->json(['message' => 'Not authorised.'], 403);
        }

        if ($editRequest->status !== 'pending') {
            return response()->json(['message' => 'Cannot cancel a reviewed request.'], 422);
        }

        $editRequest->delete();

        return response()->json(['message' => 'Edit request cancelled.']);
    }

    // -------------------------------------------------------
    // Admin: list all edit requests with filters
    // -------------------------------------------------------
    public function index(Request $request): JsonResponse
    {
        $query = EditRequest::with('requestable', 'user', 'showroom', 'reviewer');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('showroom_id')) {
            $query->where('showroom_id', $request->showroom_id);
        }
        if ($request->filled('entry_type')) {
            $typeName = $request->entry_type === 'cash'
                ? 'daily_cash_entries'
                : 'daily_card_entries';
            $query->where('requestable_type', $typeName);
        }
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        // Default: pending first, then newest
        $query->orderByRaw("CASE WHEN status = 'pending' THEN 0 ELSE 1 END")
              ->orderByDesc('created_at');

        $requests = $query->paginate(20);

        return response()->json(EditRequestResource::collection($requests)->response()->getData(true));
    }

    // -------------------------------------------------------
    // Admin: pending count
    // -------------------------------------------------------
    public function pendingCount(): JsonResponse
    {
        $count = EditRequest::pending()->count();
        return response()->json(['count' => $count]);
    }

    // -------------------------------------------------------
    // Admin: show single edit request
    // -------------------------------------------------------
    public function show(EditRequest $editRequest): JsonResponse
    {
        $editRequest->load('requestable', 'user', 'showroom', 'reviewer');
        return response()->json(new EditRequestResource($editRequest));
    }

    // -------------------------------------------------------
    // Admin: approve
    // -------------------------------------------------------
    public function approve(ReviewEditRequestRequest $request, EditRequest $editRequest): JsonResponse
    {
        if ($editRequest->status !== 'pending') {
            return response()->json(['message' => 'This request has already been reviewed.'], 422);
        }

        $model = $editRequest->requestable;

        if (! $model) {
            return response()->json(['message' => 'The original entry no longer exists.'], 422);
        }

        // Check if original values still match (warn only — admin already confirmed on frontend)
        DB::transaction(function () use ($request, $editRequest, $model) {
            $changes = $editRequest->requested_changes;

            if ($editRequest->requestable_type === 'daily_card_entries') {
                // Recalculate card balance if amount changes
                if (isset($changes['amount'])) {
                    $oldAmount = (float) $model->amount;
                    $newAmount = (float) $changes['amount'];
                    $diff      = $newAmount - $oldAmount;

                    $model->update($changes);

                    if (abs($diff) > 0.001) {
                        $model->cardAccount()->increment('current_balance', $diff);
                    }
                } else {
                    $model->update($changes);
                }
            } else {
                $model->update($changes);
            }

            $editRequest->update([
                'status'        => 'approved',
                'admin_remarks' => $request->admin_remarks,
                'reviewed_by'   => $request->user()->id,
                'reviewed_at'   => now(),
            ]);
        });

        return response()->json(
            new EditRequestResource($editRequest->fresh()->load('user', 'showroom', 'reviewer'))
        );
    }

    // -------------------------------------------------------
    // Admin: reject
    // -------------------------------------------------------
    public function reject(ReviewEditRequestRequest $request, EditRequest $editRequest): JsonResponse
    {
        if ($editRequest->status !== 'pending') {
            return response()->json(['message' => 'This request has already been reviewed.'], 422);
        }

        $editRequest->update([
            'status'        => 'rejected',
            'admin_remarks' => $request->admin_remarks,
            'reviewed_by'   => $request->user()->id,
            'reviewed_at'   => now(),
        ]);

        return response()->json(
            new EditRequestResource($editRequest->fresh()->load('user', 'showroom', 'reviewer'))
        );
    }

    // -------------------------------------------------------
    // Helpers
    // -------------------------------------------------------
    private function resolveModel(string $entryType, int $entryId): array
    {
        if ($entryType === 'cash') {
            return [DailyCashEntry::findOrFail($entryId), 'daily_cash_entries'];
        }
        return [DailyCardEntry::findOrFail($entryId), 'daily_card_entries'];
    }

    private function captureOriginal(mixed $model, string $entryType, array $requestedChanges): array
    {
        $original = [];
        foreach (array_keys($requestedChanges) as $key) {
            $original[$key] = $model->$key ?? null;
        }
        return $original;
    }
}
