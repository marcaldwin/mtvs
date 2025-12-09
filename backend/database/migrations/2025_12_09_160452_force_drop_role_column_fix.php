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

        // On Postgres, drop the CHECK constraint that references "role", if it exists
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
        }

        // Backfill role_id from the legacy "role" column if possible
        if (Schema::hasColumn('users', 'role') && Schema::hasColumn('users', 'role_id')) {
            $roles = DB::table('roles')->pluck('id', 'slug'); // ['admin' => 1, 'enforcer' => 2]

            // specific fix for known users if needed
            $adminId = $roles['admin'] ?? null;
            $enforcerId = $roles['enforcer'] ?? null;

            if ($adminId) {
                DB::table('users')->where('role', 'admin')->whereNull('role_id')->update(['role_id' => $adminId]);
                // Also ensure the known admin email has it
                DB::table('users')->where('email', 'admin@mtvts.com')->update(['role_id' => $adminId]);
            }
            if ($enforcerId) {
                DB::table('users')->where('role', 'enforcer')->whereNull('role_id')->update(['role_id' => $enforcerId]);
                // Also ensure the known enforcer email has it
                DB::table('users')->where('email', 'enforcer@mtvts.com')->update(['role_id' => $enforcerId]);
            }
        }

        // Drop the legacy text "role" column if it still exists
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

        // Recreate the column as nullable in case of rollback
        if (!Schema::hasColumn('users', 'role')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('role', 50)->nullable();
            });
        }
    }
};
