<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Player;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    /**
     * Cihaz UUID'si ile hızlı anonim misafir oturumu açar veya mevcut oyuncuyu getirir.
     */
    public function guest(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_id' => 'required|string|min:4|max:128',
            'nickname' => 'nullable|string|max:50',
            'avatar_id' => 'nullable|string|max:50',
        ]);

        $deviceId = $validated['device_id'];
        $nickname = $validated['nickname'] ?? null;
        $avatarId = $validated['avatar_id'] ?? null;

        $player = Player::where('device_id', $deviceId)->first();

        if (!$player) {
            $defaultName = $nickname ?: 'Oyuncu #' . rand(1000, 9999);
            $player = Player::create([
                'device_id' => $deviceId,
                'nickname' => $defaultName,
                'avatar_id' => $avatarId ?? 'avatar_default',
                'is_bot' => false,
                'league_tier' => 'stone',
                'last_active_at' => now(),
            ]);
        } else {
            $updates = ['last_active_at' => now()];
            if ($nickname && $player->nickname !== $nickname) {
                $updates['nickname'] = $nickname;
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
            'nickname' => 'nullable|string|min:2|max:30',
            'avatar_id' => 'nullable|string|max:50',
        ]);

        $player->update(array_filter($validated));

        return response()->json([
            'status' => 'success',
            'message' => 'Profil güncellendi',
            'player' => [
                'id' => $player->id,
                'device_id' => $player->device_id,
                'nickname' => $player->nickname,
                'avatar_id' => $player->avatar_id,
                'league_tier' => $player->league_tier,
            ],
        ]);
    }
}
