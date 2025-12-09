<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration {
    public function up(): void
    {
        // No-op:
        // This migration was only meant to backfill role_id
        // from the legacy text column "role" and then drop "role".
        // On a fresh Render/Postgres database, there is no legacy data
        // to migrate, so we safely skip this.
    }

    public function down(): void
    {
        // No-op rollback.
    }
};
