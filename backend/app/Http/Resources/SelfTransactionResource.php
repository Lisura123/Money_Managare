<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SelfTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'from_card_account_id' => $this->from_card_account_id,
            'to_card_account_id'   => $this->to_card_account_id,
            'admin_id'             => $this->admin_id,
            'amount'               => $this->amount,
            'notes'                => $this->notes,
            'from_card_account'    => $this->whenLoaded('fromCardAccount', fn () => new CardAccountResource($this->fromCardAccount)),
            'to_card_account'      => $this->whenLoaded('toCardAccount', fn () => new CardAccountResource($this->toCardAccount)),
            'admin'                => $this->whenLoaded('admin', fn () => new UserResource($this->admin)),
            'created_at'           => $this->created_at,
        ];
    }
}
