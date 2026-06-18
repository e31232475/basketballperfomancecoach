<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PerformanceLog extends Model
{
    protected $table = 'performance_logs';

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'workout_id',
        'exercise_id',
        'set_number',
        'success',
        'created_at',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'workout_id' => 'integer',
        'exercise_id' => 'integer',
        'set_number' => 'integer',
        'success' => 'boolean',
        'created_at' => 'datetime',
    ];
}
