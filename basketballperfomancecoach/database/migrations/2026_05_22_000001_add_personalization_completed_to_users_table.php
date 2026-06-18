<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $columns = Schema::getColumnListing('users');

        Schema::table('users', function (Blueprint $table) use ($columns) {
            if (! in_array('personalization_completed', $columns, true)) {
                $column = $table->boolean('personalization_completed')
                    ->default(false);

                if (in_array('training_level', $columns, true)) {
                    $column->after('training_level');
                }
            }
        });
    }

    public function down(): void
    {
        $columns = Schema::getColumnListing('users');

        Schema::table('users', function (Blueprint $table) use ($columns) {
            if (in_array('personalization_completed', $columns, true)) {
                $table->dropColumn('personalization_completed');
            }
        });
    }
};
