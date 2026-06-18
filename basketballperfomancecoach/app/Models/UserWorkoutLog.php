<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserWorkoutLog extends Model
{
    protected $table = 'user_workout_logs';

    protected $fillable = [
        'user_id',
        'day_number',
        'status',
        'completed_at',
    ];

    public $timestamps = false;

    protected $casts = [
        'user_id' => 'integer',
        'day_number' => 'integer',
        'completed_at' => 'datetime',
    ];
}
