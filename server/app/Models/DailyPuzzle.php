<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DailyPuzzle extends Model
{
    protected $fillable = [
        'date_id',
        'game_type',
        'difficulty',
        'payload',
        'is_special',
        'special_note',
        'source',
    ];

    protected $casts = [
        'payload' => 'array',
        'is_special' => 'boolean',
    ];
}

