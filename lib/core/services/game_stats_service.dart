import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../games/common/base_game.dart';

/// IQ milestone eşikleri ve karşılaştırma mesajları.
/// Kullanıcı belirli IQ seviyelerine ulaştığında hareketli kutlama gösterilir.
class IQMilestone {
  final int iqThreshold;
  final String title;
  final String message;
  final String emoji;
  final double betterThanPercent;

  const IQMilestone({
    required this.iqThreshold,
    required this.title,
    required this.message,
    required this.emoji,
    required this.betterThanPercent,
  });

  static const List<IQMilestone> all = [
    IQMilestone(
      iqThreshold: 100,
      title: 'Ortalama Zekâ',
      message: 'Dünya ortalamasındasın! Oynadıkça yükseleceksin.',
      emoji: '🧠',
      betterThanPercent: 50,
    ),
    IQMilestone(
      iqThreshold: 108,
      title: 'Ortalamanın Üstü',
      message: 'Diğer oyuncuların %70\'inden daha iyi seviyedesin!',
      emoji: '⭐',
      betterThanPercent: 70,
    ),
    IQMilestone(
      iqThreshold: 115,
      title: 'Parlak Zekâ',
      message: 'Diğer oyuncuların %84\'ünden daha iyi seviyedesin!',
      emoji: '🌟',
      betterThanPercent: 84,
    ),
    IQMilestone(
      iqThreshold: 120,
      title: 'Yüksek Zekâ',
      message: 'Diğer oyuncuların %91\'inden daha iyi seviyedesin! Çoğu insanın ulaşamadığı bir seviye.',
      emoji: '💡',
      betterThanPercent: 91,
    ),
    IQMilestone(
      iqThreshold: 130,
      title: 'Üstün Zekâ',
      message: 'Einstein seviyesine yaklaşıyorsun! Nüfusun %98\'inden üstünsün!',
      emoji: '🚀',
      betterThanPercent: 98,
    ),
    IQMilestone(
      iqThreshold: 140,
      title: 'Dahi Seviyesi',
      message: 'Einstein\'ı geride bıraktın! Dünya nüfusunun %99.6\'sından üstünsün!',
      emoji: '👑',
      betterThanPercent: 99.6,
    ),
    IQMilestone(
      iqThreshold: 145,
      title: 'Eşsiz Deha',
      message: 'Tarihte nadir görülen zekâ seviyesindesin! Her alanda mutlak dominasyon!',
      emoji: '🏆',
      betterThanPercent: 99.9,
    ),
  ];

  /// Verilen IQ değeri için ulaşılan en yüksek milestone'u döner.
  static IQMilestone? currentMilestone(int iq) {
    IQMilestone? best;
    for (final m in all) {
      if (iq >= m.iqThreshold) best = m;
    }
    return best;
  }

  /// Verilen IQ değeri için bir sonraki hedef milestone'u döner.
  static IQMilestone? nextMilestone(int iq) {
    for (final m in all) {
      if (iq < m.iqThreshold) return m;
    }
    return null;
  }
}

class GamePerformanceData {
  final GameType gameType;
  final int? percentile; // 1 = Top %1, 3 = Top %3, vb.
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
      return '🚀 HENÜZ OYNANMADI';
    }
    if (percentile! <= 1) {
      return '🏆 ZİRVE %1\'LİK DİLİM (DAHİ)';
    } else if (percentile! <= 5) {
      return '⚡ İLK %$percentile\'LİK DİLİM (ÜSTÜN ZEKÂ)';
    } else if (percentile! <= 10) {
      return '🎯 İLK %$percentile\'LİK DİLİM (YÜKSEK)';
    } else if (percentile! <= 25) {
      return '📊 İLK %$percentile\'LİK DİLİM';
    } else if (percentile! <= 50) {
      return '📈 ORTALAMA ÜSTÜ';
    } else {
      return '📉 GELİŞMEKTE';
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
        geniusTitle: (json['geniusTitle'] as String?) ?? 'Henüz Belirlenmedi',
      );
}

class GameStatsUpdateResult {
  final int previousIQ;
  final int currentIQ;
  final IQMilestone? milestone;
  final int percentile;
  final String geniusTitle;

  const GameStatsUpdateResult({
    required this.previousIQ,
    required this.currentIQ,
    this.milestone,
    required this.percentile,
    required this.geniusTitle,
  });
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

