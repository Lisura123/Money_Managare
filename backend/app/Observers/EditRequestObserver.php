<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\EditRequest;
use Illuminate\Support\Facades\Auth;

class EditRequestObserver
{
    public function created(EditRequest $editRequest): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'created',
            'table_name' => 'edit_requests',
            'record_id'  => $editRequest->id,
            'old_values' => null,
            'new_values' => $editRequest->toArray(),
        ]);
    }

    public function updated(EditRequest $editRequest): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => $editRequest->status === 'approved' ? 'approved' : 'rejected',
            'table_name' => 'edit_requests',
            'record_id'  => $editRequest->id,
            'old_values' => $editRequest->getOriginal(),
            'new_values' => $editRequest->getChanges(),
        ]);
    }

    public function deleted(EditRequest $editRequest): void
    {
        AuditLog::create([
            'user_id'    => Auth::id(),
            'action'     => 'cancelled',
            'table_name' => 'edit_requests',
            'record_id'  => $editRequest->id,
            'old_values' => $editRequest->toArray(),
            'new_values' => null,
        ]);
    }
}
