<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cash_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnDelete();
            $table->string('from_account_type');           // 'main' | 'mano'
            $table->string('to_account_type')->nullable(); // 'main' | 'mano' | null (= others)
            $table->foreignId('to_external_account_id')
                ->nullable()
                ->constrained('external_accounts')
                ->nullOnDelete();
            $table->decimal('amount', 15, 2);
            $table->text('notes')->nullable();
            $table->date('transaction_date');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cash_transactions');
    }
};
