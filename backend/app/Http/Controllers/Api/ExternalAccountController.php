<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CashTransaction;
use App\Models\DailyCashEntry;
use App\Models\ExternalAccount;
use App\Models\SelfTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ExternalAccountController extends Controller
{
    public function index(): JsonResponse
    {
        $accounts = ExternalAccount::orderBy('name')->get();

        // Compute live balance: daily cash entries + self-transfers received
        $accounts->each(function (ExternalAccount $acc) {
            if ($acc->cash_account_type) {
                $cashTotal = (float) DailyCashEntry::where('cash_account_type', $acc->cash_account_type)
                    ->sum('cash_amount');

                $selfIn = (float) SelfTransaction::where('to_external_account_id', $acc->id)->sum('amount');

                $acc->balance = $cashTotal + $selfIn;
            }
        });

        $result = $accounts->map(fn ($a) => [
            'id'                => $a->id,
            'name'              => $a->name,
            'balance'           => $a->balance,
            'cash_account_type' => $a->cash_account_type,
        ])->values()->toArray();

        // Synthetic "Main Account" — cumulative running balance across all time
        // Formula: SUM(main cash entries) + SUM(main cash adjustments)
        //          - SUM(cash_transactions sent from main) + SUM(cash_transactions received into main)
        $mainEntries = (float) DailyCashEntry::where('cash_account_type', 'main')->sum('cash_amount');

        $mainAdj = (float) DB::table('admin_cash_adjustments')
            ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
            ->where('daily_cash_entries.cash_account_type', 'main')
            ->sum('admin_cash_adjustments.adjusted_amount');

        $mainOut = (float) CashTransaction::where('from_account_type', 'main')->sum('amount');
        $mainIn  = (float) CashTransaction::where('to_account_type', 'main')->sum('amount');

        array_unshift($result, [
            'id'                => -1,
            'name'              => 'Main Account',
            'balance'           => round($mainEntries + $mainAdj - $mainOut + $mainIn, 2),
            'cash_account_type' => 'main',
        ]);

        return response()->json($result);
    }
}
