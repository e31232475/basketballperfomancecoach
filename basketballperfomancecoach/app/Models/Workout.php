<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Workout extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'title',
        'name',
        'level',
        'day_number',
    ];

    public function exercises()
    {
        return $this->belongsToMany(Exercise::class, 'workout_exercises')
            ->withPivot(['sets', 'reps', 'duration', 'rest_seconds']);
    }
}
