<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('violators', function (Blueprint $table) {
            $table->integer('age')->nullable()->after('name');
            $table->string('sex', 10)->nullable()->after('age');
        });

        Schema::table('tickets', function (Blueprint $table) {
            $table->date('compliance_date')->nullable()->after('apprehended_at');
        });
    }

    public function down(): void
    {
        Schema::table('violators', function (Blueprint $table) {
            $table->dropColumn(['age', 'sex']);
        });

        Schema::table('tickets', function (Blueprint $table) {
            $table->dropColumn('compliance_date');
        });
    }
};
