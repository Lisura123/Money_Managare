<?php

namespace App\Models;

use App\Observers\DailyCardEntryObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Model;

#[ObservedBy([DailyCardEntryObserver::class])]
class DailyCardEntry extends Model
{
    protected $fillable = ['showroom_id', 'user_id', 'card_account_id', 'entry_date', 'amount', 'notes', 'is_locked'];

    protected $casts = [
        'entry_date' => 'date:Y-m-d',
        'amount'     => 'decimal:2',
        'is_locked'  => 'boolean',
    ];

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function cardAccount()
    {
        return $this->belongsTo(CardAccount::class);
    }

    public function adjustments()
    {
        return $this->hasMany(AdminCardAdjustment::class);
    }

    public function editRequests()
    {
        return $this->morphMany(EditRequest::class, 'requestable');
    }
}
