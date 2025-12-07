<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TicketViolation extends Model
{
    use HasFactory;

    protected $table = 'ticket_violation';

    protected $fillable = [
        'ticket_id',
        'violation_id',
        'fine_amount',
        'remarks',
    ];

    public function ticket()
    {
        return $this->belongsTo(Ticket::class);
    }

    public function violation()
    {
        return $this->belongsTo(Violation::class);
    }
}
