<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AdminCashAdjustmentRequest;
use App\Http\Resources\AdminCashAdjustmentResource;
use App\Models\AdminCashAdjustment;
use App\Models\BalanceUpdate;
use App\Models\DailyCashEntry;
use App\Models\SelfTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

        if ($request->filled('date')) {
            $query->whereHas('dailyCashEntry', fn ($q) =>
                $q->whereDate('entry_date', $request->date));
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereHas('dailyCashEntry', fn ($q) =>
                $q->whereBetween('entry_date', [$request->from, $request->to]));
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
        $cashAccountType = $request->input('cash_account_type', 'main');
        $showroomId = $request->input('showroom_id')
            ?? \App\Models\Showroom::orderBy('id')->value('id');

        $entry = DailyCashEntry::firstOrCreate(
            [
                'showroom_id'       => $showroomId,
                'entry_date'        => now()->toDateString(),
                'cash_account_type' => $cashAccountType,
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

        // Record the change in the Balance Updates log (main cash only).
        if ($cashAccountType === 'main') {
            $previous = $this->mainCashBalance($showroomId) - (float) $request->adjusted_amount;
            $new      = $previous + (float) $request->adjusted_amount;
            BalanceUpdate::create([
                'showroom_id'     => $showroomId,
                'account_type'    => 'main_cash',
                'card_account_id' => null,
                'account_label'   => 'Main Cash',
                'previous_amount' => round($previous, 2),
                'new_amount'      => round($new, 2),
                'change_amount'   => round((float) $request->adjusted_amount, 2),
                'reason'          => $request->reason,
                'user_id'         => $request->user()->id,
            ]);
        }

        return response()->json(new AdminCashAdjustmentResource($adjustment->load('admin', 'dailyCashEntry')), 201);
    }

    /**
     * Live computed main cash balance for a showroom:
     * SUM(main entries) + SUM(main adjustments) − SUM(self-transfers out) + SUM(self-transfers in).
     */
    private function mainCashBalance(int $showroomId): float
    {
        $entries = (float) DailyCashEntry::where('showroom_id', $showroomId)
            ->where('cash_account_type', 'main')
            ->sum('cash_amount');

        $adj = (float) DB::table('admin_cash_adjustments')
            ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
            ->where('daily_cash_entries.showroom_id', $showroomId)
            ->where('daily_cash_entries.cash_account_type', 'main')
            ->sum('admin_cash_adjustments.adjusted_amount');

        $selfOut = (float) SelfTransaction::where('from_account_type', 'main')
            ->where('from_showroom_id', $showroomId)->sum('amount');
        $selfIn  = (float) SelfTransaction::where('to_account_type', 'main')
            ->where('to_showroom_id', $showroomId)->sum('amount');

        return $entries + $adj - $selfOut + $selfIn;
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
