import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../games/common/base_game.dart';
import '../utils/date_utils.dart';

class DailyPlayRecord {
  final GameType gameType;
  final String dateId;
  final int score;
  final int durationMs;
  final DateTime completedAt;
  final String? subKey;
  final bool isArchivePlay;

  const DailyPlayRecord({
    required this.gameType,
    required this.dateId,
    required this.score,
    required this.durationMs,
    required this.completedAt,
    this.subKey,
    this.isArchivePlay = false,
  });

  Map<String, dynamic> toJson() => {
        'gameType': gameType.id,
        'dateId': dateId,
        'score': score,
        'durationMs': durationMs,
        'completedAt': completedAt.toIso8601String(),
        if (subKey != null) 'subKey': subKey,
        if (isArchivePlay) 'isArchivePlay': true,
      };

  factory DailyPlayRecord.fromJson(Map<String, dynamic> json) => DailyPlayRecord(
        gameType: GameType.values.firstWhere(
          (g) => g.id == json['gameType'],
          orElse: () => GameType.queens,
        ),
        dateId: json['dateId'] as String,
        score: json['score'] as int,
        durationMs: json['durationMs'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        subKey: json['subKey'] as String?,
        isArchivePlay: json['isArchivePlay'] == true,
      );
}

class DailyPlayState {
  /// Anahtar: "$gameId|$dateId" veya "$gameId:$subKey|$dateId" -> Örn: "queens:kolay|2026-10-08"
  final Map<String, DailyPlayRecord> records;

  const DailyPlayState({this.records = const {}});

  static String makeKey(GameType game, String dateId, [String? subKey]) {
    if (subKey != null && subKey.isNotEmpty) {
      return '${game.id}:$subKey|$dateId';
    }
    return '${game.id}|$dateId';
  }

  /// Belirli bir oyunun [dateId] tarihinde tamamlanıp tamamlanmadığını kontrol eder.
  /// [subKey] verilmezse (örn. Vezirler genel kartı), ilgili tarihte en az 1 bölüm
  /// dahi oynanmışsa oyun o gün için tamamlanmış (1 oyun) kabul edilir.
  bool isCompleted(GameType game, String dateId, {String? subKey}) {
    if (subKey != null && subKey.isNotEmpty) {
      return records.containsKey(makeKey(game, dateId, subKey));
    }
    if (records.containsKey(makeKey(game, dateId))) {
      return true;
    }
    for (final r in records.values) {
      if (r.gameType == game && r.dateId == dateId) {
        return true;
      }
    }
    return false;
  }

  /// [subKey] verilmezse ve alt bölümler (örn. Vezirler Kolay/Zor/Master) mevcutsa,
  /// o güne ait toplam puanı ve en son tamamlanma bilgisini tek bir oyun kaydı olarak döner.
  DailyPlayRecord? getRecord(GameType game, String dateId, {String? subKey}) {
    if (subKey != null && subKey.isNotEmpty) {
      return records[makeKey(game, dateId, subKey)];
    }

    final subRecords = records.entries
        .where((e) =>
            e.key.startsWith('${game.id}:') &&
            e.value.gameType == game &&
            e.value.dateId == dateId)
        .map((e) => e.value)
        .toList();

    if (subRecords.isNotEmpty) {
      int totalScore = 0;
      int totalDurationMs = 0;
      DateTime latestCompleted = subRecords.first.completedAt;
      for (final r in subRecords) {
        totalScore += r.score;
        totalDurationMs += r.durationMs;
        if (r.completedAt.isAfter(latestCompleted)) {
          latestCompleted = r.completedAt;
        }
      }
      return DailyPlayRecord(
        gameType: game,
        dateId: dateId,
        score: totalScore,
        durationMs: totalDurationMs,
        completedAt: latestCompleted,
      );
    }

    return records[makeKey(game, dateId)];
  }

  /// Verilen tarihte kaç farklı oyunun tamamlandığını döner (Maksimum 6).
  /// Vezirler'de 1 bölüm de oynansa, 3 bölüm de oynansa 1 oyun olarak sayılır.
  int getCompletedCountForDate(String dateId) {
    final completedGames = <GameType>{};
    for (final r in records.values) {
      if (r.dateId == dateId) {
        completedGames.add(r.gameType);
      }
    }
    return completedGames.length;
  }

