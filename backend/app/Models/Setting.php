<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $fillable = ['key', 'value', 'description'];

    public static function get(string $key, mixed $default = null): mixed
    {
        $setting = static::where('key', $key)->first();
        return $setting ? $setting->value : $default;
    }

    public function getRouteKeyName(): string
    {
        return 'key';
    }

    public static function isWithinEditWindow(): bool
    {
        $start = static::get('edit_window_start', '00:00');
        $end   = static::get('edit_window_end', '23:59');
        $now   = now()->format('H:i');

        return $now >= $start && $now <= $end;
    }

    public static function cashEntriesEnabled(): bool
    {
        return static::get('cash_entries_enabled', '1') === '1';
    }

    public static function bankEntriesEnabled(): bool
    {
        return static::get('bank_entries_enabled', '1') === '1';
    }
}
