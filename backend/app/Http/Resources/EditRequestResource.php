<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EditRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $entryType = $this->requestable_type === 'daily_cash_entries' ? 'cash' : 'card';

        return [
            'id'                => $this->id,
            'entry_type'        => $entryType,
            'entry_id'          => $this->requestable_id,
            'original_values'   => $this->original_values,
            'requested_changes' => $this->requested_changes,
            'reason'            => $this->reason,
            'status'            => $this->status,
            'admin_remarks'     => $this->admin_remarks,
            'staff_name'        => $this->user?->name,
            'staff_email'       => $this->user?->email,
            'showroom_name'     => $this->showroom?->name,
            'reviewer_name'     => $this->reviewer?->name,
            'reviewed_at'       => $this->reviewed_at?->toISOString(),
            'created_at'        => $this->created_at?->toISOString(),

            // Include the related entry data when loaded
            'entry'             => $this->when(
                $this->relationLoaded('requestable') && $this->requestable !== null,
                function () use ($entryType) {
                    $entry = $this->requestable;
                    if ($entryType === 'cash') {
                        return [
                            'id'          => $entry->id,
                            'entry_date'  => $entry->entry_date,
                            'cash_amount' => $entry->cash_amount,
                            'notes'       => $entry->notes,
                            'is_locked'   => $entry->is_locked,
                        ];
                    } else {
                        return [
                            'id'          => $entry->id,
                            'entry_date'  => $entry->entry_date,
                            'amount'      => $entry->amount,
                            'notes'       => $entry->notes,
                            'is_locked'   => $entry->is_locked,
                            'bank_name'   => $entry->cardAccount?->bank_name ?? null,
                            'last_four'   => $entry->cardAccount?->last_four ?? null,
                        ];
                    }
                }
            ),
        ];
    }
}
