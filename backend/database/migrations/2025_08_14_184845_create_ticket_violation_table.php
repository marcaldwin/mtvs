<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('ticket_violation', function (Blueprint $table) {
            $table->id();

            // Link to the ticket
            $table->foreignId('ticket_id')
                ->constrained()
                ->cascadeOnDelete();

            // Link to the violation
            $table->foreignId('violation_id')
                ->constrained()
                ->cascadeOnDelete();

            // Fine at the time of issuance (snapshot)
            $table->decimal('fine_amount', 10, 2);

            // Optional: remarks if violation has special note
            $table->string('remarks')->nullable();

            $table->timestamps();

            // Prevent duplicate entries of the same violation on the same ticket
            $table->unique(['ticket_id', 'violation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ticket_violation');
    }
};
