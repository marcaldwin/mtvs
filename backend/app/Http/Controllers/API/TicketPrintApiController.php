<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ticket;

class TicketPrintApiController extends Controller
{
    public function show(Ticket $ticket)
    {
        $ticket->load([
            'violator',
            'enforcer',
            'violations',
            'primaryViolation',
            'latestPayment',
        ]);

        $violations = $ticket->violations->map(function ($v, $idx) {
            return [
                'index'        => $idx + 1,
                'name'         => $v->name,
                'ordinance_no' => $v->ordinance_no,
                'fine'         => (float) ($v->pivot->fine_amount ?? $v->fine),
            ];
        });

        return response()->json([
            'citation_no'   => $ticket->control_no,
            'status'        => $ticket->status,
            'date_time'     => $ticket->apprehended_at?->format('Y-m-d H:i:s'),
            'place'         => $ticket->place_of_apprehension,
            'violator'      => [
                'name'            => $ticket->violator?->name,
                'address'         => $ticket->violator?->address,
                'drivers_license' => $ticket->violator?->drivers_license,
                'plate_no'        => $ticket->violator?->plate_no,
                'kd_no'           => $ticket->violator?->kd_no,
            ],
            'enforcer'      => [
                'name'        => $ticket->enforcer?->full_name,
                'enforcer_no' => $ticket->enforcer?->enforcer_no,
            ],
            'violations'    => $violations,
            'additional_fees' => (float) $ticket->additional_fees,
            'total_amount'    => (float) $ticket->total_amount,
            'latest_payment'  => $ticket->latestPayment ? [
                'receipt_no' => $ticket->latestPayment->receipt_no,
                'amount'     => (float) $ticket->latestPayment->amount,
                'paid_at'    => $ticket->latestPayment->paid_at?->format('Y-m-d H:i:s'),
            ] : null,
        ]);
    }
}
