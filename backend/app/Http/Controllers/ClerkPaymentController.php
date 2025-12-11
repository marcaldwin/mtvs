<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ClerkPaymentController extends Controller
{
    /**
     * GET /api/clerk/payments/ticket-lookup?control_no=KD-2025-0001
     *
     * Returns ticket + violator + payments + outstanding_amount.
     */
    public function lookupTicket(Request $request)
    {
        $validated = $request->validate([
            'control_no' => ['required', 'string'],
        ]);

        $ticket = Ticket::with([
            'violator',
            'payments' => function ($q) {
                $q->orderByDesc('paid_at');
            }
        ])
            ->where('control_no', $validated['control_no'])
            ->first();

        if (!$ticket) {
            return response()->json([
                'message' => 'Ticket not found.',
            ], 404);
        }

        $paid = $ticket->payments()
            ->where('status', 'recorded')
            ->sum('amount');

        $outstanding = max($ticket->total_amount - $paid, 0);

        return response()->json([
            'ticket' => $ticket,
            'violator' => $ticket->violator,
            'payments' => $ticket->payments,
            'outstanding_amount' => (float) $outstanding,
        ]);
    }

    /**
     * POST /api/clerk/payments
     *
     * Body: ticket_id, amount, receipt_no, remarks?
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'ticket_id' => ['required', 'exists:tickets,id'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'receipt_no' => ['required', 'string', 'max:255'],
            'remarks' => ['nullable', 'string', 'max:255'],
        ]);

        $user = $request->user();

        $result = DB::transaction(function () use ($validated, $user) {
            /** @var \App\Models\Ticket $ticket */
            $ticket = Ticket::lockForUpdate()->findOrFail($validated['ticket_id']);

            $alreadyPaid = $ticket->payments()
                ->where('status', 'recorded')
                ->sum('amount');

            $newTotalPaid = $alreadyPaid + $validated['amount'];

            if ($newTotalPaid > $ticket->total_amount + 0.01) {
                throw ValidationException::withMessages([
                    'amount' => ['Payment exceeds ticket total.'],
                ]);
            }

            /** @var \App\Models\Payment $payment */
            $payment = Payment::create([
                'ticket_id' => $ticket->id,
                'recorded_by' => $user?->id,
                'amount' => $validated['amount'],
                'receipt_no' => $validated['receipt_no'],
                'paid_at' => now(),
                'status' => 'recorded',
                'remarks' => $validated['remarks'] ?? null,
            ]);

            if ($newTotalPaid >= $ticket->total_amount - 0.01) {
                $ticket->status = 'paid';
                $ticket->save();
            }

            return compact('ticket', 'payment');
        });

        /** @var \App\Models\Ticket $ticket */
        /** @var \App\Models\Payment $payment */
        $ticket = $result['ticket'];
        $payment = $result['payment'];

        $ticket->load('violator', 'payments');

    }

    /**
     * GET /api/clerk/payments/unpaid
     *
     * Returns recent unpaid tickets (limit 50).
     */
    public function recentUnpaid(Request $request)
    {
        $tickets = Ticket::with('violator')
            ->where('status', 'unpaid')
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json($tickets);
    }
}
