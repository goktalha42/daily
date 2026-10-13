import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../games/common/base_game.dart';

class DailyPlayRecord {
  final GameType gameType;
  final String dateId;
  final int score;
  final int durationMs;
  final DateTime completedAt;
  final String? subKey;

  const DailyPlayRecord({
    required this.gameType,
    required this.dateId,
    required this.score,
    required this.durationMs,
    required this.completedAt,
    this.subKey,
  });

  Map<String, dynamic> toJson() => {
        'gameType': gameType.id,
        'dateId': dateId,
        'score': score,
        'durationMs': durationMs,
        'completedAt': completedAt.toIso8601String(),
        if (subKey != null) 'subKey': subKey,
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

  bool isCompleted(GameType game, String dateId, {String? subKey}) {
    return records.containsKey(makeKey(game, dateId, subKey));
  }

  DailyPlayRecord? getRecord(GameType game, String dateId, {String? subKey}) {
    return records[makeKey(game, dateId, subKey)];
  }

  int getCompletedCountForDate(String dateId) {
    return records.values.where((r) => r.dateId == dateId && r.subKey == null).length;
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
        state = DailyPlayState(records: map);
      }
    } catch (_) {}
  }

  Future<void> recordCompletion({
    required GameType game,
    required String dateId,
    required int score,
    required int durationMs,
    String? subKey,
  }) async {
    final record = DailyPlayRecord(
      gameType: game,
      dateId: dateId,
      score: score,
      durationMs: durationMs,
      completedAt: DateTime.now(),
      subKey: subKey,
    );

    final key = DailyPlayState.makeKey(game, dateId, subKey);
    final updated = Map<String, DailyPlayRecord>.from(state.records);
    updated[key] = record;

    // Eğer subKey varsa ana anahtarı da (örn. 'queens|date') güncelle
    if (subKey != null && subKey.isNotEmpty) {
      final mainKey = '${game.id}|$dateId';
      if (!updated.containsKey(mainKey) || updated[mainKey]!.score < score) {
        updated[mainKey] = record;
      }
    }

    state = state.copyWith(records: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = updated.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}
  }
}

final dailyPlayServiceProvider =
    StateNotifierProvider<DailyPlayNotifier, DailyPlayState>((ref) {
  return DailyPlayNotifier();
});
