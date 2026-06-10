<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AdminCardAdjustmentRequest;
use App\Http\Resources\AdminCardAdjustmentResource;
use App\Models\AdminCardAdjustment;
use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminCardAdjustmentController extends Controller
{
    public function store(AdminCardAdjustmentRequest $request, DailyCardEntry $dailyCardEntry): JsonResponse
    {
        $adjustment = DB::transaction(function () use ($request, $dailyCardEntry) {
            $adj = AdminCardAdjustment::create([
                'daily_card_entry_id' => $dailyCardEntry->id,
                'admin_id'            => $request->user()->id,
                'adjusted_amount'     => $request->adjusted_amount,
                'reason'              => $request->reason,
            ]);

            CardAccount::lockForUpdate()
                ->findOrFail($dailyCardEntry->card_account_id)
                ->increment('current_balance', (float) $request->adjusted_amount);

            return $adj;
        });

        return response()->json(new AdminCardAdjustmentResource($adjustment->load('admin', 'dailyCardEntry.cardAccount')), 201);
    }

    public function index(DailyCardEntry $dailyCardEntry): JsonResponse
    {
        $adjustments = $dailyCardEntry->adjustments()->with('admin')->get();
        return AdminCardAdjustmentResource::collection($adjustments)->toResponse(request());
    }

    /**
     * List all card adjustments (standalone — not entry-scoped).
     */
    public function all(Request $request): JsonResponse
    {
        $query = AdminCardAdjustment::with(['admin', 'dailyCardEntry.cardAccount'])
            ->orderByDesc('created_at');

        if ($request->filled('card_account_id')) {
            $query->whereHas('dailyCardEntry', fn ($q) =>
                $q->where('card_account_id', $request->card_account_id));
        }

        if ($request->filled('date')) {
            $query->whereHas('dailyCardEntry', fn ($q) =>
                $q->whereDate('entry_date', $request->date));
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereHas('dailyCardEntry', fn ($q) =>
                $q->whereBetween('entry_date', [$request->from, $request->to]));
        }

        $adjustments = $query->paginate(20);
        return AdminCardAdjustmentResource::collection($adjustments)->toResponse(request());
    }

    /**
     * Create a card adjustment for today's entry of a card account.
     * Requires card_account_id. Creates today's card entry if it doesn't exist.
     */
    public function storeForAccount(AdminCardAdjustmentRequest $request): JsonResponse
    {
        $cardAccountId = $request->input('card_account_id');

        $cardAccount = CardAccount::findOrFail($cardAccountId);

        $adjustment = DB::transaction(function () use ($request, $cardAccount, $cardAccountId) {
            $entry = DailyCardEntry::firstOrCreate(
                [
                    'card_account_id' => $cardAccountId,
                    'entry_date'      => now()->toDateString(),
                ],
                [
                    'showroom_id' => $cardAccount->showroom_id,
                    'user_id'     => $request->user()->id,
                    'amount'      => 0,
                    'is_locked'   => false,
                ]
            );

            $adj = AdminCardAdjustment::create([
                'daily_card_entry_id' => $entry->id,
                'admin_id'            => $request->user()->id,
                'adjusted_amount'     => $request->adjusted_amount,
                'reason'              => $request->reason,
            ]);

            CardAccount::lockForUpdate()
                ->findOrFail($cardAccountId)
                ->increment('current_balance', (float) $request->adjusted_amount);

            return $adj;
        });

        return response()->json(new AdminCardAdjustmentResource($adjustment->load('admin', 'dailyCardEntry.cardAccount')), 201);
    }

    public function destroy(AdminCardAdjustment $adminCardAdjustment): JsonResponse
    {
        DB::transaction(function () use ($adminCardAdjustment) {
            $entry = $adminCardAdjustment->dailyCardEntry;

            // Reverse the adjustment effect on card account balance
            CardAccount::lockForUpdate()
                ->findOrFail($entry->card_account_id)
                ->decrement('current_balance', (float) $adminCardAdjustment->adjusted_amount);

            $adminCardAdjustment->delete();
        });

        return response()->json(['message' => 'Card adjustment deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $adjustments = AdminCardAdjustment::with('dailyCardEntry')
            ->whereIn('id', $request->ids)
            ->get();

        DB::transaction(function () use ($adjustments) {
            foreach ($adjustments as $adjustment) {
                CardAccount::lockForUpdate()
                    ->findOrFail($adjustment->dailyCardEntry->card_account_id)
                    ->decrement('current_balance', (float) $adjustment->adjusted_amount);

                $adjustment->delete();
            }
        });

        return response()->json(['message' => "Deleted {$adjustments->count()} card adjustments."]);
    }
}
