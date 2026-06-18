<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CoachReview extends Model
{
    protected $table = 'coach_reviews';

    protected $fillable = [
        'workout_recording_id',
        'user_id',
        'workout_id',
        'day_number',
        'coach_id',
        'status',
        'score',
        'feedback',
        'reviewed_at',
    ];

    protected $casts = [
        'workout_recording_id' => 'integer',
        'user_id' => 'integer',
        'workout_id' => 'integer',
        'day_number' => 'integer',
        'coach_id' => 'integer',
        'score' => 'integer',
        'reviewed_at' => 'datetime',
    ];
}
