<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'showroom_id',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isStaff(): bool
    {
        return $this->role === 'staff';
    }

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function showrooms()
    {
        return $this->belongsToMany(Showroom::class)->withTimestamps();
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
