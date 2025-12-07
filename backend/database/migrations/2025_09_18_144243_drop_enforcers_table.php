<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // No FKs point to enforcers (you verified), so just drop it.
        Schema::dropIfExists('enforcers');
    }

    public function down(): void
    {
        // Minimal rollback (structure only)
        Schema::create('enforcers', function (Blueprint $table) {
            $table->id();
            // add back any columns you previously had if you want a true rollback
            $table->timestamps();
        });
    }
};
