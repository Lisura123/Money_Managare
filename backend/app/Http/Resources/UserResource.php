<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'           => $this->id,
            'name'         => $this->name,
            'email'        => $this->email,
            'role'         => $this->role,
            'is_active'    => $this->is_active,
            'showroom_id'  => $this->showroom_id,
            'showroom'     => $this->whenLoaded('showroom', fn () => new ShowroomResource($this->showroom)),
            'showroom_ids' => $this->whenLoaded('showrooms', fn () => $this->showrooms->pluck('id')->values()),
            'showrooms'    => $this->whenLoaded('showrooms', fn () => ShowroomResource::collection($this->showrooms)),
            'created_at'   => $this->created_at,
        ];
    }
}
