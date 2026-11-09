import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/services/badge_service.dart';
import 'package:daily_games/core/services/cloud_backup_service.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/core/services/retention_notification_service.dart';
import 'package:daily_games/core/services/sound_haptic_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RetentionNotificationService Zamanlama ve İçerik Testleri', () {
    test('Bugün oyun çözülmediyse ve saat 20:00 öncesi ise bugün 20:00 döner', () {
      final now = DateTime(2026, 11, 8, 15, 30);
      final next = RetentionNotificationService.computeNextStreakTriggerTime(
        now: now,
        hasCompletedGameToday: false,
      );
      expect(next, DateTime(2026, 11, 8, 20, 0));
    });

    test('Bugün en az 1 oyun çözüldüyse bildirim otomatik yarına (20:00) ertelenir', () {
      final now = DateTime(2026, 11, 8, 14, 10);
      final next = RetentionNotificationService.computeNextStreakTriggerTime(
        now: now,
        hasCompletedGameToday: true,
      );
      expect(next, DateTime(2026, 11, 9, 20, 0));
    });

    test('Pazar akşamı 20:00 Haftalık Zeka Raporu zamanlaması doğru hesaplanır', () {
      // Çarşamba günü -> Aynı haftanın Pazar günü 20:00
      final wednesday = DateTime(2026, 11, 4, 12, 0);
      final nextSunday =
          RetentionNotificationService.computeNextSundayReportTriggerTime(
            wednesday,
          );
      expect(nextSunday.weekday, DateTime.sunday);
      expect(nextSunday, DateTime(2026, 11, 8, 20, 0));

      // Pazar saat 21:00 -> Gelecek haftanın Pazar günü 20:00
      final sundayLate = DateTime(2026, 11, 8, 21, 0);
      final followingSunday =
          RetentionNotificationService.computeNextSundayReportTriggerTime(
            sundayLate,
          );
      expect(followingSunday, DateTime(2026, 11, 15, 20, 0));
    });

    test('Seri sayısına göre bildirim metni kişiselleştirilir', () {
      final activeContent =
          RetentionNotificationService.buildStreakNotificationContent(12);
      expect(activeContent.title, contains('12 Günlük Serin'));
      expect(activeContent.body, contains('12 günlük'));

      final zeroContent =
          RetentionNotificationService.buildStreakNotificationContent(0);
      expect(zeroContent.title, contains('Günün 6 Zeka Bulmacası'));
    });
  });

  group('CloudBackupService & Cihaz Taşıma Testleri', () {
    test('Cihaz kimliğinden ZHT-XXXX-XXXX formatında deterministik kurtarma kodu üretilir', () {
      final code1 = CloudBackupNotifier.deriveDeterministicCodeFromDeviceId(
        'device-abc-123',
      );
      final code2 = CloudBackupNotifier.deriveDeterministicCodeFromDeviceId(
        'device-abc-123',
      );
      expect(code1, equals(code2));
      expect(code1, matches(RegExp(r'^ZHT-[A-Z0-9]{4}-[A-Z0-9]{4}$')));
    });

    test('Taşınabilir yedek anahtarı (ZBK1) seri, IQ ve rozetleri eksiksiz taşır', () async {
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      // 1. Cihazda oyun çöz, seri ve rozet kazan
      final testDate = GameDateUtils.getTodayLevelId();
      await container1.read(dailyPlayServiceProvider.notifier).recordCompletion(
            game: GameType.queens,
            dateId: testDate,
            score: 885,
            durationMs: 19000,
            subKey: 'kolay',
          );
      await container1.read(gameStatsServiceProvider.notifier).recordGameResult(
            gameType: GameType.queens,
            score: 885,
            durationMs: 19000,
            moveCount: 12,
            difficulty: 'kolay',
            dateId: testDate,
            isArchivePlay: false,
          );
      await container1
          .read(badgeServiceProvider.notifier)
          .awardBadge('badge_first_win');

      final backupKey = container1
          .read(cloudBackupProvider.notifier)
          .exportPortableBackupKey();
      expect(backupKey, startsWith('ZBK1.'));

      // Bozuk imza reddedilmeli
      expect(
        CloudBackupNotifier.decodePortableBackupKey('${backupKey}X'),
        isNull,
      );

      // 2. Yeni sıfırlanmış cihazda yedek anahtarını geri yükle
      SharedPreferences.setMockInitialValues({});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final restoreRes = await container2
          .read(cloudBackupProvider.notifier)
          .restoreFromInput(backupKey);
      expect(restoreRes.success, isTrue);

      final restoredDaily = container2.read(dailyPlayServiceProvider);
      expect(
        restoredDaily.isCompleted(
          GameType.queens,
          testDate,
          subKey: 'kolay',
        ),
        isTrue,
      );
      expect(
        restoredDaily
            .getRecord(GameType.queens, testDate, subKey: 'kolay')
            ?.score,
        885,
      );

      final restoredStats = container2.read(gameStatsServiceProvider);
      expect(restoredStats[GameType.queens]?.bestScore, 885);

      final restoredBadges = container2.read(badgeServiceProvider.notifier);
      expect(restoredBadges.isUnlocked('badge_first_win'), isTrue);
    });
  });

  group('SoundHapticService Tercih Kalıcılığı Testi', () {
    test('Ses ve titreşim tercihleri kaydedilir ve okunur', () async {
      await SoundHapticService.instance.setSoundEnabled(false);
      await SoundHapticService.instance.setHapticEnabled(false);

      final loaded = await SoundHapticService.instance.ensureLoaded();
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.hapticEnabled, isFalse);

      await SoundHapticService.instance.setSoundEnabled(true);
      await SoundHapticService.instance.setHapticEnabled(true);
      expect(SoundHapticService.instance.soundEnabled, isTrue);
      expect(SoundHapticService.instance.hapticEnabled, isTrue);
    });
  });
}

