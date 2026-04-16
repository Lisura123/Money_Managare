<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SelfTransactionRequest;
use App\Http\Resources\SelfTransactionResource;
use App\Models\CardAccount;
use App\Models\ExternalAccount;
use App\Models\SelfTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SelfTransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transactions = SelfTransaction::with('fromCardAccount', 'toCardAccount', 'admin')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($transactions);
    }

    public function store(SelfTransactionRequest $request): JsonResponse
    {
        $transaction = DB::transaction(function () use ($request) {
            $from        = CardAccount::lockForUpdate()->findOrFail($request->from_card_account_id);
            $toExternal  = $request->to_external_account_id !== null;
            $toOthers    = ! $toExternal && ($request->to_card_account_id === null);

            if ($from->current_balance < $request->amount) {
                abort(422, 'Insufficient balance in the source card account.');
            }

            $from->decrement('current_balance', $request->amount);

            $toCardId     = null;
            $toExternalId = null;

            if ($toExternal) {
                $ext = ExternalAccount::lockForUpdate()->findOrFail($request->to_external_account_id);
                $ext->increment('balance', $request->amount);
                $toExternalId = $ext->id;
            } elseif (! $toOthers) {
                $to = CardAccount::lockForUpdate()->findOrFail($request->to_card_account_id);
                $to->increment('current_balance', $request->amount);
                $toCardId = $to->id;
            }

            return SelfTransaction::create([
                'from_card_account_id'   => $from->id,
                'to_card_account_id'     => $toCardId,
                'to_external_account_id' => $toExternalId,
                'admin_id'               => $request->user()->id,
                'amount'                 => $request->amount,
                'notes'                  => $request->notes,
            ]);
        });

        return response()->json(
            new SelfTransactionResource($transaction->load('fromCardAccount', 'toCardAccount', 'admin')),
            201
        );
    }

    public function destroy(SelfTransaction $selfTransaction): JsonResponse
    {
        DB::transaction(function () use ($selfTransaction) {
            $amount = (float) $selfTransaction->amount;

            // Reverse: re-credit the source card account
            CardAccount::lockForUpdate()
                ->findOrFail($selfTransaction->from_card_account_id)
                ->increment('current_balance', $amount);

            // Reverse: debit the destination
            if ($selfTransaction->to_card_account_id) {
                CardAccount::lockForUpdate()
                    ->findOrFail($selfTransaction->to_card_account_id)
                    ->decrement('current_balance', $amount);
            } elseif ($selfTransaction->to_external_account_id) {
                ExternalAccount::lockForUpdate()
                    ->findOrFail($selfTransaction->to_external_account_id)
                    ->decrement('balance', $amount);
            }

            $selfTransaction->delete();
        });

        return response()->json(['message' => 'Self transaction deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $transactions = SelfTransaction::whereIn('id', $request->ids)->get();

        DB::transaction(function () use ($transactions) {
            foreach ($transactions as $tx) {
                $amount = (float) $tx->amount;

                CardAccount::lockForUpdate()
                    ->findOrFail($tx->from_card_account_id)
                    ->increment('current_balance', $amount);

                if ($tx->to_card_account_id) {
                    CardAccount::lockForUpdate()
                        ->findOrFail($tx->to_card_account_id)
                        ->decrement('current_balance', $amount);
                } elseif ($tx->to_external_account_id) {
                    ExternalAccount::lockForUpdate()
                        ->findOrFail($tx->to_external_account_id)
                        ->decrement('balance', $amount);
                }

                $tx->delete();
            }
        });

        return response()->json(['message' => "Deleted {$transactions->count()} self transactions."]);
    }
}
