<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\CardAccount;
use Illuminate\Support\Facades\Auth;

class CardAccountObserver
{
    public function created(CardAccount $account): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'created',
            'table_name' => 'card_accounts',
            'record_id'  => $account->id,
            'old_values' => null,
            'new_values' => $account->toArray(),
        ]);
    }

    public function updated(CardAccount $account): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'updated',
            'table_name' => 'card_accounts',
            'record_id'  => $account->id,
            'old_values' => $account->getOriginal(),
            'new_values' => $account->getChanges(),
        ]);
    }

    public function deleted(CardAccount $account): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'deleted',
            'table_name' => 'card_accounts',
            'record_id'  => $account->id,
            'old_values' => $account->toArray(),
            'new_values' => null,
        ]);
    }
}
