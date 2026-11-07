<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameScore;
use App\Models\Player;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GameController extends Controller
{
    /**
     * Güvenilir UTC sunucu saatini döner (TimeSyncService için).
     */
    public function time(): JsonResponse
    {
        $nowUtc = Carbon::now('UTC');
        $tomorrowMidnight = $nowUtc->copy()->addDay()->startOfDay();
        $secondsUntilReset = $nowUtc->diffInSeconds($tomorrowMidnight);

        return response()->json([
            'status' => 'success',
            'server_time_utc' => $nowUtc->toIso8601String(),
            'timestamp' => $nowUtc->timestamp,
            'date_id' => $nowUtc->format('Y-m-d'),
            'seconds_until_midnight' => $secondsUntilReset,
        ]);
    }

    /**
     * Tamamlanan oyunun skorunu kaydeder veya en iyi skoru günceller.
     */
    public function submit(Request $request): JsonResponse
    {
        if ($request->input('game_type') === 'zipPath') {
            $request->merge(['game_type' => 'zip_path']);
        }

        $validated = $request->validate([
            'game_type' => 'required|string|in:queens,pinpoint,crossclimb,tango,zip_path,zipPath,patches',
            'date_id' => 'required|string|regex:/^\d{4}-\d{2}-\d{2}$/',
            'difficulty' => 'nullable|string|max:32',
            'score' => 'required|integer|min:0|max:3000',
            'duration_ms' => 'required|integer|min:500',
            'move_count' => 'nullable|integer|min:0',
            'device_id' => 'nullable|string',
        ]);

        // Oyuncuyu Bearer Token, X-Device-Id veya parametreden esnekçe belirle
        $player = null;
        $bearer = $request->bearerToken();
        if ($bearer) {
            $tokenModel = \Laravel\Sanctum\PersonalAccessToken::findToken($bearer);
            if ($tokenModel && $tokenModel->tokenable instanceof Player) {
                $player = $tokenModel->tokenable;
            }
        }

        if (!$player) {
            $deviceId = $request->header('X-Device-Id') ?: ($validated['device_id'] ?? null);
            if ($deviceId) {
                $player = Player::firstOrCreate(
                    ['device_id' => $deviceId],
                    ['nickname' => 'Oyuncu #' . rand(1000, 9999), 'league_tier' => 'stone']
                );
            }
        }

        if (!$player) {
            return response()->json([
                'status' => 'error',
                'message' => 'Geçerli bir oyuncu kimliği (Token veya Device-ID) bulunamadı.'
            ], 401);
        }

        $difficulty = $validated['difficulty'] ?: 'default';
        $gameType = $validated['game_type'];
        $dateId = $validated['date_id'];
        $durationMs = $validated['duration_ms'];
        $moveCount = $validated['move_count'] ?? 0;

        // Geçmiş oyun kuralı: Oyunlar sadece ait oldukları günde puan kazandırır
        $todayUtc = Carbon::now('UTC')->format('Y-m-d');
        $isPastDate = ($dateId !== $todayUtc);
        $score = $isPastDate ? 0 : $validated['score'];

        $existing = GameScore::where('player_id', $player->id)
            ->where('game_type', $gameType)
            ->where('date_id', $dateId)
            ->where('difficulty', $difficulty)
            ->first();

        $isNewBest = false;

        if ($existing) {
            if ($score > $existing->score || ($score == $existing->score && $durationMs < $existing->duration_ms)) {
                $existing->update([
                    'score' => $score,
                    'duration_ms' => $durationMs,
                    'move_count' => $moveCount,
                    'completed_at' => now(),
                ]);
                $isNewBest = true;
                $activeScore = $existing;
            } else {
                $activeScore = $existing;
            }
        } else {
            $activeScore = GameScore::create([
                'player_id' => $player->id,
                'game_type' => $gameType,
                'date_id' => $dateId,
                'difficulty' => $difficulty,
                'score' => $score,
                'duration_ms' => $durationMs,
                'move_count' => $moveCount,
                'completed_at' => now(),
            ]);
            $isNewBest = true;
        }

        // Oyuncunun son görülme zamanını güncelle
        $player->update(['last_active_at' => now()]);

        return response()->json([
            'status' => 'success',
            'message' => $isNewBest ? 'Yeni en iyi skor kaydedildi!' : 'Mevcut skor korundu.',
            'is_new_best' => $isNewBest,
            'result' => [
                'id' => $activeScore->id,
                'player_id' => $player->id,
                'player_name' => $player->nickname,
                'game_type' => $activeScore->game_type,
                'date_id' => $activeScore->date_id,
                'difficulty' => $activeScore->difficulty,
                'score' => $activeScore->score,
                'duration_ms' => $activeScore->duration_ms,
                'move_count' => $activeScore->move_count,
                'completed_at' => $activeScore->completed_at?->toIso8601String(),
            ],
        ]);
    }
}
