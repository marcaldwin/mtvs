<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Violator extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'drivers_license',
        'plate_no',
        'kd_no',
    ];

    public function tickets()
    {
        return $this->hasMany(Ticket::class);
    }
}
