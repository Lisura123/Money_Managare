<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminCashAdjustment extends Model
{
    protected $fillable = ['daily_cash_entry_id', 'admin_id', 'adjusted_amount', 'reason'];

    protected $casts = ['adjusted_amount' => 'decimal:2'];

    public function dailyCashEntry()
    {
        return $this->belongsTo(DailyCashEntry::class);
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
