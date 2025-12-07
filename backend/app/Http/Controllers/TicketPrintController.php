<?php

namespace App\Http\Controllers;

use App\Models\Ticket;
use Illuminate\Http\Request;

class TicketPrintController extends Controller
{
    public function show(Ticket $ticket)
    {
        // Eager load everything needed for the citation
        $ticket->load([
            'violator',
            'enforcer',
            'violations',
            'primaryViolation',
            'payments',
            'latestPayment',
        ]);

        // You can calculate some derived values here if needed
        $totalViolationFine = $ticket->violations->sum(function ($v) {
            return $v->pivot->fine_amount ?? $v->fine;
        });

        $data = [
            'ticket'            => $ticket,
            'totalViolationFine' => $totalViolationFine,
            'hasMultiple'       => $ticket->violations->count() > 1,
        ];

        return view('tickets.print', $data);
    }
}
