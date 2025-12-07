<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('violators', function (Blueprint $table) {
            $table->id();
            $table->string('name');                    // Name
            $table->string('address')->nullable();     // Address
            $table->string('drivers_license')->index(); // Driver's License
            $table->string('plate_no')->nullable()->index(); // Plate No.
            $table->string('kd_no')->nullable();       // KD#
            $table->timestamps();

            $table->index(['drivers_license', 'plate_no']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('violators');
    }
};
