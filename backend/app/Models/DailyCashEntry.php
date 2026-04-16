<?php

namespace App\Models;

use App\Observers\DailyCashEntryObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Model;

#[ObservedBy([DailyCashEntryObserver::class])]
class DailyCashEntry extends Model
{
    protected $fillable = ['showroom_id', 'user_id', 'entry_date', 'cash_amount', 'notes', 'is_locked', 'cash_account_type'];

    protected $casts = [
        'entry_date'        => 'date',
        'cash_amount'       => 'decimal:2',
        'is_locked'         => 'boolean',
        'cash_account_type' => 'string',
    ];

    public function getCashAccountLabelAttribute(): string
    {
        return $this->cash_account_type === 'mano' ? "Mano's Account" : 'Main Account';
    }

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function adjustments()
    {
        return $this->hasMany(AdminCashAdjustment::class);
    }

    public function editRequests()
    {
        return $this->morphMany(EditRequest::class, 'requestable');
    }
}
