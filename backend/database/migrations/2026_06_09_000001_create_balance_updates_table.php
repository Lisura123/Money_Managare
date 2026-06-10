<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('balance_updates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('showroom_id')->nullable()->constrained()->nullOnDelete();
            // 'main_cash' or 'bank'
            $table->string('account_type', 20);
            $table->foreignId('card_account_id')->nullable()->constrained()->nullOnDelete();
            $table->string('account_label');
            $table->decimal('previous_amount', 15, 2)->default(0);
            $table->decimal('new_amount', 15, 2)->default(0);
            $table->decimal('change_amount', 15, 2)->default(0);
            $table->string('reason')->nullable();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->index('account_type');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('balance_updates');
    }
};
