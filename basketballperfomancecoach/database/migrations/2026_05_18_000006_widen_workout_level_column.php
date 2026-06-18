<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('workouts', 'level')) {
            return;
        }

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE `workouts` MODIFY `level` VARCHAR(255) NULL');

            return;
        }

        Schema::table('workouts', function (Blueprint $table) {
            $table->string('level')->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasColumn('workouts', 'level')) {
            return;
        }

        DB::statement("ALTER TABLE `workouts` MODIFY `level` ENUM('beginner','intermediate') NULL");
    }
};
