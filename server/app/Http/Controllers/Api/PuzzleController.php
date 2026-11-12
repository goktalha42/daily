<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyPuzzle;
use App\Services\DailyPuzzleGeneratorService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PuzzleController extends Controller
{
    public function daily(Request $request, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        $dateId = $request->query('date') ?: Carbon::now('Europe/Istanbul')->format('Y-m-d');
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Geçersiz tarih formatı (YYYY-MM-DD bekleniyor).',
            ], 422);
        }

        $generator->ensureDay($dateId, false);
        $rows = DailyPuzzle::where('date_id', $dateId)->get();

        $isSpecial = false;
        $specialNote = null;
        $games = [
            'queens' => [],
        ];

        foreach ($rows as $row) {
            if ($row->is_special) {
                $isSpecial = true;
            }
            if ($row->special_note) {
                $specialNote = $row->special_note;
            }
            if ($row->game_type === 'queens') {
                $games['queens'][$row->difficulty] = $row->payload;
            } else {
                $games[$row->game_type] = $row->payload;
            }
        }

        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'is_special' => $isSpecial,
            'special_note' => $specialNote,
            'games' => $games,
        ]);
    }

    public function showGame(Request $request, string $gameType, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($gameType === 'zipPath') {
            $gameType = 'zip_path';
        }
        $allowed = ['queens', 'pinpoint', 'crossclimb', 'tango', 'zip_path', 'patches'];
        if (!in_array($gameType, $allowed, true)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bilinmeyen oyun türü.',
            ], 404);
        }

        $dateId = $request->query('date') ?: Carbon::now('Europe/Istanbul')->format('Y-m-d');
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Geçersiz tarih formatı (YYYY-MM-DD bekleniyor).',
            ], 422);
        }

        $difficulty = $request->query('difficulty') ?: ($gameType === 'queens' ? 'kolay' : 'default');
        $generator->ensureDay($dateId, false);

        $row = DailyPuzzle::where('date_id', $dateId)
            ->where('game_type', $gameType)
            ->where('difficulty', $difficulty)
            ->first();

        if (!$row) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu tarih ve zorluk için bulmaca bulunamadı.',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'game_type' => $gameType,
            'difficulty' => $difficulty,
            'is_special' => $row->is_special,
            'special_note' => $row->special_note,
            'source' => $row->source,
            'puzzle' => $row->payload,
        ]);
    }
}

