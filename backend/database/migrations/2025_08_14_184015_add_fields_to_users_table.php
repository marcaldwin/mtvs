<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Basic Laravel users table already has: id, name, email, password, etc.
            // We'll align to your fields and add what's needed.

            // Rename 'name' to 'full_name' if you want a strict match (optional):
            if (Schema::hasColumn('users', 'name')) {
                $table->renameColumn('name', 'full_name');
            } else {
                $table->string('full_name')->after('id');
            }

            $table->string('enforcer_no')->nullable()->unique()->after('full_name'); // for enforcers; nullable for admins
            $table->string('employee_id')->nullable()->unique()->after('enforcer_no'); // for HR tie-in; nullable for enforcers
            $table->string('username')->unique()->after('employee_id');

            // Auth essentials (Laravel already has password + remember_token usually)
            if (!Schema::hasColumn('users', 'password')) {
                $table->string('password');
            }
            if (!Schema::hasColumn('users', 'remember_token')) {
                $table->rememberToken();
            }

            // role to distinguish admin vs enforcer
            $table->enum('role', ['admin', 'enforcer'])->default('enforcer')->after('username');

            // Ensure email can be nullable if you don’t want to require it:
            // $table->string('email')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Cautious rollback (won’t rename back automatically)
            if (Schema::hasColumn('users', 'role')) $table->dropColumn('role');
            if (Schema::hasColumn('users', 'username')) $table->dropColumn('username');
            if (Schema::hasColumn('users', 'employee_id')) $table->dropColumn('employee_id');
            if (Schema::hasColumn('users', 'enforcer_no')) $table->dropColumn('enforcer_no');
            // (Optional) Rename back:
            // if (Schema::hasColumn('users', 'full_name')) $table->renameColumn('full_name', 'name');
        });
    }
};
