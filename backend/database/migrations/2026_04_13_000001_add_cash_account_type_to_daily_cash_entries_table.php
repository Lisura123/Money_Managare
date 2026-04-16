<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('daily_cash_entries', function (Blueprint $table) {
            $table->string('cash_account_type')->default('main')->after('notes')->index();
        });
    }

    public function down(): void
    {
        Schema::table('daily_cash_entries', function (Blueprint $table) {
            $table->dropColumn('cash_account_type');
        });
    }
};
