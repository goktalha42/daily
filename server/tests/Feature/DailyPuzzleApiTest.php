<?php

namespace Tests\Feature;

use App\Models\DailyPuzzle;
use App\Services\DailyPuzzleGeneratorService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DailyPuzzleApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        putenv('ADMIN_API_SECRET=test-admin-secret');
        $_ENV['ADMIN_API_SECRET'] = 'test-admin-secret';
    }

    public function test_daily_puzzles_endpoint_auto_populates_and_returns_all_six_games(): void
    {
        $response = $this->getJson('/api/v1/puzzles/daily?date=2026-11-12');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('date_id', '2026-11-12')
            ->assertJsonStructure([
                'games' => [
                    'queens' => ['kolay', 'zor', 'master'],
                    'pinpoint' => ['targetWord', 'clues'],
                    'crossclimb' => ['startWord', 'endWord', 'steps'],
                    'tango' => ['gridSize', 'initialGrid', 'constraints'],
                    'zip_path' => ['gridSize', 'numberPoints', 'edgeWalls'],
                    'patches' => ['gridSize', 'clues'],
                ],
            ]);
    }

    public function test_admin_endpoints_require_secret_and_allow_customizing_special_days(): void
    {
        $this->getJson('/api/v1/admin/day/2026-12-31')->assertStatus(401);

        $headers = ['X-Admin-Secret' => 'test-admin-secret'];

        // Özel Pinpoint kaydetme
        $this->putJson('/api/v1/admin/day/2026-12-31/pinpoint', [
            'difficulty' => 'default',
            'is_special' => true,
            'special_note' => 'Yılbaşı Özel',
            'payload' => [
                'categoryHint' => 'Kutlama',
                'targetWord' => 'YILBAŞI',
                'clues' => ['31 Aralık', 'Geri Sayım', 'Takvim', 'Yeni Yıl', 'Havai Fişek'],
                'alternativeAnswers' => [],
            ],
        ], $headers)->assertStatus(200)
            ->assertJsonPath('source', 'admin');

        // Geçersiz Crossclimb (2 harf farklı) reddedilmeli
        $this->putJson('/api/v1/admin/day/2026-12-31/crossclimb', [
            'difficulty' => 'default',
            'payload' => [
                'startWord' => 'KARA',
                'endWord' => 'ELMA',
                'steps' => [
                    ['targetWord' => 'KIRA', 'clue' => 'test', 'index' => 0, 'changedIndex' => 1],
                    ['targetWord' => 'ELMA', 'clue' => 'test2', 'index' => 1, 'changedIndex' => 0],
                ],
            ],
        ], $headers)->assertStatus(422);

        // Toplu auto yenileme admin özelleştirmesini ezmemeli
        app(DailyPuzzleGeneratorService::class)->generateRange('2026-12-30', 3, true);

        $daily = $this->getJson('/api/v1/puzzles/daily?date=2026-12-31');
        $daily->assertStatus(200)
            ->assertJsonPath('is_special', true)
            ->assertJsonPath('special_note', 'Yılbaşı Özel')
            ->assertJsonPath('games.pinpoint.targetWord', 'YILBAŞI');

        $row = DailyPuzzle::where('date_id', '2026-12-31')->where('game_type', 'pinpoint')->first();
        $this->assertEquals('admin', $row->source);
    }
}