  /// Temiz başlangıç: hiçbir oyun oynanmamış, sahte veri yok
  static Map<GameType, GamePerformanceData> _createInitialState() {
    return {
      for (var type in GameType.values)
        type: GamePerformanceData(
          gameType: type,
          percentile: null,
          bestScore: 0,
          bestDurationMs: 0,
          totalGamesPlayed: 0,
          lastPlayedAt: null,
          geniusTitle: 'Henüz Belirlenmedi',
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

  Future<GameStatsUpdateResult> recordGameResult({
    required GameType gameType,
    required int score,
    required int durationMs,
    required int moveCount,
  }) async {
    final int previousIQ = getOverallIQ();

    // Gerçekçi Yüzdelik Dilim Hesaplama:
    // Puan kalitesi (score / referans) + hız bonusu birleşik değerlendirmesi
    final double scoreRatio = score / 1100.0;
    final double speedBonus = durationMs < 25000
        ? 0.18
        : durationMs < 45000
            ? 0.12
            : durationMs < 70000
                ? 0.06
                : durationMs < 100000
                    ? 0.02
                    : 0.0;
    final double quality = (scoreRatio + speedBonus).clamp(0.0, 1.5);

    int calculatedPercentile;
    String calculatedTitle;

    if (quality >= 1.0) {
      calculatedPercentile = 1;
      calculatedTitle = 'Olağanüstü Zekâ';
    } else if (quality >= 0.88) {
      calculatedPercentile = 3;
      calculatedTitle = 'Üstün Zekâ';
    } else if (quality >= 0.75) {
      calculatedPercentile = 7;
      calculatedTitle = 'Yüksek Zekâ';
    } else if (quality >= 0.62) {
      calculatedPercentile = 15;
      calculatedTitle = 'Ortalamanın Üstü';
    } else if (quality >= 0.48) {
      calculatedPercentile = 30;
      calculatedTitle = 'Ortalama Seviye';
    } else if (quality >= 0.35) {
      calculatedPercentile = 50;
      calculatedTitle = 'Ortalama';
    } else {
      calculatedPercentile = 65;
      calculatedTitle = 'Gelişmekte';
    }

    final old = state[gameType]!;
    final newBestScore = _mathMax(old.bestScore, score);
    final newBestDuration = old.bestDurationMs == 0
        ? durationMs
        : (durationMs < old.bestDurationMs ? durationMs : old.bestDurationMs);

    // Yüzdelik dilimi sadece iyiye doğru güncelle (en iyi performansı koru)
    final bestPercentile = old.percentile != null
        ? min(calculatedPercentile, old.percentile!)
        : calculatedPercentile;

    // En iyi yüzdelik değiştiyse unvanı da güncelle
    final bestTitle = bestPercentile == calculatedPercentile
        ? calculatedTitle
        : old.geniusTitle;

    final updated = GamePerformanceData(
      gameType: gameType,
      percentile: bestPercentile,
      bestScore: newBestScore,
      bestDurationMs: newBestDuration,
      totalGamesPlayed: old.totalGamesPlayed + 1,
      lastPlayedAt: DateTime.now(),
      geniusTitle: bestTitle,
    );

    final newState = Map<GameType, GamePerformanceData>.from(state);
    newState[gameType] = updated;
    state = newState;

    final int currentIQ = getOverallIQ();
    final IQMilestone? milestone = detectNewMilestone(previousIQ, currentIQ);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (var e in newState.entries) e.key.id: e.value.toJson(),
      };
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}

    return GameStatsUpdateResult(
      previousIQ: previousIQ,
      currentIQ: currentIQ,
      milestone: milestone,
      percentile: bestPercentile,
      geniusTitle: bestTitle,
    );
  }

  int _mathMax(int a, int b) => a > b ? a : b;

  /// Kullanıcının Genel Beyin Gücü / IQ Endeksi.
  /// Oynanmış oyunların yüzdelik dilimlerinden ağırlıklı IQ hesaplar.
  /// Standart IQ dağılımına yakın gerçekçi değerler üretir (100 = popülasyon ortalaması).
  int getOverallIQ() {
    final played = state.values.where((e) => e.hasPlayed).toList();
    if (played.isEmpty) return 100;

    double totalIQ = 0;
    for (final perf in played) {
      final p = perf.percentile!;
      double gameIQ;
      if (p <= 1) {
        gameIQ = 142;
      } else if (p <= 3) {
        gameIQ = 133;
      } else if (p <= 5) {
        gameIQ = 126;
      } else if (p <= 7) {
        gameIQ = 122;
      } else if (p <= 10) {
        gameIQ = 119;
      } else if (p <= 15) {
        gameIQ = 115;
      } else if (p <= 20) {
        gameIQ = 112;
      } else if (p <= 25) {
        gameIQ = 110;
      } else if (p <= 30) {
        gameIQ = 108;
      } else if (p <= 40) {
        gameIQ = 104;
      } else if (p <= 50) {
        gameIQ = 100;
      } else if (p <= 65) {
        gameIQ = 95;
      } else {
        gameIQ = 90;
      }
      totalIQ += gameIQ;
    }

    // Oyun çeşitliliği bonusu: Daha fazla farklı oyun oynayan hafif bonus alır
    final diversityBonus = played.length >= 5
        ? 3.0
        : played.length >= 3
            ? 1.5
            : 0.0;

    return ((totalIQ / played.length) + diversityBonus).round();
  }

  /// Yeni ulaşılan IQ milestone'unu tespit eder.
  /// [previousIQ] kaydedilmeden önceki IQ değeri, [currentIQ] kaydedildikten sonraki IQ.
  /// Eğer yeni bir milestone aşıldıysa o milestone'u döner, yoksa null.
  IQMilestone? detectNewMilestone(int previousIQ, int currentIQ) {
    if (currentIQ <= previousIQ) return null;

    IQMilestone? newMilestone;
    for (final m in IQMilestone.all) {
      if (previousIQ < m.iqThreshold && currentIQ >= m.iqThreshold) {
        newMilestone = m;
      }
    }
    return newMilestone;
  }
}
