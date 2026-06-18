<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Exercise extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'name',
        'type',
        'video',
        'video_url',
    ];

    public function workouts()
    {
        return $this->belongsToMany(Workout::class, 'workout_exercises')
            ->withPivot(['sets', 'reps', 'duration', 'rest_seconds']);
    }
}
