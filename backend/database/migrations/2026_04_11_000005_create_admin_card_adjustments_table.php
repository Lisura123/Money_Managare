<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_card_adjustments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('daily_card_entry_id')->constrained('daily_card_entries')->cascadeOnDelete();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('adjusted_amount', 15, 2);
            $table->text('reason');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_card_adjustments');
    }
};
