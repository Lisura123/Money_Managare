<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('edit_requests', function (Blueprint $table) {
            $table->id();
            $table->string('requestable_type');
            $table->unsignedBigInteger('requestable_id');
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('showroom_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->json('requested_changes');
            $table->json('original_values');
            $table->text('reason');
            $table->text('admin_remarks')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index('status');
            $table->index('user_id');
            $table->index('showroom_id');
            $table->index(['requestable_type', 'requestable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('edit_requests');
    }
};
