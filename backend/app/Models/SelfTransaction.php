<?php

namespace App\Models;

use App\Observers\SelfTransactionObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Model;

#[ObservedBy([SelfTransactionObserver::class])]
class SelfTransaction extends Model
{
    protected $fillable = ['from_card_account_id', 'to_card_account_id', 'to_external_account_id', 'admin_id', 'amount', 'notes'];

    protected $casts = ['amount' => 'decimal:2'];

    public function fromCardAccount()
    {
        return $this->belongsTo(CardAccount::class, 'from_card_account_id');
    }

    public function toCardAccount()
    {
        return $this->belongsTo(CardAccount::class, 'to_card_account_id');
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
