<?php

namespace App\Http\Resources;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DailyCashEntryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user     = $request->user();
        $isLocked = $this->is_locked;

        if ($user && ! $user->isAdmin()) {
            $isLocked = ! Setting::isWithinEditWindow();
        }

        return [
            'id'                 => $this->id,
            'showroom_id'        => $this->showroom_id,
            'user_id'            => $this->user_id,
            'entry_date'         => $this->entry_date,
            'cash_amount'        => $this->cash_amount,
            'notes'              => $this->notes,
            'is_locked'          => $isLocked,
            'cash_account_type'  => $this->cash_account_type ?? 'main',
            'cash_account_label' => $this->cash_account_type === 'mano' ? "Mano's Account" : 'Main Account',
            'showroom'           => $this->whenLoaded('showroom', fn () => new ShowroomResource($this->showroom)),
            'user'               => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'adjustments'        => AdminCashAdjustmentResource::collection($this->whenLoaded('adjustments')),
            'created_at'         => $this->created_at,
        ];
    }
}
