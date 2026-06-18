<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('performance_logs')) {
            return;
        }

        Schema::create('performance_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->unsignedBigInteger('workout_id')->index();
            $table->unsignedBigInteger('exercise_id')->index();
            $table->unsignedInteger('set_number');
            $table->boolean('success')->default(true);
            $table->timestamp('created_at')->nullable();
            $table->unique(
                ['user_id', 'workout_id', 'exercise_id', 'set_number'],
                'performance_logs_unique_set'
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('performance_logs');
    }
};
