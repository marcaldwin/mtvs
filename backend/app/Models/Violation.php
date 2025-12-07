<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Violation extends Model
{
    use HasFactory;

    protected $fillable = [
        'type',         // Type of Violation
        'name',         // Name of Violation
        'fine',         // Decimal
        'ordinance_no', // Nullable
    ];

    // If you use the pivot for multiple violations per ticket
    public function tickets()
    {
        return $this->belongsToMany(Ticket::class, 'ticket_violation')
            ->withPivot('fine_amount', 'remarks')
            ->withTimestamps();
    }
}
