<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SelfTransaction;
use App\Models\Showroom;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ShowroomCashController extends Controller
{
    public function index(): JsonResponse
    {
        $showrooms = Showroom::where('is_active', true)->orderBy('name')->get();

        $result = $showrooms->map(function (Showroom $s) {
            $entries = (float) DB::table('daily_cash_entries')
                ->where('showroom_id', $s->id)
                ->where('cash_account_type', 'main')
                ->sum('cash_amount');

            $adj = (float) DB::table('admin_cash_adjustments')
                ->join('daily_cash_entries', 'admin_cash_adjustments.daily_cash_entry_id', '=', 'daily_cash_entries.id')
                ->where('daily_cash_entries.showroom_id', $s->id)
                ->where('daily_cash_entries.cash_account_type', 'main')
                ->sum('admin_cash_adjustments.adjusted_amount');

            $selfOut = (float) SelfTransaction::where('from_account_type', 'main')
                ->where('from_showroom_id', $s->id)
                ->sum('amount');

            $selfIn = (float) SelfTransaction::where('to_account_type', 'main')
                ->where('to_showroom_id', $s->id)
                ->sum('amount');

            return [
                'showroom_id'   => $s->id,
                'showroom_name' => $s->name,
                'balance'       => round($entries + $adj - $selfOut + $selfIn, 2),
            ];
        })->values();

        return response()->json($result);
    }
}
