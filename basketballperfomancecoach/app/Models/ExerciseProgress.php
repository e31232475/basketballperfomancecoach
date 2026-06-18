<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExerciseProgress extends Model
{
    protected $table = 'exercise_progress';

    protected $fillable = [
        'user_id',
        'workout_id',
        'exercise_id',
        'status',
        'set_number',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'workout_id' => 'integer',
        'exercise_id' => 'integer',
        'set_number' => 'integer',
    ];
}
