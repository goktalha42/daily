import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/patches/patches_models.dart';
import 'package:daily_games/games/patches/patches_logic.dart';
import 'package:daily_games/games/patches/patches_levels.dart';

void main() {
  group('Patches (Alan Bölme / Shikaku) Testleri', () {
    test('Preset seviyelerin ipucu toplamları tahta alanına eşittir', () {
      for (final level in PatchesLevelRepository.presets) {
        final totalArea = level.gridSize * level.gridSize;
        final clueSum = level.clues.fold<int>(0, (sum, clue) => sum + clue.targetArea);
        expect(clueSum, equals(totalArea),
            reason: 'Level ${level.id} ipucu toplamı ($clueSum) tahta alanına ($totalArea) eşit olmalı.');
      }
    });

    test('Dikdörtgen çakışması doğru tespit edilir', () {
      final rect1 = PatchRect.fromPoints(const PatchPoint(0, 0), const PatchPoint(1, 1));
      final rect2 = PatchRect.fromPoints(const PatchPoint(1, 1), const PatchPoint(2, 2));
      final rect3 = PatchRect.fromPoints(const PatchPoint(2, 2), const PatchPoint(3, 3));

      // rect1 ile rect2 (1,1) noktasında çakışır
      expect(rect1.overlaps(rect2), isTrue);
      // rect1 ile rect3 tamamen ayrıdır
      expect(rect1.overlaps(rect3), isFalse);
    });

    test('Tüm preset seviyelerin çözümleri PatchesLogic tarafından doğrulanır', () {
      for (final level in PatchesLevelRepository.presets) {
        final isValid = PatchesLogic.validateBoard(
          level.solution!,
          level.clues,
          level.gridSize,
        );
        expect(isValid, isTrue,
            reason: 'Level ${level.id} çözümü tahta doğrulamasından geçmeli.');
      }
    });
  });
}
