<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;

class AdminPaymentController extends Controller
{
    /**
     * GET /api/admin/payments
     * Returns ALL payments with ticket + violator + cashier info.
     */
    public function index(Request $request)
    {
        $payments = Payment::query()
            ->with(['ticket.violator', 'recordedBy'])
            ->orderByDesc('paid_at')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'data' => $payments->map(function (Payment $p) {
                return [
                    'id'            => $p->id,
                    'receipt_no'    => $p->receipt_no,
                    'control_no'    => $p->ticket?->control_no,
                    'violator_name' => $p->ticket?->violator?->name,
                    'amount'        => $p->amount, // decimal(10,2)
                    'status'        => $p->status, // recorded | reversed
                    'paid_at'       => optional($p->paid_at)->toIso8601String(),
                    'cashier_name'  => $p->recordedBy?->full_name,
                ];
            }),
        ]);
    }
}
