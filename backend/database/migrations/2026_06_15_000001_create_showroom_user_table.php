<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('showroom_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('showroom_id')->constrained()->cascadeOnDelete();
            $table->unique(['user_id', 'showroom_id']);
            $table->timestamps();
        });

        // Migrate existing single-showroom assignments into the pivot table.
        DB::statement('
            INSERT INTO showroom_user (user_id, showroom_id, created_at, updated_at)
            SELECT id, showroom_id, NOW(), NOW()
            FROM users
            WHERE showroom_id IS NOT NULL
        ');
    }

    public function down(): void
    {
        Schema::dropIfExists('showroom_user');
    }
};
