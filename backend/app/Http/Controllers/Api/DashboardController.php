<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use App\Models\DailyCashEntry;
use App\Models\Showroom;
use App\Services\BalanceService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __construct(private BalanceService $balanceService) {}

    /**
     * GET /api/admin/dashboard-summary
     *
     * Returns today's and yesterday's financial totals, per-showroom breakdowns,
     * and a server_date so the client knows what the server considers "today".
     */
    public function summary(): JsonResponse
    {
        $today     = Carbon::today()->toDateString();
        $yesterday = Carbon::yesterday()->toDateString();

        return response()->json([
            'server_date'     => $today,
            'last_updated_at' => now()->toDateTimeString(),
            'today'           => $this->buildSnapshot($today),
            'yesterday'       => $this->buildSnapshot($yesterday),
        ]);
    }

    /**
     * GET /api/records-summary
     *
     * Returns comprehensive, date-scoped Total Cash, Total Bank and Total Mano's
     * amounts. Each total combines entries + adjustments + self-transfers within
     * the selected single date (?date=) or range (?from=&to=). With no filter it
     * falls back to today.
     *
     * Cash (main)  = main entries + main adjustments − main transfers out + main transfers in
     * Mano         = mano entries + mano adjustments − mano transfers out + mano transfers in
     * Bank (card)  = card entries + card adjustments − card transfers out + card transfers in
     */
    public function recordsSummary(Request $request): JsonResponse
    {
        $hasRange = $request->filled('from') && $request->filled('to');

        if ($hasRange) {
            $startDate = $request->from;
            $endDate   = $request->to;
        } else {
            $date      = $request->filled('date') ? $request->date : Carbon::today()->toDateString();
            $startDate = $date;
            $endDate   = $date;
        }

        $start = $startDate . ' 00:00:00';
        $end   = $endDate . ' 23:59:59';

        // --- Entries (filtered by entry_date) ---
        $cashEntries = fn (string $type) => (float) DailyCashEntry::query()
            ->where('cash_account_type', $type)
            ->whereBetween('entry_date', [$startDate, $endDate])
            ->sum('cash_amount');

        $cardEntries = (float) DailyCardEntry::query()
            ->whereBetween('entry_date', [$startDate, $endDate])
            ->sum('amount');

        // --- Adjustments (filtered by created_at) ---
        $cashAdj = fn (string $type) => (float) DB::table('admin_cash_adjustments')
            ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
            ->where('daily_cash_entries.cash_account_type', $type)
            ->whereBetween('admin_cash_adjustments.created_at', [$start, $end])
            ->sum('admin_cash_adjustments.adjusted_amount');

        $cardAdj = (float) DB::table('admin_card_adjustments')
            ->whereBetween('created_at', [$start, $end])
            ->sum('adjusted_amount');

        // --- Self-transfers (filtered by created_at) ---
        $transferOut = fn (string $type) => (float) DB::table('self_transactions')
            ->where('from_account_type', $type)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        $transferIn = fn (string $type) => (float) DB::table('self_transactions')
            ->where('to_account_type', $type)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        // Mano flows are tracked by external_account_id (to_account_type is null for
        // external accounts), so resolve them via the mano external account ids.
        $manoExtIds = \App\Models\ExternalAccount::where('cash_account_type', 'mano')->pluck('id')->all();

        $manoTransferIn = (float) DB::table('self_transactions')
            ->whereIn('to_external_account_id', $manoExtIds)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        $manoTransferOut = (float) DB::table('self_transactions')
            ->whereIn('from_external_account_id', $manoExtIds)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        $cashTotal = $cashEntries('main') + $cashAdj('main') - $transferOut('main') + $transferIn('main');
        $manoTotal = $cashEntries('mano') + $cashAdj('mano') - $manoTransferOut + $manoTransferIn;
        $bankTotal = $cardEntries + $cardAdj - $transferOut('card') + $transferIn('card');

        return response()->json([
            'cash_total' => round($cashTotal, 2),
            'mano_total' => round($manoTotal, 2),
            'bank_total' => round($bankTotal, 2),
        ]);
    }

    // -------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------

    private function buildSnapshot(string $date): array
    {
        $global = $this->balanceService->getGlobalDailySummary($date);

        $showroomIds  = Showroom::pluck('id')->toArray();
        $perShowroom  = [];
        $showroomNames = Showroom::whereIn('id', $showroomIds)->pluck('name', 'id');

        foreach ($showroomIds as $sid) {
            $sr  = $this->balanceService->getShowroomDailySummary($sid, $date);
            $sr['showroom_name'] = $showroomNames[$sid] ?? 'Unknown';
            $perShowroom[] = $sr;
        }

        return [
            'cash_main_total'    => number_format($global['cash_main_total'],    2, '.', ''),
            'cash_mano_total'    => number_format($global['cash_mano_total'],    2, '.', ''),
            'card_total'         => number_format($global['card_total'],         2, '.', ''),
            'grand_total'        => number_format($global['grand_total'],        2, '.', ''),
            'cash_main_adjusted' => number_format($global['cash_main_adjusted'], 2, '.', ''),
            'cash_mano_adjusted' => number_format($global['cash_mano_adjusted'], 2, '.', ''),
            'card_adjusted'      => number_format($global['card_adjusted'],      2, '.', ''),
            'grand_adjusted'     => number_format($global['grand_adjusted'],     2, '.', ''),
            'per_showroom'       => array_map(function (array $s): array {
                return [
                    'showroom_id'         => $s['showroom_id'],
                    'showroom_name'       => $s['showroom_name'],
                    'cash_main_total'     => number_format($s['cash_main_total'],    2, '.', ''),
                    'cash_mano_total'     => number_format($s['cash_mano_total'],    2, '.', ''),
                    'card_total'          => number_format($s['card_total'],         2, '.', ''),
                    'combined_total'      => number_format($s['combined_total'],     2, '.', ''),
                    'cash_main_adjusted'  => number_format($s['cash_main_adjusted'], 2, '.', ''),
                    'cash_mano_adjusted'  => number_format($s['cash_mano_adjusted'], 2, '.', ''),
                    'card_adjusted'       => number_format($s['card_adjusted'],      2, '.', ''),
                    'entry_count'         => $s['entry_count'],
                ];
            }, $perShowroom),
        ];
    }

    /**
     * GET /api/admin/verify-balances
     *
     * Compares every card account's stored current_balance against the
     * recalculated value from transaction history. Returns mismatches.
     */
    public function verifyBalances(): JsonResponse
    {
        $accounts   = CardAccount::all();
        $mismatches = [];

        foreach ($accounts as $account) {
            $recalculated = $this->balanceService->recalculateCardBalance($account);
            $stored       = (float) $account->current_balance;
            $diff         = abs($recalculated - $stored);

            if ($diff > 0.001) {
                $mismatches[] = [
                    'card_account_id'      => $account->id,
                    'bank_name'            => $account->bank_name,
                    'last_four'            => $account->last_four,
                    'stored_balance'       => number_format($stored,       2, '.', ''),
                    'recalculated_balance' => number_format($recalculated, 2, '.', ''),
                    'difference'           => number_format($diff,         2, '.', ''),
                ];
            }
        }

        return response()->json([
            'checked'     => $accounts->count(),
            'mismatches'  => $mismatches,
            'all_correct' => empty($mismatches),
        ]);
    }

    /**
     * POST /api/admin/fix-balances
     *
     * Corrects any card account balances that don't match recalculated values.
     */
    public function fixBalances(): JsonResponse
    {
        $accounts = CardAccount::all();
        $fixed    = [];

        DB::transaction(function () use ($accounts, &$fixed) {
            foreach ($accounts as $account) {
                $recalculated = $this->balanceService->recalculateCardBalance($account);
                $stored       = (float) $account->current_balance;
                $diff         = abs($recalculated - $stored);

                if ($diff > 0.001) {
                    $account->update(['current_balance' => $recalculated]);
                    $fixed[] = [
                        'card_account_id' => $account->id,
                        'old_balance'     => number_format($stored,       2, '.', ''),
                        'new_balance'     => number_format($recalculated, 2, '.', ''),
                    ];
                }
            }
        });

        return response()->json([
            'fixed'    => count($fixed),
            'accounts' => $fixed,
        ]);
    }
}
