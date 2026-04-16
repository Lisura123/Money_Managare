<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('external_accounts', function (Blueprint $table) {
            $table->string('cash_account_type')->nullable()->after('balance');
        });
    }

    public function down(): void
    {
        Schema::table('external_accounts', function (Blueprint $table) {
            $table->dropColumn('cash_account_type');
        });
    }
};
