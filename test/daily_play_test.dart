import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/games/common/base_game.dart';
import 'package:daily_games/core/services/daily_play_service.dart';

void main() {
  group('DailyPlayRecord Tests', () {
    test('JSON serileştirme ve deserileştirme kayıpsız çalışmalıdır', () {
      final now = DateTime.utc(2026, 10, 7, 14, 30);
      final record = DailyPlayRecord(
        gameType: GameType.queens,
        dateId: '2026-10-07',
        score: 850,
        durationMs: 45000,
        completedAt: now,
      );

      final json = record.toJson();
      final restored = DailyPlayRecord.fromJson(json);

      expect(restored.gameType, GameType.queens);
      expect(restored.dateId, '2026-10-07');
      expect(restored.score, 850);
      expect(restored.durationMs, 45000);
      expect(restored.completedAt.toIso8601String(), now.toIso8601String());
    });
  });

  group('DailyPlayNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Başlangıçta hiçbir oyun tamamlanmamış görünmelidir', () {
      final notifier = DailyPlayNotifier();
      expect(notifier.state.isCompleted(GameType.queens, '2026-10-07'), isFalse);
      expect(notifier.state.getRecord(GameType.queens, '2026-10-07'), isNull);
      expect(notifier.state.getCompletedCountForDate('2026-10-07'), 0);
    });

    test('recordCompletion bir oyunu tamamlandı olarak işaretlemeli ve skoru kaydetmelidir', () async {
      final notifier = DailyPlayNotifier();

      await notifier.recordCompletion(
        game: GameType.queens,
        dateId: '2026-10-07',
        score: 900,
        durationMs: 30000,
      );

      expect(notifier.state.isCompleted(GameType.queens, '2026-10-07'), isTrue);
      expect(notifier.state.isCompleted(GameType.tango, '2026-10-07'), isFalse);
      expect(notifier.state.getCompletedCountForDate('2026-10-07'), 1);

      final record = notifier.state.getRecord(GameType.queens, '2026-10-07');
      expect(record, isNotNull);
      expect(record!.score, 900);
      expect(record.durationMs, 30000);
    });

    test('Farklı günler birbirinden bağımsız kilitlenmelidir', () async {
      final notifier = DailyPlayNotifier();

      await notifier.recordCompletion(
        game: GameType.queens,
        dateId: '2026-10-07',
        score: 900,
        durationMs: 30000,
      );

      // 2026-10-07 tamamlandı ama 2026-10-08 henüz oynanmadı
      expect(notifier.state.isCompleted(GameType.queens, '2026-10-07'), isTrue);
      expect(notifier.state.isCompleted(GameType.queens, '2026-10-08'), isFalse);
    });

    test('SharedPreferences üzerinden veriler kalıcı olarak yüklenmelidir', () async {
      final mapData = {
        'zipPath|2026-10-07': {
          'gameType': 'zipPath',
          'dateId': '2026-10-07',
          'score': 950,
          'durationMs': 20000,
          'completedAt': '2026-10-07T12:00:00.000Z',
        }
      };
      SharedPreferences.setMockInitialValues({
        'zuhtu_daily_play_records_v1': jsonEncode(mapData),
      });

      final notifier = DailyPlayNotifier();
      await notifier.loadFromPrefs();

      expect(notifier.state.isCompleted(GameType.zipPath, '2026-10-07'), isTrue);
      final record = notifier.state.getRecord(GameType.zipPath, '2026-10-07');
      expect(record?.score, 950);
    });
  });
}
