import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/crossclimb/crossclimb_models.dart';
import 'package:daily_games/games/crossclimb/crossclimb_logic.dart';
import 'package:daily_games/games/crossclimb/crossclimb_generator.dart';
import 'package:daily_games/games/crossclimb/crossclimb_levels.dart';

void main() {
  group('Crossclimb (Kelime Tırmanışı) Mantık ve Doğrulama Testleri', () {
    test('Türkçe karakter normalizasyonu kurallara uyar', () {
      expect(CrossclimbLogic.normalize('kar'), equals('KAR'));
      expect(CrossclimbLogic.normalize('boş'), equals('BOŞ'));
      expect(CrossclimbLogic.normalize('çiçek'), equals('ÇİÇEK'));
      expect(CrossclimbLogic.normalize('ışık'), equals('IŞIK'));
      expect(CrossclimbLogic.normalize('ağaç'), equals('AĞAÇ'));
    });

    test('hammingDistance farklı harf sayısını doğru hesaplar', () {
      expect(CrossclimbLogic.hammingDistance('KAR', 'TAR'), equals(1));
      expect(CrossclimbLogic.hammingDistance('KAR', 'KOR'), equals(1));
      expect(CrossclimbLogic.hammingDistance('KAR', 'KAS'), equals(1));
      expect(CrossclimbLogic.hammingDistance('KAR', 'KAR'), equals(0));
      expect(CrossclimbLogic.hammingDistance('KAR', 'TOP'), equals(3));
      expect(CrossclimbLogic.hammingDistance('KAR', 'KOT'), equals(2));
      expect(CrossclimbLogic.hammingDistance('KALE', 'BALO'), equals(2));
      expect(CrossclimbLogic.hammingDistance('KAR', 'KALE'), equals(-1));
    });

    test('findChangedIndex tek harf değişiminin indeksini doğru bulur', () {
      expect(CrossclimbLogic.findChangedIndex('KAR', 'TAR'), equals(0));
      expect(CrossclimbLogic.findChangedIndex('KAR', 'KOR'), equals(1));
      expect(CrossclimbLogic.findChangedIndex('KAR', 'KAS'), equals(2));
      expect(CrossclimbLogic.findChangedIndex('TEST', 'TOST'), equals(1));
      // 2 harf farkı olan durumda -1 dönmeli
      expect(CrossclimbLogic.findChangedIndex('KAR', 'TOP'), equals(-1));
    });

    test('Havuzdaki tüm seviyeler validateLevel kuralını sağlar', () {
      for (final level in CrossclimbGenerator.pool) {
        expect(CrossclimbLogic.validateLevel(level), isTrue,
            reason: '${level.id} zinciri kurallara uygun olmalıdır.');
      }
    });

    test('Preset seviyelerin tümü validateLevel kuralını sağlar', () {
      for (final level in CrossclimbLevelRepository.presets) {
        expect(CrossclimbLogic.validateLevel(level), isTrue,
            reason: '${level.id} preset zinciri kurallara uygun olmalıdır.');
      }
    });

    test('validateLevel hatalı zincirleri reddeder', () {
      final invalidChain = CrossclimbLevel(
        id: 'invalid_1',
        startWord: 'KAR',
        endWord: 'TOP',
        steps: [
          CrossclimbStep(index: 0, targetWord: 'TOP', clue: '2 harf birden değişti', changedIndex: 0),
        ],
      );
      expect(CrossclimbLogic.validateLevel(invalidChain), isFalse);
    });

    test('calculateScore süre ve hatalara göre doğru puan hesaplar', () {
      final fastScore = CrossclimbLogic.calculateScore(
        durationMs: 15000,
        stepCount: 4,
        wrongAttempts: 0,
      );
      // 2000 - 90 - 0 = 1910
      expect(fastScore, equals(1910));

      final lowScore = CrossclimbLogic.calculateScore(
        durationMs: 500000,
        stepCount: 4,
        wrongAttempts: 10,
      );
      expect(lowScore, equals(200));
    });

    test('CrossclimbGenerator aynı gün için deterministiktir', () {
      final level1 = CrossclimbGenerator.generate(levelId: '2026-10-10');
      final level2 = CrossclimbGenerator.generate(levelId: '2026-10-10');

      expect(level1.startWord, equals(level2.startWord));
      expect(level1.endWord, equals(level2.endWord));
      expect(level1.steps.length, equals(level2.steps.length));
    });

    test('CrossclimbGenerator farklı günlerde farklı seviyeler döner', () {
      final levelA = CrossclimbGenerator.generate(levelId: '2026-10-10');
      final levelB = CrossclimbGenerator.generate(levelId: '2026-10-11');

      expect(levelA.startWord != levelB.startWord || levelA.endWord != levelB.endWord, isTrue);
    });

    test('LocalCrossclimbPuzzleRepository günlük seviyeyi başarıyla döner', () async {
      const repo = LocalCrossclimbPuzzleRepository();
      final level = await repo.getDaily('2026-10-25');

      expect(level.startWord.isNotEmpty, isTrue);
      expect(level.endWord.isNotEmpty, isTrue);
      expect(CrossclimbLogic.validateLevel(level), isTrue);
    });
  });
}
