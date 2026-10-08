import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/pinpoint/pinpoint_logic.dart';
import 'package:daily_games/games/pinpoint/pinpoint_generator.dart';
import 'package:daily_games/games/pinpoint/pinpoint_levels.dart';

void main() {
  group('Pinpoint (Kelime İzleri) Mantık ve Doğrulama Testleri', () {
    test('Türkçe karakter normalizasyonu kurallara uyar', () {
      expect(PinpointLogic.normalize('kahve'), equals('KAHVE'));
      expect(PinpointLogic.normalize('içecek'), equals('İÇECEK'));
      expect(PinpointLogic.normalize('ışık'), equals('IŞIK'));
      expect(PinpointLogic.normalize('çiçek'), equals('ÇİÇEK'));
      expect(PinpointLogic.normalize('şeker'), equals('ŞEKER'));
      expect(PinpointLogic.normalize('ağaç'), equals('AĞAÇ'));
      expect(PinpointLogic.normalize('ördek'), equals('ÖRDEK'));
      expect(PinpointLogic.normalize('üzüm'), equals('ÜZÜM'));
      expect(PinpointLogic.normalize('  kitap  '), equals('KİTAP'));
    });

    test('Tahmin doğrulaması hedef kelimeyi ve alternatifleri tanır', () {
      expect(
        PinpointLogic.isCorrectGuess('kahve', 'KAHVE'),
        isTrue,
      );
      expect(
        PinpointLogic.isCorrectGuess('KAHVE', 'kahve'),
        isTrue,
      );
      expect(
        PinpointLogic.isCorrectGuess('türk kahvesi', 'KAHVE', alternativeAnswers: ['TÜRK KAHVESİ']),
        isTrue,
      );
      expect(
        PinpointLogic.isCorrectGuess('çay', 'KAHVE'),
        isFalse,
      );
      expect(
        PinpointLogic.isCorrectGuess('', 'KAHVE'),
        isFalse,
      );
    });

    test('Puanlama formülü ipucu sayısı, hata ve süreye göre doğru çalışır', () {
      // 1 ipucuyla, 0 hatayla, 10 saniyede bilen: 2000 - 0 - 0 - 50 = 1950
      final perfectScore = PinpointLogic.calculateScore(
        durationMs: 10000,
        revealedClues: 1,
        wrongGuessesCount: 0,
      );
      expect(perfectScore, equals(1950));

      // 4 ipucuyla (3 ekstra = 750 ceza), 2 hata (200 ceza), 30 saniye (150 ceza): 2000 - 1100 = 900
      final midScore = PinpointLogic.calculateScore(
        durationMs: 30000,
        revealedClues: 4,
        wrongGuessesCount: 2,
      );
      expect(midScore, equals(900));

      // Çok kötü performans taban puan 200 altına inemez
      final lowScore = PinpointLogic.calculateScore(
        durationMs: 500000,
        revealedClues: 5,
        wrongGuessesCount: 20,
      );
      expect(lowScore, equals(200));
    });

    test('Havuzdaki tüm seviyeler PinpointLogic.validateLevel kuralını sağlar', () {
      for (final level in PinpointGenerator.pool) {
        expect(PinpointLogic.validateLevel(level), isTrue,
            reason: '${level.targetWord} seviyesi kurallara uygun olmalıdır.');
        expect(level.clues.length, equals(5));
      }
    });

    test('PinpointGenerator aynı gün için deterministiktir', () {
      final level1 = PinpointGenerator.generate(levelId: '2026-10-08');
      final level2 = PinpointGenerator.generate(levelId: '2026-10-08');

      expect(level1.targetWord, equals(level2.targetWord));
      expect(level1.categoryHint, equals(level2.categoryHint));
      expect(level1.clues, equals(level2.clues));
    });

    test('PinpointGenerator farklı günlerde farklı seviyeler döner', () {
      final levelA = PinpointGenerator.generate(levelId: '2026-10-08');
      final levelB = PinpointGenerator.generate(levelId: '2026-10-09');

      expect(levelA.targetWord != levelB.targetWord || levelA.categoryHint != levelB.categoryHint, isTrue);
    });

    test('LocalPinpointPuzzleRepository günlük seviyeyi başarıyla döner', () async {
      const repo = LocalPinpointPuzzleRepository();
      final level = await repo.getDaily('2026-10-15');

      expect(level.targetWord.isNotEmpty, isTrue);
      expect(level.clues.length, equals(5));
      expect(PinpointLogic.validateLevel(level), isTrue);
    });
  });
}
