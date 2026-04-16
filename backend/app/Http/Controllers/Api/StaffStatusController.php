<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyCashEntry;
use App\Models\DailyCardEntry;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StaffStatusController extends Controller
{
    /**
     * GET /api/today-status
     *
     * Returns today's submission status for the authenticated staff member.
     * Tells the staff dashboard which entries have been submitted today.
     */
    public function today(Request $request): JsonResponse
    {
        $user  = $request->user();
        $today = Carbon::today()->toDateString();

        // Main cash entry for today
        $mainEntry = DailyCashEntry::where('user_id', $user->id)
            ->where('entry_date', $today)
            ->where('cash_account_type', 'main')
            ->first();

        // Mano's cash entry for today
        $manoEntry = DailyCashEntry::where('user_id', $user->id)
            ->where('entry_date', $today)
            ->where('cash_account_type', 'mano')
            ->first();

        // Card entries for today (multiple allowed)
        $cardEntries = DailyCardEntry::where('user_id', $user->id)
            ->where('entry_date', $today)
            ->with('cardAccount')
            ->get();

        $cardTotal = $cardEntries->sum('amount');

        return response()->json([
            'date'      => $today,
            'main_cash' => [
                'submitted' => $mainEntry !== null,
                'amount'    => $mainEntry ? (float) $mainEntry->cash_amount : null,
                'entry_id'  => $mainEntry?->id,
            ],
            'mano_cash' => [
                'submitted' => $manoEntry !== null,
                'amount'    => $manoEntry ? (float) $manoEntry->cash_amount : null,
                'entry_id'  => $manoEntry?->id,
            ],
            'card' => [
                'count'   => $cardEntries->count(),
                'total'   => (float) $cardTotal,
                'entries' => $cardEntries->map(fn ($e) => [
                    'id'        => $e->id,
                    'amount'    => (float) $e->amount,
                    'bank_name' => $e->cardAccount?->bank_name,
                    'last_four' => $e->cardAccount?->last_four,
                ])->values()->toArray(),
            ],
        ]);
    }
}
