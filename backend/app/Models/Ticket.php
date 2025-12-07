<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Ticket extends Model
{
    protected $fillable = [
        'violator_id',
        'enforcer_id',
        'violation_id',
        'fine_amount',
        'additional_fees',
        'total_amount',
        'place_of_apprehension',
        'apprehended_at',
        'control_no',
        'status',
    ];

    protected $casts = [
        'apprehended_at'   => 'datetime',
        'fine_amount'      => 'decimal:2',
        'additional_fees'  => 'decimal:2',
        'total_amount'     => 'decimal:2',
    ];

    // 👇 this tells Laravel to include `enforcer_name` in JSON
    protected $appends = ['enforcer_name'];

    /**
     * Auto-generate control_no if not provided.
     */
    protected static function booted()
    {
        static::creating(function (Ticket $ticket) {
            if (empty($ticket->control_no)) {
                $ticket->control_no = static::nextControlNo();
            }
        });
    }

    /**
     * Pattern: YYYYMMDD-#### e.g. 20251130-0001
     */
    public static function nextControlNo(): string
    {
        $today  = now()->format('Ymd');
        $prefix = $today . '-';

        $last = static::where('control_no', 'like', $prefix . '%')
            ->orderByDesc('control_no')
            ->first();

        $nextSeq = 1;

        if ($last) {
            $lastSeq = (int) Str::afterLast($last->control_no, '-');
            $nextSeq = $lastSeq + 1;
        }

        return sprintf('%s%04d', $prefix, $nextSeq);
    }

    public function violator(): BelongsTo
    {
        return $this->belongsTo(Violator::class);
    }

    public function enforcer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'enforcer_id');
    }

    public function violation(): BelongsTo
    {
        return $this->belongsTo(Violation::class);
    }

    public function violations()
    {
        // in case you later use multiple violations
        return $this->belongsToMany(Violation::class, 'ticket_violation')
            ->withPivot('fine_amount', 'remarks')
            ->withTimestamps();
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    // 👇 THIS is what Flutter will read as `enforcer_name`
    public function getEnforcerNameAttribute()
    {
        // users table uses `full_name`, not `name`
        return $this->enforcer ? $this->enforcer->full_name : null;
    }
}
