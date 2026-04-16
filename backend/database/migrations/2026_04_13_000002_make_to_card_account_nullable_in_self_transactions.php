<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('self_transactions', function (Blueprint $table) {
            $table->foreignId('to_card_account_id')
                ->nullable()
                ->change();
        });
    }

    public function down(): void
    {
        Schema::table('self_transactions', function (Blueprint $table) {
            $table->foreignId('to_card_account_id')
                ->nullable(false)
                ->change();
        });
    }
};
