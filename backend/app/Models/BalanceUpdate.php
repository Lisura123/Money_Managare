<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BalanceUpdate extends Model
{
    protected $fillable = [
        'showroom_id',
        'account_type',
        'card_account_id',
        'account_label',
        'previous_amount',
        'new_amount',
        'change_amount',
        'reason',
        'user_id',
    ];

    protected $casts = [
        'previous_amount' => 'decimal:2',
        'new_amount'      => 'decimal:2',
        'change_amount'   => 'decimal:2',
    ];

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function cardAccount()
    {
        return $this->belongsTo(CardAccount::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
