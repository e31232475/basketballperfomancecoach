<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('workout_exercises', 'reps')) {
            return;
        }

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE `workout_exercises` MODIFY `reps` VARCHAR(255) NULL');

            return;
        }

        Schema::table('workout_exercises', function (Blueprint $table) {
            $table->string('reps')->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasColumn('workout_exercises', 'reps')) {
            return;
        }

        DB::statement('ALTER TABLE `workout_exercises` MODIFY `reps` INT NULL');
    }
};
