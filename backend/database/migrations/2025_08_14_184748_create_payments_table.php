<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ticket_id')->constrained()->cascadeOnDelete();

            // Admin who recorded the payment (at treasurer confirmation)
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->decimal('amount', 10, 2);
            $table->string('receipt_no')->nullable(); // Treasurer’s receipt
            $table->timestamp('paid_at')->nullable();

            // Optional: method/status
            $table->enum('status', ['recorded', 'reversed'])->default('recorded');
            $table->string('remarks')->nullable();

            $table->timestamps();

            $table->index(['ticket_id', 'paid_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
