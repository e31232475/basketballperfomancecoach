<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'role',
        'password',
        'firebase_uid',
        'height',
        'weight',
        'age',
        'gender',
        'profile_photo_url',
        'training_level',
        'intermediate_approved_at',
        'intermediate_approved_by',
        'personalization_completed',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'height' => 'float',
            'weight' => 'float',
            'age' => 'integer',
            'intermediate_approved_at' => 'datetime',
            'intermediate_approved_by' => 'integer',
            'personalization_completed' => 'boolean',
        ];
    }
}
