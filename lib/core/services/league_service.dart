import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/user_nickname_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import '../../games/common/base_game.dart';

// ============================================================================
// LIG SEVİYELERİ (10 Kademe — Demir → Şampiyonluk)
// ============================================================================

enum LeagueLevel {
  iron,       // 1. Demir
  bronze,     // 2. Bronz
  silver,     // 3. Gümüş
  gold,       // 4. Altın
  platinum,   // 5. Platin
  emerald,    // 6. Zümrüt
  diamond,    // 7. Elmas
  master,     // 8. Ustalık
  grandmaster,// 9. Üstatlık
  champion,   // 10. Şampiyonluk
}

extension LeagueLevelExt on LeagueLevel {
  String get displayName {
    switch (this) {
      case LeagueLevel.iron:
        return 'Demir';
      case LeagueLevel.bronze:
        return 'Bronz';
      case LeagueLevel.silver:
        return 'Gümüş';
      case LeagueLevel.gold:
        return 'Altın';
      case LeagueLevel.platinum:
        return 'Platin';
      case LeagueLevel.emerald:
        return 'Zümrüt';
      case LeagueLevel.diamond:
        return 'Elmas';
      case LeagueLevel.master:
        return 'Ustalık';
      case LeagueLevel.grandmaster:
        return 'Üstatlık';
      case LeagueLevel.champion:
        return 'Şampiyonluk';
    }
  }

  String get emoji {
    switch (this) {
      case LeagueLevel.iron:
        return '⛓️';
      case LeagueLevel.bronze:
        return '🥉';
      case LeagueLevel.silver:
        return '🥈';
      case LeagueLevel.gold:
        return '🥇';
      case LeagueLevel.platinum:
        return '💠';
      case LeagueLevel.emerald:
        return '💚';
      case LeagueLevel.diamond:
        return '💎';
      case LeagueLevel.master:
        return '🔮';
      case LeagueLevel.grandmaster:
        return '🦅';
      case LeagueLevel.champion:
        return '👑';
    }
  }

  Color get primaryColor {
    switch (this) {
      case LeagueLevel.iron:
        return const Color(0xFF64748B);
      case LeagueLevel.bronze:
        return const Color(0xFFCD7F32);
      case LeagueLevel.silver:
        return const Color(0xFF94A3B8);
      case LeagueLevel.gold:
        return const Color(0xFFF59E0B);
      case LeagueLevel.platinum:
        return const Color(0xFF06B6D4);
      case LeagueLevel.emerald:
        return const Color(0xFF10B981);
      case LeagueLevel.diamond:
        return const Color(0xFF38BDF8);
      case LeagueLevel.master:
        return const Color(0xFF8B5CF6);
      case LeagueLevel.grandmaster:
        return const Color(0xFFDC2626);
      case LeagueLevel.champion:
        return const Color(0xFFD97706);
    }
  }

  Color get bgColor {
    switch (this) {
      case LeagueLevel.iron:
        return const Color(0xFFF1F5F9);
      case LeagueLevel.bronze:
        return const Color(0xFFFEF3C7);
      case LeagueLevel.silver:
        return const Color(0xFFF1F5F9);
      case LeagueLevel.gold:
        return const Color(0xFFFFFBEB);
      case LeagueLevel.platinum:
        return const Color(0xFFECFEFF);
      case LeagueLevel.emerald:
        return const Color(0xFFECFDF5);
      case LeagueLevel.diamond:
        return const Color(0xFFF0F9FF);
      case LeagueLevel.master:
        return const Color(0xFFF5F3FF);
      case LeagueLevel.grandmaster:
        return const Color(0xFFFEF2F2);
      case LeagueLevel.champion:
        return const Color(0xFFFFFBEB);
    }
  }

