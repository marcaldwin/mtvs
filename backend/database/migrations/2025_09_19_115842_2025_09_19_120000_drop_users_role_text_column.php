<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        // If both columns exist, backfill role_id from legacy text column "role"
        if (Schema::hasColumn('users', 'role') && Schema::hasColumn('users', 'role_id')) {

            // The JOIN update is MySQL/Postgres style.
            // SQLite doesn't support this syntax, so we skip it there.
            if (DB::getDriverName() !== 'sqlite') {
                DB::statement("
                    UPDATE users u
                    JOIN roles r ON r.slug = u.role
                    SET u.role_id = r.id
                    WHERE u.role_id IS NULL AND u.role IS NOT NULL
                ");
            }
        }

        // Drop the legacy 'role' column if it still exists
        if (Schema::hasColumn('users', 'role')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('role');
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        // Recreate 'role' column (nullable)
        if (!Schema::hasColumn('users', 'role')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('role', 50)->nullable();
            });
        }

        // Backfill 'role' from role_id when not on SQLite
        if (Schema::hasColumn('users', 'role') && Schema::hasColumn('users', 'role_id')) {
            if (DB::getDriverName() !== 'sqlite') {
                DB::statement("
                    UPDATE users u
                    JOIN roles r ON r.id = u.role_id
                    SET u.role = r.slug
                ");
            }
        }
    }
};
