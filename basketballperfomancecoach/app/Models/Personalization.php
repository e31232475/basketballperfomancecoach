<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Personalization extends Model
{
    protected $table = 'personalizations';

    protected $fillable = [
        'user_id',
        'level',
        'current_day',
    ];

    public $timestamps = false;
}
