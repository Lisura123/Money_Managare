<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingsSeeder extends Seeder
{
    public function run(): void
    {
        Setting::create([
            'key'         => 'edit_window_start',
            'value'       => '00:00',
            'description' => 'Start time (HH:MM) of the daily window during which staff can edit entries',
        ]);

        Setting::create([
            'key'         => 'edit_window_end',
            'value'       => '23:59',
            'description' => 'End time (HH:MM) of the daily window during which staff can edit entries',
        ]);

        Setting::create([
            'key'         => 'cash_entries_enabled',
            'value'       => '1',
            'description' => 'Whether staff are allowed to submit cash entries (1 = enabled, 0 = disabled)',
        ]);

        Setting::create([
            'key'         => 'bank_entries_enabled',
            'value'       => '1',
            'description' => 'Whether staff are allowed to submit bank entries (1 = enabled, 0 = disabled)',
        ]);
    }
}
