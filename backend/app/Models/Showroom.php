<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Showroom extends Model
{
    protected $fillable = ['name', 'location', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function cardAccounts()
    {
        return $this->hasMany(CardAccount::class);
    }

    public function dailyCashEntries()
    {
        return $this->hasMany(DailyCashEntry::class);
    }

    public function dailyCardEntries()
    {
        return $this->hasMany(DailyCardEntry::class);
    }
}
