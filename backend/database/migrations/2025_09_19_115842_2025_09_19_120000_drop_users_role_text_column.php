<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ensure role_id exists and is FK'ed to roles (if you already have this, it will be skipped)
        if (! Schema::hasColumn('users', 'role_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->foreignId('role_id')->nullable()->constrained('roles');
            });
        }

        // If there's still a legacy text column "role", use it to populate role_id
        if (Schema::hasColumn('users', 'role')) {
            // Backfill: map users.role (slug) -> roles.id into users.role_id (only where role_id is null)
            DB::statement("
                UPDATE users u
                JOIN roles r ON r.slug = u.role
                SET u.role_id = r.id
                WHERE u.role_id IS NULL AND u.role IS NOT NULL
            ");

            // Drop the legacy text column
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('role');
            });
        }
    }

    public function down(): void
    {
        // Recreate the legacy text column (nullable), backfill from role_id, if you ever roll back
        if (! Schema::hasColumn('users', 'role')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('role', 50)->nullable()->after('username');
            });

            DB::statement("
                UPDATE users u
                JOIN roles r ON r.id = u.role_id
                SET u.role = r.slug
            ");
        }
    }
};
