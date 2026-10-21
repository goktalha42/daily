import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/date_utils.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import '../../games/common/base_game.dart';

// ============================================================================
// LIG SEVİYELERİ (10 Kademe — Taş → Muhteşem)
// ============================================================================

enum LeagueLevel {
  stone,
  bronze,
  silver,
  gold,
  sapphire,
  ruby,
  diamond,
  amethyst,
  emerald,
  legendary,
}

extension LeagueLevelExt on LeagueLevel {
  String get displayName {
    switch (this) {
      case LeagueLevel.stone:
        return 'Taş';
      case LeagueLevel.bronze:
        return 'Bronz';
      case LeagueLevel.silver:
        return 'Gümüş';
      case LeagueLevel.gold:
        return 'Altın';
      case LeagueLevel.sapphire:
        return 'Safir';
      case LeagueLevel.ruby:
        return 'Yakut';
      case LeagueLevel.diamond:
        return 'Elmas';
      case LeagueLevel.amethyst:
        return 'Ametist';
      case LeagueLevel.emerald:
        return 'Zümrüt';
      case LeagueLevel.legendary:
        return 'Muhteşem';
    }
  }

  String get emoji {
    switch (this) {
      case LeagueLevel.stone:
        return '🪨';
      case LeagueLevel.bronze:
        return '🥉';
      case LeagueLevel.silver:
        return '🥈';
      case LeagueLevel.gold:
        return '🥇';
      case LeagueLevel.sapphire:
        return '💙';
      case LeagueLevel.ruby:
        return '♦️';
      case LeagueLevel.diamond:
        return '💎';
      case LeagueLevel.amethyst:
        return '🔮';
      case LeagueLevel.emerald:
        return '💚';
      case LeagueLevel.legendary:
        return '👑';
    }
  }

  Color get primaryColor {
    switch (this) {
      case LeagueLevel.stone:
        return const Color(0xFF78716C);
      case LeagueLevel.bronze:
        return const Color(0xFFCD7F32);
      case LeagueLevel.silver:
        return const Color(0xFF94A3B8);
      case LeagueLevel.gold:
        return const Color(0xFFF59E0B);
      case LeagueLevel.sapphire:
        return const Color(0xFF38BDF8);
      case LeagueLevel.ruby:
        return const Color(0xFFEF4444);
      case LeagueLevel.diamond:
        return const Color(0xFF67E8F9);
      case LeagueLevel.amethyst:
        return const Color(0xFFC4B5FD);
      case LeagueLevel.emerald:
        return const Color(0xFF10B981);
      case LeagueLevel.legendary:
        return const Color(0xFFF59E0B);
    }
  }

  Color get bgColor {
    switch (this) {
      case LeagueLevel.stone:
        return const Color(0xFFF5F5F4);
      case LeagueLevel.bronze:
        return const Color(0xFFFEF3C7);
      case LeagueLevel.silver:
        return const Color(0xFFF1F5F9);
      case LeagueLevel.gold:
        return const Color(0xFFFFFBEB);
      case LeagueLevel.sapphire:
        return const Color(0xFFF0F9FF);
      case LeagueLevel.ruby:
        return const Color(0xFFFEF2F2);
      case LeagueLevel.diamond:
        return const Color(0xFFECFEFF);
      case LeagueLevel.amethyst:
        return const Color(0xFFF5F3FF);
      case LeagueLevel.emerald:
        return const Color(0xFFECFDF5);
      case LeagueLevel.legendary:
        return const Color(0xFFFFFBEB);
    }
  }

  bool get isMax => this == LeagueLevel.legendary;
  bool get isMin => this == LeagueLevel.stone;

  LeagueLevel? get next {
    final idx = LeagueLevel.values.indexOf(this);
    if (idx >= LeagueLevel.values.length - 1) return null;
    return LeagueLevel.values[idx + 1];
  }

  LeagueLevel? get previous {
    final idx = LeagueLevel.values.indexOf(this);
    if (idx <= 0) return null;
    return LeagueLevel.values[idx - 1];
  }
}

// ============================================================================
// LIG OYUNCUSU VERİSİ
// ============================================================================

class LeaguePlayer {
  final String userId;
  final String userName;
  final int weeklyScore;
  final int rank;
  final bool isUser;

  const LeaguePlayer({
    required this.userId,
    required this.userName,
    required this.weeklyScore,
    required this.rank,
    required this.isUser,
  });

  LeaguePlayer copyWith({
    String? userId,
    String? userName,
    int? weeklyScore,
    int? rank,
    bool? isUser,
  }) {
    return LeaguePlayer(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      rank: rank ?? this.rank,
      isUser: isUser ?? this.isUser,
    );
  }
}

