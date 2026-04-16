<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\SelfTransaction;
use Illuminate\Support\Facades\Auth;

class SelfTransactionObserver
{
    public function created(SelfTransaction $transaction): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'created',
            'table_name' => 'self_transactions',
            'record_id'  => $transaction->id,
            'old_values' => null,
            'new_values' => $transaction->toArray(),
        ]);
    }

    public function updated(SelfTransaction $transaction): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'updated',
            'table_name' => 'self_transactions',
            'record_id'  => $transaction->id,
            'old_values' => $transaction->getOriginal(),
            'new_values' => $transaction->getChanges(),
        ]);
    }

    public function deleted(SelfTransaction $transaction): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'deleted',
            'table_name' => 'self_transactions',
            'record_id'  => $transaction->id,
            'old_values' => $transaction->toArray(),
            'new_values' => null,
        ]);
    }
}
