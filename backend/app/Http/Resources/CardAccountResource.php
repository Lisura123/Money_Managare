<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CardAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'showroom_id'     => $this->showroom_id,
            'bank_name'       => $this->bank_name,
            'last_four'       => $this->last_four,
            'current_balance' => $this->current_balance,
            'is_active'       => $this->is_active,
            'showroom'        => $this->whenLoaded('showroom', fn () => new ShowroomResource($this->showroom)),
            'created_at'      => $this->created_at,
        ];
    }
}
