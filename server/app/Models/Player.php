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
        'progress_payload' => 'array',
        'progress_synced_at' => 'datetime',
    ];

    /**
     * Benzersiz ve okunaklı 8 haneli kurtarma kodu üretir (Örn: ZHT-4829-K7M2).
     */
    public static function generateUniqueRecoveryCode(): string
    {
        $chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
        $max = strlen($chars) - 1;
        do {
            $part1 = '';
            $part2 = '';
            for ($i = 0; $i < 4; $i++) {
                $part1 .= $chars[random_int(0, $max)];
                $part2 .= $chars[random_int(0, $max)];
            }
            $code = "ZHT-{$part1}-{$part2}";
        } while (self::where('recovery_code', $code)->exists());

        return $code;
    }

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
            if (!$player->is_bot && empty($player->recovery_code)) {
                $player->recovery_code = self::generateUniqueRecoveryCode();
            }
        });
    }

    public function scores(): HasMany
    {
        return $this->hasMany(GameScore::class);
    }
}
