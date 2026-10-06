import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/tango/tango_generator.dart';
import 'package:daily_games/games/tango/tango_levels.dart';
import 'package:daily_games/games/tango/tango_logic.dart';
import 'package:daily_games/games/tango/tango_models.dart';

void main() {
  group('TangoGenerator (Güneş & Ay Jeneratörü) Testleri', () {
    test('Aynı gün ve zorluk için deterministik bulmaca üretir', () {
      final l1 = TangoGenerator.generate(
        levelId: '2026-10-06',
        difficulty: TangoDifficulty.kolay,
      );
      final l2 = TangoGenerator.generate(
        levelId: '2026-10-06',
        difficulty: TangoDifficulty.kolay,
      );

      expect(l1.gridSize, equals(l2.gridSize));
      expect(l1.constraints.length, equals(l2.constraints.length));

      for (int r = 0; r < l1.gridSize; r++) {
        for (int c = 0; c < l1.gridSize; c++) {
          expect(l1.initialGrid[r][c], equals(l2.initialGrid[r][c]));
          expect(l1.solution![r][c], equals(l2.solution![r][c]));
        }
      }
    });

    test('Üretilen her tahtanın TEK bir geçerli çözümü vardır', () {
      for (final diff in TangoDifficulty.values) {
        final level = TangoGenerator.generate(
          levelId: '2026-10-06',
          difficulty: diff,
        );

        final solCount = TangoLogic.countSolutions(
          level.initialGrid,
          level.gridSize,
          level.constraints,
          maxCount: 2,
        );

        expect(solCount, equals(1),
            reason: '${diff.name} seviyesinde tam 1 çözüm olmalı.');
      }
    });

    test('Üretilen bulmacalar oyuncu için TAHMİNSİZ, saf mantıkla %100 çözülebilir', () {
      for (final diff in TangoDifficulty.values) {
        final level = TangoGenerator.generate(
          levelId: '2026-10-06',
          difficulty: diff,
        );

        final deductive = TangoLogic.solveDeductively(
          level.initialGrid,
          level.gridSize,
          level.constraints,
        );

        expect(deductive.isSolvable, isTrue,
            reason: '${diff.name} seviyesi hiçbir tahmin/deneme yanılma gerektirmeden insan mantığıyla çözülebilmeli.');
      }
    });

    test('Üretilen çözüm tam ve kurallara uygundur', () {
      final level = TangoGenerator.generate(
        levelId: '2026-10-07',
        difficulty: TangoDifficulty.orta,
      );

      final cells = List.generate(
        level.gridSize,
        (r) => List.generate(
          level.gridSize,
          (c) => TangoCell(
            row: r,
            col: c,
            symbol: level.solution![r][c],
          ),
        ),
      );

      final isValid = TangoLogic.validateGrid(cells, level.gridSize, level.constraints);
      expect(isValid, isTrue, reason: 'Üretilen çözüm Tango kurallarına tam uymalı.');
    });

    test('Farklı günler farklı bulmacalar üretir', () {
      final l1 = TangoGenerator.generate(
        levelId: '2026-10-06',
        difficulty: TangoDifficulty.orta,
      );
      final l2 = TangoGenerator.generate(
        levelId: '2026-10-07',
        difficulty: TangoDifficulty.orta,
      );

      bool hasDifference = false;
      for (int r = 0; r < l1.gridSize; r++) {
        for (int c = 0; c < l1.gridSize; c++) {
          if (l1.initialGrid[r][c] != l2.initialGrid[r][c]) {
            hasDifference = true;
            break;
          }
        }
      }

      expect(hasDifference, isTrue, reason: 'İki farklı gün aynı bulmacayı üretmemeli.');
    });

    test('TangoDifficultyScheduler 365 gün boyunca art arda 3 aynı zorluk getirmez', () {
      final history = <TangoDifficulty>[];
      for (var day = 0; day < 365; day++) {
        final d = TangoDifficultyScheduler.getDifficultyForDays(day);
        history.add(d);
        if (history.length >= 3) {
          final last3 = history.sublist(history.length - 3);
          expect(
            last3[0] == last3[1] && last3[1] == last3[2],
            isFalse,
            reason: '$day. günde art arda 3 kez ${d.name} geldi',
          );
        }
      }
    });

    test('LocalTangoPuzzleRepository günlük seviyeyi döner', () async {
      const repo = LocalTangoPuzzleRepository();
      final level = await repo.getDaily('2026-10-08');

      expect(level, isNotNull);
      expect(level.gridSize, equals(6));
      expect(level.initialGrid.isNotEmpty, isTrue);
    });
  });
}
