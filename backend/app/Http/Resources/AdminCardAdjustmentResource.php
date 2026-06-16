<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminCardAdjustmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'daily_card_entry_id'  => $this->daily_card_entry_id,
            'admin_id'             => $this->admin_id,
            'adjusted_amount'      => $this->adjusted_amount,
            'reason'               => $this->reason,
            'admin'                => $this->whenLoaded('admin', fn () => new UserResource($this->admin)),
            'bank_name'            => $this->whenLoaded('dailyCardEntry', fn () => $this->dailyCardEntry->cardAccount?->bank_name),
            'last_four'            => $this->whenLoaded('dailyCardEntry', fn () => $this->dailyCardEntry->cardAccount?->last_four),
            'showroom_name'        => $this->whenLoaded('dailyCardEntry', fn () => $this->dailyCardEntry->cardAccount?->showroom?->name),
            'created_at'           => $this->created_at,
        ];
    }
}
