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

    /**
     * İsimleri büyük/küçük harf ve Türkçe karakter duyarsız tekilleştirir.
     * Örn: "TALHA", "Talha", "talha", "TaLhA" -> hepsi "talha" olur.
     */
    public static function normalizeNickname(?string $name): string
    {
        if (!$name) return '';
        $s = trim($name);
        $s = str_replace(['İ', 'I'], ['i', 'ı'], $s);
        $s = mb_strtolower($s, 'UTF-8');
        $s = str_replace(["i\u{0307}", "\u{0307}"], 'i', $s);
        return $s;
    }

    protected static function booted(): void
    {
        static::saving(function (Player $player) {
            if ($player->nickname && ($player->isDirty('nickname') || !$player->normalized_nickname)) {
                $player->normalized_nickname = self::normalizeNickname($player->nickname);
            }
        });
    }

    public function scores(): HasMany
    {
        return $this->hasMany(GameScore::class);
    }
}