  bool get isMax => this == LeagueLevel.champion;
  bool get isMin => this == LeagueLevel.iron;

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

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'weeklyScore': weeklyScore,
        'rank': rank,
        'isUser': isUser,
      };

  factory LeaguePlayer.fromJson(Map<String, dynamic> json) => LeaguePlayer(
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        weeklyScore: json['weeklyScore'] as int? ?? 0,
        rank: json['rank'] as int? ?? 0,
        isUser: json['isUser'] as bool? ?? false,
      );
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
  final bool isSyncing;

  const LeagueState({
    required this.currentLevel,
    required this.players,
    required this.weekId,
    this.pendingPromotion,
    this.pendingRelegation,
    this.isSyncing = false,
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
    bool? isSyncing,
  }) {
    return LeagueState(
      currentLevel: currentLevel ?? this.currentLevel,
      players: players ?? this.players,
      weekId: weekId ?? this.weekId,
      pendingPromotion: pendingPromotion ?? this.pendingPromotion,
      pendingRelegation: pendingRelegation ?? this.pendingRelegation,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel.index,
        'weekId': weekId,
        if (pendingPromotion != null) 'pendingPromotion': pendingPromotion!.index,
        if (pendingRelegation != null) 'pendingRelegation': pendingRelegation!.index,
        'players': players.map((p) => p.toJson()).toList(),
      };
}

// ============================================================================
// LIG SERVİSİ PROVIDER
// ============================================================================

