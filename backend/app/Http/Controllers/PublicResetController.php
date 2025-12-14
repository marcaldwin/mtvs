<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\AdminPasswordReset;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class PublicResetController extends Controller
{
    public function show(Request $request)
    {
        $token = $request->query('token');

        if (!$token) {
            return $this->errorView('Invalid link: No token provided.');
        }

        // Find the valid reset record
        // We can't query by hash directly easily unless we verify all, 
        // OR we just assume the token provided is the raw string and we hash it to compare.
        // In AdminResetController we stored: 'token_hash' => Hash::make($token).
        // Hash::check($token, $hash) is needed.
        // So we must iterate or find a way to lookup.
        // ACTUALLY: `Hash::make` produces a bcrypt hash which is salted and cannot be deterministically looked up via SQL.
        // OPTIMIZATION: We should probably store a simple sha256 hash of the token if we want fast lookup, 
        // OR standard Laravel password resets use the email as a key.
        // Given existing schema plan: `token_hash`.
        // If we used Hash::make, we can't search. 
        // CORRECTION: The implementation plan said "store hashed token". 
        // If I strictly used `Hash::make` I can't lookup. 
        // I should update AdminResetController to use something deterministic like hash('sha256', $token) for `token_hash` 
        // so I can look it up.

        // I will fix AdminResetController in a moment. For now let's write this assuming deterministic hash.
        $hash = hash('sha256', $token);

        $record = AdminPasswordReset::where('token_hash', $hash)
            ->where('used_at', null)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$record) {
            return $this->errorView('Invalid or expired link. Please contact an administrator.');
        }

        return view('auth.passwords.reset-admin', ['token' => $token]);
    }

    public function update(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'password' => 'required|confirmed|min:8',
        ]);

        $token = $request->input('token');
        $hash = hash('sha256', $token);

        $record = AdminPasswordReset::where('token_hash', $hash)
            ->where('used_at', null)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$record) {
            return back()->withErrors(['token' => 'Invalid or expired link.']);
        }

        $user = $record->user;
        $user->password = Hash::make($request->input('password'));
        $user->save();

        // Mark used
        $record->used_at = Carbon::now();
        $record->save();

        // Optional: Invalidate other sessions?
        // Method to logout user not easily available here without session access, 
        // but changing password generally checks hash on next auth.

        return redirect()->route('login')->with('status', 'Password reset successfully! You can now login.');
    }

    private function errorView($message)
    {
        // Return a simple view or use the reset form with an error
        return view('auth.passwords.reset-admin-error', ['message' => $message]);
    }
}
