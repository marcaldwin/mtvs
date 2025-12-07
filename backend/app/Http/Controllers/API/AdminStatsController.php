<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Ticket;
use App\Models\User;

class AdminStatsController extends Controller
{
    public function __invoke(Request $request)
    {
        // You’re already behind auth:sanctum via routes/api.php

        $today = now()->toDateString();

        // Use created_at (always exists) so we avoid custom column issues
        $totalCitationsToday = Ticket::whereDate('created_at', $today)->count();

        // Count users whose role slug is 'enforcer'
        $totalEnforcers = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.id')
            ->where('roles.slug', 'enforcer') // or ->where('roles.name', 'Enforcer')
            ->count();

        return response()->json([
            'total_citations_today' => $totalCitationsToday,
            'total_enforcers'       => $totalEnforcers,
        ]);
    }
}
