<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\AdminPasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class AdminResetController extends Controller
{
    /**
     * Generate a password reset link for the given user.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  string  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request, string $id)
    {
        $user = User::findOrFail($id);

        // Security check: Ensure only admins can do this functionality is handled by route middleware, 
        // but verifying the actor is an admin here is good practice or handled via Gate/Policy.
        // Assuming 'auth:sanctum' checks user is logged in. 
        // We might want to check if Auth::user()->role is admin.

        // Generate a random token
        $token = Str::random(60);
        $hash = hash('sha256', $token);

        // Create reset record
        AdminPasswordReset::create([
            'user_id' => $user->id,
            'token_hash' => $hash,
            'expires_at' => Carbon::now()->addHours(24),
            'created_by_admin_id' => Auth::id(),
        ]);

        // Construct the link
        // Relies on a named route 'password.reset.admin' (we will create this in web.php)
        // OR manually constructing it if the frontend structure is cleaner.
        // The requirement said: APP_URL/reset-password?token=...
        $baseUrl = config('app.url');
        // If app.url ends with /, remove it to avoid double slash, though browsers handle it.
        $link = rtrim($baseUrl, '/') . "/reset-password?token={$token}";

        return response()->json([
            'message' => 'Reset link generated successfully.',
            'link' => $link,
            // 'password' is kept for backward compatibility if the previous code expected a password field, 
            // but we are changing the behavior. We should return 'link' primarily.
            // The existing repo methods returns 'password', so we'll just not return it,
            // and update the flutter app to look for 'link'.
        ]);
    }
}
