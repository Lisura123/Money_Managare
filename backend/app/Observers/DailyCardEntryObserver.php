<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\DailyCardEntry;
use Illuminate\Support\Facades\Auth;

class DailyCardEntryObserver
{
    public function created(DailyCardEntry $entry): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'created',
            'table_name' => 'daily_card_entries',
            'record_id'  => $entry->id,
            'old_values' => null,
            'new_values' => $entry->toArray(),
        ]);
    }

    public function updated(DailyCardEntry $entry): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'updated',
            'table_name' => 'daily_card_entries',
            'record_id'  => $entry->id,
            'old_values' => $entry->getOriginal(),
            'new_values' => $entry->getChanges(),
        ]);
    }

    public function deleted(DailyCardEntry $entry): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'deleted',
            'table_name' => 'daily_card_entries',
            'record_id'  => $entry->id,
            'old_values' => $entry->toArray(),
            'new_values' => null,
        ]);
    }
}
