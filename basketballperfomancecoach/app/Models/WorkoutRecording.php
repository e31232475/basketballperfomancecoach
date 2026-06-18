<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutRecording extends Model
{
    protected $table = 'workout_recordings';

    protected $fillable = [
        'user_id',
        'workout_id',
        'day_number',
        'file_path',
        'file_url',
        'mime_type',
        'file_size',
        'duration_seconds',
        'recorded_at',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'workout_id' => 'integer',
        'day_number' => 'integer',
        'file_size' => 'integer',
        'duration_seconds' => 'integer',
        'recorded_at' => 'datetime',
    ];
}
