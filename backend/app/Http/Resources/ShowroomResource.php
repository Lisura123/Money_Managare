<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShowroomResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'           => $this->id,
            'name'         => $this->name,
            'location'     => $this->location,
            'is_active'    => $this->is_active,
            'card_accounts'=> CardAccountResource::collection($this->whenLoaded('cardAccounts')),
            'created_at'   => $this->created_at,
        ];
    }
}
