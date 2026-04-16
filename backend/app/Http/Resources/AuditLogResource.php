<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuditLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'user_id'    => $this->user_id,
            'action'     => $this->action,
            'table_name' => $this->table_name,
            'record_id'  => $this->record_id,
            'old_values' => $this->old_values,
            'new_values' => $this->new_values,
            'user'       => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'created_at' => $this->created_at,
        ];
    }
}
