<?php

use App\Http\Controllers\Api\AdminPuzzleController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\PuzzleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // 1. Cihaz / Misafir Girişi, Zorunlu Benzersiz İsim, Bulut Yedekleme ve Profil
    Route::get('/auth/check-nickname', [AuthController::class, 'checkNickname']);
    Route::post('/auth/set-nickname', [AuthController::class, 'setNickname']);
    Route::post('/auth/guest', [AuthController::class, 'guest']);
    Route::post('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::get('/player/stats', [AuthController::class, 'playerStats']);
    Route::post('/auth/sync-progress', [AuthController::class, 'syncProgress']);
    Route::post('/auth/restore-progress', [AuthController::class, 'restoreProgress']);
    Route::post('/auth/delete-account', [AuthController::class, 'deleteAccount']);

    // 2. Zaman Senkronizasyonu (Hile ve saat manipülasyonu engelleme)
    Route::get('/time', [GameController::class, 'time']);

    // 3. Skor Gönderme
    Route::post('/games/submit', [GameController::class, 'submit']);

    // 4. Liderlik Tablosu (Günlük, Haftalık, Aylık, Genel)
    Route::get('/leaderboard', [LeaderboardController::class, 'index']);

    // 5. Haftalık Genel Lig Sıralaması (Tüm oyunların bu haftaki puanları)
    Route::get('/league', [LeaderboardController::class, 'league']);

    // 6. 365 Günlük Bulmaca Takvimi & İstemci Yayını
    Route::get('/puzzles/daily', [PuzzleController::class, 'daily']);
    Route::get('/puzzles/{gameType}', [PuzzleController::class, 'showGame']);

    // 7. Admin 365 Günlük Takvim Yönetimi (X-Admin-Secret korumalı)
    Route::prefix('admin')->group(function () {
        Route::get('/calendar', [AdminPuzzleController::class, 'calendar']);
        Route::post('/generate-year', [AdminPuzzleController::class, 'generateYear']);
        Route::get('/day/{dateId}', [AdminPuzzleController::class, 'showDay']);
        Route::put('/day/{dateId}/meta', [AdminPuzzleController::class, 'updateDayMeta']);
        Route::put('/day/{dateId}/{gameType}', [AdminPuzzleController::class, 'updateGame']);
        Route::post('/day/{dateId}/regenerate', [AdminPuzzleController::class, 'regenerate']);
    });

    // 8. Uygulama Otomatik Güncelleme Bilgisi
    Route::get('/app-version', function () {
        $versionFile = base_path('../version.json');
        if (file_exists($versionFile)) {
            return response()->file($versionFile, ['Content-Type' => 'application/json']);
        }
        return response()->json([
            'version' => '1.0.4',
            'build_number' => 5,
            'title' => 'Zühtü v1.0.4 Güncellemesi 🧠✨',
            'changelog' => "• Gerçekçi WAIS-IV psikometrik IQ sistemi ve katı Einstein (148+ IQ) kriterleri eklendi.\n• Ana sayfa Beyin Gücü kartı %100 dinamik, koreografili ve el çizimi tasarıma kavuştu.\n• 6 Bilişsel Alan Karnesi ve Son 7 Gün Seri Takvimi eklendi.",
            'apk_url' => 'https://github.com/goktalha42/daily/releases/download/v1.0.4/Zuhtu_v1.0.4.apk',
            'release_url' => 'https://github.com/goktalha42/daily/releases/tag/v1.0.4',
            'force_update' => false,
        ]);
    });
});
