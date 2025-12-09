<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration {
    public function up(): void
    {
        // No-op: we are not enforcing a DB-level foreign key
        // on sessions.user_id in production. The app logic
        // works fine without this constraint.
    }

    public function down(): void
    {
        // No-op rollback.
    }
};
