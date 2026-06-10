<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DailyCardEntryRequest;
use App\Http\Resources\DailyCardEntryResource;
use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DailyCardEntryController extends Controller
{
    public function store(DailyCardEntryRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin() && ! Setting::bankEntriesEnabled()) {
            return response()->json(['message' => 'Bank entries are currently disabled by the administrator.'], 422);
        }

        if (! $user->isAdmin() && ! Setting::isWithinEditWindow()) {
            return response()->json(['message' => 'Entry submission is only allowed during the edit window.'], 422);
        }

        // Ensure the card account belongs to the staff's showroom
        $cardAccount = CardAccount::where('id', $request->card_account_id)
            ->where('showroom_id', $user->showroom_id)
            ->where('is_active', true)
            ->firstOrFail();

        $entry = DB::transaction(function () use ($request, $user, $cardAccount) {
            $entry = DailyCardEntry::create([
                'showroom_id'     => $user->showroom_id,
                'user_id'         => $user->id,
                'card_account_id' => $cardAccount->id,
                'entry_date'      => $request->entry_date,
                'amount'          => $request->amount,
                'notes'           => $request->notes,
            ]);

            // Update card account balance
            $cardAccount->increment('current_balance', $request->amount);

            return $entry;
        });

        return response()->json(new DailyCardEntryResource($entry->load('showroom', 'user', 'cardAccount')), 201);
    }

    public function myHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        $entries = DailyCardEntry::where('user_id', $user->id)
            ->with('showroom', 'cardAccount', 'adjustments')
            ->orderByDesc('entry_date')
            ->paginate(20);

        return response()->json($entries);
    }

    /**
     * Admin: view all entries with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = DailyCardEntry::with('showroom', 'user', 'cardAccount', 'adjustments')
            ->where('amount', '>', 0);

        if ($request->filled('showroom_id')) {
            $query->where('showroom_id', $request->showroom_id);
        }

        if ($request->filled('date')) {
            $query->whereDate('entry_date', $request->date);
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereBetween('entry_date', [$request->from, $request->to]);
        }

        if ($request->filled('card_account_id')) {
            $query->where('card_account_id', $request->card_account_id);
        }

        // Calculate total across ALL matching entries (not just the current page)
        $totalAmount = (clone $query)->sum('amount');

        $entries  = $query->orderByDesc('entry_date')->paginate(20);
        $response = DailyCardEntryResource::collection($entries)->response()->getData(true);

        // Inject total_amount into the existing meta object
        $response['meta']['total_amount'] = round((float) $totalAmount, 2);

        return response()->json($response);
    }

    /**
     * Admin: update a card entry (can edit locked entries).
     * Staff must submit an edit request instead.
     */
    public function update(DailyCardEntryRequest $request, DailyCardEntry $dailyCardEntry): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin()) {
            return response()->json(['message' => 'Please submit an edit request instead.'], 403);
        }

        $entry = DB::transaction(function () use ($request, $dailyCardEntry) {
            $oldAmount = (float) $dailyCardEntry->amount;

            $dailyCardEntry->update($request->validated());

            // Recalculate card balance if amount changed
            if ($request->has('amount')) {
                $newAmount = (float) $dailyCardEntry->fresh()->amount;
                $diff = $newAmount - $oldAmount;
                if (abs($diff) > 0.001) {
                    $dailyCardEntry->cardAccount()->increment('current_balance', $diff);
                }
            }

            return $dailyCardEntry;
        });

        return response()->json(new DailyCardEntryResource($entry->load('showroom', 'user', 'cardAccount')));
    }

    public function destroy(DailyCardEntry $dailyCardEntry): JsonResponse
    {
        DB::transaction(function () use ($dailyCardEntry) {
            // Reverse adjustments from card account balance
            $adjustmentTotal = (float) $dailyCardEntry->adjustments()->sum('adjusted_amount');
            // Reverse the entry amount from card account balance
            $totalToReverse = (float) $dailyCardEntry->amount + $adjustmentTotal;

            if (abs($totalToReverse) > 0.001) {
                CardAccount::lockForUpdate()
                    ->findOrFail($dailyCardEntry->card_account_id)
                    ->decrement('current_balance', $totalToReverse);
            }

            $dailyCardEntry->adjustments()->delete();
            $dailyCardEntry->delete();
        });

        return response()->json(['message' => 'Card entry deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $entries = DailyCardEntry::whereIn('id', $request->ids)->get();

        DB::transaction(function () use ($entries) {
            foreach ($entries as $entry) {
                $adjustmentTotal = (float) $entry->adjustments()->sum('adjusted_amount');
                $totalToReverse = (float) $entry->amount + $adjustmentTotal;

                if (abs($totalToReverse) > 0.001) {
                    CardAccount::lockForUpdate()
                        ->findOrFail($entry->card_account_id)
                        ->decrement('current_balance', $totalToReverse);
                }

                $entry->adjustments()->delete();
                $entry->delete();
            }
        });

        return response()->json(['message' => "Deleted {$entries->count()} card entries."]);
    }
}
