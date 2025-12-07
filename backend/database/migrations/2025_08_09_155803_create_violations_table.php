<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('violations', function (Blueprint $table) {
            $table->id();
            $table->string('type');               // Type of Violation
            $table->string('name');               // Name of Violation
            $table->decimal('fine', 10, 2);       // Fine of Violation
            $table->string('ordinance_no')->nullable(); // Ordinance #
            $table->timestamps();

            $table->index(['type', 'name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('violations');
    }
};
