<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('coach_reviews')) {
            return;
        }

        Schema::create('coach_reviews', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('workout_recording_id')->index();
            $table->unsignedBigInteger('user_id')->index();
            $table->unsignedBigInteger('workout_id')->index();
            $table->unsignedInteger('day_number')->index();
            $table->unsignedBigInteger('coach_id')->nullable()->index();
            $table->string('status', 32)->default('pending')->index();
            $table->unsignedTinyInteger('score')->nullable();
            $table->text('feedback')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->unique('workout_recording_id', 'coach_reviews_recording_unique');
            $table->index(
                ['user_id', 'workout_id', 'day_number'],
                'coach_reviews_user_workout_day_index'
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coach_reviews');
    }
};
