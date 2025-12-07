<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Ticket;
use App\Models\Payment;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminReportsController extends Controller
{
    /**
     * GET /api/admin/reports/overview?from=YYYY-MM-DD&to=YYYY-MM-DD
     *
     * Returns:
     * {
     *   "summary": {
     *     "total_tickets": 0,
     *     "open_tickets": 0,
     *     "paid_tickets": 0,
     *     "total_collections": 0,
     *     "today_collections": 0
     *   },
     *   "by_violation": [
     *     { "violation_name": "...", "count": 10, "amount": 1500.00 }
     *   ],
     *   "daily": [
     *     { "date": "2025-11-01", "tickets": 5, "amount": 800.00 }
     *   ]
     * }
     */
    public function overview(Request $request)
    {
        [$from, $to] = $this->parseRange($request);

        // ── TICKETS SUMMARY (by apprehended_at) ──────────────────────────────
        $ticketsQuery = Ticket::query();

        if ($from && $to) {
            $ticketsQuery->whereBetween('apprehended_at', [$from, $to]);
        }

        $totalTickets = (clone $ticketsQuery)->count();
        $openTickets  = (clone $ticketsQuery)
            ->where('status', 'unpaid')
            ->count();
        $paidTickets  = (clone $ticketsQuery)
            ->where('status', 'paid')
            ->count();

        // ── COLLECTIONS SUMMARY (by payments.paid_at) ───────────────────────
        $totalCollections = $this->collectionsTotal($from, $to);
        $todayCollections = $this->collectionsToday();

        $summary = [
            'total_tickets'     => $totalTickets,
            'open_tickets'      => $openTickets,
            'paid_tickets'      => $paidTickets,
            'total_collections' => $totalCollections,
            'today_collections' => $todayCollections,
        ];

        // ── BY VIOLATION (collections per violation) ────────────────────────
        $byViolation = $this->byViolation($from, $to);

        // ── DAILY COLLECTIONS (trend) ───────────────────────────────────────
        $daily = $this->dailyCollections($from, $to);

        return response()->json([
            'summary'      => $summary,
            'by_violation' => $byViolation,
            'daily'        => $daily,
        ]);
    }

    /**
     * Parse from/to=YYYY-MM-DD => Carbon startOfDay / endOfDay
     */
    protected function parseRange(Request $request): array
    {
        $from = $request->query('from');
        $to   = $request->query('to');

        $fromDate = null;
        $toDate   = null;

        if ($from) {
            try {
                $fromDate = Carbon::createFromFormat('Y-m-d', $from)->startOfDay();
            } catch (\Exception $e) {
                // ignore invalid format → treat as null
            }
        }

        if ($to) {
            try {
                $toDate = Carbon::createFromFormat('Y-m-d', $to)->endOfDay();
            } catch (\Exception $e) {
                // ignore invalid format → treat as null
            }
        }

        return [$fromDate, $toDate];
    }

    /**
     * Sum of recorded payments in the selected range (by paid_at).
     */
    protected function collectionsTotal(?Carbon $from, ?Carbon $to): float
    {
        $query = Payment::query()
            ->where('status', 'recorded')
            ->whereNotNull('paid_at');

        if ($from && $to) {
            $query->whereBetween('paid_at', [$from, $to]);
        }

        return (float) $query->sum('amount');
    }

    /**
     * Today's recorded collections (ignores range filter).
     */
    protected function collectionsToday(): float
    {
        return (float) Payment::query()
            ->where('status', 'recorded')
            ->whereNotNull('paid_at')
            ->whereDate('paid_at', Carbon::today())
            ->sum('amount');
    }

    /**
     * Daily trend of collections: counts distinct tickets + sum(amount).
     */
    protected function dailyCollections(?Carbon $from, ?Carbon $to): array
    {
        $query = Payment::query()
            ->selectRaw('DATE(paid_at) as date, COUNT(DISTINCT ticket_id) as tickets, SUM(amount) as amount')
            ->where('status', 'recorded')
            ->whereNotNull('paid_at');

        if ($from && $to) {
            $query->whereBetween('paid_at', [$from, $to]);
        }

        $rows = $query
            ->groupBy(DB::raw('DATE(paid_at)'))
            ->orderBy('date')
            ->get();

        return $rows->map(function ($row) {
            return [
                'date'    => $row->date, // "YYYY-MM-DD"
                'tickets' => (int) $row->tickets,
                'amount'  => (float) $row->amount,
            ];
        })->all();
    }

    /**
     * Collections and ticket count grouped by violation.
     */
    protected function byViolation(?Carbon $from, ?Carbon $to): array
    {
        $query = Payment::query()
            ->join('tickets', 'payments.ticket_id', '=', 'tickets.id')
            ->join('violations', 'tickets.violation_id', '=', 'violations.id')
            ->where('payments.status', 'recorded')
            ->whereNotNull('payments.paid_at');

        if ($from && $to) {
            $query->whereBetween('payments.paid_at', [$from, $to]);
        }

        $rows = $query
            ->selectRaw('violations.name as violation_name, COUNT(DISTINCT tickets.id) as count, SUM(payments.amount) as amount')
            ->groupBy('violations.id', 'violations.name')
            ->orderByDesc('count')
            ->limit(20)
            ->get();

        return $rows->map(function ($row) {
            return [
                'violation_name' => $row->violation_name,
                'count'          => (int) $row->count,
                'amount'         => (float) $row->amount,
            ];
        })->all();
    }
}
