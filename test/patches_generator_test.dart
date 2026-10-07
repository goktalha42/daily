import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/patches/patches_models.dart';
import 'package:daily_games/games/patches/patches_logic.dart';
import 'package:daily_games/games/patches/patches_generator.dart';
import 'package:daily_games/games/patches/patches_levels.dart';

void main() {
  group('PatchesGenerator ve Çözücü Testleri', () {
    test('countSolutions preset seviyelerin tek çözümlü olduğunu onaylar', () {
      for (final level in PatchesLevelRepository.presets) {
        final count = PatchesLogic.countSolutions(
          level.gridSize,
          level.clues,
          maxCount: 2,
        );
        expect(count, equals(1),
            reason: 'Seviye ${level.id} tek çözüme sahip olmalıdır.');
      }
    });

    test('PatchesGenerator aynı gün ve zorluk için deterministiktir', () {
      final level1 = PatchesGenerator.generate(
        levelId: '2026-10-08',
        difficulty: PatchesDifficulty.orta,
      );
      final level2 = PatchesGenerator.generate(
        levelId: '2026-10-08',
        difficulty: PatchesDifficulty.orta,
      );

      expect(level1.gridSize, equals(level2.gridSize));
      expect(level1.clues.length, equals(level2.clues.length));

      for (int i = 0; i < level1.clues.length; i++) {
        expect(level1.clues[i].row, equals(level2.clues[i].row));
        expect(level1.clues[i].col, equals(level2.clues[i].col));
        expect(level1.clues[i].targetArea, equals(level2.clues[i].targetArea));
      }
    });

    test('PatchesGenerator farklı günlerde farklı seviyeler üretir', () {
      final levelA = PatchesGenerator.generate(
        levelId: '2026-10-08',
        difficulty: PatchesDifficulty.orta,
      );
      final levelB = PatchesGenerator.generate(
        levelId: '2026-10-09',
        difficulty: PatchesDifficulty.orta,
      );

      final cluesMatch = levelA.clues.length == levelB.clues.length &&
          List.generate(
            levelA.clues.length,
            (i) =>
                levelA.clues[i].row == levelB.clues[i].row &&
                levelA.clues[i].col == levelB.clues[i].col &&
                levelA.clues[i].targetArea == levelB.clues[i].targetArea,
          ).every((match) => match);

      expect(cluesMatch, isFalse,
          reason: 'Farklı gün tohumları farklı bulmacalar üretmelidir.');
    });

    test('Her zorluk seviyesi için üretilen tahtalar geçerli ve TEK ÇÖZÜMLÜDÜR', () {
      for (final diff in PatchesDifficulty.values) {
        final level = PatchesGenerator.generate(
          levelId: '2026-10-15',
          difficulty: diff,
        );

        expect(level.gridSize, equals(diff.gridSize));

        // 1. İpucu alanlarının toplamı tahtayı tam doldurmalı
        final sumArea = level.clues.fold<int>(0, (sum, c) => sum + c.targetArea);
        expect(sumArea, equals(diff.gridSize * diff.gridSize));

        // 2. Çözücü tek çözüm bulmalı
        final solCount = PatchesLogic.countSolutions(
          level.gridSize,
          level.clues,
          maxCount: 2,
        );
        expect(solCount, equals(1),
            reason: '${diff.name} seviyesinde tahta tam olarak 1 çözüme sahip olmalıdır.');

        // 3. Üretilen çözüm tahta doğrulayıcısından geçerli olmalı
        expect(level.solution, isNotNull);
        final isValid = PatchesLogic.validateBoard(
          level.solution!,
          level.clues,
          level.gridSize,
        );
        expect(isValid, isTrue);
      }
    });

    test('PatchesDifficultyScheduler art arda 3 gün aynı zorluk vermez', () {
      PatchesDifficulty? last1;
      PatchesDifficulty? last2;

      for (int day = 0; day < 365; day++) {
        final diff = PatchesDifficultyScheduler.getDifficultyForDays(day);
        if (last1 != null && last2 != null) {
          final allSame = diff == last1 && last1 == last2;
          expect(allSame, isFalse,
              reason: '$day. günde art arda 3 aynı zorluk geldi: $diff');
        }
        last2 = last1;
        last1 = diff;
      }
    });

    test('LocalPatchesPuzzleRepository günlük seviyeyi başarıyla döner', () async {
      const repo = LocalPatchesPuzzleRepository();
      final level = await repo.getDaily('2026-10-20');

      expect(level.clues.isNotEmpty, isTrue);
      expect(level.gridSize, greaterThanOrEqualTo(4));

      final solCount = PatchesLogic.countSolutions(
        level.gridSize,
        level.clues,
        maxCount: 2,
      );
      expect(solCount, equals(1));
    });
  });
}
