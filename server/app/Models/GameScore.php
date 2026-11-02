<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GameScore extends Model
{
    protected $guarded = [];

    protected $casts = [
        'score' => 'integer',
        'duration_ms' => 'integer',
        'move_count' => 'integer',
        'completed_at' => 'datetime',
    ];

    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }
}
