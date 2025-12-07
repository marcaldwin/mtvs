<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;

class Enforcer extends User
{
    protected $table = 'users';

    protected static function booted(): void
    {
        static::addGlobalScope('role_enforcer', function (Builder $q) {
            $q->where('role', 'enforcer');
        });
    }

    protected $attributes = [
        'role' => 'enforcer',
    ];
}
