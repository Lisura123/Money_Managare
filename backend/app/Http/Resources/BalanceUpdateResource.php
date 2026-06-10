<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BalanceUpdateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'showroom_id'     => $this->showroom_id,
            'showroom_name'   => $this->whenLoaded('showroom', fn () => $this->showroom?->name),
            'account_type'    => $this->account_type,
            'card_account_id' => $this->card_account_id,
            'account_label'   => $this->account_label,
            'previous_amount' => $this->previous_amount,
            'new_amount'      => $this->new_amount,
            'change_amount'   => $this->change_amount,
            'reason'          => $this->reason,
            'user_id'         => $this->user_id,
            'user_name'       => $this->whenLoaded('user', fn () => $this->user?->name),
            'created_at'      => $this->created_at,
        ];
    }
}
