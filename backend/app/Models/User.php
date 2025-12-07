<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $fillable = [
        'full_name',
        'username',
        'email',
        'password',
        'enforcer_no',
        'employee_id',
        'role_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Simple-roles relationship
    public function role(): BelongsTo
    {
        return $this->belongsTo(Role::class);
    }

    // Optional helper
    public function hasRole(string $nameOrSlug): bool
    {
        if (!$this->role) return false;
        $x = strtolower($nameOrSlug);
        return strtolower($this->role->name) === $x
            || strtolower($this->role->slug) === $x;
    }
}
