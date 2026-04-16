<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('card_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('showroom_id')->constrained('showrooms')->cascadeOnDelete();
            $table->string('bank_name');
            $table->string('last_four', 4);
            $table->decimal('current_balance', 15, 2)->default(0.00);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('card_accounts');
    }
};
