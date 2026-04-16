<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminCardAdjustment extends Model
{
    protected $fillable = ['daily_card_entry_id', 'admin_id', 'adjusted_amount', 'reason'];

    protected $casts = ['adjusted_amount' => 'decimal:2'];

    public function dailyCardEntry()
    {
        return $this->belongsTo(DailyCardEntry::class);
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
