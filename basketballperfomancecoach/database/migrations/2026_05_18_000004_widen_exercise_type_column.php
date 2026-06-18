<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('exercises', 'type')) {
            return;
        }

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE `exercises` MODIFY `type` VARCHAR(255) NULL');

            return;
        }

        Schema::table('exercises', function (Blueprint $table) {
            $table->string('type')->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasColumn('exercises', 'type')) {
            return;
        }

        DB::statement("ALTER TABLE `exercises` MODIFY `type` ENUM('reps','time') NULL");
    }
};
