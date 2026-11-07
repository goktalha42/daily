import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../games/common/base_game.dart';
import '../utils/date_utils.dart';
import '../widgets/sketch_badge_icons.dart';

/// WAIS-IV Psikometrik Normal Dağılım (Ortalama = 100, Standart Sapma = 15)
/// tabanlı IQ kilometre taşları ve Gauss yüzdelik dilim hesaplayıcısı.
class IQMilestone {
  final int iqThreshold;
  final String title;
  final String message;
  final BadgeArtType artType;
  final double betterThanPercent;

  const IQMilestone({
    required this.iqThreshold,
    required this.title,
    required this.message,
    required this.artType,
    required this.betterThanPercent,
  });

  static const List<IQMilestone> all = [
    IQMilestone(
      iqThreshold: 100,
      title: 'Dengeli Zihin',
      message: 'Dünya ortalamasıyla dengeli bir başlangıç! Farklı kategorileri çözdükçe zihin profilin netleşecek.',
      artType: BadgeArtType.balanceScale,
      betterThanPercent: 50.0,
    ),
    IQMilestone(
      iqThreshold: 110,
      title: 'Keskin Zihin',
      message: 'Ortalamanın belirgin şekilde üzerindesin! Nüfusun %75\'inden daha hızlı örüntü yakalıyorsun.',
      artType: BadgeArtType.sharpStar,
      betterThanPercent: 74.8,
    ),
    IQMilestone(
      iqThreshold: 120,
      title: 'Büyük Usta',
      message: 'Üstün analitik kapasite! Nüfusun %91\'ini geride bıraktın, karmaşık bulmacalarda ustalaşıyorsun.',
      artType: BadgeArtType.lightbulb,
      betterThanPercent: 90.9,
    ),
    IQMilestone(
      iqThreshold: 130,
      title: 'Üstün Mantık (Mensa)',
      message: 'Mensa kabul barajındasın (+2σ)! Nüfusun %97.7\'sinden daha keskin bir muhakeme gücün var.',
      artType: BadgeArtType.mensaCrest,
      betterThanPercent: 97.7,
    ),
    IQMilestone(
      iqThreshold: 140,
      title: 'Zühtü Dahisi',
      message: 'Nadir görülen bilişsel hız! Nüfusun %99.6\'sından üstünsün, efsanevi Einstein zirvesine çok yakınsın!',
      artType: BadgeArtType.zuhtuGenius,
      betterThanPercent: 99.6,
    ),
    IQMilestone(
      iqThreshold: 148,
      title: 'Einstein Mertebesi',
      message: 'Binde birlik tarihsel deha (+3.2σ)! 6 bilişsel alanın tamamında mutlak ve istikrarlı zirvedesin!',
      artType: BadgeArtType.einsteinBrain,
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

  /// Standart Gauss Normal Dağılımı N(100, 15²) üzerinden verilen IQ puanının
  /// nüfusun yüzde kaçından daha yüksek olduğunu [1.0 .. 99.95] aralığında hesaplar.
  static double gaussianBetterThanPercent(int iq) {
    final double z = (iq - 100.0) / 15.0;
    final double cdf = 0.5 * (1.0 + _erf(z / math.sqrt2));
    return (cdf * 100.0).clamp(1.0, 99.95);
  }

  /// Kullanıcının üstten yüzde kaçlık dilimde olduğunu döner (Örn: 148 IQ -> 0.07 -> İlk %0.1).
  static double gaussianTopPercent(int iq) {
    return (100.0 - gaussianBetterThanPercent(iq)).clamp(0.05, 99.0);
  }

  /// Abramowitz & Stegun hata fonksiyonu (erf) yaklaşımı (maksimum hata < 1.5e-7).
  static double _erf(double x) {
    final double sign = x < 0 ? -1.0 : 1.0;
    final double ax = x.abs();
    const double p = 0.3275911;
    const double a1 = 0.254829592;
    const double a2 = -0.284496736;
    const double a3 = 1.421413741;
    const double a4 = -1.453152027;
    const double a5 = 1.061405429;

    final double t = 1.0 / (1.0 + p * ax);
    final double y = 1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
    return sign * y;
  }
}

/// Her bir oyun kategorisinin bilişsel alan etiketi
extension GameCognitiveDomainExt on GameType {
  String get cognitiveDomainLabel {
    switch (this) {
      case GameType.queens:
        return 'Çıkarımsal Mantık';
      case GameType.pinpoint:
        return 'Kavramsal Çağrışım';
      case GameType.crossclimb:
        return 'Sözel Akıcılık';
      case GameType.tango:
        return 'İkili Örüntü';
      case GameType.zipPath:
        return 'Uzamsal Planlama';
      case GameType.patches:
        return 'Geometrik Muhakeme';
    }
  }

  String get shortDomainLabel {
    switch (this) {
      case GameType.queens:
        return 'Mantık';
      case GameType.pinpoint:
        return 'Çağrışım';
      case GameType.crossclimb:
        return 'Sözel';
      case GameType.tango:
        return 'Örüntü';
      case GameType.zipPath:
        return 'Uzamsal';
      case GameType.patches:
        return 'Geometri';
    }
  }
}

class GamePerformanceData {
  final GameType gameType;
  final int? percentile; // 1 = İlk %1, 5 = İlk %5, vb.
  final int bestScore;
  final int bestDurationMs;
  final int totalGamesPlayed;
  final double effectiveGamesPlayed;
  final DateTime? lastPlayedAt;
  final String geniusTitle;
  final double emaZScore;
  final double peakZScore;
  final String? lastCountedDateId;
  final double preDayEmaZScore;
  final double dayBestZScore;

  GamePerformanceData({
    required this.gameType,
    this.percentile,
    required this.bestScore,
    required this.bestDurationMs,
    required this.totalGamesPlayed,
    double? effectiveGamesPlayed,
    this.lastPlayedAt,
    required this.geniusTitle,
    this.emaZScore = 0.0,
    this.peakZScore = 0.0,
    this.lastCountedDateId,
    this.preDayEmaZScore = 0.0,
    this.dayBestZScore = 0.0,
  }) : effectiveGamesPlayed = effectiveGamesPlayed ?? totalGamesPlayed.toDouble();

  bool get hasPlayed => percentile != null && (totalGamesPlayed > 0 || effectiveGamesPlayed > 0);

  /// İstikrar (%72 EMA) ve Kişisel Zirve (%28 Peak) birleşimi efektif Z-skoru.
  /// Böylece tek şanslı oyunla kalıcı yüksek IQ kazanılamaz ve kötü oyunlar ortalamayı düşürebilir.
  double get effectiveZScore => (0.72 * emaZScore) + (0.28 * peakZScore);

  /// Alt-test Bayesyen güvenilirlik katsayısı: c(n) = 1 - exp(-n / 2.6)
  /// Geçmiş gün oyunları n değerini 0.10 artırır; gününde oynanan oyunlar tam 1.0 artırır.
  double get credibility =>
      hasPlayed ? (1.0 - math.exp(-effectiveGamesPlayed / 2.6)).clamp(0.0, 1.0) : 0.0;

  /// Bu bilişsel alandaki kalibre edilmiş alt-IQ skoru (82 .. 153)
  int get domainIQ {
    if (!hasPlayed) return 100;
    return (100.0 + 15.0 * effectiveZScore * credibility).clamp(82.0, 153.0).round();
  }

  String get percentileBadgeText {
    if (!hasPlayed) {
      return 'HENÜZ OYNANMADI';
    }
    if (percentile! <= 1) {
      return 'ZİRVE %1\'LİK DİLİM';
    } else if (percentile! <= 5) {
      return 'İLK %$percentile\'LİK DİLİM';
    } else if (percentile! <= 15) {
      return 'İLK %$percentile\'LİK DİLİM';
    } else if (percentile! <= 35) {
      return 'İLK %$percentile\'LİK DİLİM';
    } else if (percentile! <= 55) {
      return 'DENGELİ PERFORMANS';
    } else {
      return 'GELİŞMEKTE';
    }
  }

  GamePerformanceData copyWith({
    int? percentile,
    int? bestScore,
    int? bestDurationMs,
    int? totalGamesPlayed,
    double? effectiveGamesPlayed,
    DateTime? lastPlayedAt,
    String? geniusTitle,
    double? emaZScore,
    double? peakZScore,
    String? lastCountedDateId,
    double? preDayEmaZScore,
    double? dayBestZScore,
  }) {
    return GamePerformanceData(
      gameType: gameType,
      percentile: percentile ?? this.percentile,
      bestScore: bestScore ?? this.bestScore,
      bestDurationMs: bestDurationMs ?? this.bestDurationMs,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      effectiveGamesPlayed: effectiveGamesPlayed ?? this.effectiveGamesPlayed,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      geniusTitle: geniusTitle ?? this.geniusTitle,
      emaZScore: emaZScore ?? this.emaZScore,
      peakZScore: peakZScore ?? this.peakZScore,
      lastCountedDateId: lastCountedDateId ?? this.lastCountedDateId,
      preDayEmaZScore: preDayEmaZScore ?? this.preDayEmaZScore,
      dayBestZScore: dayBestZScore ?? this.dayBestZScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameType': gameType.id,
        'percentile': percentile,
        'bestScore': bestScore,
        'bestDurationMs': bestDurationMs,
        'totalGamesPlayed': totalGamesPlayed,
        'effectiveGamesPlayed': effectiveGamesPlayed,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'geniusTitle': geniusTitle,
        'emaZScore': emaZScore,
        'peakZScore': peakZScore,
        if (lastCountedDateId != null) 'lastCountedDateId': lastCountedDateId,
        'preDayEmaZScore': preDayEmaZScore,
        'dayBestZScore': dayBestZScore,
      };

  factory GamePerformanceData.fromJson(Map<String, dynamic> json, GameType type) {
    final bestScore = (json['bestScore'] as int?) ?? 0;
    final bestDurationMs = (json['bestDurationMs'] as int?) ?? 0;
    final totalPlayed = (json['totalGamesPlayed'] as int?) ?? 0;
    final effectivePlayed =
        (json['effectiveGamesPlayed'] as num?)?.toDouble() ?? totalPlayed.toDouble();

    // Eski kayıtlarda emaZScore yoksa mevcut bestScore/bestDuration üzerinden gerçekçi tahmini Z üret
    final double fallbackZ = totalPlayed > 0
        ? PsychometricIQCalculator.evaluateSingleSolveZ(
            gameType: type,
            score: bestScore,
            durationMs: bestDurationMs > 0 ? bestDurationMs : 60000,
          )
        : 0.0;

    final resolvedEma = (json['emaZScore'] as num?)?.toDouble() ?? fallbackZ;
    final resolvedPeak = (json['peakZScore'] as num?)?.toDouble() ?? fallbackZ;

    return GamePerformanceData(
      gameType: type,
      percentile: json['percentile'] as int?,
      bestScore: bestScore,
      bestDurationMs: bestDurationMs,
      totalGamesPlayed: totalPlayed,
      effectiveGamesPlayed: effectivePlayed,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'])
          : null,
      geniusTitle: (json['geniusTitle'] as String?) ?? 'Henüz Belirlenmedi',
      emaZScore: resolvedEma,
      peakZScore: resolvedPeak,
      lastCountedDateId: json['lastCountedDateId'] as String?,
      preDayEmaZScore: (json['preDayEmaZScore'] as num?)?.toDouble() ?? resolvedEma,
      dayBestZScore: (json['dayBestZScore'] as num?)?.toDouble() ?? resolvedEma,
    );
  }
}

class GameStatsUpdateResult {
  final int previousIQ;
  final int currentIQ;
  final IQMilestone? milestone;
  final int percentile; // Bu tekil oyundaki yüzdelik dilim (1..90)
  final String geniusTitle;

  const GameStatsUpdateResult({
    required this.previousIQ,
    required this.currentIQ,
    this.milestone,
    required this.percentile,
    required this.geniusTitle,
  });

  int get iqDelta => currentIQ - previousIQ;
}

/// Her oyunun kendi puan tabanına (2000 tabanlı standart oyunlar ve 900/1200/1350 Vezirler)
/// ve ideal çözüm sürelerine göre psikometrik Z-skoru hesaplayıcısı.
class PsychometricIQCalculator {
  PsychometricIQCalculator._();

  /// Tek bir oyun çözümünü [0.0 .. 1.0] normalize performansa ve ardından [-1.20 .. +3.55] Z-skoruna çevirir.
  static double evaluateSingleSolveZ({
    required GameType gameType,
    required int score,
    required int durationMs,
    String? difficulty,
  }) {
    final double perf = evaluateNormalizedPerformance(
      gameType: gameType,
      score: score,
      durationMs: durationMs,
      difficulty: difficulty,
    );
    return _performanceToZScore(perf);
  }

  static double evaluateNormalizedPerformance({
    required GameType gameType,
    required int score,
    required int durationMs,
    String? difficulty,
  }) {
    double scoreNorm;
    double speedNorm;
    double domainCeiling = 1.0;

    switch (gameType) {
      case GameType.queens:
        final diff = difficulty?.toLowerCase();
        if (diff == 'easy' || diff == 'kolay') {
          // 6x6 Kolay Vezirler (max 900): tek başına Einstein seviyesi vermez, tavan 0.78
          scoreNorm = ((score - 450.0) / (870.0 - 450.0)).clamp(0.0, 1.0);
          speedNorm = _normalizeSpeed(durationMs, eliteMs: 14000, medianMs: 38000, slowMs: 100000);
          domainCeiling = 0.78;
        } else if (diff == 'master') {
          // 9x9 Çift Vezirli Master (max 1350): en yüksek bilişsel ağırlık
          scoreNorm = ((score - 700.0) / (1280.0 - 700.0)).clamp(0.0, 1.0);
          speedNorm = _normalizeSpeed(durationMs, eliteMs: 38000, medianMs: 105000, slowMs: 240000);
        } else if (diff == 'hard' || diff == 'zor') {
          // 8x8 Zor Vezirler (max 1200)
          scoreNorm = ((score - 600.0) / (1150.0 - 600.0)).clamp(0.0, 1.0);
          speedNorm = _normalizeSpeed(durationMs, eliteMs: 22000, medianMs: 65000, slowMs: 160000);
        } else {
          // Zorluk belirtilmemişse puana göre ölçekle (1200 veya 2000 taban uyumu)
          if (score > 1350) {
            scoreNorm = ((score - 600.0) / (1840.0 - 600.0)).clamp(0.0, 1.0);
          } else {
            scoreNorm = ((score - 550.0) / (1150.0 - 550.0)).clamp(0.0, 1.0);
          }
          speedNorm = _normalizeSpeed(durationMs, eliteMs: 22000, medianMs: 65000, slowMs: 160000);
        }
        break;

      case GameType.pinpoint:
        // 2000 tabanlı: 1. ipucu ~1925, 2. ipucu ~1650, 3. ipucu ~1325
        scoreNorm = ((score - 550.0) / (1850.0 - 550.0)).clamp(0.0, 1.0);
        speedNorm = _normalizeSpeed(durationMs, eliteMs: 18000, medianMs: 50000, slowMs: 130000);
        break;

      case GameType.crossclimb:
        // 2000 - sn*6 - hata*50
        scoreNorm = ((score - 650.0) / (1830.0 - 650.0)).clamp(0.0, 1.0);
        speedNorm = _normalizeSpeed(durationMs, eliteMs: 25000, medianMs: 75000, slowMs: 180000);
        break;

      case GameType.tango:
        // 2000 - sn*10 - fazlaHamle*4
        scoreNorm = ((score - 500.0) / (1810.0 - 500.0)).clamp(0.0, 1.0);
        speedNorm = _normalizeSpeed(durationMs, eliteMs: 19000, medianMs: 58000, slowMs: 145000);
        break;

      case GameType.zipPath:
        // 2000 - sn*10
        scoreNorm = ((score - 550.0) / (1830.0 - 550.0)).clamp(0.0, 1.0);
        speedNorm = _normalizeSpeed(durationMs, eliteMs: 17000, medianMs: 48000, slowMs: 125000);
        break;

      case GameType.patches:
        // 2000 - sn*10 - fazlaHamle*5
        scoreNorm = ((score - 500.0) / (1810.0 - 500.0)).clamp(0.0, 1.0);
        speedNorm = _normalizeSpeed(durationMs, eliteMs: 19000, medianMs: 58000, slowMs: 145000);
        break;
    }

    final double rawPerf = (0.60 * scoreNorm) + (0.40 * speedNorm);
    return rawPerf.clamp(0.0, domainCeiling);
  }

  /// Çözüm süresini elit / medyan / yavaş eşiklerine göre [0.0 .. 1.0] aralığına haritalar.
  static double _normalizeSpeed(
    int durationMs, {
    required int eliteMs,
    required int medianMs,
    required int slowMs,
  }) {
    if (durationMs <= 0) return 0.45;
    if (durationMs <= eliteMs) {
      // Elit eşiğinden de hızlıysa 0.94 -> 1.00 arası ince ödül
      final ratio = (durationMs / eliteMs).clamp(0.3, 1.0);
      return (1.0 - (ratio - 0.3) * 0.085).clamp(0.94, 1.0);
    }
    if (durationMs <= medianMs) {
      // eliteMs -> 0.94, medianMs -> 0.45
      final t = (durationMs - eliteMs) / (medianMs - eliteMs);
      return 0.94 - (t * 0.49);
    }
    if (durationMs <= slowMs) {
      // medianMs -> 0.45, slowMs -> 0.10
      final t = (durationMs - medianMs) / (slowMs - medianMs);
      return 0.45 - (t * 0.35);
    }
    return 0.06;
  }

  /// Normalize performansı [0..1] konveks üst kuyruklu psikometrik Z-skoruna [-1.20 .. +3.55] dönüştürür.
  /// p = 0.45 -> z = 0.0 (100 IQ medyan)
  /// p = 0.72 -> z = +1.33 (120 IQ)
  /// p = 0.83 -> z = +2.09 (131 IQ Mensa)
  /// p = 0.97 -> z = +3.26 (149 IQ Einstein düzeyi)
  /// p = 1.00 -> z = +3.55 (153 IQ mutlak tavan)
  static double _performanceToZScore(double p) {
    final clamped = p.clamp(0.0, 1.0);
    if (clamped <= 0.45) {
      return -1.20 + (clamped / 0.45) * 1.20;
    }
    final double u = (clamped - 0.45) / 0.55;
    return (2.10 * u) + (1.45 * math.pow(u, 2.2));
  }

  /// Z-skorunu tekil oyun yüzdelik dilimine (1 = İlk %1 .. 85 = İlk %85) çevirir.
  static int zScoreToSolvePercentile(double z) {
    final double cdf = 0.5 * (1.0 + IQMilestone._erf(z / math.sqrt2));
    final double topPercent = (1.0 - cdf) * 100.0;
    return topPercent.round().clamp(1, 90);
  }

  /// Kullanıcının kalibre edilmiş genel IQ puanına göre tutarlı unvan üretir.
  static String titleForIQ(int iq, {required int playedCategories}) {
    if (playedCategories == 0) return 'Kalibrasyon Bekliyor';
    if (iq >= 148) return 'Einstein Mertebesi';
    if (iq >= 140) return 'Zühtü Dahisi';
    if (iq >= 130) return 'Üstün Mantık (Mensa)';
    if (iq >= 120) return 'Büyük Usta';
    if (iq >= 110) return 'Keskin Zihin';
    if (iq >= 100) return 'Dengeli Zihin';
    return 'Gelişen Zihin';
  }
}

final gameStatsServiceProvider =
    StateNotifierProvider<GameStatsNotifier, Map<GameType, GamePerformanceData>>(
  (ref) => GameStatsNotifier(),
);

class GameStatsNotifier extends StateNotifier<Map<GameType, GamePerformanceData>> {
  static const _prefKey = 'daily_genius_game_stats_v3';
  static const _legacyPrefKey = 'daily_genius_game_stats_v2';
  static const _dailyPlayPrefKey = 'zuhtu_daily_play_records_v1';
  static const _queensCountMigrationKey = 'daily_genius_queens_1perday_v1';

  late final Future<void> _initFuture;

  GameStatsNotifier() : super(_createInitialState()) {
    _initFuture = _loadStats();
  }

  /// İlk açılışta diskteki istatistiklerin ve Vezirler migrasyonunun yüklenmesini bekler.
  Future<void> ensureLoaded() => _initFuture;

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
          emaZScore: 0.0,
          peakZScore: 0.0,
        ),
    };
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey) ?? prefs.getString(_legacyPrefKey);
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

