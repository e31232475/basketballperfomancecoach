<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('workouts')) {
            return;
        }

        if (! Schema::hasColumn('workouts', 'name')) {
            Schema::table('workouts', function (Blueprint $table) {
                $table->string('name')->nullable()->after('title');
            });
        }
    }

    public function down(): void
    {
        if (! Schema::hasTable('workouts')) {
            return;
        }

        if (Schema::hasColumn('workouts', 'name')) {
            Schema::table('workouts', function (Blueprint $table) {
                $table->dropColumn('name');
            });
        }
    }
};
