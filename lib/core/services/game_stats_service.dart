import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../games/common/base_game.dart';

class GamePerformanceData {
  final GameType gameType;
  final int? percentile; // 1 = Top %1, 3 = Top %3
  final int bestScore;
  final int bestDurationMs;
  final int totalGamesPlayed;
  final DateTime? lastPlayedAt;
  final String geniusTitle;

  GamePerformanceData({
    required this.gameType,
    this.percentile,
    required this.bestScore,
    required this.bestDurationMs,
    required this.totalGamesPlayed,
    this.lastPlayedAt,
    required this.geniusTitle,
  });

  bool get hasPlayed => percentile != null && totalGamesPlayed > 0;

  String get percentileBadgeText {
    if (!hasPlayed) {
      return '🚀 HENÜZ OYNANMADI • HEDEF: %1';
    }
    if (percentile! <= 1) {
      return '🏆 ZİRVE %1\'LİK DİLİM (DAHİ)';
    } else if (percentile! <= 3) {
      return '⚡ İLK %$percentile\'LİK DİLİM (ÜSTÜN ZEKÂ)';
    } else {
      return '🎯 İLK %$percentile\'LİK DİLİM';
    }
  }

  Map<String, dynamic> toJson() => {
        'gameType': gameType.id,
        'percentile': percentile,
        'bestScore': bestScore,
        'bestDurationMs': bestDurationMs,
        'totalGamesPlayed': totalGamesPlayed,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'geniusTitle': geniusTitle,
      };

  factory GamePerformanceData.fromJson(Map<String, dynamic> json, GameType type) =>
      GamePerformanceData(
        gameType: type,
        percentile: json['percentile'] as int?,
        bestScore: (json['bestScore'] as int?) ?? 0,
        bestDurationMs: (json['bestDurationMs'] as int?) ?? 0,
        totalGamesPlayed: (json['totalGamesPlayed'] as int?) ?? 0,
        lastPlayedAt: json['lastPlayedAt'] != null
            ? DateTime.tryParse(json['lastPlayedAt'])
            : null,
        geniusTitle: (json['geniusTitle'] as String?) ?? 'Üstün Zekâ',
      );
}

final gameStatsServiceProvider =
    StateNotifierProvider<GameStatsNotifier, Map<GameType, GamePerformanceData>>(
  (ref) => GameStatsNotifier(),
);

class GameStatsNotifier extends StateNotifier<Map<GameType, GamePerformanceData>> {
  static const _prefKey = 'daily_genius_game_stats_v2';

  GameStatsNotifier() : super(_createInitialState()) {
    _loadStats();
  }

  static Map<GameType, GamePerformanceData> _createInitialState() {
    return {
      for (var type in GameType.values)
        type: GamePerformanceData(
          gameType: type,
          percentile: (type == GameType.queens) ? 1 : (type == GameType.pinpoint) ? 2 : null,
          bestScore: (type == GameType.queens) ? 1420 : (type == GameType.pinpoint) ? 1200 : 0,
          bestDurationMs: (type == GameType.queens) ? 38000 : 0,
          totalGamesPlayed: (type == GameType.queens || type == GameType.pinpoint) ? 1 : 0,
          lastPlayedAt: (type == GameType.queens || type == GameType.pinpoint)
              ? DateTime.now().subtract(const Duration(hours: 3))
              : null,
          geniusTitle: 'Saf Dahi',
        ),
    };
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final current = Map<GameType, GamePerformanceData>.from(state);
        for (var type in GameType.values) {
          if (decoded.containsKey(type.id)) {
            current[type] = GamePerformanceData.fromJson(
              decoded[type.id] as Map<String, dynamic>,
              type,
            );
          }
        }
        state = current;
      }
    } catch (_) {}
  }

  Future<void> recordGameResult({
    required GameType gameType,
    required int score,
    required int durationMs,
    required int moveCount,
  }) async {
    // ADHD & Dopamin Odaklı Zeka Yüzdeliği Hesaplama:
    // Kullanıcıyı her zaman yüksek performanslı ve dahi hissettirecek mantık
    int calculatedPercentile;
    String calculatedTitle;

    if (durationMs < 45000 || score >= 900) {
      calculatedPercentile = 1; // Zirve %1
      calculatedTitle = 'Süper İnsan Dahi (IQ 150+)';
    } else if (durationMs < 80000 || score >= 650) {
      calculatedPercentile = 2; // İlk %2
      calculatedTitle = 'Üstün Mantık Dehası';
    } else if (durationMs < 120000) {
      calculatedPercentile = 3; // İlk %3
      calculatedTitle = 'Işık Hızında Zihin';
    } else {
      calculatedPercentile = 5; // İlk %5
      calculatedTitle = 'Stratejik Zeka Ustası';
    }

    final old = state[gameType]!;
    final newBestScore = mathMax(old.bestScore, score);
    final newBestDuration = old.bestDurationMs == 0
        ? durationMs
        : (durationMs < old.bestDurationMs ? durationMs : old.bestDurationMs);

    final updated = GamePerformanceData(
      gameType: gameType,
      percentile: calculatedPercentile,
      bestScore: newBestScore,
      bestDurationMs: newBestDuration,
      totalGamesPlayed: old.totalGamesPlayed + 1,
      lastPlayedAt: DateTime.now(),
      geniusTitle: calculatedTitle,
    );

    final newState = Map<GameType, GamePerformanceData>.from(state);
    newState[gameType] = updated;
    state = newState;

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (var e in newState.entries) e.key.id: e.value.toJson(),
      };
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}
  }

  int mathMax(int a, int b) => a > b ? a : b;

  /// Kullanıcının Genel Beyin Gücü / IQ Endeksi
  int getOverallIQ() {
    int playedCount = state.values.where((e) => e.hasPlayed).length;
    if (playedCount == 0) return 138;
    return 145 + playedCount * 2;
  }
}
