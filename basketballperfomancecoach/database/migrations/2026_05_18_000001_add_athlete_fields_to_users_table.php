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
            if (! in_array('height', $columns, true)) {
                $table->decimal('height', 5, 2)->nullable()->after('password');
            }

            if (! in_array('weight', $columns, true)) {
                $table->decimal('weight', 5, 2)->nullable()->after('height');
            }

            if (! in_array('age', $columns, true)) {
                $table->unsignedTinyInteger('age')->nullable()->after('weight');
            }

            if (! in_array('training_level', $columns, true)) {
                $table->string('training_level')->nullable()->after('age');
            }
        });
    }

    public function down(): void
    {
        $columns = Schema::getColumnListing('users');

        Schema::table('users', function (Blueprint $table) use ($columns) {
            foreach (['training_level', 'age', 'weight', 'height'] as $column) {
                if (in_array($column, $columns, true)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
