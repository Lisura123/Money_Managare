<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SelfTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                       => $this->id,
            'from_card_account_id'     => $this->from_card_account_id,
            'from_external_account_id' => $this->from_external_account_id,
            'from_account_type'        => $this->from_account_type,
            'from_showroom_id'         => $this->from_showroom_id,
            'to_showroom_id'           => $this->to_showroom_id,
            'to_card_account_id'       => $this->to_card_account_id,
            'to_external_account_id'   => $this->to_external_account_id,
            'to_account_type'          => $this->to_account_type,
            'admin_id'                 => $this->admin_id,
            'amount'                   => $this->amount,
            'notes'                    => $this->notes,
            'from_card_account'        => $this->whenLoaded('fromCardAccount', fn () => new CardAccountResource($this->fromCardAccount)),
            'from_external_account'    => $this->whenLoaded('fromExternalAccount', fn () => $this->fromExternalAccount
                ? ['id' => $this->fromExternalAccount->id, 'name' => $this->fromExternalAccount->name, 'cash_account_type' => $this->fromExternalAccount->cash_account_type]
                : null
            ),
            'to_card_account'          => $this->whenLoaded('toCardAccount', fn () => new CardAccountResource($this->toCardAccount)),
            'to_external_account'      => $this->whenLoaded('toExternalAccount', fn () => $this->toExternalAccount
                ? ['id' => $this->toExternalAccount->id, 'name' => $this->toExternalAccount->name, 'cash_account_type' => $this->toExternalAccount->cash_account_type]
                : null
            ),
            'admin'                    => $this->whenLoaded('admin', fn () => new UserResource($this->admin)),
            'created_at'               => $this->created_at,
        ];
    }
}
