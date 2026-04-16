<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AdminCashAdjustmentRequest;
use App\Http\Resources\AdminCashAdjustmentResource;
use App\Models\AdminCashAdjustment;
use App\Models\DailyCashEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminCashAdjustmentController extends Controller
{
    public function store(AdminCashAdjustmentRequest $request, DailyCashEntry $dailyCashEntry): JsonResponse
    {
        $adjustment = AdminCashAdjustment::create([
            'daily_cash_entry_id' => $dailyCashEntry->id,
            'admin_id'            => $request->user()->id,
            'adjusted_amount'     => $request->adjusted_amount,
            'reason'              => $request->reason,
        ]);

        return response()->json(new AdminCashAdjustmentResource($adjustment->load('admin')), 201);
    }

    public function index(DailyCashEntry $dailyCashEntry): JsonResponse
    {
        $adjustments = $dailyCashEntry->adjustments()->with('admin')->get();
        return AdminCashAdjustmentResource::collection($adjustments)->toResponse(request());
    }

    /**
     * List all cash adjustments (standalone — not entry-scoped).
     */
    public function all(Request $request): JsonResponse
    {
        $query = AdminCashAdjustment::with(['admin', 'dailyCashEntry'])
            ->orderByDesc('created_at');

        if ($request->filled('showroom_id')) {
            $query->whereHas('dailyCashEntry', fn ($q) =>
                $q->where('showroom_id', $request->showroom_id));
        }

        $adjustments = $query->paginate(20);
        return AdminCashAdjustmentResource::collection($adjustments)->toResponse(request());
    }

    /**
     * Create a cash adjustment for today's entry of a showroom.
     * Requires showroom_id in the request body. Creates today's cash entry if it doesn't exist.
     */
    public function storeForShowroom(AdminCashAdjustmentRequest $request): JsonResponse
    {
        $showroomId = $request->input('showroom_id');

        $entry = DailyCashEntry::firstOrCreate(
            [
                'showroom_id' => $showroomId,
                'entry_date'  => now()->toDateString(),
            ],
            [
                'user_id'     => $request->user()->id,
                'cash_amount' => 0,
                'is_locked'   => false,
            ]
        );

        $adjustment = AdminCashAdjustment::create([
            'daily_cash_entry_id' => $entry->id,
            'admin_id'            => $request->user()->id,
            'adjusted_amount'     => $request->adjusted_amount,
            'reason'              => $request->reason,
        ]);

        return response()->json(new AdminCashAdjustmentResource($adjustment->load('admin')), 201);
    }

    public function destroy(AdminCashAdjustment $adminCashAdjustment): JsonResponse
    {
        $adminCashAdjustment->delete();

        return response()->json(['message' => 'Cash adjustment deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $count = AdminCashAdjustment::whereIn('id', $request->ids)->delete();

        return response()->json(['message' => "Deleted {$count} cash adjustments."]);
    }
}
