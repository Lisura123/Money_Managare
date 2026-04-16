<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('external_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('balance', 15, 2)->default(0.00);
            $table->timestamps();
        });

        Schema::table('self_transactions', function (Blueprint $table) {
            $table->foreignId('to_external_account_id')
                ->nullable()
                ->after('to_card_account_id')
                ->constrained('external_accounts')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('self_transactions', function (Blueprint $table) {
            $table->dropForeign(['to_external_account_id']);
            $table->dropColumn('to_external_account_id');
        });

        Schema::dropIfExists('external_accounts');
    }
};