  /// Verilen tarihte tamamlanan tüm oyunların özet kayıtlarını döner (Maksimum 6 oyun).
  Map<GameType, DailyPlayRecord> getCompletedGamesForDate(String dateId) {
    final result = <GameType, DailyPlayRecord>{};
    for (final game in GameType.values) {
      if (isCompleted(game, dateId)) {
        final rec = getRecord(game, dateId);
        if (rec != null) {
          result[game] = rec;
        }
      }
    }
    return result;
  }

  /// Bir oyun/seviye için oyuncunun bu kayıttan önceki en yüksek skorunu döner.
  int getPreviousBestScore(GameType game, {String? subKey}) {
    int maxScore = 0;
    for (final r in records.values) {
      if (r.gameType == game) {
        if (subKey != null && subKey.isNotEmpty) {
          if (r.subKey == subKey && r.score > maxScore) {
            maxScore = r.score;
          }
        } else {
          if (r.score > maxScore) {
            maxScore = r.score;
          }
        }
      }
    }
    return maxScore;
  }

  /// Bir oyun/seviye için oyuncunun bu kayıttan önceki en iyi (en kısa) süresini döner (ms).
  int getPreviousBestDurationMs(GameType game, {String? subKey}) {
    int minDuration = 0;
    for (final r in records.values) {
      if (r.gameType == game) {
        if (subKey != null && subKey.isNotEmpty) {
          if (r.subKey == subKey && r.durationMs > 0) {
            if (minDuration == 0 || r.durationMs < minDuration) {
              minDuration = r.durationMs;
            }
          }
        } else {
          if (r.durationMs > 0) {
            if (minDuration == 0 || r.durationMs < minDuration) {
              minDuration = r.durationMs;
            }
          }
        }
      }
    }
    return minDuration;
  }

  /// Belirli bir oyunun toplam kaç farklı günde oynandığını (oyun sayısını) döner.
  int getDistinctPlayedDatesCount(GameType game) {
    final dates = <String>{};
    for (final r in records.values) {
      if (r.gameType == game) {
        dates.add(r.dateId);
      }
    }
    return dates.length;
  }

  /// Belirli bir oyun (veya [game] null ise herhangi bir oyun) için
  /// bugün ve geçmişe doğru kaç gün aralıksız oynandığını (aktif seri) hesaplar.
  int getCurrentStreak([GameType? game]) {
    final distinctDates = <String>{};
    for (final r in records.values) {
      if (!r.isArchivePlay && (game == null || r.gameType == game)) {
        distinctDates.add(r.dateId);
      }
    }
    if (distinctDates.isEmpty) return 0;

    final activeDate = GameDateUtils.getActiveDate();
    DateTime checkDate = DateTime(activeDate.year, activeDate.month, activeDate.day);
    String checkKey = _formatDateKey(checkDate);

    // Eğer bugün henüz oynanmadıysa seriyi kırmıyoruz; dün oynandıysa dünden itibaren sayıyoruz.
    if (!distinctDates.contains(checkKey)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      checkKey = _formatDateKey(checkDate);
      if (!distinctDates.contains(checkKey)) {
        return 0; // Hem bugün hem dün oynanmamışsa seri 0'dır.
      }
    }

    int streak = 0;
    while (distinctDates.contains(checkKey)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      checkKey = _formatDateKey(checkDate);
    }
    return streak;
  }

  /// Tüm zamanların en uzun aralıksız serisini hesaplar.
  int getMaxStreak([GameType? game]) {
    final distinctDates = <String>{};
    for (final r in records.values) {
      if (!r.isArchivePlay && (game == null || r.gameType == game)) {
        distinctDates.add(r.dateId);
      }
    }
    if (distinctDates.isEmpty) return 0;

    final sortedDates = distinctDates.map((d) => DateTime.parse(d)).toList()..sort();
    int maxStreak = 1;
    int currentRun = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = sortedDates[i - 1];
      final curr = sortedDates[i];
      final diff = curr.difference(prev).inDays;
      if (diff == 1) {
        currentRun++;
        if (currentRun > maxStreak) maxStreak = currentRun;
      } else if (diff > 1) {
        currentRun = 1;
      }
    }
    return maxStreak;
  }

  static String _formatDateKey(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DailyPlayState copyWith({Map<String, DailyPlayRecord>? records}) {
    return DailyPlayState(records: records ?? this.records);
  }
}

class DailyPlayNotifier extends StateNotifier<DailyPlayState> {
  static const _prefKey = 'zuhtu_daily_play_records_v1';

  DailyPlayNotifier() : super(const DailyPlayState()) {
    loadFromPrefs();
  }

