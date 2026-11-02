<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Sanctum\HasApiTokens;

class Player extends Model
{
    use HasApiTokens;

    protected $guarded = [];

    protected $casts = [
        'is_bot' => 'boolean',
        'last_active_at' => 'datetime',
    ];

    public function scores(): HasMany
    {
        return $this->hasMany(GameScore::class);
    }
}