// ============================================================================
// LIG DURUMU
// ============================================================================

enum LeagueZone {
  promotion,  // İlk 10: Yükselme bölgesi
  safe,       // 11..32: Güvenli bölge
  relegation, // Son 10 (33..42): Düşme bölgesi
}

class LeagueState {
  final LeagueLevel currentLevel;
  final List<LeaguePlayer> players;
  final String weekId;
  final LeagueLevel? pendingPromotion;
  final LeagueLevel? pendingRelegation;

  const LeagueState({
    required this.currentLevel,
    required this.players,
    required this.weekId,
    this.pendingPromotion,
    this.pendingRelegation,
  });

  LeaguePlayer? get userPlayer {
    try {
      return players.firstWhere((p) => p.isUser);
    } catch (_) {
      return null;
    }
  }

  int get userRank => userPlayer?.rank ?? 42;
  int get userWeeklyScore => userPlayer?.weeklyScore ?? 0;

  LeagueZone get userZone {
    final rank = userRank;
    if (rank <= 10) return LeagueZone.promotion;
    if (rank <= 32) return LeagueZone.safe;
    return LeagueZone.relegation;
  }

  int get pointsToPromotion {
    final borderPlayers = players.where((p) => p.rank == 10).toList();
    final user = userPlayer;
    if (user == null) return 0;
    if (user.rank <= 10) return 0;
    if (borderPlayers.isEmpty) return 0;
    return (borderPlayers.first.weeklyScore - user.weeklyScore).clamp(0, 99999);
  }

  int get pointsSafetyMargin {
    final borderPlayers = players.where((p) => p.rank == 33).toList();
    final user = userPlayer;
    if (user == null) return 0;
    if (user.rank >= 33) return 0;
    if (borderPlayers.isEmpty) return 0;
    return (user.weeklyScore - borderPlayers.first.weeklyScore).clamp(0, 99999);
  }

  LeagueState copyWith({
    LeagueLevel? currentLevel,
    List<LeaguePlayer>? players,
    String? weekId,
    LeagueLevel? pendingPromotion,
    LeagueLevel? pendingRelegation,
  }) {
    return LeagueState(
      currentLevel: currentLevel ?? this.currentLevel,
      players: players ?? this.players,
      weekId: weekId ?? this.weekId,
      pendingPromotion: pendingPromotion,
      pendingRelegation: pendingRelegation,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel.index,
        'weekId': weekId,
        if (pendingPromotion != null) 'pendingPromotion': pendingPromotion!.index,
        if (pendingRelegation != null) 'pendingRelegation': pendingRelegation!.index,
      };
}

// ============================================================================
// LIG SERVİSİ PROVIDER
// ============================================================================

final leagueServiceProvider =
    StateNotifierProvider<LeagueNotifier, LeagueState>((ref) {
  final leaderboard = ref.watch(leaderboardServiceProvider);
  return LeagueNotifier(leaderboard);
});

class LeagueNotifier extends StateNotifier<LeagueState> {
  static const _prefKey = 'zuhtu_league_state_v1';
  static const int leagueSize = 42;
  static const int promotionCount = 10;
  static const int relegationCount = 10;

  final LeaderboardService _leaderboard;

  LeagueNotifier(this._leaderboard)
      : super(LeagueState(
          currentLevel: LeagueLevel.stone,
          players: [],
          weekId: _currentWeekId(),
        )) {
    _initLeague();
  }

  static String _currentWeekId([DateTime? date]) {
    final active = date ?? GameDateUtils.getActiveDate();
    final weekNumber = _isoWeekNumber(active);
    return '${active.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    final weekDay = date.weekday;
    return ((dayOfYear + startOfYear.weekday - weekDay) / 7).floor() + 1;
  }

  Future<void> _initLeague() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      final currentWeekId = _currentWeekId();

      LeagueLevel savedLevel = LeagueLevel.stone;
      LeagueLevel? pendingPromotion;
      LeagueLevel? pendingRelegation;

      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final savedWeekId = decoded['weekId'] as String? ?? '';
        savedLevel =
            LeagueLevel.values[(decoded['currentLevel'] as int?) ?? 0];

