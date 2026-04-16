<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CashTransaction extends Model
{
    protected $fillable = [
        'admin_id',
        'from_account_type',
        'to_account_type',
        'to_external_account_id',
        'amount',
        'notes',
        'transaction_date',
    ];

    protected $casts = [
        'amount'           => 'decimal:2',
        'transaction_date' => 'date',
    ];

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function toExternalAccount(): BelongsTo
    {
        return $this->belongsTo(ExternalAccount::class, 'to_external_account_id');
    }

    /** Human-readable label for from_account_type */
    public function getFromLabelAttribute(): string
    {
        return $this->from_account_type === 'mano' ? "Mano's account" : 'Main Account';
    }

    /** Human-readable label for to_account_type */
    public function getToLabelAttribute(): string
    {
        if ($this->to_account_type === 'mano') return "Mano's account";
        if ($this->to_account_type === 'main') return 'Main Account';
        if ($this->toExternalAccount) return $this->toExternalAccount->name;
        return 'Others (External)';
    }
}
