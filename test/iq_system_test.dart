import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WAIS-IV Psikometrik IQ Sistemi & Katı Einstein Kriterleri', () {
    test('Yeni kullanıcı tam dünya ortalaması olan 100 IQ ile başlar', () {
      final notifier = GameStatsNotifier();
      final initialIQ = notifier.getOverallIQ();

      expect(initialIQ, 100);
      expect(IQMilestone.gaussianBetterThanPercent(100), closeTo(50.0, 0.1));
      expect(IQMilestone.gaussianBetterThanPercent(130), closeTo(97.7, 0.2));
      expect(IQMilestone.gaussianBetterThanPercent(148), greaterThan(99.85));
    });

    test('1 veya 2 kusursuz dünya rekoru oyunda bile yüksek IQ görülmez (101-106 bandı)', () async {
      final notifier = GameStatsNotifier();

      // 1. Oyun: Sayı Yolu (2000 tabanlı oyunda 15 saniyede 1850 puanlık kusursuz çözüm)
      final res1 = await notifier.recordGameResult(
        gameType: GameType.zipPath,
        score: 1850,
        durationMs: 15000,
        moveCount: 20,
      );

      expect(res1.currentIQ, greaterThanOrEqualTo(101));
      expect(res1.currentIQ, lessThanOrEqualTo(104));
      expect(res1.iqDelta, greaterThan(0));

      // 2. Oyun: Güneş & Ay (17 saniyede 1830 puanlık kusursuz çözüm)
      final res2 = await notifier.recordGameResult(
        gameType: GameType.tango,
        score: 1830,
        durationMs: 17000,
        moveCount: 22,
      );

      expect(res2.currentIQ, greaterThan(res1.currentIQ));
      expect(res2.currentIQ, lessThanOrEqualTo(106));
      expect(IQMilestone.currentMilestone(res2.currentIQ)?.title, 'Dengeli Zihin');
    });

    test('Sadece tek bir kategoriyi 50 kez kusursuz oynayan oyuncu 110 IQ barajını bile aşamaz', () async {
      final notifier = GameStatsNotifier();

      for (int i = 0; i < 50; i++) {
        await notifier.recordGameResult(
          gameType: GameType.pinpoint,
          score: 1920,
          durationMs: 14000,
          moveCount: 1,
        );
      }

      // 5/6 bilişsel alan hiç test edilmediği için doğal Bayesyen sınır ~109 IQ'dur
      final singleDomainIQ = notifier.getOverallIQ();
      expect(singleDomainIQ, lessThanOrEqualTo(109));
    });

    test('Ortalama performansla 60 oyun oynamak (grind) bedava yüksek IQ vermez', () async {
      final notifier = GameStatsNotifier();

      // 10 gün boyunca 6 oyunu da ortalama hızda (60-70 sn, ~1300 puan) çözsün
      for (int day = 0; day < 10; day++) {
        for (final game in GameType.values) {
          await notifier.recordGameResult(
            gameType: game,
            score: game == GameType.queens ? 850 : 1300,
            durationMs: 65000,
            moveCount: 25,
            difficulty: game == GameType.queens ? 'hard' : null,
          );
        }
      }

      final grindIQ = notifier.getOverallIQ();
      expect(grindIQ, greaterThanOrEqualTo(98));
      expect(grindIQ, lessThan(112)); // Asla Büyük Usta, Mensa veya Einstein olamaz!
    });

    test('İlk gün 6/6 kusursuz çözüm motive edici şekilde ~115-117 IQ (Keskin Zihin) seviyesine taşır', () async {
      final notifier = GameStatsNotifier();

      for (final game in GameType.values) {
        await notifier.recordGameResult(
          gameType: game,
          score: game == GameType.queens ? 1300 : 1860,
          durationMs: game == GameType.queens ? 32000 : 15000,
          moveCount: 12,
          difficulty: game == GameType.queens ? 'master' : null,
        );
      }

      final day1IQ = notifier.getOverallIQ();
      expect(day1IQ, greaterThanOrEqualTo(114));
      expect(day1IQ, lessThan(120)); // İlk günden Büyük Usta (120) veya Mensa (130) olamaz
    });

    test('Einstein Mertebesi (148+ IQ) yalnızca 6/6 kategori, 35+ oyun ve %99.9 elit istikrarla açılır', () async {
      final notifier = GameStatsNotifier();

      // 4 gün (24 elit oyun) -> henüz 35 oyun ve kategori başına 5 derinlik dolmadı
      for (int day = 0; day < 4; day++) {
        for (final game in GameType.values) {
          await notifier.recordGameResult(
            gameType: game,
            score: game == GameType.queens ? 1310 : 1880,
            durationMs: game == GameType.queens ? 30000 : 14000,
            moveCount: 10,
            difficulty: game == GameType.queens ? 'master' : null,
          );
        }
      }

      final day4IQ = notifier.getOverallIQ();
      expect(day4IQ, lessThan(148)); // 4. günde bile henüz Einstein değil!

      // 3 gün daha aynı %99.9 elit performansı sürdürsün (Toplam 7 gün = 42 oyun, her kategoride 7'şer kez)
      for (int day = 0; day < 3; day++) {
        for (final game in GameType.values) {
          await notifier.recordGameResult(
            gameType: game,
            score: game == GameType.queens ? 1310 : 1880,
            durationMs: game == GameType.queens ? 30000 : 14000,
            moveCount: 10,
            difficulty: game == GameType.queens ? 'master' : null,
          );
        }
      }

      final einsteinIQ = notifier.getOverallIQ();
      expect(einsteinIQ, greaterThanOrEqualTo(148));
      expect(IQMilestone.currentMilestone(einsteinIQ)?.title, 'Einstein Mertebesi');

      // Ardından üst üste çok kötü ve yavaş oyunlar oynarsa EMA düşer ve Einstein unvanını kaybeder!
      for (int slump = 0; slump < 3; slump++) {
        for (final game in GameType.values) {
          await notifier.recordGameResult(
            gameType: game,
            score: 300,
            durationMs: 220000,
            moveCount: 60,
          );
        }
      }

      final droppedIQ = notifier.getOverallIQ();
      expect(droppedIQ, lessThan(148));
    });
  });
}
