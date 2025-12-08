<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('sessions') || !Schema::hasColumn('sessions', 'user_id')) {
            return;
        }

        // Ensure user_id is nullable and bigint
        try {
            Schema::table('sessions', function (Blueprint $table) {
                $table->unsignedBigInteger('user_id')->nullable()->change();
            });
        } catch (\Throwable $e) {
            // MySQL fallback
            try {
                DB::statement("ALTER TABLE sessions MODIFY user_id BIGINT UNSIGNED NULL");
            } catch (\Throwable $ignored) {}

            // PostgreSQL fallback
            try {
                DB::statement("ALTER TABLE sessions ALTER COLUMN user_id DROP NOT NULL");
                DB::statement("ALTER TABLE sessions ALTER COLUMN user_id TYPE BIGINT USING user_id::bigint");
            } catch (\Throwable $ignored) {}
        }

        // Clean orphan user_id values before adding FK
        try {
            // MySQL
            DB::statement("
                UPDATE sessions s
                LEFT JOIN users u ON u.id = s.user_id
                SET s.user_id = NULL
                WHERE s.user_id IS NOT NULL AND u.id IS NULL
            ");
        } catch (\Throwable $ignored) {
            // PostgreSQL
            DB::statement("
                UPDATE sessions
                SET user_id = NULL
                WHERE user_id IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1 FROM users WHERE users.id = sessions.user_id
                )
            ");
        }

        // Drop existing FK if exists
        try {
            Schema::table('sessions', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
            });
        } catch (\Throwable $e) {}

        // Add new FK
        Schema::table('sessions', function (Blueprint $table) {
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('sessions') || !Schema::hasColumn('sessions', 'user_id')) {
            return;
        }

        try {
            Schema::table('sessions', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
            });
        } catch (\Throwable $e) {}
    }
};
