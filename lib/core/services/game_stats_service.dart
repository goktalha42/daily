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
      message: 'Dünya standartlarında dengeli bir başlangıç! Diğer oyunları çözdükçe zihnin açılacak.',
      emoji: '🌱',
      betterThanPercent: 50.0,
    ),
    IQMilestone(
      iqThreshold: 110,
      title: 'Keskin Zihin',
      message: 'Ortalamanın üzerindesin! Nüfusun %75\'inden daha hızlı örüntü yakalıyorsun.',
      emoji: '⭐',
      betterThanPercent: 75.0,
    ),
    IQMilestone(
      iqThreshold: 120,
      title: 'Büyük Usta',
      message: 'Yüksek mantık kapasitesi! Nüfusun %90\'ından üstünsün, zorlu bulmacalar sana vız geliyor!',
      emoji: '💡',
      betterThanPercent: 90.0,
    ),
    IQMilestone(
      iqThreshold: 130,
      title: 'Üstün Mantık (Mensa)',
      message: 'Mensa seviyesindesin! Nüfusun %98\'ini geride bıraktın, olağanüstü analitik hız!',
      emoji: '🌟',
      betterThanPercent: 98.0,
    ),
    IQMilestone(
      iqThreshold: 140,
      title: 'Zühtü Dahisi',
      message: 'Gerçek bir problem çözücü! Nüfusun %99.5\'inden üstünsün, zirveye sadece bir adım kaldı!',
      emoji: '🚀',
      betterThanPercent: 99.5,
    ),
    IQMilestone(
      iqThreshold: 148,
      title: 'Einstein Mertebesi',
      message: 'Tarihe geçen eşsiz deha! Nüfusun %99.9\'unun üzerindesin, arenanın efsanevi dâhisi sensin!',
      emoji: '👑',
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

    // Zorlu ve Gerçekçi Tekil Oyun Yüzdelik Dilim Hesaplama:
    // Zirve %1 dilim için hem 1100+ puan hem de 30 saniye altı kusursuz çözüm gerekir!
    int calculatedPercentile;
    String calculatedTitle;

    if (score >= 1100 && durationMs < 30000) {
      calculatedPercentile = 1;
      calculatedTitle = 'Olağanüstü Zekâ';
    } else if (score >= 1050 && durationMs < 45000) {
      calculatedPercentile = 3;
      calculatedTitle = 'Üstün Zekâ';
    } else if (score >= 980 && durationMs < 65000) {
      calculatedPercentile = 7;
      calculatedTitle = 'Yüksek Zekâ';
    } else if (score >= 900 && durationMs < 90000) {
      calculatedPercentile = 15;
      calculatedTitle = 'Keskin Zihin';
    } else if (score >= 800) {
      calculatedPercentile = 30;
      calculatedTitle = 'Ortalama Üstü';
    } else if (score >= 650) {
      calculatedPercentile = 50;
      calculatedTitle = 'Dengeli Zihin';
    } else {
      calculatedPercentile = 70;
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

  /// Kullanıcının Genel Beyin Gücü / Gerçekçi IQ Endeksi.
  /// Psikometrik Güvenilirlik & Çoklu Kategori Ağırlıklı Model:
  /// - 1-2 oyun oynayan bir kullanıcı hemen Einstein veya Mensa olamaz!
  /// - Tam kalibrasyon için farklı oyun kategorilerinin (en az 4-5) oynanması zorunludur.
  /// - Einstein (148+) yalnızca tüm 6 kategoriyi fethetmiş ve 25+ oyun çözmüş elit oyunculara açıktır.
  int getOverallIQ() {
    final played = state.values.where((e) => e.hasPlayed).toList();
    if (played.isEmpty) return 95; // Başlangıç taban kalibrasyonu

    double rawTotal = 0;
    int totalGamesCount = 0;

    for (final perf in played) {
      totalGamesCount += perf.totalGamesPlayed;

      // Puan kalitesi (Referans 1000 puan)
      final double scoreFactor = (perf.bestScore / 1000.0).clamp(0.4, 1.2);

      // Çözüm hızı faktörü
      double speedFactor = 1.0;
      if (perf.bestDurationMs > 0) {
        if (perf.bestDurationMs < 30000) {
          speedFactor = 1.15;
        } else if (perf.bestDurationMs < 60000) {
          speedFactor = 1.06;
        } else if (perf.bestDurationMs < 120000) {
          speedFactor = 0.98;
        } else {
          speedFactor = 0.90;
        }
      }

      // Bu oyun için hesaplanan ham zeka puanı (90 - 140 aralığı)
      final double gameRaw = 90.0 + (scoreFactor * speedFactor * 34.0);
      rawTotal += gameRaw;
    }

    final double averageGameIQ = rawTotal / played.length;

    // 1. Kategori Çeşitliliği Ağırlığı (Confidence / Çeşitlilik Güveni):
    // 1 kategori oynayan: %25 güven (kalan %75 taban 95 puan)
    // 2 kategori: %45 güven
    // 3 kategori: %65 güven
    // 4 kategori: %80 güven
    // 5 kategori: %92 güven
    // 6 kategori: %100 tam güven!
    double confidenceWeight;
    switch (played.length) {
      case 1:
        confidenceWeight = 0.25;
        break;
      case 2:
        confidenceWeight = 0.45;
        break;
      case 3:
        confidenceWeight = 0.65;
        break;
      case 4:
        confidenceWeight = 0.80;
        break;
      case 5:
        confidenceWeight = 0.92;
        break;
      default:
        confidenceWeight = 1.00;
        break;
    }

    // 2. Deneyim ve Tutarlılık Bonusu (Oynadıkça kazanılan ekstra güven puanı)
    final double experienceBonus = (totalGamesCount * 0.45).clamp(0.0, 16.0);

    final double blendedIQ =
        (95.0 * (1.0 - confidenceWeight)) + (averageGameIQ * confidenceWeight) + experienceBonus;

    // 3. ZORLU TAVAN BARİYERLERİ (Hiçbir hileli hızlı başlangıç üst liglere atlayamaz!):
    // - 1 kategori: Tavan 106 (Asla ortalama üstü olamaz)
    // - 2 kategori: Tavan 116 (Parlak Zihin tavanı)
    // - 3 kategori: Tavan 126 (Büyük Usta tavanı)
    // - 4 kategori: Tavan 136 (Üstün Mantık tavanı)
    // - 5 kategori: Tavan 144 (Zühtü Dahisi tavanı)
    // - 6 kategori:
    //    * Eğer toplam oynanan oyun sayısı < 25 ise Tavan 144!
    //    * 25+ oyun çözüldüyse ve ortalama yüksekse 148+ Einstein kapısı açılır!
    double cap;
    if (played.length <= 1) {
      cap = 106.0;
    } else if (played.length == 2) {
      cap = 116.0;
    } else if (played.length == 3) {
      cap = 126.0;
    } else if (played.length == 4) {
      cap = 136.0;
    } else if (played.length == 5) {
      cap = 144.0;
    } else {
      if (totalGamesCount < 25) {
        cap = 144.0;
      } else {
        cap = 160.0;
      }
    }

    return blendedIQ.clamp(90.0, cap).round();
  }

  /// Yeni ulaşılan IQ milestone'unu tespit eder.
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
