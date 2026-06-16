<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BalanceUpdateResource;
use App\Models\BalanceUpdate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BalanceUpdateController extends Controller
{
    /**
     * List balance updates (manual Main Cash / Bank balance changes).
     * Filterable by showroom_id, account_type, single date or date range.
     */
    public function index(Request $request): JsonResponse
    {
        $query = BalanceUpdate::with(['showroom', 'user'])
            ->orderByDesc('created_at');

        if ($request->filled('showroom_id')) {
            $query->where('showroom_id', $request->showroom_id);
        }

        if ($request->filled('account_type')) {
            $query->where('account_type', $request->account_type);
        }

        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->date);
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereBetween('created_at', [
                $request->from . ' 00:00:00',
                $request->to . ' 23:59:59',
            ]);
        }

        $updates = $query->paginate(
            (int) $request->input('per_page', 20)
        );

        return BalanceUpdateResource::collection($updates)->toResponse($request);
    }

    /**
     * Delete a single balance-update log entry.
     */
    public function destroy(BalanceUpdate $balanceUpdate): JsonResponse
    {
        $balanceUpdate->delete();

        return response()->json(['message' => 'Balance update deleted.']);
    }

    /**
     * Delete several balance-update log entries at once.
     */
    public function bulkDestroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ids'   => ['required', 'array', 'min:1'],
            'ids.*' => ['integer'],
        ]);

        $count = BalanceUpdate::whereIn('id', $validated['ids'])->delete();

        return response()->json(['message' => "Deleted {$count} balance update(s)."]);
    }
}
