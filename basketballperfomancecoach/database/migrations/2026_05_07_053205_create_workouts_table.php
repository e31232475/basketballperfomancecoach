<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('workouts')) {
            $columns = Schema::getColumnListing('workouts');

            Schema::table('workouts', function (Blueprint $table) use ($columns) {
                if (! in_array('title', $columns, true)) {
                    $table->string('title')->nullable()->after('id');
                }

                if (! in_array('level', $columns, true)) {
                    $table->string('level')->default('Beginner')->after('title');
                }

                if (! in_array('day_number', $columns, true)) {
                    $table->integer('day_number')->after('level');
                }
            });

            return;
        }

        Schema::create('workouts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('level')->default('Beginner');
            $table->integer('day_number')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workouts');
    }
};
