import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/games/common/base_game.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Geçmiş Oyun Puan ve IQ Testleri', () {
    test('Normal gün oyunu tam etki (%100) sağlarken, geçmiş gün oyunu %10 etki sağlar', () async {
      final normalNotifier = GameStatsNotifier();
      await normalNotifier.ensureLoaded();

      // Normal günde ilk oyun
      final todayLevelId = GameDateUtils.getTodayLevelId();
      final normalResult = await normalNotifier.recordGameResult(
        gameType: GameType.crossclimb,
        score: 1800,
        durationMs: 30000,
        moveCount: 5,
        dateId: todayLevelId,
        isArchivePlay: false,
      );

      final normalPerf = normalNotifier.debugState[GameType.crossclimb]!;

      // SharedPreferences'ı sıfırla ki geçmiş oyun testi bağımsız temiz bir kullanıcı gibi başlasın
      SharedPreferences.setMockInitialValues({});

      // Geçmiş günde ilk oyun
      final archiveNotifier = GameStatsNotifier();
      await archiveNotifier.ensureLoaded();

      const pastLevelId = '2026-10-15';
      final archiveResult = await archiveNotifier.recordGameResult(
        gameType: GameType.crossclimb,
        score: 1800,
        durationMs: 30000,
        moveCount: 5,
        dateId: pastLevelId,
        isArchivePlay: true,
      );

      final archivePerf = archiveNotifier.debugState[GameType.crossclimb]!;

      // Geçmiş oyunda EMA ve Peak normal oyunun %10'u olmalıdır
      expect(archivePerf.emaZScore, closeTo(normalPerf.emaZScore * 0.10, 0.001));
      expect(archivePerf.peakZScore, closeTo(normalPerf.peakZScore * 0.10, 0.001));

      // Effective games played normal oyunda 1.0 iken geçmiş oyunda 0.10 olmalıdır
      expect(normalPerf.effectiveGamesPlayed, closeTo(1.0, 0.001));
      expect(archivePerf.effectiveGamesPlayed, closeTo(0.10, 0.001));

      // Geçmiş oyunda bestScore artmamalıdır (0 puan kuralı)
      expect(archivePerf.bestScore, equals(0));
      expect(normalPerf.bestScore, equals(1800));

      // Credibility geçmiş oyunda daha düşüktür
      expect(archivePerf.credibility, lessThan(normalPerf.credibility));
    });

    test('Mevcut oyunu olan bir kullanıcıda geçmiş gün oyunu Z-skor deltasına %10 etki eder', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = GameStatsNotifier();
      await notifier.ensureLoaded();

      final todayLevelId = GameDateUtils.getTodayLevelId();
      // 1. Oyun (Bugün)
      await notifier.recordGameResult(
        gameType: GameType.tango,
        score: 1500,
        durationMs: 40000,
        moveCount: 22,
        dateId: todayLevelId,
      );

      final basePerf = notifier.debugState[GameType.tango]!;
      final initialEma = basePerf.emaZScore;

      // 2. Oyun (Geçmiş gün oyunu)
      const pastLevelId = '2026-10-10';
      await notifier.recordGameResult(
        gameType: GameType.tango,
        score: 1900,
        durationMs: 20000,
        moveCount: 22,
        dateId: pastLevelId,
        isArchivePlay: true,
      );

      final afterArchivePerf = notifier.debugState[GameType.tango]!;
      final archiveDelta = afterArchivePerf.emaZScore - initialEma;

      // Normal oyunda 0.32 * (solveZ - oldEma) kadar artacaktı.
      // Geçmiş oyunda bunun %10'u kadar (0.10 * 0.32 * (solveZ - oldEma)) artmalıdır.
      final solveZ = PsychometricIQCalculator.evaluateSingleSolveZ(
        gameType: GameType.tango,
        score: 1900,
        durationMs: 20000,
      );
      final expectedNormalDelta = 0.32 * (solveZ - initialEma);
      expect(archiveDelta, closeTo(expectedNormalDelta * 0.10, 0.001));

      // Effective games played 1.0 + 0.10 = 1.10 olmalıdır
      expect(afterArchivePerf.effectiveGamesPlayed, closeTo(1.10, 0.001));
    });

    test('DailyPlayService geçmiş oyunu isArchivePlay olarak kaydeder', () async {
      final dailyNotifier = DailyPlayNotifier();
      await dailyNotifier.loadFromPrefs();

      const pastDateId = '2026-10-15';
      await dailyNotifier.recordCompletion(
        game: GameType.pinpoint,
        dateId: pastDateId,
        score: 0, // Geçmiş oyunda 0 puan verilir
        durationMs: 45000,
      );

      final rec = dailyNotifier.debugState.getRecord(GameType.pinpoint, pastDateId);
      expect(rec, isNotNull);
      expect(rec!.score, equals(0));
      expect(rec.isArchivePlay, isTrue);
    });
  });
}

extension GameStatsNotifierTestExt on GameStatsNotifier {
  Map<GameType, GamePerformanceData> get debugState => state;
}

extension DailyPlayNotifierTestExt on DailyPlayNotifier {
  DailyPlayState get debugState => state;
}

