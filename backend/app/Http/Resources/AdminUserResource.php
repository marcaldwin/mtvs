<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;

class AdminUserResource extends JsonResource
{
    public function toArray($request): array
    {
        // Prefer full_name, then name, then email
        $name = $this->full_name ?? $this->name ?? $this->email ?? null;

        // Resolve role name defensively
        $roleName = null;

        // 1) Spatie-like roles relation (if present & loaded)
        if (method_exists($this, 'roles') && $this->relationLoaded('roles') && $this->roles->isNotEmpty()) {
            $roleName = $this->roles->first()->name ?? null;
        }

        // 2) If there is a role_id column and it has value, try lookup
        if ($roleName === null && isset($this->role_id)) {
            $r = DB::table('roles')->where('id', $this->role_id)->first();
            if ($r) {
                $roleName = $r->name;
            }
        }

        // 3) If users.role stores JSON (stringified object) decode it
        if ($roleName === null && isset($this->role) && is_string($this->role)) {
            $decoded = json_decode($this->role, true);
            if (is_array($decoded)) {
                $roleName = $decoded['name'] ?? $decoded['slug'] ?? null;
            } else {
                // maybe it's just a simple string
                $roleName = $this->role;
            }
        }

        // 4) As fallback, check role_name or role_name column
        if ($roleName === null) {
            $roleName = $this->role_name ?? $this->roleName ?? null;
        }

        return [
            'id' => (string) $this->id,
            'name' => $name,
            'email' => $this->email,
            'role' => $roleName,
            'active' => (bool) ($this->active ?? false),
            'avatar_url' => $this->avatar_url ?? null,
        ];
    }
}
