import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/games/common/base_game.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/features/home/widgets/time_machine_dialog.dart';

void main() {
  group('Zaman Makinesi (Time Machine) - DailyPlayRecord & Streak Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isArchivePlay serileştirme ve deserileştirme kayıpsız çalışmalıdır', () {
      final record = DailyPlayRecord(
        gameType: GameType.tango,
        dateId: '2026-10-01',
        score: 820,
        durationMs: 34000,
        completedAt: DateTime.utc(2026, 10, 1, 10, 0),
        isArchivePlay: true,
      );

      final json = record.toJson();
      expect(json['isArchivePlay'], isTrue);

      final restored = DailyPlayRecord.fromJson(json);
      expect(restored.isArchivePlay, isTrue);
      expect(restored.dateId, '2026-10-01');
      expect(restored.score, 820);
    });

    test('Geçmiş tarihli tamamlama otomatik olarak isArchivePlay=true atanmalıdır', () async {
      final notifier = DailyPlayNotifier();
      final todayId = GameDateUtils.getTodayLevelId();
      const pastId = '2026-01-01';

      expect(pastId, isNot(equals(todayId)));

      await notifier.recordCompletion(
        game: GameType.zipPath,
        dateId: pastId,
        score: 950,
        durationMs: 25000,
      );

      final pastRecord = notifier.state.getRecord(GameType.zipPath, pastId);
      expect(pastRecord, isNotNull);
      expect(pastRecord!.isArchivePlay, isTrue);

      // Bugün tamamlanan ise isArchivePlay=false olmalıdır
      await notifier.recordCompletion(
        game: GameType.zipPath,
        dateId: todayId,
        score: 980,
        durationMs: 21000,
      );

      final todayRecord = notifier.state.getRecord(GameType.zipPath, todayId);
      expect(todayRecord, isNotNull);
      expect(todayRecord!.isArchivePlay, isFalse);
    });

    test('Kural: Günlük seri kazanımı sadece gününde çözülünce verilir (Arşiv oyunları seriyi artırmaz)', () async {
      final notifier = DailyPlayNotifier();
      final today = GameDateUtils.getActiveDate();
      final todayId = GameDateUtils.getTodayLevelId();

      // Dün ve önceki gün arşivden sonradan çözüldü (isArchivePlay = true)
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayId =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // 1. Dünü arşiv olarak çözelim
      await notifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: yesterdayId,
        score: 800,
        durationMs: 30000,
      );

      final yesterdayRecord = notifier.state.getRecord(GameType.crossclimb, yesterdayId);
      expect(yesterdayRecord?.isArchivePlay, isTrue);

      // Arşiv oyunu çözüldüğü için dünkü oyun seri oluşturmamalıdır
      expect(notifier.state.getCurrentStreak(), 0);
      expect(notifier.state.getMaxStreak(), 0);

      // 2. Bugünü gününde çözelim (isArchivePlay = false)
      await notifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: todayId,
        score: 850,
        durationMs: 28000,
      );

      final todayRecord = notifier.state.getRecord(GameType.crossclimb, todayId);
      expect(todayRecord?.isArchivePlay, isFalse);

      // Sadece bugün gününde çözüldüğü için seri 1 olmalıdır (dünkü arşiv seriye eklenmez)
      expect(notifier.state.getCurrentStreak(), 1);
      expect(notifier.state.getMaxStreak(), 1);
    });
  });

  group('TimeMachineDialog Widget Tests', () {
    testWidgets('TimeMachineDialog açıldığında takvim ve geçmiş tarihler görüntülenir',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final records = <String, DailyPlayRecord>{
        'queens|2026-10-01': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: '2026-10-01',
          score: 900,
          durationMs: 30000,
          completedAt: DateTime(2026, 10, 1),
        ),
      };
      final dailyState = DailyPlayState(records: records);

      String? chosenDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  chosenDate = await TimeMachineDialog.show(
                    ctx,
                    dailyPlayState: dailyState,
                    activeLevelId: '2026-10-01',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Başlık ve öğeler görünmeli
      expect(find.text('ZAMAN MAKİNESİ'), findsOneWidget);
      expect(find.text('GEÇMİŞ BULMACA ARŞİVİ'), findsOneWidget);
      expect(find.text('Bu Tarihe Işınlan ➔'), findsOneWidget);

      // Işınlan butonuna basıldığında seçilen tarih dönmeli
      await tester.ensureVisible(find.text('Bu Tarihe Işınlan ➔'));
      await tester.tap(find.text('Bu Tarihe Işınlan ➔'));
      await tester.pumpAndSettle();

      expect(chosenDate, isNotNull);
      expect(chosenDate, '2026-10-01');
    });
  });
}