        if (savedWeekId != currentWeekId) {
          // Yeni hafta: Önceki hafta sonuçlarına göre lig atla/düş
          final lastRank = decoded['lastRank'] as int? ?? 21;
          LeagueLevel newLevel = savedLevel;
          if (lastRank <= promotionCount && !savedLevel.isMax) {
            newLevel = savedLevel.next ?? savedLevel;
            pendingPromotion = newLevel;
          } else if (lastRank > leagueSize - relegationCount &&
              !savedLevel.isMin) {
            newLevel = savedLevel.previous ?? savedLevel;
            pendingRelegation = newLevel;
          }
          savedLevel = newLevel;
        } else {
          pendingPromotion = decoded['pendingPromotion'] != null
              ? LeagueLevel.values[decoded['pendingPromotion'] as int]
              : null;
          pendingRelegation = decoded['pendingRelegation'] != null
              ? LeagueLevel.values[decoded['pendingRelegation'] as int]
              : null;
        }
      }

      final players = _buildLeaguePlayers(savedLevel, currentWeekId);

      state = LeagueState(
        currentLevel: savedLevel,
        players: players,
        weekId: currentWeekId,
        pendingPromotion: pendingPromotion,
        pendingRelegation: pendingRelegation,
      );

      await _saveState();
    } catch (_) {
      final players =
          _buildLeaguePlayers(LeagueLevel.stone, _currentWeekId());
      state = LeagueState(
        currentLevel: LeagueLevel.stone,
        players: players,
        weekId: _currentWeekId(),
      );
    }
  }

  /// Haftalık liderlik tablosundan kullanıcı puanını çeker + bot oyuncuları üretir
  List<LeaguePlayer> _buildLeaguePlayers(
      LeagueLevel level, String weekId) {
    int userScore = _getUserWeeklyScore();

    final (int botMin, int botMax) = _botScoreRange(level);
    final rng = Random(_weekSeed(weekId, level));
    final bots = _generateBotPlayers(level, rng, botMin, botMax);

    final allPlayers = [
      LeaguePlayer(
        userId: 'user_local',
        userName: 'Sen',
        weeklyScore: userScore,
        rank: 0,
        isUser: true,
      ),
      ...bots,
    ];

    allPlayers.sort((a, b) {
      if (b.weeklyScore != a.weeklyScore) {
        return b.weeklyScore.compareTo(a.weeklyScore);
      }
      return a.userId.compareTo(b.userId);
    });

    return List.generate(allPlayers.length, (i) {
      return allPlayers[i].copyWith(rank: i + 1);
    });
  }

  int _getUserWeeklyScore() {
    try {
      int total = 0;
      for (final game in GameType.values) {
        final entries = _leaderboard.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.weekly,
        );
        final userEntries =
            entries.where((e) => e.userId == 'user_local').toList();
        if (userEntries.isNotEmpty) {
          total += userEntries.first.totalScore;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  int _weekSeed(String weekId, LeagueLevel level) {
    int seed = 0;
    for (final ch in weekId.codeUnits) {
      seed += ch;
    }
    return seed + level.index * 1000;
  }

  (int, int) _botScoreRange(LeagueLevel level) {
    switch (level) {
      case LeagueLevel.stone:
        return (200, 4000);
      case LeagueLevel.bronze:
        return (1500, 6000);
      case LeagueLevel.silver:
        return (3000, 9000);
      case LeagueLevel.gold:
        return (5000, 13000);
      case LeagueLevel.sapphire:
        return (7000, 17000);
      case LeagueLevel.ruby:
        return (10000, 22000);
      case LeagueLevel.diamond:
        return (14000, 28000);
      case LeagueLevel.amethyst:
        return (18000, 34000);
      case LeagueLevel.emerald:
        return (24000, 42000);
      case LeagueLevel.legendary:
        return (32000, 55000);
    }
  }

  List<LeaguePlayer> _generateBotPlayers(
      LeagueLevel level, Random rng, int minScore, int maxScore) {
    final active = GameDateUtils.getActiveDate();
    // Haftanın ilerleyişine göre bot skorlarını dinamik ölçekle (Pzt: %25 -> Paz: %100)
    // Böylece Pazartesi yeni haftaya geçildiğinde botların puanları da sıfırlanıp baştan başlar!
    final double dayFactor = (active.weekday / 7.0).clamp(0.25, 1.0);
    final currentMin = (minScore * dayFactor).round();
    final currentMax = (maxScore * dayFactor).round();

    final names = _botNamesForLevel(level);
    final count = leagueSize - 1;
    return List.generate(count, (i) {
      final baseName = names[i % names.length];
      final suffix = rng.nextInt(9000) + 1000;
      final range = max(10, currentMax - currentMin);
      final score = currentMin + rng.nextInt(range);
      return LeaguePlayer(
        userId: 'bot_${level.index}_$i',
        userName: '${baseName}_$suffix',
        weeklyScore: score,
        rank: 0,
        isUser: false,
      );
    });
  }

  static const _allBotNames = [
    'ZekaUstası', 'BeyinFırtınası', 'HızlıDüşünür', 'MatematikKurdu',
    'GizemliZeka', 'AkılOyunları', 'PuanAvcısı', 'StratejiUstası',
    'ZirveHedefi', 'ElitBeyinler', 'KodKırıcı', 'PazartesiWarrior',
    'HaftalıkŞampiyon', 'LigKralı', 'NokTaAtış', 'SüperBeyin',
    'ZühtüHayranı', 'GünlükDeha', 'BulmacaSever', 'ZekaDüellosu',
    'TahtaYolu', 'AltınBeyin', 'YıldızOyuncu', 'SkorKıran',
    'MantıkUstası', 'Analist99', 'KomboBeyni', 'SatranççıRuhu',
    'PerfektSkor', 'AceDetektif', 'BeyazKalem', 'GrafikUsta',
    'RakamKıran', 'TartışmazZeka', 'ŞampiyonRuhu', 'HızlıKalem',
    'GüçlüSkor', 'ElitOyuncu', 'GünPuanı', 'TaşUyandı',
    'BronzKral', 'GümüşYıldız',
  ];

  List<String> _botNamesForLevel(LeagueLevel level) {
    if (level.index >= 7) {
      return [
        'ElitDeha', 'AbsoluteZeka', 'PerfektBeyin', 'GrandMaster',
        'ZirveKralı', 'NihayetŞampiyon', 'EfsaneOyuncu', 'MuhteşemBeyin'
      ];
    }
    if (level.index >= 4) {
      return [
        'DiamondZeka', 'SafirUsta', 'YakutBeyin', 'LigEfsanesi',
        'ŞampiyonYolu', 'StratejiKral', 'ZirveYıldız', 'ElitSkor'
      ];
    }
    return _allBotNames;
  }

  /// Gün değişimi veya yeni haftaya geçiş kontrolü
  Future<void> checkWeekTransition() async {
    final currentWeekId = _currentWeekId();
    if (state.weekId != currentWeekId && state.weekId.isNotEmpty) {
      // Önceki haftanın sıralaması:
      final lastRank = state.userRank;
      LeagueLevel newLevel = state.currentLevel;
      LeagueLevel? pendingPromotion;
      LeagueLevel? pendingRelegation;

      if (lastRank <= promotionCount && !state.currentLevel.isMax) {
        newLevel = state.currentLevel.next ?? state.currentLevel;
        pendingPromotion = newLevel;
      } else if (lastRank > leagueSize - relegationCount && !state.currentLevel.isMin) {
        newLevel = state.currentLevel.previous ?? state.currentLevel;
        pendingRelegation = newLevel;
      }

      // Yeni hafta için botları ve kullanıcı puanını yeni haftaya göre kur
      final players = _buildLeaguePlayers(newLevel, currentWeekId);

      state = LeagueState(
        currentLevel: newLevel,
        players: players,
        weekId: currentWeekId,
        pendingPromotion: pendingPromotion,
        pendingRelegation: pendingRelegation,
      );

      await _saveState();
    } else {
      await refreshAfterGame();
    }
  }

  /// Oyun bitişinde ligi yenile
  Future<void> refreshAfterGame() async {
    final currentWeekId = _currentWeekId();
    final players = _buildLeaguePlayers(state.currentLevel, currentWeekId);
    state = state.copyWith(players: players, weekId: currentWeekId);
    await _saveState();
  }

  /// Bekleyen yükselme/düşme bildirimini temizle
  Future<void> clearPendingLeagueChange() async {
    state = LeagueState(
      currentLevel: state.currentLevel,
      players: state.players,
      weekId: state.weekId,
    );
    await _saveState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.toJson();
      json['lastRank'] = state.userRank;
      await prefs.setString(_prefKey, jsonEncode(json));
    } catch (_) {}
  }
}

// ============================================================================
// YARDIMCI: Haftanın bitiş süresini döner
// ============================================================================

String leagueDaysRemaining() {
  final now = GameDateUtils.getActiveDate();
  final daysUntilSunday = 7 - now.weekday;
  final sunday = now.add(Duration(days: daysUntilSunday));
  final endOfWeek =
      DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  final diff = endOfWeek.difference(now);
  if (diff.inDays > 0) return '${diff.inDays} gün';
  if (diff.inHours > 0) return '${diff.inHours} saat';
  return '${diff.inMinutes} dakika';
}
