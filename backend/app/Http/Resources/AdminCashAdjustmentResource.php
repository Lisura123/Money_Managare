<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminCashAdjustmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'daily_cash_entry_id'  => $this->daily_cash_entry_id,
            'admin_id'             => $this->admin_id,
            'adjusted_amount'      => $this->adjusted_amount,
            'reason'               => $this->reason,
            'cash_account_type'    => $this->whenLoaded('dailyCashEntry', fn () => $this->dailyCashEntry->cash_account_type),
            'showroom_name'        => $this->whenLoaded('dailyCashEntry', fn () => $this->dailyCashEntry->showroom?->name),
            'admin'                => $this->whenLoaded('admin', fn () => new UserResource($this->admin)),
            'created_at'           => $this->created_at,
        ];
    }
}
