<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CashTransactionRequest;
use App\Http\Resources\CashTransactionResource;
use App\Models\CashTransaction;
use App\Models\ExternalAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CashTransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = CashTransaction::with('admin', 'toExternalAccount')
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at');

        if ($request->filled('from_account_type')) {
            $query->where('from_account_type', $request->from_account_type);
        }

        if ($request->filled('date_from')) {
            $query->where('transaction_date', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->where('transaction_date', '<=', $request->date_to);
        }

        if ($request->filled('type')) {
            if ($request->type === 'internal') {
                $query->whereNotNull('to_account_type');
            } elseif ($request->type === 'external') {
                $query->whereNull('to_account_type');
            }
        }

        $transactions = $query->paginate(20);

        return response()->json([
            'data'         => CashTransactionResource::collection($transactions->items()),
            'current_page' => $transactions->currentPage(),
            'last_page'    => $transactions->lastPage(),
        ]);
    }

    public function store(CashTransactionRequest $request): JsonResponse
    {
        $transaction = DB::transaction(function () use ($request) {
            $toExternal = $request->to_external_account_id !== null;
            $toOthers   = ! $toExternal && $request->to_account_type === null;

            if ($toExternal) {
                $ext = ExternalAccount::lockForUpdate()->findOrFail($request->to_external_account_id);
                $ext->increment('balance', $request->amount);
            }

            return CashTransaction::create([
                'admin_id'               => $request->user()->id,
                'from_account_type'      => $request->from_account_type,
                'to_account_type'        => $toOthers || $toExternal ? null : $request->to_account_type,
                'to_external_account_id' => $toExternal ? $request->to_external_account_id : null,
                'amount'                 => $request->amount,
                'notes'                  => $request->notes,
                'transaction_date'       => $request->transaction_date,
            ]);
        });

        return response()->json(
            new CashTransactionResource($transaction->load('admin', 'toExternalAccount')),
            201
        );
    }

    public function destroy(CashTransaction $cashTransaction): JsonResponse
    {
        DB::transaction(function () use ($cashTransaction) {
            // Reverse: if money was sent to an external account, decrement its balance
            if ($cashTransaction->to_external_account_id) {
                ExternalAccount::lockForUpdate()
                    ->findOrFail($cashTransaction->to_external_account_id)
                    ->decrement('balance', (float) $cashTransaction->amount);
            }

            $cashTransaction->delete();
        });

        return response()->json(['message' => 'Cash transaction deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $transactions = CashTransaction::whereIn('id', $request->ids)->get();

        DB::transaction(function () use ($transactions) {
            foreach ($transactions as $tx) {
                if ($tx->to_external_account_id) {
                    ExternalAccount::lockForUpdate()
                        ->findOrFail($tx->to_external_account_id)
                        ->decrement('balance', (float) $tx->amount);
                }

                $tx->delete();
            }
        });

        return response()->json(['message' => "Deleted {$transactions->count()} cash transactions."]);
    }
}
