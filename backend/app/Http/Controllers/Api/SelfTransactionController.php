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
        $transactions = SelfTransaction::with('fromCardAccount', 'fromExternalAccount', 'toCardAccount', 'admin')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($transactions);
    }

    public function store(SelfTransactionRequest $request): JsonResponse
    {
        $transaction = DB::transaction(function () use ($request) {
            $fromCardId      = null;
            $fromExternalId  = null;
            $fromAccountType = null;

            if ($request->from_card_account_id) {
                $from = CardAccount::lockForUpdate()->findOrFail($request->from_card_account_id);
                if ($from->current_balance < $request->amount) {
                    abort(422, 'Insufficient balance in the source card account.');
                }
                $from->decrement('current_balance', $request->amount);
                $fromCardId = $from->id;
            } elseif ($request->from_external_account_id) {
                $fromExt = ExternalAccount::lockForUpdate()->findOrFail($request->from_external_account_id);
                if ($fromExt->balance < $request->amount) {
                    abort(422, 'Insufficient balance in the source account.');
                }
                $fromExt->decrement('balance', $request->amount);
                $fromExternalId = $fromExt->id;
            } elseif ($request->from_account_type === 'main') {
                $fromAccountType = 'main'; // main cash is computed; just record
            }

            $toCardId     = null;
            $toExternalId = null;
            $toAccountType = $request->to_account_type; // 'main' or null

            if ($request->to_external_account_id) {
                $ext = ExternalAccount::lockForUpdate()->findOrFail($request->to_external_account_id);
                $ext->increment('balance', $request->amount);
                $toExternalId = $ext->id;
            } elseif ($request->to_card_account_id) {
                $to = CardAccount::lockForUpdate()->findOrFail($request->to_card_account_id);
                $to->increment('current_balance', $request->amount);
                $toCardId = $to->id;
            }
            // to_account_type = 'main': main cash is computed, just record
            // no to_card / to_external / to_account_type = others: just record notes

            return SelfTransaction::create([
                'from_card_account_id'     => $fromCardId,
                'from_external_account_id' => $fromExternalId,
                'from_account_type'        => $fromAccountType,
                'to_card_account_id'       => $toCardId,
                'to_external_account_id'   => $toExternalId,
                'to_account_type'          => $toAccountType,
                'admin_id'                 => $request->user()->id,
                'amount'                   => $request->amount,
                'notes'                    => $request->notes,
            ]);
        });

        return response()->json(
            new SelfTransactionResource($transaction->load('fromCardAccount', 'fromExternalAccount', 'toCardAccount', 'admin')),
            201
        );
    }

    public function destroy(SelfTransaction $selfTransaction): JsonResponse
    {
        DB::transaction(function () use ($selfTransaction) {
            $amount = (float) $selfTransaction->amount;

            // Reverse: re-credit the source
            if ($selfTransaction->from_card_account_id) {
                CardAccount::lockForUpdate()
                    ->findOrFail($selfTransaction->from_card_account_id)
                    ->increment('current_balance', $amount);
            } elseif ($selfTransaction->from_external_account_id) {
                ExternalAccount::lockForUpdate()
                    ->findOrFail($selfTransaction->from_external_account_id)
                    ->increment('balance', $amount);
            }
            // from_account_type = 'main': computed, no direct update needed

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
            // to_account_type = 'main': computed, no direct update needed

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

                if ($tx->from_card_account_id) {
                    CardAccount::lockForUpdate()
                        ->findOrFail($tx->from_card_account_id)
                        ->increment('current_balance', $amount);
                } elseif ($tx->from_external_account_id) {
                    ExternalAccount::lockForUpdate()
                        ->findOrFail($tx->from_external_account_id)
                        ->increment('balance', $amount);
                }

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
