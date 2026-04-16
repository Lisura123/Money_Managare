<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyCashEntry;
use App\Models\ExternalAccount;
use Illuminate\Http\JsonResponse;

class ExternalAccountController extends Controller
{
    public function index(): JsonResponse
    {
        $accounts = ExternalAccount::orderBy('name')->get();

        // Compute live balance from daily_cash_entries for linked account types
        $accounts->each(function (ExternalAccount $acc) {
            if ($acc->cash_account_type) {
                $acc->balance = (float) DailyCashEntry::where('cash_account_type', $acc->cash_account_type)
                    ->sum('cash_amount');
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
