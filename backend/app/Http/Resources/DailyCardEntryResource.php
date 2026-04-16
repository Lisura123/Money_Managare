<?php

namespace App\Http\Resources;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DailyCardEntryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user     = $request->user();
        $isLocked = $this->is_locked;

        if ($user && ! $user->isAdmin()) {
            $isLocked = ! Setting::isWithinEditWindow();
        }

        return [
            'id'              => $this->id,
            'showroom_id'     => $this->showroom_id,
            'user_id'         => $this->user_id,
            'card_account_id' => $this->card_account_id,
            'entry_date'      => $this->entry_date,
            'amount'          => $this->amount,
            'notes'           => $this->notes,
            'is_locked'       => $isLocked,
            'showroom'        => $this->whenLoaded('showroom', fn () => new ShowroomResource($this->showroom)),
            'user'            => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'card_account'    => $this->whenLoaded('cardAccount', fn () => new CardAccountResource($this->cardAccount)),
            'adjustments'     => AdminCardAdjustmentResource::collection($this->whenLoaded('adjustments')),
            'created_at'      => $this->created_at,
        ];
    }
}
