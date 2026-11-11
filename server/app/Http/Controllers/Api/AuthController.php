<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\GameScore;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    /**
     * İsim kullanılabilirlik kontrolü (Büyük/küçük harf duyarsız).
     */
    public function checkNickname(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nickname' => ['required', 'string', 'min:3', 'max:20', 'regex:/^[\p{L}\p{N}_]{3,20}$/u'],
            'device_id' => 'nullable|string',
        ], [
            'nickname.regex' => 'İsim yalnızca harf, rakam ve alt çizgi içerebilir; boşluk veya özel karakter içeremez.',
            'nickname.min' => 'İsim en az 3 karakter olmalıdır.',
            'nickname.max' => 'İsim en fazla 20 karakter olabilir.',
        ]);

        $nickname = trim($validated['nickname']);
        $norm = Player::normalizeNickname($nickname);
        $deviceId = $validated['device_id'] ?? $request->header('X-Device-Id');

        $query = Player::where('normalized_nickname', $norm);
        if ($deviceId) {
            $query->where('device_id', '!=', $deviceId);
        }

        $exists = $query->exists();

        if ($exists) {
            return response()->json([
                'status' => 'taken',
                'available' => false,
                'message' => 'Bu isim ("' . $nickname . '") zaten alınmış. Lütfen başka bir isim seçin.',
            ]);
        }

        return response()->json([
            'status' => 'available',
            'available' => true,
            'message' => 'Bu isim kullanılabilir!',
        ]);
    }

    /**
     * Cihaz için zorunlu benzersiz takma ad belirler ve kaydeder.
     */
    public function setNickname(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_id' => 'required|string|min:4|max:128',
            'nickname' => ['required', 'string', 'min:3', 'max:20', 'regex:/^[\p{L}\p{N}_]{3,20}$/u'],
            'avatar_id' => 'nullable|string|max:50',
        ], [
            'nickname.regex' => 'İsim yalnızca harf, rakam ve alt çizgi içerebilir; boşluk veya özel karakter içeremez.',
            'nickname.min' => 'İsim en az 3 karakter olmalıdır.',
            'nickname.max' => 'İsim en fazla 20 karakter olabilir.',
        ]);

        $deviceId = $validated['device_id'];
        $nickname = trim($validated['nickname']);
        $norm = Player::normalizeNickname($nickname);
        $avatarId = $validated['avatar_id'] ?? null;

        // Başka bir oyuncuda bu normalize isim var mı kontrol et
        $isTaken = Player::where('normalized_nickname', $norm)
            ->where('device_id', '!=', $deviceId)
            ->exists();

        if ($isTaken) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu isim ("' . $nickname . '") zaten başka bir oyuncu tarafından kullanılıyor.',
                'errors' => [
                    'nickname' => ['Bu isim zaten alınmış. Büyük/küçük harf fark etmeksizin tüm isimler tekildir.'],
                ],
            ], 422);
        }

        $player = Player::where('device_id', $deviceId)->first();

        if (!$player) {
            $player = Player::create([
                'device_id' => $deviceId,
                'nickname' => $nickname,
                'normalized_nickname' => $norm,
                'avatar_id' => $avatarId ?? 'avatar_default',
                'is_bot' => false,
                'league_tier' => 'stone',
                'last_active_at' => now(),
            ]);
        } else {
            $player->update([
                'nickname' => $nickname,
                'normalized_nickname' => $norm,
                'avatar_id' => $avatarId ?? $player->avatar_id,
                'last_active_at' => now(),
            ]);
        }

        // Taze token üret
        $player->tokens()->delete();
        $token = $player->createToken('guest_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Kullanıcı adı başarıyla kaydedildi.',
            'token' => $token,
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
                'recovery_code' => $player->recovery_code,
                'created_at' => $player->created_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Cihaz UUID'si ile hızlı anonim misafir oturumu açar veya mevcut oyuncuyu getirir.
     */
    public function guest(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_id' => 'required|string|min:4|max:128',
            'nickname' => ['nullable', 'string', 'min:3', 'max:20', 'regex:/^[\p{L}\p{N}_]{3,20}$/u'],
            'avatar_id' => 'nullable|string|max:50',
        ]);

        $deviceId = $validated['device_id'];
        $nickname = isset($validated['nickname']) ? trim($validated['nickname']) : null;
        $avatarId = $validated['avatar_id'] ?? null;

        if ($nickname) {
            $norm = Player::normalizeNickname($nickname);
            $isTaken = Player::where('normalized_nickname', $norm)
                ->where('device_id', '!=', $deviceId)
                ->exists();

            if ($isTaken) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu isim ("' . $nickname . '") zaten başka bir oyuncu tarafından kullanılıyor.',
                    'errors' => [
                        'nickname' => ['Bu isim zaten alınmış.'],
                    ],
                ], 422);
            }
        }

        $player = Player::where('device_id', $deviceId)->first();

        if (!$player) {
            $defaultName = $nickname ?: 'Oyuncu #' . rand(1000, 9999);
            $player = Player::create([
                'device_id' => $deviceId,
                'nickname' => $defaultName,
                'normalized_nickname' => Player::normalizeNickname($defaultName),
                'avatar_id' => $avatarId ?? 'avatar_default',
                'is_bot' => false,
                'league_tier' => 'stone',
                'last_active_at' => now(),
            ]);
        } else {
            $updates = ['last_active_at' => now()];
            if ($nickname && $player->nickname !== $nickname) {
                $updates['nickname'] = $nickname;
                $updates['normalized_nickname'] = Player::normalizeNickname($nickname);
            }
            if ($avatarId && $player->avatar_id !== $avatarId) {
                $updates['avatar_id'] = $avatarId;
            }
            $player->update($updates);
        }

        // Mevcut eski tokenları temizleyip taze token üret
        $player->tokens()->delete();
        $token = $player->createToken('guest_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Oturum açıldı',
            'token' => $token,
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
                'league_group_id' => $player->league_group_id,
                'recovery_code' => $player->recovery_code,
                'created_at' => $player->created_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Profil bilgilerini günceller (kullanıcı adı vb.)
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $player = $request->user();
        if (!$player && $request->header('X-Device-Id')) {
            $player = Player::where('device_id', $request->header('X-Device-Id'))->first();
        }

        if (!$player) {
            return response()->json(['status' => 'error', 'message' => 'Yetkisiz erişim'], 401);
        }

        $validated = $request->validate([
            'nickname' => ['nullable', 'string', 'min:3', 'max:20', 'regex:/^[\p{L}\p{N}_]{3,20}$/u'],
            'avatar_id' => 'nullable|string|max:50',
        ], [
            'nickname.regex' => 'İsim yalnızca harf, rakam ve alt çizgi içerebilir; boşluk veya özel karakter içeremez.',
        ]);

        if (isset($validated['nickname'])) {
            $nickname = trim($validated['nickname']);
            $norm = Player::normalizeNickname($nickname);

            $isTaken = Player::where('normalized_nickname', $norm)
                ->where('id', '!=', $player->id)
                ->exists();

            if ($isTaken) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu isim ("' . $nickname . '") zaten başka bir oyuncu tarafından kullanılıyor.',
                    'errors' => [
                        'nickname' => ['Bu isim zaten alınmış.'],
                    ],
                ], 422);
            }

            $player->nickname = $nickname;
            $player->normalized_nickname = $norm;
        }

        if (isset($validated['avatar_id'])) {
            $player->avatar_id = $validated['avatar_id'];
        }

        $player->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Profil güncellendi',
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
                'recovery_code' => $player->recovery_code,
            ],
        ]);
    }

    /**
     * Oyuncunun tüm ilerlemesini (günlük seri, IQ istatistikleri, rozetler, lig durumu)
     * sunucuya yedekler ve oyuncuya özel ZHT-XXXX-XXXX kurtarma kodunu döner.
     */
    public function syncProgress(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_id' => 'required|string|min:4|max:128',
            'nickname' => 'nullable|string|max:32',
            'league_tier' => 'nullable|string|max:32',
            'progress_payload' => 'required|array',
        ]);

        $deviceId = $validated['device_id'];
        $player = Player::where('device_id', $deviceId)->first();

        if (!$player) {
            $nick = isset($validated['nickname']) && trim($validated['nickname']) !== ''
                ? trim($validated['nickname'])
                : 'Oyuncu #' . rand(1000, 9999);

            // Eğer aynı takma ad başka bir cihazda kayıtlıysa çakışmayı önle
            $norm = Player::normalizeNickname($nick);
            if (Player::where('normalized_nickname', $norm)->exists()) {
                $nick = $nick . '_' . rand(10, 99);
            }

            $player = Player::create([
                'device_id' => $deviceId,
                'nickname' => $nick,
                'normalized_nickname' => Player::normalizeNickname($nick),
                'avatar_id' => 'avatar_default',
                'is_bot' => false,
                'league_tier' => $validated['league_tier'] ?? 'stone',
                'progress_payload' => $validated['progress_payload'],
                'progress_synced_at' => now(),
                'last_active_at' => now(),
            ]);
        } else {
            if (empty($player->recovery_code)) {
                $player->recovery_code = Player::generateUniqueRecoveryCode();
            }
            if (!empty($validated['league_tier'])) {
                $player->league_tier = $validated['league_tier'];
            }
            $player->progress_payload = $validated['progress_payload'];
            $player->progress_synced_at = now();
            $player->last_active_at = now();
            $player->save();
        }

        return response()->json([
            'status' => 'success',
            'message' => 'İlerleme ve günlük seri başarıyla buluta yedeklendi.',
            'recovery_code' => $player->recovery_code,
            'synced_at' => $player->progress_synced_at?->toIso8601String(),
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'league_tier' => $player->league_tier,
                'recovery_code' => $player->recovery_code,
            ],
        ]);
    }

    /**
     * Kurtarma Kodu (ZHT-XXXX-XXXX) ile oyuncunun buluttaki serisini, IQ istatistiklerini,
     * rozetlerini ve kullanıcı adını yeni cihaza geri yükler.
     */
    public function restoreProgress(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'recovery_code' => 'required|string|min:6|max:32',
            'new_device_id' => 'nullable|string|min:4|max:128',
        ]);

        $normalizedCode = strtoupper(trim($validated['recovery_code']));
        $player = Player::where('recovery_code', $normalizedCode)->first();

        if (!$player) {
            return response()->json([
                'status' => 'error',
                'message' => 'Girdiğiniz kurtarma kodu (' . $normalizedCode . ') ile eşleşen bir yedek bulunamadı.',
            ], 404);
        }

        $newDeviceId = $validated['new_device_id'] ?? $request->header('X-Device-Id');

        if ($newDeviceId && $newDeviceId !== $player->device_id) {
            // Yeni cihazda daha önce oluşmuş geçici bir misafir kaydı varsa skorlarını birleştirip temizle
            $existingTemp = Player::where('device_id', $newDeviceId)
                ->where('id', '!=', $player->id)
                ->first();

            if ($existingTemp) {
                foreach ($existingTemp->scores as $tempScore) {
                    $alreadyHas = $player->scores()
                        ->where('game_type', $tempScore->game_type)
                        ->where('date_id', $tempScore->date_id)
                        ->where('difficulty', $tempScore->difficulty)
                        ->exists();
                    if (!$alreadyHas) {
                        $tempScore->update(['player_id' => $player->id]);
                    } else {
                        $tempScore->delete();
                    }
                }
                $existingTemp->tokens()->delete();
                $existingTemp->delete();
            }

            $player->device_id = $newDeviceId;
        }

        $player->last_active_at = now();
        $player->save();

        $player->tokens()->delete();
        $token = $player->createToken('guest_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Hesabınız ve tüm zeka seriniz başarıyla geri yüklendi!',
            'token' => $token,
            'recovery_code' => $player->recovery_code,
            'synced_at' => $player->progress_synced_at?->toIso8601String(),
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
                'recovery_code' => $player->recovery_code,
            ],
            'progress_payload' => $player->progress_payload ?? [],
        ]);
    }

    /**
     * Oyuncunun sunucu tarafındaki tüm geçmiş istatistiklerini, toplam kariyer puanını,
     * haftalık lig skorunu ve oyun bazlı dökümünü tek bir doğrulanmış kaynak olarak döner.
     */
    public function playerStats(Request $request): JsonResponse
    {
        $player = $request->user();
        $deviceId = $request->header('X-Device-Id') ?: $request->query('device_id');
        $nickname = $request->query('nickname');

        if (!$player && $deviceId) {
            $player = Player::where('device_id', $deviceId)->first();
        }

        if (!$player && $nickname) {
            $norm = Player::normalizeNickname($nickname);
            $player = Player::where('normalized_nickname', $norm)->first();
        }

        if (!$player) {
            return response()->json([
                'status' => 'error',
                'message' => 'Oyuncu bulunamadı.',
            ], 404);
        }

        $targetDate = Carbon::now('Europe/Istanbul');
        $todayIst = $targetDate->format('Y-m-d');
        $weekStart = $targetDate->copy()->startOfWeek(Carbon::MONDAY)->startOfDay();
        $monthStart = $targetDate->copy()->startOfMonth()->startOfDay();
        $endOfDay = $targetDate->copy()->endOfDay();

        // 1. Toplam Kariyer Puanı (Kümülatif tüm zamanlar)
        $totalCareerScore = (int) GameScore::where('player_id', $player->id)->sum('score');

        // 2. Çözülen Oyun Sayısı (Tüm tekil tamamlanan seviyeler)
        $totalGamesPlayed = (int) GameScore::where('player_id', $player->id)->count();

        // 3. Haftalık Toplam Puan (Lig puanı ile %100 birebir)
        $weeklyScore = (int) GameScore::where('player_id', $player->id)
            ->whereBetween('completed_at', [$weekStart, $endOfDay])
            ->sum('score');

        // 4. Aylık ve Günlük Toplam Puan
        $monthlyScore = (int) GameScore::where('player_id', $player->id)
            ->whereBetween('completed_at', [$monthStart, $endOfDay])
            ->sum('score');

        $todayScore = (int) GameScore::where('player_id', $player->id)
            ->where('date_id', $todayIst)
            ->sum('score');

        // 5. Ortalama Reaksiyon Süresi (Milisaniye)
        $avgDurationMs = (int) round(GameScore::where('player_id', $player->id)
            ->where('duration_ms', '>', 0)
            ->avg('duration_ms') ?? 0);

        // 6. 6 Temel Oyun Bazlı Detaylı İstatistikler
        $games = ['queens', 'crossclimb', 'pinpoint', 'tango', 'zip_path', 'patches'];
        $gameStats = [];

        foreach ($games as $g) {
            $scoresQuery = GameScore::where('player_id', $player->id)->where('game_type', $g);
            $allTimeScore = (int) $scoresQuery->sum('score');
            $bestScore = (int) ($scoresQuery->max('score') ?? 0);
            $bestTimeMs = (int) ($scoresQuery->where('score', '>', 0)->min('duration_ms') ?? 0);
            $played = (int) $scoresQuery->count();
            $weeklyGameScore = (int) GameScore::where('player_id', $player->id)
                ->where('game_type', $g)
                ->whereBetween('completed_at', [$weekStart, $endOfDay])
                ->sum('score');
            $todayGameScore = (int) GameScore::where('player_id', $player->id)
                ->where('game_type', $g)
                ->where('date_id', $todayIst)
                ->sum('score');

            $gameStats[$g] = [
                'all_time_score' => $allTimeScore,
                'best_score' => $bestScore,
                'best_time_ms' => $bestTimeMs,
                'games_played' => $played,
                'weekly_score' => $weeklyGameScore,
                'today_score' => $todayGameScore,
            ];
        }

        return response()->json([
            'status' => 'success',
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
                'total_career_score' => $totalCareerScore,
                'total_games_played' => $totalGamesPlayed,
                'weekly_score' => $weeklyScore,
                'monthly_score' => $monthlyScore,
                'today_score' => $todayScore,
                'avg_duration_ms' => $avgDurationMs,
                'games' => $gameStats,
            ],
        ]);
    }

    /**
     * Google Play Store Data Safety: Oyuncu hesabını ve tüm sunucu verilerini siler.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $player = $request->user();
        if (!$player && $request->header('X-Device-Id')) {
            $player = Player::where('device_id', $request->header('X-Device-Id'))->first();
        }
        if (!$player && $request->input('device_id')) {
            $player = Player::where('device_id', $request->input('device_id'))->first();
        }

        if ($player) {
            $player->scores()->delete();
            $player->tokens()->delete();
            $player->delete();
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Hesap ve ilişkili tüm oyun verileri başarıyla silindi.',
        ]);
    }
}
