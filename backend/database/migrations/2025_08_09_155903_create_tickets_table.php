<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $table) {
            $table->id();

            // Who was ticketed & by whom
            $table->foreignId('violator_id')->constrained()->cascadeOnDelete();
            $table->foreignId('enforcer_id')->constrained('users')->cascadeOnDelete();

            // Which violation (one violation per ticket as requested)
            $table->foreignId('violation_id')->constrained()->cascadeOnDelete();

            // Snapshot of fine at issuance (in case master data changes)
            $table->decimal('fine_amount', 10, 2);

            // If you need total fines (you mentioned "Fines" and "Total Fines")
            $table->decimal('additional_fees', 10, 2)->default(0);
            $table->decimal('total_amount', 10, 2)->computed('fine_amount + additional_fees');

            // Place of Apprehension, Date/Time, Control No.
            $table->string('place_of_apprehension')->nullable();
            $table->timestamp('apprehended_at'); // Date / Time
            $table->string('control_no')->unique();

            // Status (unpaid, paid, cancelled)
            $table->enum('status', ['unpaid', 'paid', 'cancelled'])->default('unpaid');

            $table->timestamps();

            $table->index(['control_no', 'apprehended_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};
