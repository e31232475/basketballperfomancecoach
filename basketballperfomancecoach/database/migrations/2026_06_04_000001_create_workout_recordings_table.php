<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('workout_recordings')) {
            return;
        }

        Schema::create('workout_recordings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->unsignedBigInteger('workout_id')->index();
            $table->unsignedInteger('day_number')->index();
            $table->string('file_path');
            $table->string('file_url')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('file_size')->default(0);
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->timestamp('recorded_at')->nullable();
            $table->timestamps();

            $table->index(
                ['user_id', 'workout_id', 'day_number'],
                'workout_recordings_user_workout_day_index'
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_recordings');
    }
};
