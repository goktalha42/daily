<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameScore;
use App\Models\Player;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LeaderboardController extends Controller
{
    /**
     * Liderlik tablosunu filtreye ve zaman dilimine göre döner.
     */
    public function index(Request $request): JsonResponse
    {
        if ($request->input('game_type') === 'zipPath') {
            $request->merge(['game_type' => 'zip_path']);
        }

        $validated = $request->validate([
            'game_type' => 'required|string|in:queens,pinpoint,crossclimb,tango,zip_path,zipPath,patches',
            'timeframe' => 'nullable|string|in:daily,weekly,monthly,all_time',
            'difficulty' => 'nullable|string|max:32',
            'date_id' => 'nullable|string|regex:/^\d{4}-\d{2}-\d{2}$/',
            'limit' => 'nullable|integer|min:10|max:200',
        ]);

        $gameType = $validated['game_type'];
        $timeframe = $validated['timeframe'] ?? 'daily';
        $difficulty = $validated['difficulty'] ?? null;
        $dateId = ($validated['date_id'] ?? null) ?: Carbon::now('UTC')->format('Y-m-d');
        $limit = $validated['limit'] ?? 150;

        $targetDate = Carbon::parse($dateId, 'UTC');

        // Zaman aralıklarını belirle
        $query = GameScore::query()
            ->join('players', 'game_scores.player_id', '=', 'players.id')
            ->where('game_scores.game_type', $gameType);

        if ($timeframe === 'daily') {
            $query->where('game_scores.date_id', $dateId);

            if ($difficulty) {
                $query->where('game_scores.difficulty', $difficulty);
            }
        } elseif ($timeframe === 'weekly') {
            // Takvim haftası: Pazartesi 00:00:00'dan günün sonuna kadar
            $weekStart = $targetDate->copy()->startOfWeek(Carbon::MONDAY)->startOfDay();
            $endOfDay = $targetDate->copy()->endOfDay();
            $query->whereBetween('game_scores.completed_at', [$weekStart, $endOfDay]);
        } elseif ($timeframe === 'monthly') {
            // Takvim ayı: Ayın 1'i 00:00:00'dan günün sonuna kadar
            $monthStart = $targetDate->copy()->startOfMonth()->startOfDay();
            $endOfDay = $targetDate->copy()->endOfDay();
            $query->whereBetween('game_scores.completed_at', [$monthStart, $endOfDay]);
        } else {
            // all_time
            $endOfDay = $targetDate->copy()->endOfDay();
            $query->where('game_scores.completed_at', '<=', $endOfDay);
        }

        // 1. Kural: Vezirler Günlük Toplam Puan (Kolay + Zor + Master toplamı)
        if ($gameType === 'queens' && empty($difficulty) && $timeframe === 'daily') {
            $results = $query->select(
                'players.id as player_id',
                'players.nickname as player_name',
                'players.avatar_id',
                'players.is_bot',
                'players.device_id',
                DB::raw('SUM(game_scores.score) as total_score'),
                DB::raw('SUM(game_scores.duration_ms) as total_duration_ms'),
                DB::raw('COUNT(DISTINCT game_scores.difficulty) as games_played')
            )
            ->groupBy('players.id', 'players.nickname', 'players.avatar_id', 'players.is_bot', 'players.device_id')
            ->orderByDesc('total_score')
            ->orderBy('total_duration_ms')
            ->limit($limit)
            ->get();
        } elseif ($timeframe === 'daily') {
            // Günlük tekil oyun veya belirli bir vezir zorluğu
            $results = $query->select(
                'players.id as player_id',
                'players.nickname as player_name',
                'players.avatar_id',
                'players.is_bot',
                'players.device_id',
                'game_scores.score as total_score',
                'game_scores.duration_ms as total_duration_ms',
                DB::raw('1 as games_played')
            )
            ->orderByDesc('game_scores.score')
            ->orderBy('game_scores.duration_ms')
            ->limit($limit)
            ->get();
        } else {
            // Haftalık, Aylık, Genel toplamlar
            $results = $query->select(
                'players.id as player_id',
                'players.nickname as player_name',
                'players.avatar_id',
                'players.is_bot',
                'players.device_id',
                DB::raw('SUM(game_scores.score) as total_score'),
                DB::raw('SUM(game_scores.duration_ms) as total_duration_ms'),
                DB::raw('COUNT(game_scores.id) as games_played')
            )
            ->groupBy('players.id', 'players.nickname', 'players.avatar_id', 'players.is_bot', 'players.device_id')
            ->orderByDesc('total_score')
            ->orderBy('total_duration_ms')
            ->limit($limit)
            ->get();
        }

        // Sıralama (rank) ataması
        $leaderboard = [];
        $rank = 1;
        $requestDeviceId = $request->header('X-Device-Id') ?: $request->query('device_id');
        $myRank = null;
        $myEntry = null;

        foreach ($results as $item) {
            $entry = [
                'rank' => $rank,
                'player_id' => $item->player_id,
                'player_name' => $item->player_name,
                'avatar_id' => $item->avatar_id,
                'is_bot' => (bool)$item->is_bot,
                'total_score' => (int)$item->total_score,
                'best_time_ms' => (int)$item->total_duration_ms,
                'games_played' => (int)$item->games_played,
            ];

            if ($requestDeviceId && $item->device_id === $requestDeviceId) {
                $myRank = $rank;
                $myEntry = $entry;
            }

            $leaderboard[] = $entry;
            $rank++;
        }

        return response()->json([
            'status' => 'success',
            'game_type' => $gameType,
            'timeframe' => $timeframe,
            'date_id' => $dateId,
            'difficulty' => $difficulty,
            'total_entries' => count($leaderboard),
            'my_rank' => $myRank,
            'my_entry' => $myEntry,
            'leaderboard' => $leaderboard,
        ]);
    }
}
