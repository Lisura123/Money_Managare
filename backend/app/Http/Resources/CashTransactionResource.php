<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CashTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                     => $this->id,
            'admin_id'               => $this->admin_id,
            'admin_name'             => $this->whenLoaded('admin', fn () => $this->admin->name),
            'from_account_type'      => $this->from_account_type,
            'from_label'             => $this->from_label,
            'to_account_type'        => $this->to_account_type,
            'to_label'               => $this->to_label,
            'to_external_account_id' => $this->to_external_account_id,
            'to_external_account'    => $this->whenLoaded('toExternalAccount', fn () => [
                'id'      => $this->toExternalAccount->id,
                'name'    => $this->toExternalAccount->name,
            ]),
            'amount'                 => $this->amount,
            'notes'                  => $this->notes,
            'transaction_date'       => $this->transaction_date?->toDateString(),
            'created_at'             => $this->created_at,
        ];
    }
}
