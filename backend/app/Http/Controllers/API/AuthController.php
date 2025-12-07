<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Role;

class AuthController extends Controller
{
    /**
     * POST /api/auth/register
     * Accepts: full_name, username, email, password, password_confirmation, (optional) role (slug: admin|enforcer|cashier)
     */
    public function register(Request $request)
    {
        $data = $request->validate([
            'full_name' => 'required|string|max:255',
            'username'  => 'required|string|max:255|unique:users,username',
            'email'     => 'required|string|email|max:255|unique:users,email',
            'password'  => 'required|string|min:6|confirmed',
            'role'      => 'nullable|string|max:50', // slug (e.g. admin|enforcer|cashier)
        ]);

        // Map optional role slug -> role_id
        $roleId = null;
        if (!empty($data['role'])) {
            $role = Role::where('slug', $data['role'])->first();
            $roleId = $role?->id;
        }

        $user = User::create([
            'full_name' => $data['full_name'],
            'username'  => $data['username'],
            'email'     => $data['email'],
            'password'  => Hash::make($data['password']),
            'role_id'   => $roleId, // nullable is fine
        ]);

        $token = $user->createToken('mtvts-app')->plainTextToken;

        return response()->json([
            'message'    => 'Registration successful',
            'token'      => $token,
            'token_type' => 'Bearer',
            'user'       => [
                'id'        => $user->id,
                'full_name' => $user->full_name,
                'username'  => $user->username,
                'email'     => $user->email,
            ],
            'roles'      => $user->role ? [$user->role->slug] : [],
        ], 201);
    }

    /**
     * POST /api/auth/login
     * Accepts: email (can be email OR username), password
     */
    public function login(Request $request)
    {
        $data = $request->validate([
            'email'    => 'required|string',   // email or username
            'password' => 'required|string|min:6',
        ]);

        $login = $data['email'];

        $user = filter_var($login, FILTER_VALIDATE_EMAIL)
            ? User::where('email', $login)->first()
            : User::where('username', $login)->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        // one active app token per user
        $user->tokens()->where('name', 'mtvts-app')->delete();
        $token = $user->createToken('mtvts-app')->plainTextToken;

        return response()->json([
            'token'      => $token,
            'token_type' => 'Bearer',
            'user'       => [
                'id'        => $user->id,
                'full_name' => $user->full_name,
                'username'  => $user->username,
                'email'     => $user->email,
            ],
            'roles'      => $user->role ? [$user->role->slug] : [],
        ]);
    }

    /**
     * GET /api/auth/me   (requires auth:sanctum)
     */
    public function me(Request $request)
    {
        $u = $request->user();

        return response()->json([
            'id'        => $u->id,
            'full_name' => $u->full_name,
            'username'  => $u->username,
            'email'     => $u->email,
            'roles'     => $u->role ? [$u->role->slug] : [],
        ]);
    }

    /**
     * POST /api/auth/logout   (requires auth:sanctum)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();
        return response()->json(['message' => 'Logged out']);
    }
}
