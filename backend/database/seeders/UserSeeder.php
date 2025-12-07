<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Role;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Fetch role IDs by slug
        $adminRole    = Role::where('slug', 'admin')->first();
        $enforcerRole = Role::where('slug', 'enforcer')->first();
        $cashierRole  = Role::where('slug', 'cashier')->first(); // use this for "clerk" account

        // Admin
        User::updateOrCreate(
            ['email' => 'admin@mtvts.com'],
            [
                'full_name' => 'System Administrator',
                'username'  => 'admin',
                'password'  => Hash::make('password123'),
                'role_id'   => $adminRole?->id,
            ]
        );

        // Enforcer
        User::updateOrCreate(
            ['email' => 'enforcer@mtvts.com'],
            [
                'full_name' => 'Traffic Enforcer',
                'username'  => 'enforcer',
                'password'  => Hash::make('password123'),
                'role_id'   => $enforcerRole?->id,
            ]
        );

        // Clerk (maps to "cashier" role based on your roles table)
        User::updateOrCreate(
            ['email' => 'clerk@mtvts.com'],
            [
                'full_name' => 'Clerk Staff',
                'username'  => 'clerk',
                'password'  => Hash::make('password123'),
                'role_id'   => $cashierRole?->id,
            ]
        );
    }
}
