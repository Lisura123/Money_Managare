<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CardStatementReportRequest;
use App\Http\Requests\DateRangeReportRequest;
use App\Http\Requests\DailySummaryReportRequest;
use App\Http\Requests\ShowroomReportRequest;
use App\Models\AdminCardAdjustment;
use App\Models\AdminCashAdjustment;
use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use App\Models\DailyCashEntry;
use App\Models\SelfTransaction;
use App\Models\Showroom;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Response;

class ReportController extends Controller
{
    /**
     * Daily Summary Report — all showrooms for a single date.
     */
    public function dailySummary(DailySummaryReportRequest $request): Response
    {
        $from = $request->from;
        $to   = $request->to;
        $isSingleDay = ($from === $to);

        $query = Showroom::with([
            'cardAccounts',
            'dailyCashEntries' => fn ($q) => $q->whereBetween('entry_date', [$from, $to])->with('user'),
            'dailyCardEntries' => fn ($q) => $q->whereBetween('entry_date', [$from, $to])->with('user', 'cardAccount'),
        ]);

        if ($request->filled('showroom_id')) {
            $query->where('id', $request->showroom_id);
        }

        $showrooms = $query->get();

        $grandCashTotal     = 0;
        $grandCardTotal     = 0;
        $grandMainCashTotal = 0;
        $grandManoCashTotal = 0;

        foreach ($showrooms as $showroom) {
            $showroom->cash_total      = $showroom->dailyCashEntries->sum('cash_amount');
            $showroom->card_total      = $showroom->dailyCardEntries->sum('amount');
            $showroom->main_cash_total = $showroom->dailyCashEntries->where('cash_account_type', 'main')->sum('cash_amount');
            $showroom->mano_cash_total = $showroom->dailyCashEntries->where('cash_account_type', 'mano')->sum('cash_amount');

            // Group cash entries by date then account type
            $showroom->cash_entries_by_type = $showroom->dailyCashEntries
                ->groupBy('cash_account_type')
                ->sortKeys();

            // Group card entries by card account
            $showroom->card_entries_by_account = $showroom->dailyCardEntries
                ->groupBy('card_account_id')
                ->map(fn ($entries) => [
                    'card_account' => $entries->first()->cardAccount,
                    'total'        => $entries->sum('amount'),
                    'entries'      => $entries,
                ]);

            $grandCashTotal     += $showroom->cash_total;
            $grandCardTotal     += $showroom->card_total;
            $grandMainCashTotal += $showroom->main_cash_total;
            $grandManoCashTotal += $showroom->mano_cash_total;
        }

        $pdf = Pdf::loadView('reports.daily-summary', compact(
            'showrooms', 'from', 'to', 'isSingleDay', 'grandCashTotal', 'grandCardTotal',
            'grandMainCashTotal', 'grandManoCashTotal'
        ))->setPaper('a4', 'portrait');

        $filename = $isSingleDay
            ? 'daily-summary-' . $from . '.pdf'
            : 'daily-summary-' . $from . '-to-' . $to . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * Showroom Report — entries, adjustments, and totals for a showroom over a date range.
     */
    public function showroom(ShowroomReportRequest $request): Response
    {
        $showroom = Showroom::findOrFail($request->showroom_id);
        $from     = $request->from;
        $to       = $request->to;

        $cashEntries = DailyCashEntry::where('showroom_id', $showroom->id)
            ->whereBetween('entry_date', [$from, $to])
            ->with('user', 'adjustments.admin')
            ->orderBy('entry_date')
            ->get();

        $cardEntries = DailyCardEntry::where('showroom_id', $showroom->id)
            ->whereBetween('entry_date', [$from, $to])
            ->with('user', 'cardAccount', 'adjustments.admin')
            ->orderBy('entry_date')
            ->get();

        // Stand-alone adjustments (not attached to a specific entry in this range) — covered via relations above
        $cashTotal          = $cashEntries->sum('cash_amount');
        $cardTotal          = $cardEntries->sum('amount');
        $cashAdjTotal       = $cashEntries->flatMap->adjustments->sum('adjusted_amount');
        $cardAdjTotal       = $cardEntries->flatMap->adjustments->sum('adjusted_amount');

        $pdf = Pdf::loadView('reports.showroom', compact(
            'showroom', 'from', 'to',
            'cashEntries', 'cardEntries',
            'cashTotal', 'cardTotal',
            'cashAdjTotal', 'cardAdjTotal'
        ))->setPaper('a4', 'landscape');

        $slug     = strtolower(preg_replace('/\s+/', '-', $showroom->name));
        $filename = "showroom-{$slug}-{$from}-to-{$to}.pdf";

        return $pdf->download($filename);
    }

    /**
     * Card Account Statement — entries, adjustments, and self-transactions for one card account.
     */
    public function cardStatement(CardStatementReportRequest $request): Response
    {
        $cardAccount = CardAccount::with('showroom')->findOrFail($request->card_account_id);
        $from        = $request->from;
        $to          = $request->to;

        $cardEntries = DailyCardEntry::where('card_account_id', $cardAccount->id)
            ->whereBetween('entry_date', [$from, $to])
            ->with('user')
            ->orderBy('entry_date')
            ->get();

        // Adjustments for entries in this range
        $entryIds    = $cardEntries->pluck('id');
        $adjustments = AdminCardAdjustment::whereIn('daily_card_entry_id', $entryIds)
            ->with('admin', 'dailyCardEntry')
            ->get();

        $selfTxOut = SelfTransaction::where('from_card_account_id', $cardAccount->id)
            ->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
            ->with('toCardAccount.showroom', 'admin')
            ->orderBy('created_at')
            ->get();

        $selfTxIn = SelfTransaction::where('to_card_account_id', $cardAccount->id)
            ->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
            ->with('fromCardAccount.showroom', 'admin')
            ->orderBy('created_at')
            ->get();

        $entryTotal   = $cardEntries->sum('amount');
        $adjTotal     = $adjustments->sum('adjusted_amount');
        $txOutTotal   = $selfTxOut->sum('amount');
        $txInTotal    = $selfTxIn->sum('amount');
        $netMovement  = $entryTotal + $adjTotal + $txInTotal - $txOutTotal;

        $pdf = Pdf::loadView('reports.card-statement', compact(
            'cardAccount', 'from', 'to',
            'cardEntries', 'adjustments',
            'selfTxOut', 'selfTxIn',
            'entryTotal', 'adjTotal',
            'txOutTotal', 'txInTotal', 'netMovement'
        ))->setPaper('a4', 'portrait');

        $filename = "card-statement-{$cardAccount->bank_name}-{$cardAccount->last_four}-{$from}-to-{$to}.pdf";
        $filename = strtolower(preg_replace('/\s+/', '-', $filename));

        return $pdf->download($filename);
    }

    /**
     * Self-Transaction Report — all transfers in a date range.
     */
    public function selfTransactions(DateRangeReportRequest $request): Response
    {
        $from = $request->from;
        $to   = $request->to;

        $transactions = SelfTransaction::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
            ->with('fromCardAccount.showroom', 'toCardAccount.showroom', 'admin')
            ->orderBy('created_at')
            ->get();

        $totalAmount = $transactions->sum('amount');

        $pdf = Pdf::loadView('reports.self-transactions', compact(
            'transactions', 'from', 'to', 'totalAmount'
        ))->setPaper('a4', 'landscape');

        $filename = "self-transactions-{$from}-to-{$to}.pdf";

        return $pdf->download($filename);
    }

    /**
     * Adjustments Report — all cash & card adjustments in a date range grouped by showroom.
     */
    public function adjustments(DateRangeReportRequest $request): Response
    {
        $from = $request->from;
        $to   = $request->to;

        $cashAdjustments = AdminCashAdjustment::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
            ->with('admin', 'dailyCashEntry.showroom', 'dailyCashEntry.user')
            ->orderBy('created_at')
            ->get();

        $cardAdjustments = AdminCardAdjustment::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
            ->with('admin', 'dailyCardEntry.showroom', 'dailyCardEntry.user', 'dailyCardEntry.cardAccount')
            ->orderBy('created_at')
            ->get();

        // Group by showroom
        $cashByShowroom = $cashAdjustments->groupBy(fn ($a) => $a->dailyCashEntry->showroom->name ?? 'Unknown');
        $cardByShowroom = $cardAdjustments->groupBy(fn ($a) => $a->dailyCardEntry->showroom->name ?? 'Unknown');

        $cashTotal = $cashAdjustments->sum('adjusted_amount');
        $cardTotal = $cardAdjustments->sum('adjusted_amount');

        $pdf = Pdf::loadView('reports.adjustments', compact(
            'cashByShowroom', 'cardByShowroom',
            'cashTotal', 'cardTotal',
            'from', 'to'
        ))->setPaper('a4', 'portrait');

        $filename = "adjustments-{$from}-to-{$to}.pdf";

        return $pdf->download($filename);
    }
}