        // Tek seferlik Vezirler oyun adedi uzlaştırması:
        // Vezirler'de aynı gün çözülen 3 ayrı zorluk seviyesi geçmişte 3 ayrı oyun sayıldığı için
        // (toplamda 8 oyun gibi görünmesi), günlük oyun kayıtlarındaki benzersiz gün sayısıyla eşitlenir.
        final bool migrated = prefs.getBool(_queensCountMigrationKey) ?? false;
        bool needsSave = false;
        if (!migrated) {
          final dailyRaw = prefs.getString(_dailyPlayPrefKey);
          final queensPerf = current[GameType.queens];
          if (dailyRaw != null && queensPerf != null && queensPerf.hasPlayed) {
            final dailyDecoded = jsonDecode(dailyRaw) as Map<String, dynamic>;
            final distinctQueensDates = <String>{};
            String? latestDateId;

            dailyDecoded.forEach((_, val) {
              if (val is Map<String, dynamic> && val['gameType'] == GameType.queens.id) {
                final dId = val['dateId'] as String?;
                if (dId != null && dId.isNotEmpty) {
                  distinctQueensDates.add(dId);
                  if (latestDateId == null || dId.compareTo(latestDateId!) > 0) {
                    latestDateId = dId;
                  }
                }
              }
            });

            if (distinctQueensDates.isNotEmpty) {
              current[GameType.queens] = queensPerf.copyWith(
                totalGamesPlayed: distinctQueensDates.length,
                lastCountedDateId: queensPerf.lastCountedDateId ?? latestDateId,
                dayBestZScore: queensPerf.emaZScore,
                preDayEmaZScore: queensPerf.emaZScore,
              );
              needsSave = true;
            }
          }
          await prefs.setBool(_queensCountMigrationKey, true);
        }

