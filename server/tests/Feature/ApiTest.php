<?php

namespace Tests\Feature;

use App\Models\Player;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiTest extends TestCase
{
    use RefreshDatabase;
    public function test_time_endpoint_returns_server_utc(): void
    {
        $response = $this->getJson('/api/v1/time');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'server_time_utc',
                'timestamp',
                'date_id',
                'seconds_until_midnight',
            ]);
    }

    public function test_guest_auth_registers_and_returns_token(): void
    {
        $response = $this->postJson('/api/v1/auth/guest', [
            'device_id' => 'test-device-uuid-12345',
            'nickname' => 'Talha',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'player' => [
                    'device_id' => 'test-device-uuid-12345',
                    'nickname' => 'Talha',
                ],
            ]);

        $this->assertDatabaseHas('players', [
            'device_id' => 'test-device-uuid-12345',
            'nickname' => 'Talha',
        ]);
    }

    public function test_submitting_game_score_records_and_updates(): void
    {
        $auth = $this->postJson('/api/v1/auth/guest', [
            'device_id' => 'phone-device-alpha',
            'nickname' => 'TelefonA',
        ]);
        $token = $auth->json('token');

        // İlk skor: 800
        $res1 = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/v1/games/submit', [
                'game_type' => 'queens',
                'date_id' => '2026-11-02',
                'difficulty' => 'kolay',
                'score' => 800,
                'duration_ms' => 25000,
                'move_count' => 18,
            ]);

        $res1->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'is_new_best' => true,
            ]);

        // İkinci daha iyi skor: 850
        $res2 = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/v1/games/submit', [
                'game_type' => 'queens',
                'date_id' => '2026-11-02',
                'difficulty' => 'kolay',
                'score' => 850,
                'duration_ms' => 20000,
                'move_count' => 18,
            ]);

        $res2->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'is_new_best' => true,
            ]);

        // Leaderboard kontrolü
        $lead = $this->withHeader('X-Device-Id', 'phone-device-alpha')
            ->getJson('/api/v1/leaderboard?game_type=queens&difficulty=kolay&date_id=2026-11-02');

        $lead->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'game_type',
                'leaderboard',
            ]);
    }

    public function test_nickname_uniqueness_and_case_insensitivity(): void
    {
        // 1. Cihaz A "Talha" ismini kaydeder
        $resA = $this->postJson('/api/v1/auth/set-nickname', [
            'device_id' => 'device-user-a',
            'nickname' => 'Talha',
        ]);
        $resA->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'player' => [
                    'nickname' => 'Talha',
                ],
            ]);

        // 2. Cihaz B aynı ismi küçük harfle ("talha") almaya çalışır -> 422 dönmeli
        $resB = $this->postJson('/api/v1/auth/set-nickname', [
            'device_id' => 'device-user-b',
            'nickname' => 'talha',
        ]);
        $resB->assertStatus(422);

        // 3. Cihaz C aynı ismi büyük harfle ("TALHA") almaya çalışır -> 422 dönmeli
        $resC = $this->postJson('/api/v1/auth/set-nickname', [
            'device_id' => 'device-user-c',
            'nickname' => 'TALHA',
        ]);
        $resC->assertStatus(422);

        // 4. check-nickname sorgusu "talha" için available: false dönmeli
        $checkTaken = $this->getJson('/api/v1/auth/check-nickname?nickname=TaLhA');
        $checkTaken->assertStatus(200)
            ->assertJson([
                'status' => 'taken',
                'available' => false,
            ]);

        // 5. Cihaz D farklı bir isim ("Ahmet") seçer -> başarılı olmalı
        $resD = $this->postJson('/api/v1/auth/set-nickname', [
            'device_id' => 'device-user-d',
            'nickname' => 'Ahmet',
        ]);
        $resD->assertStatus(200);

        // 6. check-nickname boşta olan bir isim için available: true dönmeli
        $checkFree = $this->getJson('/api/v1/auth/check-nickname?nickname=Mehmet_99');
        $checkFree->assertStatus(200)
            ->assertJson([
                'status' => 'available',
                'available' => true,
            ]);
    }
}
