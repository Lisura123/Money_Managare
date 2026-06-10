<?php

use App\Models\Setting;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Setting::firstOrCreate(
            ['key' => 'cash_entries_enabled'],
            [
                'value'       => '1',
                'description' => 'Whether staff are allowed to submit cash entries (1 = enabled, 0 = disabled)',
            ]
        );

        Setting::firstOrCreate(
            ['key' => 'bank_entries_enabled'],
            [
                'value'       => '1',
                'description' => 'Whether staff are allowed to submit bank entries (1 = enabled, 0 = disabled)',
            ]
        );
    }

    public function down(): void
    {
        Setting::whereIn('key', ['cash_entries_enabled', 'bank_entries_enabled'])->delete();
    }
};
