class GameServerStats {
  final int allTimeScore;
  final int bestScore;
  final int bestTimeMs;
  final int gamesPlayed;
  final int weeklyScore;
  final int todayScore;

  const GameServerStats({
    this.allTimeScore = 0,
    this.bestScore = 0,
    this.bestTimeMs = 0,
    this.gamesPlayed = 0,
    this.weeklyScore = 0,
    this.todayScore = 0,
  });

  factory GameServerStats.fromJson(Map<String, dynamic> json) {
    return GameServerStats(
      allTimeScore: (json['all_time_score'] as num?)?.toInt() ?? 0,
      bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
      bestTimeMs: (json['best_time_ms'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      weeklyScore: (json['weekly_score'] as num?)?.toInt() ?? 0,
      todayScore: (json['today_score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'all_time_score': allTimeScore,
        'best_score': bestScore,
        'best_time_ms': bestTimeMs,
        'games_played': gamesPlayed,
        'weekly_score': weeklyScore,
        'today_score': todayScore,
      };
}

class PlayerServerStats {
  final int totalCareerScore;
  final int totalGamesPlayed;
  final int weeklyScore;
  final int monthlyScore;
  final int todayScore;
  final int avgDurationMs;
  final Map<String, GameServerStats> games;
  final bool isSynced;

  const PlayerServerStats({
    this.totalCareerScore = 0,
    this.totalGamesPlayed = 0,
    this.weeklyScore = 0,
    this.monthlyScore = 0,
    this.todayScore = 0,
    this.avgDurationMs = 0,
    this.games = const {},
    this.isSynced = false,
  });

  factory PlayerServerStats.fromJson(Map<String, dynamic> json) {
    final gamesMap = <String, GameServerStats>{};
    if (json['games'] is Map) {
      (json['games'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          gamesMap[k] = GameServerStats.fromJson(v);
        }
      });
    }

    return PlayerServerStats(
      totalCareerScore: (json['total_career_score'] as num?)?.toInt() ?? 0,
      totalGamesPlayed: (json['total_games_played'] as num?)?.toInt() ?? 0,
      weeklyScore: (json['weekly_score'] as num?)?.toInt() ?? 0,
      monthlyScore: (json['monthly_score'] as num?)?.toInt() ?? 0,
      todayScore: (json['today_score'] as num?)?.toInt() ?? 0,
      avgDurationMs: (json['avg_duration_ms'] as num?)?.toInt() ?? 0,
      games: gamesMap,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_career_score': totalCareerScore,
        'total_games_played': totalGamesPlayed,
        'weekly_score': weeklyScore,
        'monthly_score': monthlyScore,
        'today_score': todayScore,
        'avg_duration_ms': avgDurationMs,
        'games': games.map((k, v) => MapEntry(k, v.toJson())),
      };
}
