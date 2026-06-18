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
        if (Schema::hasTable('exercises')) {
            $columns = Schema::getColumnListing('exercises');

            Schema::table('exercises', function (Blueprint $table) use ($columns) {
                if (! in_array('type', $columns, true)) {
                    $table->string('type')->nullable()->after('name');
                }

                if (! in_array('video', $columns, true)) {
                    $table->string('video')->nullable()->after('type');
                }
            });

            return;
        }

        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('type')->nullable();
            $table->string('video')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercises');
    }
};
