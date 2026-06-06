<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ExternalAccount extends Model
{
    protected $fillable = ['name', 'cash_account_type'];

    protected $casts = [];

    public function selfTransactions(): HasMany
    {
        return $this->hasMany(SelfTransaction::class, 'to_external_account_id');
    }
}
