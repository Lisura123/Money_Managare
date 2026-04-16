<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ExternalAccount extends Model
{
    protected $fillable = ['name', 'balance', 'cash_account_type'];

    protected $casts = [
        'balance' => 'decimal:2',
    ];

    public function selfTransactions(): HasMany
    {
        return $this->hasMany(SelfTransaction::class, 'to_external_account_id');
    }
}
