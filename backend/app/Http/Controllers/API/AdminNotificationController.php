<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PasswordResetRequest;

class AdminNotificationController extends Controller
{
    /**
     * GET /api/admin/notifications/password-resets
     */
    public function index()
    {
        // Return unresolved requests with user details
        $requests = PasswordResetRequest::with('user')
            ->where('is_resolved', false)
            ->latest()
            ->get();

        return response()->json($requests);
    }

    /**
     * POST /api/admin/notifications/password-resets/{id}/resolve
     */
    public function resolve($id)
    {
        $req = PasswordResetRequest::findOrFail($id);
        $req->is_resolved = true;
        $req->save();

        return response()->json(['message' => 'Request marked as resolved.']);
    }
}
