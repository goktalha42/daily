<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LeaderboardController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // 1. Cihaz / Misafir Girişi ve Profil
    Route::post('/auth/guest', [AuthController::class, 'guest']);
    Route::post('/auth/profile', [AuthController::class, 'updateProfile']);

    // 2. Zaman Senkronizasyonu (Hile ve saat manipülasyonu engelleme)
    Route::get('/time', [GameController::class, 'time']);

    // 3. Skor Gönderme
    Route::post('/games/submit', [GameController::class, 'submit']);

    // 4. Liderlik Tablosu (Günlük, Haftalık, Aylık, Genel)
    Route::get('/leaderboard', [LeaderboardController::class, 'index']);
});
