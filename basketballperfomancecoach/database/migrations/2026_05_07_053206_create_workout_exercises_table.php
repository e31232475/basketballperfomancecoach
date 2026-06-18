<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('workout_exercises')) {
            $columns = Schema::getColumnListing('workout_exercises');

            Schema::table('workout_exercises', function (Blueprint $table) use ($columns) {
                if (! in_array('workout_id', $columns, true)) {
                    $table->foreignId('workout_id')->after('id');
                }

                if (! in_array('exercise_id', $columns, true)) {
                    $table->foreignId('exercise_id')->after('workout_id');
                }

                if (! in_array('sets', $columns, true)) {
                    $table->integer('sets')->default(1)->after('exercise_id');
                }

                if (! in_array('reps', $columns, true)) {
                    $table->string('reps')->default('10')->after('sets');
                }

                if (! in_array('duration', $columns, true)) {
                    $table->integer('duration')->nullable()->after('reps');
                }

                if (! in_array('rest_seconds', $columns, true)) {
                    $table->integer('rest_seconds')->default(60)->after('duration');
                }
            });

            return;
        }

        Schema::create('workout_exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workout_id')->constrained()->onDelete('cascade');
            $table->foreignId('exercise_id')->constrained()->onDelete('cascade');
            $table->integer('sets')->default(1);
            $table->string('reps')->default('10');
            $table->integer('duration')->nullable();
            $table->integer('rest_seconds')->default(60);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_exercises');
    }
};
