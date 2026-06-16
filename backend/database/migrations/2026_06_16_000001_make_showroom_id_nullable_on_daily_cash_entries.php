<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Mano's cash is a global account not tied to any showroom, so allow
        // showroom_id to be null. Raw SQL keeps the existing foreign key intact.
        DB::statement('ALTER TABLE daily_cash_entries MODIFY showroom_id BIGINT UNSIGNED NULL');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE daily_cash_entries MODIFY showroom_id BIGINT UNSIGNED NOT NULL');
    }
};
