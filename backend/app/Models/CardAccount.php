<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CardAccount extends Model
{
    protected $fillable = ['showroom_id', 'bank_name', 'last_four', 'current_balance', 'opening_balance', 'opening_balance_date', 'is_active'];

    protected $casts = [
        'current_balance' => 'decimal:2',
        'is_active'       => 'boolean',
    ];

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function dailyCardEntries()
    {
        return $this->hasMany(DailyCardEntry::class);
    }

    public function selfTransactionsFrom()
    {
        return $this->hasMany(SelfTransaction::class, 'from_card_account_id');
    }

    public function selfTransactionsTo()
    {
        return $this->hasMany(SelfTransaction::class, 'to_card_account_id');
    }
}
