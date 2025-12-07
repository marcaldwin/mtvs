<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Role;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        // Simple-roles seeding: only name + slug
        Role::updateOrCreate(
            ['slug' => 'admin'],
            ['name' => 'Admin']
        );

        Role::updateOrCreate(
            ['slug' => 'enforcer'],
            ['name' => 'Enforcer']
        );

        // If you use "cashier" as the clerk role, keep this:
        Role::updateOrCreate(
            ['slug' => 'cashier'],
            ['name' => 'Cashier']
        );

        // If instead you want a true "clerk" role, replace the block above with:
        // Role::updateOrCreate(
        //     ['slug' => 'clerk'],
        //     ['name' => 'Clerk']
        // );
    }
}
