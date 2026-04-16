<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CardAccount;
use App\Models\Showroom;
use App\Services\BalanceService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
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
