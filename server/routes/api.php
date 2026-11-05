<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LeaderboardController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // 1. Cihaz / Misafir Girişi, Zorunlu Benzersiz İsim ve Profil
    Route::get('/auth/check-nickname', [AuthController::class, 'checkNickname']);
    Route::post('/auth/set-nickname', [AuthController::class, 'setNickname']);
    Route::post('/auth/guest', [AuthController::class, 'guest']);
    Route::post('/auth/profile', [AuthController::class, 'updateProfile']);

    // 2. Zaman Senkronizasyonu (Hile ve saat manipülasyonu engelleme)
    Route::get('/time', [GameController::class, 'time']);

    // 3. Skor Gönderme
    Route::post('/games/submit', [GameController::class, 'submit']);

    // 4. Liderlik Tablosu (Günlük, Haftalık, Aylık, Genel)
    Route::get('/leaderboard', [LeaderboardController::class, 'index']);

    // 5. Haftalık Genel Lig Sıralaması (Tüm oyunların bu haftaki puanları)
    Route::get('/league', [LeaderboardController::class, 'league']);

    // 6. Uygulama Otomatik Güncelleme Bilgisi
    Route::get('/app-version', function () {
        $versionFile = base_path('../version.json');
        if (file_exists($versionFile)) {
            return response()->file($versionFile, ['Content-Type' => 'application/json']);
        }
        return response()->json([
            'version' => '1.0.3',
            'build_number' => 4,
            'title' => 'Zühtü v1.0.3 Güncellemesi 🚀',
            'changelog' => "• Otomatik güncelleme sistemi eklendi.\n• Lig ve liderlik tablosu botlardan temizlendi.\n• Profil sayfası el çizimi tasarımına kavuştu.",
            'apk_url' => 'https://github.com/goktalha42/daily/releases/download/v1.0.3/Zuhtu_v1.0.3.apk',
            'release_url' => 'https://github.com/goktalha42/daily/releases/tag/v1.0.3',
            'force_update' => false,
        ]);
    });
});
