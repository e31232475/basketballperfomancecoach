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
            if (! in_array('role', $columns, true)) {
                $table->string('role', 32)->default('athlete')->after('email');
            }
        });
    }

    public function down(): void
    {
        $columns = Schema::getColumnListing('users');

        Schema::table('users', function (Blueprint $table) use ($columns) {
            if (in_array('role', $columns, true)) {
                $table->dropColumn('role');
            }
        });
    }
};