  /// Eski sürümlerde Vezirler için hem "queens:kolay|tarih" hem de mükerrer "queens|tarih"
  /// anahtarı kaydedilmişse, mükerrer özet anahtarı temizler.
  static Map<String, DailyPlayRecord> _sanitizeLegacyDuplicates(
    Map<String, DailyPlayRecord> rawMap,
  ) {
    final datesWithSubKeys = <String>{};
    for (final entry in rawMap.entries) {
      if (entry.key.contains(':')) {
        datesWithSubKeys.add('${entry.value.gameType.id}|${entry.value.dateId}');
      }
    }
    if (datesWithSubKeys.isEmpty) return rawMap;

    final cleaned = <String, DailyPlayRecord>{};
    rawMap.forEach((k, v) {
      if (!k.contains(':') && datesWithSubKeys.contains(k)) {
        return;
      }
      cleaned[k] = v;
    });
    return cleaned;
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final map = <String, DailyPlayRecord>{};
        decoded.forEach((k, v) {
          map[k] = DailyPlayRecord.fromJson(v as Map<String, dynamic>);
        });
        final sanitized = _sanitizeLegacyDuplicates(map);
        state = DailyPlayState(records: sanitized);
        if (sanitized.length != map.length) {
          final mapToSave = sanitized.map((k, v) => MapEntry(k, v.toJson()));
          await prefs.setString(_prefKey, jsonEncode(mapToSave));
        }
      }
    } catch (_) {}
  }

  /// Tamamlama kaydını işler ve oyuncunun önceki rekorlarını kırıp kırmadığını döner.
  Future<({bool isNewPersonalBestScore, bool isNewPersonalBestTime, bool isFirstCompletion})> recordCompletion({
    required GameType game,
    required String dateId,
    required int score,
    required int durationMs,
    String? subKey,
  }) async {
    final prevBestScore = state.getPreviousBestScore(game, subKey: subKey);
    final prevBestTime = state.getPreviousBestDurationMs(game, subKey: subKey);
    final isFirst = prevBestScore == 0 && prevBestTime == 0;

    final isNewScore = !isFirst && score > prevBestScore;
    final isNewTime = !isFirst && durationMs > 0 && (prevBestTime == 0 || durationMs < prevBestTime);

    final todayId = GameDateUtils.getTodayLevelId();
    final isArchive = dateId != todayId;

    final record = DailyPlayRecord(
      gameType: game,
      dateId: dateId,
      score: score,
      durationMs: durationMs,
      completedAt: DateTime.now(),
      subKey: subKey,
      isArchivePlay: isArchive,
    );

    final key = DailyPlayState.makeKey(game, dateId, subKey);
    final updated = Map<String, DailyPlayRecord>.from(state.records);
    updated[key] = record;

    // Alt seviye (subKey) kullanılıyorsa mükerrer ana anahtarı ("queens|date") tutma
    if (subKey != null && subKey.isNotEmpty) {
      updated.remove('${game.id}|$dateId');
    }

    state = state.copyWith(records: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = updated.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}

    return (
      isNewPersonalBestScore: isNewScore,
      isNewPersonalBestTime: isNewTime,
      isFirstCompletion: isFirst,
    );
  }

  /// Bulut yedekleme için tüm günlük oyun ve seri kayıtlarını JSON haritası olarak döner.
  Map<String, dynamic> exportBackupMap() {
    return state.records.map((k, v) => MapEntry(k, v.toJson()));
  }

  /// Buluttan veya yedek anahtarından gelen kayıtları geri yükler (mevcutlarla güvenli birleştirir).
  Future<void> restoreFromBackupMap(
    Map<String, dynamic> rawMap, {
    bool merge = true,
  }) async {
    final merged = merge
        ? Map<String, DailyPlayRecord>.from(state.records)
        : <String, DailyPlayRecord>{};

    rawMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        try {
          final incoming = DailyPlayRecord.fromJson(value);
          final existing = merged[key];
          if (existing == null ||
              incoming.score > existing.score ||
              (incoming.score == existing.score &&
                  incoming.durationMs < existing.durationMs)) {
            merged[key] = incoming;
          }
        } catch (_) {}
      }
    });

    final sanitized = _sanitizeLegacyDuplicates(merged);
    state = DailyPlayState(records: sanitized);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = sanitized.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}
  }
}

final dailyPlayServiceProvider =
    StateNotifierProvider<DailyPlayNotifier, DailyPlayState>((ref) {
  return DailyPlayNotifier();
});
