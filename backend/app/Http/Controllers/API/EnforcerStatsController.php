<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Ticket;
use Carbon\Carbon;

class EnforcerStatsController extends Controller
{
    public function today(Request $request)
    {
        $user = $request->user();
        $today = now()->toDateString();

        $query = Ticket::where('enforcer_id', $user->id)
            ->whereDate('apprehended_at', $today);

        $todayCitations  = $query->count();
        $todayTotalFines = (float) $query->sum('total_amount');

        // Get latest apprehended_at for today
        $last = $query->orderByDesc('apprehended_at')->value('apprehended_at');

        $lastCitationAt   = $last ? Carbon::parse($last) : null;
        $lastCitationTime = $lastCitationAt
            ? $lastCitationAt->timezone(config('app.timezone'))
            ->format('h:i A') // e.g. "10:20 PM"
            : null;

        return response()->json([
            'today_citations'    => $todayCitations,
            'today_total_fines'  => $todayTotalFines,
            'last_citation_at'   => $lastCitationAt?->toIso8601String(),
            'last_citation_time' => $lastCitationTime,
        ]);
    }
}
