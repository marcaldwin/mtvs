<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Ticket;
use App\Models\Violator;
use App\Models\Violation;
use Illuminate\Support\Facades\DB;

class TicketController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user(); // enforcer issuing the ticket

        $data = $request->validate([
            'violator_name' => 'required|string|max:255',
            'drivers_license' => 'required|string|max:255',
            'plate_no' => 'nullable|string|max:255',
            'place_of_apprehension' => 'nullable|string|max:255',

            // 🔹 New Fields
            'age' => 'nullable|integer',
            'sex' => 'nullable|string|max:10',
            'address' => 'nullable|string|max:255',
            'compliance_date' => 'nullable|date',

            // 🔹 Multi-violations
            'violations' => 'required|array|min:1',
            'violations.*.violation_id' => 'required|integer|exists:violations,id',
        ]);

        try {
            $ticket = DB::transaction(function () use ($data, $user) {
                // 1) Violator record
                // Update if exists or create
                $violator = Violator::updateOrCreate(
                    [
                        'drivers_license' => $data['drivers_license'],
                    ],
                    [
                        'name' => $data['violator_name'],
                        'address' => $data['address'] ?? null,
                        'age' => $data['age'] ?? null,
                        'sex' => $data['sex'] ?? null,
                        'plate_no' => $data['plate_no'] ?? null,
                        'kd_no' => null,
                    ]
                );

                // 2) Resolve violations + compute fines
                $violationItems = collect($data['violations'])->map(function ($item) {
                    $violation = Violation::findOrFail($item['violation_id']);

                    return [
                        'violation_id' => $violation->id,
                        'fine_amount' => $violation->fine, // from violations table
                        'remarks' => null,
                    ];
                });

                $totalFine = (float) $violationItems->sum('fine_amount');
                $additionalFees = 0.0;
                $totalAmount = $totalFine + $additionalFees;

                // Use first violation as "primary" for tickets.violation_id
                $primaryViolationId = $violationItems->first()['violation_id'];

                // 3) Create ticket main record
                // ❌ no control_no here – model will auto-generate
                $ticket = Ticket::create([
                    'violator_id' => $violator->id,
                    'enforcer_id' => $user->id,
                    'violation_id' => $primaryViolationId,
                    'fine_amount' => $totalFine,
                    'additional_fees' => $additionalFees,
                    'total_amount' => $totalAmount,
                    'place_of_apprehension' => $data['place_of_apprehension'] ?? null,
                    'compliance_date' => $data['compliance_date'] ?? null,
                    'status' => 'unpaid',
                    'apprehended_at' => now(),
                ]);

                // 4) Insert into ticket_violation pivot
                foreach ($violationItems as $item) {
                    DB::table('ticket_violation')->insert([
                        'ticket_id' => $ticket->id,
                        'violation_id' => $item['violation_id'],
                        'fine_amount' => $item['fine_amount'],
                        'remarks' => $item['remarks'],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                // Optionally eager load relationships for the response
                return $ticket->load('violator', 'enforcer', 'violations');
            });

            return response()->json([
                'message' => 'Ticket created successfully.',
                'ticket' => $ticket,
            ], 201);
        } catch (\Throwable $e) {
            // 👇 instead of a blind 500, return the real error
            return response()->json([
                'message' => 'Failed to create ticket',
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ], 500);
        }
    }
}
