<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $columns = Schema::getColumnListing('exercises');

        Schema::table('exercises', function (Blueprint $table) use ($columns) {
            if (! in_array('video_url', $columns, true)) {
                $table->string('video_url')->nullable()->after('video');
            }
        });
    }

    public function down(): void
    {
        if (Schema::hasColumn('exercises', 'video_url')) {
            Schema::table('exercises', function (Blueprint $table) {
                $table->dropColumn('video_url');
            });
        }
    }
};