        state = current;

        if (needsSave) {
          final mapToSave = {
            for (var e in current.entries) e.key.id: e.value.toJson(),
          };
          await prefs.setString(_prefKey, jsonEncode(mapToSave));
        }
      }
    } catch (_) {}
  }

  Future<GameStatsUpdateResult> recordGameResult({
    required GameType gameType,
    required int score,
    required int durationMs,
    required int moveCount,
    String? difficulty,
    String? dateId,
    bool? isArchivePlay,
  }) async {
    await _initFuture;
    final int previousIQ = getOverallIQ();
    final bool hasExplicitDate = dateId != null && dateId.isNotEmpty;
    final bool isArchive = isArchivePlay ??
        (hasExplicitDate && dateId != GameDateUtils.getTodayLevelId());

    // 1. Bu tekil çözümün gerçekçi psikometrik Z-skoru ve yüzdelik dilimi
    final double solveZ = PsychometricIQCalculator.evaluateSingleSolveZ(
      gameType: gameType,
      score: score,
      durationMs: durationMs,
      difficulty: difficulty,
    );
    final int solvePercentile = PsychometricIQCalculator.zScoreToSolvePercentile(solveZ);

    final old = state[gameType]!;
    final bool isFirstPlayEver = old.totalGamesPlayed == 0 && old.effectiveGamesPlayed == 0;

    double updatedEmaZ;
    double updatedPeakZ;
    double updatedEffectivePlayed;
    int updatedTotalPlayed;
    int newBestScore;
    double preDayEma;
    double dayBestZ;

    if (isArchive) {
      // GEÇMİŞ OYUN KURALI:
      // Geçmiş oyunlar kullanıcıya oyun puanı kazandırmaz (newBestScore değişmez)
      // ve IQ kartlarına normal etkinin tam yüzde 10'u (%10 / 0.10) oranında etki eder.
      preDayEma = old.emaZScore;
      dayBestZ = solveZ;

      if (isFirstPlayEver) {
        updatedEmaZ = 0.10 * solveZ;
        updatedPeakZ = 0.10 * solveZ;
        updatedEffectivePlayed = 0.10;
        updatedTotalPlayed = 1;
      } else {
        final double normalEmaDelta = 0.32 * (solveZ - old.emaZScore);
        updatedEmaZ = old.emaZScore + (0.10 * normalEmaDelta);

        final double normalPeakDelta = math.max(0.0, solveZ - old.peakZScore);
        updatedPeakZ = old.peakZScore + (0.10 * normalPeakDelta);

        updatedEffectivePlayed = old.effectiveGamesPlayed + 0.10;
        updatedTotalPlayed = old.totalGamesPlayed + 1;
      }

      // Geçmiş oyunda oyuncu lig/sıralama puanı kazanmadığı için bestScore eski skorda kalır
      newBestScore = old.bestScore;
    } else {
      // GÜNÜN OYUNU KURALI (Normal tam etki):
      final bool isSameDayRepeat =
          !isFirstPlayEver && hasExplicitDate && old.lastCountedDateId == dateId;

      updatedTotalPlayed =
          isSameDayRepeat ? old.totalGamesPlayed : (old.totalGamesPlayed + 1);
      updatedEffectivePlayed =
          old.effectiveGamesPlayed + (isSameDayRepeat ? 0.0 : 1.0);

      preDayEma = isSameDayRepeat ? old.preDayEmaZScore : old.emaZScore;
      dayBestZ = isSameDayRepeat
          ? math.max(old.dayBestZScore, solveZ)
          : solveZ;

      updatedEmaZ = (updatedTotalPlayed <= 1)
          ? dayBestZ
          : (0.68 * preDayEma) + (0.32 * dayBestZ);
      updatedPeakZ = isFirstPlayEver
          ? solveZ
          : math.max(old.peakZScore, solveZ);

      newBestScore = math.max(old.bestScore, score);
    }

    final int newBestDuration = old.bestDurationMs == 0
        ? durationMs
        : (durationMs > 0 && durationMs < old.bestDurationMs ? durationMs : old.bestDurationMs);

    // Kategori kartında gösterilen yüzdelik dilim efektif Z-skorundan türetilir
    final double tempEffectiveZ = (0.72 * updatedEmaZ) + (0.28 * updatedPeakZ);
    final int categoryPercentile = PsychometricIQCalculator.zScoreToSolvePercentile(tempEffectiveZ);

    final updated = GamePerformanceData(
      gameType: gameType,
      percentile: categoryPercentile,
      bestScore: newBestScore,
      bestDurationMs: newBestDuration,
      totalGamesPlayed: updatedTotalPlayed,
      effectiveGamesPlayed: updatedEffectivePlayed,
      lastPlayedAt: DateTime.now(),
      geniusTitle: _domainTitleForZ(tempEffectiveZ),
      emaZScore: updatedEmaZ,
      peakZScore: updatedPeakZ,
      lastCountedDateId: hasExplicitDate ? dateId : old.lastCountedDateId,
      preDayEmaZScore: preDayEma,
      dayBestZScore: dayBestZ,
    );

    final newState = Map<GameType, GamePerformanceData>.from(state);
    newState[gameType] = updated;
    state = newState;

    final int currentIQ = getOverallIQ();
    final int playedCategories = newState.values.where((e) => e.hasPlayed).length;
    final String overallTitle = PsychometricIQCalculator.titleForIQ(
      currentIQ,
      playedCategories: playedCategories,
    );
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
      percentile: solvePercentile,
      geniusTitle: overallTitle,
    );
  }

  static String _domainTitleForZ(double z) {
    if (z >= 3.0) return 'Efsanevi Usta';
    if (z >= 2.0) return 'Üstün Zekâ';
    if (z >= 1.2) return 'Büyük Usta';
    if (z >= 0.5) return 'Keskin Zihin';
    if (z >= -0.2) return 'Dengeli Zihin';
    return 'Gelişmekte';
  }

  /// Kullanıcının Genel Beyin Gücü / WAIS-IV Çoklu Alan Bayesyen IQ Endeksi.
  ///
  /// Temel İlkeler:
  /// 1. Başlangıç (0 oyun) tabanı tam dünya ortalaması olan **100 IQ**'dur.
  /// 2. 6 bilişsel alanın her biri toplam zekâya 1/6 oranında katılır; henüz oynanmamış
  ///    alanlar Bayesyen önsel (prior = 100 IQ, z = 0) olarak kalır.
  /// 3. Her alanın güvenilirliği oynama sayısıyla asimptotik artar: c(n) = 1 - exp(-n / 2.8).
  ///    - 1 oyun sonunda en kusursuz dünya rekoru bile IQ'yu yalnızca 100 -> 103 (+3) taşır.
  ///    - 2 oyunda maksimum ~105 IQ, ilk gün 6/6 kusursuz oyunda maksimum ~116 IQ görülür.
  ///    - Sadece bol oyun oynamak (düşük/orta performansla grind yapmak) ASLA bedava IQ vermez!
  /// 4. **Einstein Mertebesi (148+ IQ, İlk %0.07):**
  ///    - 6 kategorinin tamamının oynanmış olması,
  ///    - Her kategoride en az 5'er oyun (toplamda en az 35+ oyun) tamamlanmış olması,
  ///    - Ve tüm 6 alanda ~%99.9'luk kusursuz hız/doğruluk istikrarının korunması şarttır!
  int getOverallIQ() {
    final played = state.values.where((e) => e.hasPlayed).toList();
    if (played.isEmpty) return 100;

    double weightedZSum = 0.0;
    int totalGamesCount = 0;
    int minPlaysInAnyCategory = 999999;

    for (final type in GameType.values) {
      final perf = state[type];
      if (perf == null || !perf.hasPlayed) {
        minPlaysInAnyCategory = 0;
        continue;
      }
      totalGamesCount += perf.effectiveGamesPlayed.round();
      if (perf.effectiveGamesPlayed < minPlaysInAnyCategory) {
        minPlaysInAnyCategory = perf.effectiveGamesPlayed.floor();
      }
      weightedZSum += perf.effectiveZScore * perf.credibility;
    }

    final double meanCredibleZ = weightedZSum / GameType.values.length;
    double rawIQ = 100.0 + (15.0 * meanCredibleZ);

    // Katı Einstein Kriteri Kilidi (148+ IQ):
    // 6/6 kategori, her kategoride en az 5 oyun ve toplamda 35+ oyun olmadan 147 tavanı aşılamaz.
    final bool eligibleForEinstein =
        played.length == GameType.values.length &&
        minPlaysInAnyCategory >= 5 &&
        totalGamesCount >= 35;

    if (!eligibleForEinstein && rawIQ >= 147.5) {
      rawIQ = 147.0;
    }

    return rawIQ.clamp(82.0, 155.0).round();
  }

  /// Kalibrasyon güven yüzdesi (0.0 .. 1.0): 6 kategorideki Bayesyen güvenilirlik ortalaması.
  double getCalibrationConfidence() {
    double sum = 0.0;
    for (final type in GameType.values) {
      final perf = state[type];
      if (perf != null && perf.hasPlayed) {
        sum += perf.credibility;
      }
    }
    return (sum / GameType.values.length).clamp(0.0, 1.0);
  }

  /// Yeni ulaşılan IQ milestone'unu tespit eder (100 başlangıç tabanı hariç, gerçek seviye atlamaları).
  IQMilestone? detectNewMilestone(int previousIQ, int currentIQ) {
    if (currentIQ <= previousIQ) return null;

    IQMilestone? newMilestone;
    for (final m in IQMilestone.all) {
      if (m.iqThreshold <= 100) continue; // 100 başlangıç ortalamasıdır, kutlama eşiği 110+
      if (previousIQ < m.iqThreshold && currentIQ >= m.iqThreshold) {
        newMilestone = m;
      }
    }
    return newMilestone;
  }

  /// Bulut yedekleme için tüm bilişsel alan ve WAIS-IV IQ istatistiklerini JSON haritası olarak döner.
  Map<String, dynamic> exportBackupMap() {
    return {
      for (final e in state.entries) e.key.id: e.value.toJson(),
    };
  }

  /// Buluttan veya yedek anahtarından gelen IQ ve performans istatistiklerini geri yükler.
  Future<void> restoreFromBackupMap(
    Map<String, dynamic> decoded, {
    bool merge = true,
  }) async {
    await _initFuture;
    final updated = Map<GameType, GamePerformanceData>.from(state);

    for (final type in GameType.values) {
      final rawItem = decoded[type.id];
      if (rawItem is Map<String, dynamic>) {
        final incoming = GamePerformanceData.fromJson(rawItem, type);
        final existing = updated[type];
        if (!merge ||
            existing == null ||
            !existing.hasPlayed ||
            incoming.totalGamesPlayed >= existing.totalGamesPlayed ||
            incoming.bestScore > existing.bestScore) {
          if (incoming.hasPlayed) {
            updated[type] = incoming;
          }
        }
      }
    }

    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (final e in updated.entries) e.key.id: e.value.toJson(),
      };
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}
  }
}
