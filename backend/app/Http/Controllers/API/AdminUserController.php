<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminUserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Illuminate\Database\Eloquent\Builder;

class AdminUserController extends Controller
{
    /**
     * GET /api/admin/users?q=&role=&page=&per_page=
     */
    public function index(Request $request)
    {
        try {
            $q = trim((string) $request->query('q', ''));
            $role = strtolower((string) $request->query('role', 'all'));
            $perPage = max(1, min((int) $request->query('per_page', 20), 200));

            $userTable = (new User())->getTable();
            $query = User::query();

            // search by full_name (preferred) or name, and always email
            $nameCol = Schema::hasColumn($userTable, 'full_name') ? 'full_name' : (Schema::hasColumn($userTable, 'name') ? 'name' : null);
            if ($q !== '') {
                $query->where(function (Builder $w) use ($q, $nameCol) {
                    if ($nameCol) {
                        $w->where($nameCol, 'like', "%{$q}%");
                    }
                    $w->orWhere('email', 'like', "%{$q}%");
                });
            }

            // role filter - many possibilities handled:
            if ($role !== '' && $role !== 'all') {
                // 1) If User has roles() relation (many-to-many / Spatie)
                if (method_exists(User::class, 'roles')) {
                    $query->whereHas('roles', function (Builder $q2) use ($role) {
                        $q2->where('slug', $role)->orWhere('name', $role);
                    });
                }
                // 2) If users table has role_id (FK) we can join with roles table
                elseif (Schema::hasColumn($userTable, 'role_id') && Schema::hasTable('roles')) {
                    $query->whereExists(function ($sub) use ($role, $userTable) {
                        $sub->select(DB::raw(1))
                            ->from('roles')
                            ->whereRaw('roles.id = ' . $userTable . '.role_id')
                            ->where(function ($r) use ($role) {
                                $r->where('roles.slug', $role)->orWhere('roles.name', $role);
                            });
                    });
                }
                // 3) If users.role contains a plain string or JSON blob, try filtering on that column
                elseif (Schema::hasColumn($userTable, 'role')) {
                    // try exact match first
                    $query->where(function ($w) use ($role) {
                        $w->where('role', $role)
                            ->orWhere('role', 'like', "%\"slug\":\"{$role}\"%")
                            ->orWhere('role', 'like', "%\"name\":\"{$role}\"%");
                    });
                } else {
                    // unknown role system -> return empty set
                    $query->whereRaw('0 = 1');
                }
            }

            $query->orderByDesc('id');
            $paginator = $query->paginate($perPage);

            return response()->json([
                'data' => AdminUserResource::collection($paginator->getCollection()),
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'total' => $paginator->total(),
            ]);
        } catch (\Throwable $e) {

            return response()->json([
                'error' => true,
                'message' => config('app.debug') ? $e->getMessage() : 'Server error',
            ], 500);
        }
    }

    /**
     * GET /api/admin/users/{id}
     */
    public function show(string $id)
    {
        $user = User::findOrFail($id);
        return response()->json([
            'data' => new AdminUserResource($user),
        ]);
    }

    /**
     * PATCH /api/admin/users/{id}
     * Body can include: name (or full_name), email, role (admin|enforcer|cashier), active (bool), avatar_url
     */
    public function update(Request $request, string $id)
    {
        $user = User::findOrFail($id);

        // minimal server-side validation
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'full_name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'role' => ['sometimes', 'string', 'max:100'],
            'active' => ['sometimes', 'boolean'],
            'avatar_url' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ]);

        try {
            // handle role specially
            if (array_key_exists('role', $data)) {
                $roleValue = $data['role'];
                unset($data['role']);

                $roleRecord = null;
                if (Schema::hasTable('roles')) {
                    $roleRecord = DB::table('roles')
                        ->where('slug', $roleValue)
                        ->orWhere('name', $roleValue)
                        ->first();
                }

                // If the User model has roles() relation (many-to-many)
                if (method_exists($user, 'roles')) {
                    if ($roleRecord) {
                        $user->roles()->sync([$roleRecord->id]);
                    } else {
                        // try to find role by slug/name and add, otherwise detach all
                        $r = DB::table('roles')->where('slug', $roleValue)->orWhere('name', $roleValue)->first();
                        if ($r) {
                            $user->roles()->sync([$r->id]);
                        } else {
                            // no matching role in DB - detach all or leave unchanged - choose to detach for safety
                            $user->roles()->sync([]);
                        }
                    }
                }
                // If users table has role_id column, set it
                elseif (Schema::hasColumn($user->getTable(), 'role_id') && $roleRecord) {
                    $user->role_id = $roleRecord->id;
                }
                // Else if users table has plain 'role' column: store simple string or JSON blob
                elseif (Schema::hasColumn($user->getTable(), 'role')) {
                    if ($roleRecord) {
                        $user->role = json_encode([
                            'id' => $roleRecord->id,
                            'name' => $roleRecord->name,
                            'slug' => $roleRecord->slug,
                        ]);
                    } else {
                        $user->role = $roleValue;
                    }
                } else {
                    // last resort: set a name on model if attribute exists (full_name/name handled below)
                    // nothing to do for role
                }
            }

            // fill other fields (respecting full_name vs name)
            if (array_key_exists('full_name', $data) && Schema::hasColumn($user->getTable(), 'full_name')) {
                $user->full_name = $data['full_name'];
                unset($data['full_name']);
            } elseif (array_key_exists('name', $data) && Schema::hasColumn($user->getTable(), 'name')) {
                $user->name = $data['name'];
                unset($data['name']);
            }

            // assign remaining fillable fields (email, active, avatar_url, etc.)
            foreach ($data as $k => $v) {
                // use fill if attribute exists on model
                if (in_array($k, $user->getFillable()) || array_key_exists($k, $user->getAttributes())) {
                    $user->{$k} = $v;
                }
            }

            $user->save();

            return response()->json([
                'data' => new AdminUserResource($user),
            ]);
        } catch (\Throwable $e) {

            return response()->json([
                'error' => true,
                'message' => config('app.debug') ? $e->getMessage() : 'Server error',
            ], 500);
        }
    }
    /**
     * DELETE /api/admin/users/{id}
     */
    public function destroy(string $id)
    {
        $user = User::findOrFail($id);

        // Prevent deleting self
        if (auth()->id() == $user->id) {
            return response()->json([
                'error' => true,
                'message' => 'Cannot delete your own account.',
            ], 403);
        }

        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully.',
        ]);
    }
}
