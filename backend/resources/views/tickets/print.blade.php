<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Citation #{{ $ticket->control_no }}</title>
    <style>
        * {
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }

        body {
            margin: 0;
            padding: 16px;
            font-size: 12px;
        }

        .page {
            width: 80mm;
            /* Adjust to your printer / A4 if needed */
            margin: 0 auto;
        }

        .header {
            text-align: center;
            margin-bottom: 8px;
        }

        .header h1 {
            font-size: 14px;
            margin: 0;
            text-transform: uppercase;
        }

        .header h2 {
            font-size: 12px;
            margin: 0;
        }

        .meta,
        .section {
            margin-bottom: 8px;
        }

        .meta-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 2px;
        }

        .label {
            font-weight: bold;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 4px;
        }

        table th,
        table td {
            border: 1px solid #000;
            padding: 3px;
            font-size: 11px;
        }

        table th {
            text-align: left;
        }

        .total-row td {
            font-weight: bold;
        }

        .footer {
            margin-top: 10px;
            font-size: 11px;
        }

        .signature-line {
            margin-top: 16px;
            text-align: center;
        }

        .signature-line span {
            display: inline-block;
            border-top: 1px solid #000;
            padding-top: 2px;
            min-width: 100px;
        }

        .status-paid {
            font-weight: bold;
            color: green;
        }

        .status-unpaid {
            font-weight: bold;
            color: red;
        }

        @media print {
            body {
                margin: 0;
            }
        }
    </style>
</head>

<body onload="window.print()">
    <div class="page">

        {{-- HEADER --}}
        <div class="header">
            <h1>Republic of the Philippines</h1>
            <h2>City of Kidapawan</h2>
            <div>Traffic Management Unit</div>
            <div><strong>TRAFFIC VIOLATION CITATION</strong></div>
        </div>

        {{-- BASIC META --}}
        <div class="meta">
            <div class="meta-row">
                <span class="label">Citation No:</span>
                <span>{{ $ticket->control_no }}</span>
            </div>
            <div class="meta-row">
                <span class="label">Date/Time:</span>
                <span>{{ $ticket->apprehended_at?->format('M d, Y h:i A') }}</span>
            </div>
            <div class="meta-row">
                <span class="label">Place of Apprehension:</span>
                <span>{{ $ticket->place_of_apprehension ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span class="label">Status:</span>
                @php
                $statusClass = $ticket->status === 'paid' ? 'status-paid' : 'status-unpaid';
                @endphp
                <span class="{{ $statusClass }}">{{ strtoupper($ticket->status) }}</span>
            </div>
        </div>

        {{-- VIOLATOR INFO --}}
        <div class="section">
            <div class="label">Violator Information</div>
            <div class="meta-row">
                <span>Name:</span>
                <span>{{ $ticket->violator?->name ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>Address:</span>
                <span>{{ $ticket->violator?->address ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>Driver's License:</span>
                <span>{{ $ticket->violator?->drivers_license ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>Plate No:</span>
                <span>{{ $ticket->violator?->plate_no ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>KD No:</span>
                <span>{{ $ticket->violator?->kd_no ?? '-' }}</span>
            </div>
        </div>

        {{-- VIOLATIONS --}}
        <div class="section">
            <div class="label">Violation(s)</div>

            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Violation</th>
                        <th>Ordinance</th>
                        <th style="text-align:right;">Fine</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($ticket->violations as $index => $v)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $v->name }}</td>
                        <td>{{ $v->ordinance_no ?? '-' }}</td>
                        <td style="text-align:right;">
                            {{ number_format($v->pivot->fine_amount ?? $v->fine, 2) }}
                        </td>
                    </tr>
                    @empty
                    {{-- fallback: maybe only primaryViolation is used --}}
                    @if($ticket->primaryViolation)
                    <tr>
                        <td>1</td>
                        <td>{{ $ticket->primaryViolation->name }}</td>
                        <td>{{ $ticket->primaryViolation->ordinance_no ?? '-' }}</td>
                        <td style="text-align:right;">
                            {{ number_format($ticket->fine_amount, 2) }}
                        </td>
                    </tr>
                    @else
                    <tr>
                        <td colspan="4">No violations recorded.</td>
                    </tr>
                    @endif
                    @endforelse

                    {{-- TOTALS --}}
                    <tr class="total-row">
                        <td colspan="3">Total Violation Fine</td>
                        <td style="text-align:right;">
                            {{ number_format($totalViolationFine, 2) }}
                        </td>
                    </tr>
                    <tr class="total-row">
                        <td colspan="3">Additional Fees</td>
                        <td style="text-align:right;">
                            {{ number_format($ticket->additional_fees, 2) }}
                        </td>
                    </tr>
                    <tr class="total-row">
                        <td colspan="3">TOTAL AMOUNT DUE</td>
                        <td style="text-align:right;">
                            {{ number_format($ticket->total_amount, 2) }}
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        {{-- ENFORCER + PAYMENT INFO --}}
        <div class="section">
            <div class="label">Enforcer</div>
            <div class="meta-row">
                <span>Name:</span>
                <span>{{ $ticket->enforcer?->full_name ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>Enforcer No:</span>
                <span>{{ $ticket->enforcer?->enforcer_no ?? '-' }}</span>
            </div>
        </div>

        @if($ticket->latestPayment)
        <div class="section">
            <div class="label">Latest Payment</div>
            <div class="meta-row">
                <span>OR / Receipt No:</span>
                <span>{{ $ticket->latestPayment->receipt_no ?? '-' }}</span>
            </div>
            <div class="meta-row">
                <span>Amount Paid:</span>
                <span>{{ number_format($ticket->latestPayment->amount, 2) }}</span>
            </div>
            <div class="meta-row">
                <span>Paid At:</span>
                <span>{{ $ticket->latestPayment->paid_at?->format('M d, Y h:i A') }}</span>
            </div>
            <div class="meta-row">
                <span>Recorded By:</span>
                <span>{{ $ticket->latestPayment->recordedBy?->full_name ?? '-' }}</span>
            </div>
        </div>
        @endif

        {{-- FOOTER / UNDERTAKING --}}
        <div class="footer">
            I acknowledge receipt of this citation and understand that I must settle the
            penalty on or before the prescribed deadline at the authorized payment center.
        </div>

        <div class="signature-line">
            <span>Violator's Signature</span>
        </div>

    </div>
</body>

</html>