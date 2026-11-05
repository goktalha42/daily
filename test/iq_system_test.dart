import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  group('Realist IQ Sistemi & Einstein Kriterleri Testi', () {
    test('Yeni kullanıcı başlangıçta asla Einstein veya dahi olmaz (Taban 95)', () {
      final notifier = GameStatsNotifier();
      final initialIQ = notifier.getOverallIQ();

      expect(initialIQ, 95);
      final milestone = IQMilestone.currentMilestone(initialIQ);
      expect(milestone?.title, isNot('Einstein Mertebesi'));
      // Başlangıçta henüz milestone aşılmamış veya ilk tabandadır
      expect(initialIQ < 130, isTrue);
    });

    test('Kullanıcı tek bir oyunda 1000+ puan alsa bile 106 IQ tavanını aşamaz (Einstein olamaz)', () async {
      final notifier = GameStatsNotifier();

      // 1. Oyunda (Vezirler) olağanüstü yüksek puan ve 20 saniye hız
      await notifier.recordGameResult(
        gameType: GameType.queens,
        score: 1150,
        durationMs: 20000,
        moveCount: 8,
      );

      final currentIQ = notifier.getOverallIQ();

      // 1 oyun oynayan birine tek bir başarıyla asla dahi/Einstein unvanı verilemez!
      expect(currentIQ <= 106, isTrue);
      expect(currentIQ >= 98, isTrue);

      final milestone = IQMilestone.currentMilestone(currentIQ);
      expect(milestone?.title, isNot('Einstein Mertebesi'));
      expect(milestone?.title, isNot('Zühtü Dahisi'));
      expect(milestone?.title, isNot('Üstün Mantık (Mensa)'));
    });

    test('2 oyun çözüldüğünde tavan 116 IQ ile sınırlıdır', () async {
      final notifier = GameStatsNotifier();

      await notifier.recordGameResult(
        gameType: GameType.queens,
        score: 1150,
        durationMs: 20000,
        moveCount: 8,
      );
      await notifier.recordGameResult(
        gameType: GameType.tango,
        score: 1100,
        durationMs: 25000,
        moveCount: 10,
      );

      final currentIQ = notifier.getOverallIQ();
      expect(currentIQ <= 116, isTrue);
      expect(currentIQ < 130, isTrue);
    });

    test('3 ve 4 oyun çözüldükçe IQ kademeli olarak yükselir ve motive eder', () async {
      final notifier = GameStatsNotifier();

      await notifier.recordGameResult(
        gameType: GameType.queens,
        score: 1150,
        durationMs: 20000,
        moveCount: 8,
      );
      final iq1 = notifier.getOverallIQ();

      await notifier.recordGameResult(
        gameType: GameType.tango,
        score: 1100,
        durationMs: 25000,
        moveCount: 10,
      );
      final iq2 = notifier.getOverallIQ();

      await notifier.recordGameResult(
        gameType: GameType.zipPath,
        score: 1080,
        durationMs: 30000,
        moveCount: 20,
      );
      final iq3 = notifier.getOverallIQ();

      await notifier.recordGameResult(
        gameType: GameType.crossclimb,
        score: 1050,
        durationMs: 35000,
        moveCount: 5,
      );
      final iq4 = notifier.getOverallIQ();

      expect(iq2 >= iq1, isTrue);
      expect(iq3 >= iq2, isTrue);
      expect(iq4 >= iq3, isTrue);

      // 4 oyunda bile henüz Einstein (148+) olamaz!
      expect(iq4 <= 136, isTrue);
    });

    test('Einstein (148+) için tüm 6 oyun türü ve yüksek tecrübe (25+ oyun) şarttır', () async {
      final notifier = GameStatsNotifier();

      // 6 oyunu da 1 kez oyna
      for (final game in GameType.values) {
        await notifier.recordGameResult(
          gameType: game,
          score: 1100,
          durationMs: 24000,
          moveCount: 10,
        );
      }

      // Henüz toplam oyun sayısı 6 (25'ten az) -> Einstein kapalı (tavan 144)
      final earlyAll6IQ = notifier.getOverallIQ();
      expect(earlyAll6IQ <= 144, isTrue);

      // Şimdi tecrübe kazanarak 25+ oyun tamamlasın
      for (int i = 0; i < 4; i++) {
        for (final game in GameType.values) {
          await notifier.recordGameResult(
            gameType: game,
            score: 1150,
            durationMs: 22000,
            moveCount: 10,
          );
        }
      }

      // Artık 30 oyun çözüldü, tüm kategorilerde mutlak ustalık var -> 148+ Einstein açılır!
      final eliteIQ = notifier.getOverallIQ();
      expect(eliteIQ >= 148, isTrue);
      final milestone = IQMilestone.currentMilestone(eliteIQ);
      expect(milestone?.title, 'Einstein Mertebesi');
      expect(milestone?.emoji, '👑');
    });
  });
}
