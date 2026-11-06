import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameDateUtils.resetDayOffset();
  });

  group('Kişisel Rekor & 6/6 Tamamlama Sertifikası Testleri', () {
    test('recordCompletion ilk oyunda isFirstCompletion döner ve sonraki skor/süre gelişiminde rekor bayrağı yakar',
        () async {
      final dailyNotifier = DailyPlayNotifier();
      final date1 = '2026-11-01';
      final date2 = '2026-11-02';

      // 1. İlk tamamlama (1000 puan, 50 saniye)
      final r1 = await dailyNotifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: date1,
        score: 1000,
        durationMs: 50000,
      );

      expect(r1.isFirstCompletion, isTrue);
      expect(r1.isNewPersonalBestScore, isFalse);
      expect(r1.isNewPersonalBestTime, isFalse);

      // 2. İkinci gün daha düşük puan, daha kötü süre (900 puan, 60 saniye)
      final r2 = await dailyNotifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: date2,
        score: 900,
        durationMs: 60000,
      );

      expect(r2.isFirstCompletion, isFalse);
      expect(r2.isNewPersonalBestScore, isFalse);
      expect(r2.isNewPersonalBestTime, isFalse);

      // 3. Üçüncü gün yeni en yüksek puan (1250 puan, 55 saniye)
      final date3 = '2026-11-03';
      final r3 = await dailyNotifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: date3,
        score: 1250,
        durationMs: 55000,
      );

      expect(r3.isNewPersonalBestScore, isTrue);
      expect(r3.isNewPersonalBestTime, isFalse);

      // 4. Dördüncü gün yeni en hızlı süre (1100 puan, 38 saniye)
      final date4 = '2026-11-04';
      final r4 = await dailyNotifier.recordCompletion(
        game: GameType.crossclimb,
        dateId: date4,
        score: 1100,
        durationMs: 38000,
      );

      expect(r4.isNewPersonalBestScore, isFalse);
      expect(r4.isNewPersonalBestTime, isTrue);
    });

    test('getCompletedGamesForDate 6 oyun tamamlandığında tüm oyunların kaydını eksiksiz listeler', () async {
      final dailyNotifier = DailyPlayNotifier();
      final todayId = GameDateUtils.getTodayLevelId();

      for (final game in GameType.values) {
        await dailyNotifier.recordCompletion(
          game: game,
          dateId: todayId,
          score: 1500,
          durationMs: 40000,
          subKey: game == GameType.queens ? 'kolay' : null,
        );
      }

      final completedMap = dailyNotifier.state.getCompletedGamesForDate(todayId);
      expect(completedMap.length, 6);
      expect(completedMap.containsKey(GameType.queens), isTrue);
      expect(completedMap.containsKey(GameType.pinpoint), isTrue);
      expect(completedMap.containsKey(GameType.crossclimb), isTrue);
      expect(completedMap.containsKey(GameType.tango), isTrue);
      expect(completedMap.containsKey(GameType.zipPath), isTrue);
      expect(completedMap.containsKey(GameType.patches), isTrue);
    });
  });
}

