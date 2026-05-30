<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyCashEntry;
use App\Models\ExternalAccount;
use App\Models\SelfTransaction;
use Illuminate\Http\JsonResponse;

class ExternalAccountController extends Controller
{
    public function index(): JsonResponse
    {
        $accounts = ExternalAccount::orderBy('name')->get();

        // Compute live balance: daily cash entries + self-transfers received − self-transfers sent
        $accounts->each(function (ExternalAccount $acc) {
            if ($acc->cash_account_type) {
                $cashTotal = (float) DailyCashEntry::where('cash_account_type', $acc->cash_account_type)
                    ->sum('cash_amount');

                $selfIn  = (float) SelfTransaction::where('to_external_account_id', $acc->id)->sum('amount');
                $selfOut = (float) SelfTransaction::where('from_external_account_id', $acc->id)->sum('amount');

                $acc->balance = $cashTotal + $selfIn - $selfOut;
            }
        });

        return response()->json(
            $accounts->map(fn ($a) => [
                'id'                => $a->id,
                'name'              => $a->name,
                'balance'           => $a->balance,
                'cash_account_type' => $a->cash_account_type,
            ])
        );
    }
}
