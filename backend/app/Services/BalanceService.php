<?php

namespace App\Services;

use App\Models\AdminCardAdjustment;
use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use App\Models\SelfTransaction;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class BalanceService
{
    /**
     * Recompute a card account's balance from scratch using its full transaction history.
     *
     * Formula:
     *   opening_balance
     *   + SUM(daily_card_entries.amount)
     *   + SUM(admin_card_adjustments.adjusted_amount) via entry relationship
     *   + SUM(self_transactions.amount WHERE to_card_account_id)
     *   - SUM(self_transactions.amount WHERE from_card_account_id)
     */
    public function recalculateCardBalance(CardAccount $card): float
    {
        $entries = (float) DailyCardEntry::where('card_account_id', $card->id)->sum('amount');

        $adjustments = (float) AdminCardAdjustment::whereHas(
            'dailyCardEntry',
            fn ($q) => $q->where('card_account_id', $card->id)
        )->sum('adjusted_amount');

        $inflows  = (float) SelfTransaction::where('to_card_account_id', $card->id)->sum('amount');
        $outflows = (float) SelfTransaction::where('from_card_account_id', $card->id)->sum('amount');

        return (float) $card->opening_balance + $entries + $adjustments + $inflows - $outflows;
    }

    /**
     * Return the complete daily breakdown for one showroom.
     */
    public function getShowroomDailySummary(int $showroomId, string $date): array
    {
        $cashRows = DB::table('daily_cash_entries')
            ->select('cash_account_type', DB::raw('SUM(cash_amount) as total'))
            ->where('showroom_id', $showroomId)
            ->whereDate('entry_date', $date)
            ->groupBy('cash_account_type')
            ->get()
            ->keyBy('cash_account_type');

        $cardRow = DB::table('daily_card_entries')
            ->selectRaw('SUM(amount) as total, COUNT(*) as entry_count')
            ->where('showroom_id', $showroomId)
            ->whereDate('entry_date', $date)
            ->first();

        $cashAdjRows = DB::table('admin_cash_adjustments')
            ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
            ->select('daily_cash_entries.cash_account_type', DB::raw('SUM(admin_cash_adjustments.adjusted_amount) as total'))
            ->where('daily_cash_entries.showroom_id', $showroomId)
            ->whereDate('daily_cash_entries.entry_date', $date)
            ->groupBy('daily_cash_entries.cash_account_type')
            ->get()
            ->keyBy('cash_account_type');

        $cardAdj = (float) DB::table('admin_card_adjustments')
            ->join('daily_card_entries', 'admin_card_adjustments.daily_card_entry_id', '=', 'daily_card_entries.id')
            ->where('daily_card_entries.showroom_id', $showroomId)
            ->whereDate('daily_card_entries.entry_date', $date)
            ->sum('admin_card_adjustments.adjusted_amount');

        $cashMain    = (float) ($cashRows['main']->total ?? 0);
        $cashMano    = (float) ($cashRows['mano']->total ?? 0);
        $cardTotal   = (float) ($cardRow->total ?? 0);
        $entryCount  = (int)   ($cardRow->entry_count ?? 0);
        $cashMainAdj = (float) ($cashAdjRows['main']->total ?? 0);
        $cashManoAdj = (float) ($cashAdjRows['mano']->total ?? 0);

        return [
            'showroom_id'        => $showroomId,
            'date'               => $date,
            'cash_main_total'    => $cashMain,
            'cash_mano_total'    => $cashMano,
            'card_total'         => $cardTotal,
            'combined_total'     => $cashMain + $cashMano + $cardTotal,
            'cash_main_adjusted' => $cashMain + $cashMainAdj,
            'cash_mano_adjusted' => $cashMano + $cashManoAdj,
            'card_adjusted'      => $cardTotal + $cardAdj,
            'entry_count'        => $entryCount,
        ];
    }

    /**
     * Return the complete daily breakdown across all showrooms.
     *
     * cash_main_adjusted = SUM(main entries) + SUM(main adj) - SUM(CT out from main) + SUM(CT in to main)
     * cash_mano_adjusted = SUM(mano entries) + SUM(mano adj) - SUM(CT out from mano) + SUM(CT in to mano)
     *
     * cash_transactions are admin-level operations (not showroom-specific) so they only
     * affect the GLOBAL totals, not the per-showroom breakdown.
     */
    public function getGlobalDailySummary(string $date): array
    {
        $cashRows = DB::table('daily_cash_entries')
            ->select('cash_account_type', DB::raw('SUM(cash_amount) as total'))
            ->whereDate('entry_date', $date)
            ->groupBy('cash_account_type')
            ->get()
            ->keyBy('cash_account_type');

        $cardTotal = (float) DB::table('daily_card_entries')
            ->whereDate('entry_date', $date)
            ->sum('amount');

        $cashAdjRows = DB::table('admin_cash_adjustments')
            ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
            ->select('daily_cash_entries.cash_account_type', DB::raw('SUM(admin_cash_adjustments.adjusted_amount) as total'))
            ->whereDate('daily_cash_entries.entry_date', $date)
            ->groupBy('daily_cash_entries.cash_account_type')
            ->get()
            ->keyBy('cash_account_type');

        $cardAdj = (float) DB::table('admin_card_adjustments')
            ->join('daily_card_entries', 'admin_card_adjustments.daily_card_entry_id', '=', 'daily_card_entries.id')
            ->whereDate('daily_card_entries.entry_date', $date)
            ->sum('admin_card_adjustments.adjusted_amount');

        // Cash transactions (admin-level transfers between/out-of cash accounts)
        // Filter by transaction_date = $date (the date column on cash_transactions)
        $cashTransactions = DB::table('cash_transactions')
            ->where('transaction_date', $date)
            ->get();

        $ctMainOut = (float) $cashTransactions->where('from_account_type', 'main')->sum('amount');
        $ctManoOut = (float) $cashTransactions->where('from_account_type', 'mano')->sum('amount');
        $ctMainIn  = (float) $cashTransactions->where('to_account_type', 'main')->sum('amount');
        $ctManoIn  = (float) $cashTransactions->where('to_account_type', 'mano')->sum('amount');

        $cashMain    = (float) ($cashRows['main']->total ?? 0);
        $cashMano    = (float) ($cashRows['mano']->total ?? 0);
        $cashMainAdj = (float) ($cashAdjRows['main']->total ?? 0);
        $cashManoAdj = (float) ($cashAdjRows['mano']->total ?? 0);

        // Net positions after all admin operations
        $cashMainNet = $cashMain + $cashMainAdj - $ctMainOut + $ctMainIn;
        $cashManoNet = $cashMano + $cashManoAdj - $ctManoOut + $ctManoIn;
        $cardNet     = $cardTotal + $cardAdj;

        return [
            'date'               => $date,
            // Raw entry sums (what staff submitted — shown as secondary info)
            'cash_main_total'    => $cashMain,
            'cash_mano_total'    => $cashMano,
            'card_total'         => $cardTotal,
            'grand_total'        => $cashMain + $cashMano + $cardTotal,
            // Net positions after admin adjustments + cash transactions (primary display)
            'cash_main_adjusted' => $cashMainNet,
            'cash_mano_adjusted' => $cashManoNet,
            'card_adjusted'      => $cardNet,
            'grand_adjusted'     => $cashMainNet + $cashManoNet + $cardNet,
        ];
    }
}
