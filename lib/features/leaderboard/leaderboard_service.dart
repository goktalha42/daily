import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../games/common/base_game.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

class LeaderboardService {
  final List<GameResult> _resultsStore = [];

  LeaderboardService() {
    _seedMockData();
  }

  void _seedMockData() {
    final now = DateTime.now();

    final mockUsers = [
      {'name': 'ZekaŞampiyonu', 'score': 1950, 'time': 45000},
      {'name': 'BulmacaUstadı', 'score': 1880, 'time': 52000},
      {'name': 'HızlıDüşünür', 'score': 1820, 'time': 58000},
      {'name': 'KraliçeAvcısı', 'score': 1750, 'time': 64000},
      {'name': 'MantıkUzmanı', 'score': 1690, 'time': 71000},
    ];

    for (var game in GameType.values) {
      for (var u in mockUsers) {
        _resultsStore.add(
          GameResult(
            id: '${game.id}_${u['name']}',
            gameType: game,
            levelId: '2026-08-17',
            userId: u['name'] as String,
            userName: u['name'] as String,
            durationMs: u['time'] as int,
            moveCount: 12,
            score: u['score'] as int,
            completedAt: now.subtract(const Duration(hours: 4)),
          ),
        );
      }
    }
  }

  void submitScore(GameResult result) {
    _resultsStore.add(result);
  }

  List<LeaderboardEntry> getLeaderboard({
    required GameType gameType,
    required LeaderboardTimeframe timeframe,
  }) {
    final now = DateTime.now();

    // Filter results by game and time window
    final filtered = _resultsStore.where((r) {
      if (r.gameType != gameType) return false;

      if (timeframe == LeaderboardTimeframe.weekly) {
        return r.completedAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (timeframe == LeaderboardTimeframe.monthly) {
        return r.completedAt.isAfter(now.subtract(const Duration(days: 30)));
      }
      return true; // All time
    }).toList();

    // Aggregate user scores
    final Map<String, List<GameResult>> userMap = {};
    for (var res in filtered) {
      userMap.putIfAbsent(res.userId, () => []).add(res);
    }

    final entries = <LeaderboardEntry>[];
    userMap.forEach((userId, list) {
      final userName = list.first.userName;
      final totalScore = list.fold<int>(0, (sum, r) => sum + r.score);
      final bestTimeMs = list.map((r) => r.durationMs).reduce((a, b) => a < b ? a : b);

      entries.add(LeaderboardEntry(
        rank: 0,
        userId: userId,
        userName: userName,
        totalScore: totalScore,
        bestTimeMs: bestTimeMs,
        gamesPlayed: list.length,
      ));
    });

    // Sort by total score descending, then best time ascending
    entries.sort((a, b) {
      if (b.totalScore != a.totalScore) {
        return b.totalScore.compareTo(a.totalScore);
      }
      return a.bestTimeMs.compareTo(b.bestTimeMs);
    });

    // Assign rank numbers
    return List.generate(entries.length, (idx) {
      final e = entries[idx];
      return LeaderboardEntry(
        rank: idx + 1,
        userId: e.userId,
        userName: e.userName,
        totalScore: e.totalScore,
        bestTimeMs: e.bestTimeMs,
        gamesPlayed: e.gamesPlayed,
      );
    });
  }
}
