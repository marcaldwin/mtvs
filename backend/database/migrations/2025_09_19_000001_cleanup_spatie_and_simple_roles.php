<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration {
    public function up(): void
    {
        // --- 0) Drop Spatie tables if present (safe if missing)
        Schema::dropIfExists('model_has_permissions');
        Schema::dropIfExists('model_has_roles');
        Schema::dropIfExists('role_has_permissions');
        Schema::dropIfExists('permissions');

        // --- 1) Ensure roles table exists
        if (!Schema::hasTable('roles')) {
            Schema::create('roles', function (Blueprint $table) {
                $table->id();
                $table->string('name')->unique();
                $table->string('slug')->unique();
                $table->timestamps();
            });
            $hasGuard = false;
        } else {
            $hasGuard = Schema::hasColumn('roles', 'guard_name');

            // Add 'slug' if missing (nullable first, no unique yet)
            if (!Schema::hasColumn('roles', 'slug')) {
                Schema::table('roles', function (Blueprint $table) {
                    $table->string('slug')->nullable()->after('name');
                });
            }
        }

        // --- 1b) Backfill slugs uniquely for existing rows
        $roles = DB::table('roles')->select('id', 'name', 'slug')->orderBy('id')->get();
        if ($roles->count() > 0) {
            $used = [];
            foreach ($roles as $r) {
                $slug = $r->slug;
                if ($slug === null || $slug === '') {
                    $base = Str::slug($r->name);
                    if ($base === '') $base = 'role-' . $r->id;
                    $slug = $base;
                }
                $candidate = $slug;
                $i = 2;
                while (
                    in_array($candidate, $used, true) ||
                    DB::table('roles')->where('slug', $candidate)->where('id', '!=', $r->id)->exists()
                ) {
                    $candidate = $slug . '-' . $i;
                    $i++;
                }
                $used[] = $candidate;
                DB::table('roles')->where('id', $r->id)->update(['slug' => $candidate]);
            }

            // Add unique index on slug if not there yet
            try {
                Schema::table('roles', function (Blueprint $table) {
                    $table->unique('slug', 'roles_slug_unique');
                });
            } catch (\Throwable $e) {
                // ignore if already unique
            }
        }

        // --- 2) Add users.role_id -> roles.id (nullable, nullOnDelete)
        if (!Schema::hasColumn('users', 'role_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->foreignId('role_id')->nullable()->constrained('roles')->nullOnDelete();
            });
        }

        // --- 3) Upsert core roles (include guard_name if column exists)
        $now  = now();
        $rows = [
            ['slug' => 'admin',    'name' => 'Admin',    'created_at' => $now, 'updated_at' => $now],
            ['slug' => 'enforcer', 'name' => 'Enforcer', 'created_at' => $now, 'updated_at' => $now],
            ['slug' => 'cashier',  'name' => 'Cashier',  'created_at' => $now, 'updated_at' => $now],
        ];
        if ($hasGuard) {
            foreach ($rows as &$row) {
                $row['guard_name'] = 'web';
            }
            unset($row);
        }
        DB::table('roles')->upsert($rows, ['slug'], ['name', 'updated_at']);

        // --- 4) Ensure admin user has Admin role (adjust email if needed)
        $adminRoleId = DB::table('roles')->where('slug', 'admin')->value('id');
        if ($adminRoleId) {
            DB::table('users')
                ->where('email', 'admin@mtvts.com')
                ->update(['role_id' => $adminRoleId]);
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'role_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropForeign(['role_id']);
                $table->dropColumn('role_id');
            });
        }
        // Keep 'roles' table by default; comment in the next line if you want to drop it:
        // Schema::dropIfExists('roles');
    }
};
