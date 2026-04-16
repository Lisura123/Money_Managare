<?php

use App\Models\Setting;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Setting::where('key', 'lock_hours')->delete();

        Setting::firstOrCreate(
            ['key' => 'edit_window_start'],
            ['value' => '00:00', 'description' => 'Start time (HH:MM) of the daily window during which staff can edit entries']
        );

        Setting::firstOrCreate(
            ['key' => 'edit_window_end'],
            ['value' => '23:59', 'description' => 'End time (HH:MM) of the daily window during which staff can edit entries']
        );
    }

    public function down(): void
    {
        Setting::where('key', 'edit_window_start')->delete();
        Setting::where('key', 'edit_window_end')->delete();

        Setting::firstOrCreate(
            ['key' => 'lock_hours'],
            ['value' => '24', 'description' => 'Number of hours after which daily entries become locked and uneditable by staff']
        );
    }
};