final leagueServiceProvider =
    StateNotifierProvider<LeagueNotifier, LeagueState>((ref) {
  final leaderboard = ref.watch(leaderboardServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  final notifier = LeagueNotifier(
    leaderboard,
    apiClient,
    ref.read(userNicknameProvider),
    ref.read(dailyPlayServiceProvider),
    () => ref.read(userNicknameProvider),
    () => ref.read(dailyPlayServiceProvider),
  );

  // Nickname değiştiğinde sadece ismi güncelle, notifier'ı yok etme
  ref.listen<String>(userNicknameProvider, (prev, next) {
    notifier.updateNickname(next);
  });

  // Oyun tamamlandığında lig puanını anında yenile
  ref.listen<DailyPlayState>(dailyPlayServiceProvider, (prev, next) {
    notifier.refreshAfterGame(next);
  });

  return notifier;
});

class LeagueNotifier extends StateNotifier<LeagueState> {
  static const _prefKey = 'zuhtu_league_state_v3';
  static const int leagueSize = 42;
  static const int promotionCount = 10;
  static const int relegationCount = 10;

  final LeaderboardService? leaderboard;
  final ApiClient? apiClient;
  String _userNickname;
  final String Function()? userNicknameGetter;
  final DailyPlayState Function()? dailyPlayGetter;
  DailyPlayState? dailyPlay;
  bool _isInitialized = false;

  LeagueNotifier([
    this.leaderboard,
    this.apiClient,
    String userNickname = 'Oyuncu',
    this.dailyPlay,
    this.userNicknameGetter,
    this.dailyPlayGetter,
  ])  : _userNickname = userNickname,
        super(LeagueState(
          currentLevel: LeagueLevel.iron,
          players: [],
          weekId: _currentWeekId(),
        )) {
    _initLeague();
  }

  String get userNickname => userNicknameGetter?.call() ?? _userNickname;
  DailyPlayState? _getDailyPlay([DailyPlayState? override]) =>
      override ?? dailyPlayGetter?.call() ?? dailyPlay;

  void updateNickname(String newNickname) {
    _userNickname = newNickname;
    final trimmed = newNickname.trim().isEmpty ? 'Sen' : newNickname.trim();
    final currentPlayers = List<LeaguePlayer>.from(state.players);
    final userIdx = currentPlayers.indexWhere((p) => p.isUser);
    if (userIdx != -1) {
      currentPlayers[userIdx] = currentPlayers[userIdx].copyWith(userName: trimmed);
      state = state.copyWith(players: currentPlayers);
    }
  }

  static String _currentWeekId([DateTime? date]) {
    final active = date ?? GameDateUtils.getActiveDate();
    // ISO-8601 standardına göre haftanın ait olduğu Perşembe gününün yılı ve numarası
    final thursday = active.add(Duration(days: 4 - active.weekday));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays;
    final weekNumber = (dayOfYear / 7).floor() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  Future<void> _initLeague() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      final currentWeekId = _currentWeekId();

      LeagueLevel savedLevel = LeagueLevel.iron;
      LeagueLevel? pendingPromotion;
      LeagueLevel? pendingRelegation;
      List<LeaguePlayer> savedPlayers = [];
      int? lastRank;

      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final savedWeekId = decoded['weekId'] as String? ?? '';
        final levelIndex = (decoded['currentLevel'] as int?) ?? 0;
        savedLevel = levelIndex < LeagueLevel.values.length
            ? LeagueLevel.values[levelIndex]
            : LeagueLevel.iron;

        lastRank = decoded['lastRank'] as int?;

        // Eğer decoded['players'] listesi varsa ve kullanıcının gerçek sırası kayıtlıysa,
        // bozuk lastRank (örneğin boş liste nedeniyle 42 kaydedilmişse) yerine gerçek sırayı al
        if (decoded['players'] is List) {
          final decodedPlayers = (decoded['players'] as List)
              .map((p) => LeaguePlayer.fromJson(p as Map<String, dynamic>))
              .toList();
          final userP = decodedPlayers.cast<LeaguePlayer?>().firstWhere(
            (p) => p?.isUser == true,
            orElse: () => null,
          );
          if (userP != null && userP.rank > 0 && userP.weeklyScore > 0) {
            if (lastRank == null || lastRank == 42 || lastRank > userP.rank) {
              lastRank = userP.rank;
            }
          }
        }

        if (savedWeekId.isNotEmpty && savedWeekId != currentWeekId) {
          // Yeni hafta: Önceki hafta sonuçlarına göre lig atla/düş
          // Eğer lastRank hala belirlenememişse veya 42 ise, önceki haftanın oyun kayıtlarını kontrol et
          if (lastRank == null || lastRank > promotionCount) {
            final prevWeekScore = _calculateUserScoreForWeek(savedWeekId);
            if (prevWeekScore > 0) {
              lastRank = 1;
            }
          }

          final effectiveRank = lastRank ?? 21;
          LeagueLevel newLevel = savedLevel;
          if (effectiveRank <= promotionCount && !savedLevel.isMax) {
            newLevel = savedLevel.next ?? savedLevel;
            pendingPromotion = newLevel;
          } else if (effectiveRank > leagueSize - relegationCount &&
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
          if (decoded['players'] is List) {
            savedPlayers = (decoded['players'] as List)
                .map((p) => LeaguePlayer.fromJson(p as Map<String, dynamic>))
                .where((p) => !p.userId.startsWith('bot_') && !_allBotNames.contains(p.userName))
                .toList();
          }
        }
      }

      // Kullanıcının hakkı olan terfi durumu (otomatik telafi):
      // Eğer kullanıcı Demir ligindeyse ve bu haftadan önceki günlerde tamamlanmış oyunu varsa,
      // veya geçen hafta puan toplamış ama bug nedeniyle Demir'de kalmışsa, Bronz'a yükselt!
      if (savedLevel == LeagueLevel.iron && pendingPromotion == null) {
        final hasAnyPreviousPlays = _hasPreviousWeekPlays(currentWeekId);
        if (hasAnyPreviousPlays) {
          savedLevel = LeagueLevel.bronze;
          pendingPromotion = LeagueLevel.bronze;
        }
      }

      if (savedPlayers.isNotEmpty) {
        final currentWeeklyScore = _calculateUserWeeklyScore();
        final userIdx = savedPlayers.indexWhere((p) => p.isUser);
        if (userIdx != -1) {
          savedPlayers[userIdx] = savedPlayers[userIdx].copyWith(weeklyScore: currentWeeklyScore);
        }
      }

      final players = savedPlayers.isNotEmpty
          ? savedPlayers
          : _buildLeaguePlayers(savedLevel, currentWeekId);

      _isInitialized = true;
      if (!mounted) return;
      state = LeagueState(
        currentLevel: savedLevel,
        players: players,
        weekId: currentWeekId,
        pendingPromotion: pendingPromotion,
        pendingRelegation: pendingRelegation,
      );

      await _saveState();

      // Canlı sunucudan en güncel haftalık sıralamayı arka planda çek
      if (mounted) {
        fetchLiveLeagueData();
      }
    } catch (_) {
      _isInitialized = true;
      if (!mounted) return;
      final players =
          _buildLeaguePlayers(LeagueLevel.iron, _currentWeekId());
      state = LeagueState(
        currentLevel: LeagueLevel.iron,
        players: players,
        weekId: _currentWeekId(),
      );
    }
  }

  /// Belirli bir haftada kullanıcının tamamladığı oyunlardan kazandığı puanı döner
  int _calculateUserScoreForWeek(String targetWeekId) {
    int total = 0;
    final ps = _getDailyPlay();
    if (ps != null) {
      for (final record in ps.records.values) {
        if (record.isArchivePlay) continue;
        final recordWeekId = _currentWeekId(record.completedAt);
        if (recordWeekId == targetWeekId) {
          total += record.score;
        }
      }
    }
    return total;
  }

  /// Mevcut haftadan önceki herhangi bir haftada oynanmış oyun kaydı olup olmadığını denetler
  bool _hasPreviousWeekPlays(String currentWeekId) {
    final ps = _getDailyPlay();
    if (ps != null) {
      for (final record in ps.records.values) {
        if (record.isArchivePlay) continue;
        final recordWeekId = _currentWeekId(record.completedAt);
        if (recordWeekId != currentWeekId && record.score > 0) {
          return true;
        }
      }
    }
    if (leaderboard != null) {
      try {
        for (final game in GameType.values) {
          final entries = leaderboard!.getLeaderboard(
            gameType: game,
            timeframe: LeaderboardTimeframe.allTime,
          );
          final userEntries =
              entries.where((e) => e.userId == 'user_local').toList();
          if (userEntries.isNotEmpty && userEntries.first.totalScore > 0) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Kullanıcının bu haftaki toplam puanını yerel kayıtlardan ve liderlik tablosundan hesaplar
  int _calculateUserWeeklyScore([DailyPlayState? playState, DateTime? date]) {
    int total = 0;
    final ps = _getDailyPlay(playState);
    final targetDate = date ?? GameDateUtils.getActiveDate();
    final weekStart = GameDateUtils.getStartOfWeek(targetDate);
    final sunday = weekStart.add(const Duration(days: 6));
    final endOfWeek = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    if (ps != null && ps.records.isNotEmpty) {
      for (final record in ps.records.values) {
        if (!record.completedAt.isBefore(weekStart) && !record.completedAt.isAfter(endOfWeek)) {
          // Geçmiş gün oyunları haftalık lig skoruna kesinlikle eklenemez
          if (record.isArchivePlay) continue;
          final completedDateKey =
              '${record.completedAt.year.toString().padLeft(4, '0')}-${record.completedAt.month.toString().padLeft(2, '0')}-${record.completedAt.day.toString().padLeft(2, '0')}';
          if (record.dateId != completedDateKey) continue;
          total += record.score;
        }
      }
      return total;
    }

    if (leaderboard != null) {
      int lbTotal = 0;
      try {
        for (final game in GameType.values) {
          final entries = leaderboard!.getLeaderboard(
            gameType: game,
            timeframe: LeaderboardTimeframe.weekly,
          );
          final userEntries =
              entries.where((e) => e.userId == 'user_local').toList();
          if (userEntries.isNotEmpty) {
            lbTotal += userEntries.first.totalScore;
          }
        }
      } catch (_) {}
      if (lbTotal > total) total = lbTotal;
    }

    return total;
  }

  /// Canlı sunucudaki tüm haftalık oyun skorlarını çekip birleştirir
  Future<void> fetchLiveLeagueData() async {
    if (apiClient == null || !mounted) return;

    state = state.copyWith(isSyncing: true);

    try {
      final currentWeekId = _currentWeekId();

      // 1. Canlı sunucudan tüm oyunların haftalık sıralamalarını paralel çek
      final Map<String, int> playerTotalScores = {};
      final Map<String, String> playerDisplayNames = {};

      final games = [
        GameType.queens,
        GameType.pinpoint,
        GameType.crossclimb,
        GameType.tango,
        GameType.zipPath,
        GameType.patches,
      ];

      final results = await Future.wait(
        games.map((g) => apiClient!.fetchLeaderboard(
              gameType: g,
              timeframe: LeaderboardTimeframe.weekly,
            )),
      );

      for (final list in results) {
        if (list == null) continue;
        for (final entry in list) {
          final normalizedName = entry.userName.trim().toLowerCase();
          playerTotalScores[normalizedName] =
              (playerTotalScores[normalizedName] ?? 0) + entry.totalScore;
          playerDisplayNames[normalizedName] = entry.userName.trim();
        }
      }

      // 2. Kullanıcının haftalık puanını belirle
      final userNick = userNickname.trim().isEmpty ? 'Sen' : userNickname.trim();
      final normalizedUserNick = userNick.toLowerCase();
      final localScore = _calculateUserWeeklyScore();
      final serverScore = playerTotalScores[normalizedUserNick] ?? 0;
      final effectiveUserScore = max(localScore, serverScore);

      // Kullanıcıyı sunucu toplamından çıkar (ayrı ekleyeceğiz)
      playerTotalScores.remove(normalizedUserNick);

      // 3. Gerçek canlı sunucu oyuncuları
      final realPlayers = <LeaguePlayer>[];
      playerTotalScores.forEach((normNick, score) {
        realPlayers.add(
          LeaguePlayer(
            userId: 'server_$normNick',
            userName: playerDisplayNames[normNick] ?? normNick,
            weeklyScore: score,
            rank: 0,
            isUser: false,
          ),
        );
      });

      // 4. KESİNLİKLE BOT YOK: Sadece gerçek canlı sunucu oyuncuları
      final allPlayers = [
        LeaguePlayer(
          userId: 'user_local',
          userName: userNick,
          weeklyScore: effectiveUserScore,
          rank: 0,
          isUser: true,
        ),
        ...realPlayers,
      ];

      allPlayers.sort((a, b) {
        if (b.weeklyScore != a.weeklyScore) {
          return b.weeklyScore.compareTo(a.weeklyScore);
        }
        return a.userName.compareTo(b.userName);
      });

      final ranked = List.generate(allPlayers.length, (i) {
        return allPlayers[i].copyWith(rank: i + 1);
      });

      if (!mounted) return;
      state = state.copyWith(
        players: ranked,
        weekId: currentWeekId,
        isSyncing: false,
      );

      await _saveState();
    } catch (e) {
      debugPrint('[LeagueService] Canlı lig verisi çekme hatası (Local korundu): $e');
      if (mounted) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }

  /// Yerel lig oyuncuları tablosunu kurar
  List<LeaguePlayer> _buildLeaguePlayers(
      LeagueLevel level, String weekId) {
    int userScore = _calculateUserWeeklyScore();
    final userNick = userNickname.trim().isEmpty ? 'Sen' : userNickname.trim();

    return [
      LeaguePlayer(
        userId: 'user_local',
        userName: userNick,
        weeklyScore: userScore,
        rank: 1,
        isUser: true,
      ),
    ];
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
    'GüçlüSkor', 'ElitOyuncu', 'GünPuanı', 'DemirYürek',
    'BronzKral', 'GümüşYıldız',
  ];



  /// Gün değişimi veya yeni haftaya geçiş kontrolü
  Future<void> checkWeekTransition() async {
    if (!_isInitialized) {
      await _initLeague();
      return;
    }
    final currentWeekId = _currentWeekId();
    if (state.weekId != currentWeekId && state.weekId.isNotEmpty) {
      final lastRank = state.userPlayer?.rank ?? (state.userWeeklyScore > 0 ? 1 : 21);
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

      final players = _buildLeaguePlayers(newLevel, currentWeekId);

      state = LeagueState(
        currentLevel: newLevel,
        players: players,
        weekId: currentWeekId,
        pendingPromotion: pendingPromotion,
        pendingRelegation: pendingRelegation,
      );

      await _saveState();
      fetchLiveLeagueData();
    } else {
      await fetchLiveLeagueData();
    }
  }

  /// Oyun bitişinde ligi hemen yenile
  Future<void> refreshAfterGame([DailyPlayState? updatedDailyPlay]) async {
    if (!_isInitialized) return;
    if (updatedDailyPlay != null) {
      dailyPlay = updatedDailyPlay;
    }
    final currentWeekId = _currentWeekId();

    // Hafta geçişi olmuşsa önce lig atlamayı uygula
    if (state.weekId != currentWeekId && state.weekId.isNotEmpty) {
      await checkWeekTransition();
      return;
    }

    final updatedScore = _calculateUserWeeklyScore();

    // Kullanıcının puanını mevcut oyuncu listesinde hemen güncelle
    final currentPlayers = List<LeaguePlayer>.from(state.players);
    final userIdx = currentPlayers.indexWhere((p) => p.isUser);
    if (userIdx != -1) {
      currentPlayers[userIdx] = currentPlayers[userIdx].copyWith(
        weeklyScore: max(currentPlayers[userIdx].weeklyScore, updatedScore),
      );
      currentPlayers.sort((a, b) {
        if (b.weeklyScore != a.weeklyScore) {
          return b.weeklyScore.compareTo(a.weeklyScore);
        }
        return a.userName.compareTo(b.userName);
      });
      final ranked = List.generate(currentPlayers.length, (i) {
        return currentPlayers[i].copyWith(rank: i + 1);
      });
      state = state.copyWith(players: ranked, weekId: currentWeekId);
    } else {
      final userNick = userNickname.trim().isEmpty ? 'Sen' : userNickname.trim();
      currentPlayers.add(
        LeaguePlayer(
          userId: 'user_local',
          userName: userNick,
          weeklyScore: updatedScore,
          rank: 1,
          isUser: true,
        ),
      );
      currentPlayers.sort((a, b) {
        if (b.weeklyScore != a.weeklyScore) {
          return b.weeklyScore.compareTo(a.weeklyScore);
        }
        return a.userName.compareTo(b.userName);
      });
      final ranked = List.generate(currentPlayers.length, (i) {
        return currentPlayers[i].copyWith(rank: i + 1);
      });
      state = state.copyWith(players: ranked, weekId: currentWeekId);
    }

    await _saveState();

    // Arka planda sunucudan da en son verileri çekip güncelle
    fetchLiveLeagueData();
  }

  /// Bekleyen yükselme/düşme bildirimini temizle
  Future<void> clearPendingLeagueChange() async {
    state = state.copyWith(
      pendingPromotion: null,
      pendingRelegation: null,
    );
    await _saveState();
  }

  Future<void> _saveState() async {
    if (!_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.toJson();
      if (state.userPlayer != null) {
        json['lastRank'] = state.userRank;
      }
      await prefs.setString(_prefKey, jsonEncode(json));
    } catch (_) {}
  }

  /// Bulut yedekleme için mevcut lig durumunu JSON haritası olarak döner.
  Map<String, dynamic> exportBackupMap() {
    return {
      'currentLevel': state.currentLevel.index,
      'currentLevelName': state.currentLevel.name,
      'weekId': state.weekId,
    };
  }

  /// Buluttan veya yedek anahtarından gelen lig seviyesini geri yükler.
  Future<void> restoreFromBackupMap(Map<String, dynamic> decoded) async {
    int? levelIndex = decoded['currentLevel'] as int?;
    if (levelIndex == null && decoded['currentLevelName'] is String) {
      final name = decoded['currentLevelName'] as String;
      final idx = LeagueLevel.values.indexWhere((l) => l.name == name);
      if (idx != -1) levelIndex = idx;
    }

    if (levelIndex != null &&
        levelIndex >= 0 &&
        levelIndex < LeagueLevel.values.length) {
      final restoredLevel = LeagueLevel.values[levelIndex];
      if (restoredLevel.index > state.currentLevel.index) {
        state = state.copyWith(currentLevel: restoredLevel);
        await _saveState();
      }
    }
    await refreshAfterGame();
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
