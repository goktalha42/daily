import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/queens/queens_generator.dart';
import 'package:daily_games/games/queens/queens_levels.dart';
import 'package:daily_games/games/queens/queens_logic.dart';
import 'package:daily_games/games/queens/queens_models.dart';

String _dateId(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('QueensGenerator', () {
    test('aynı gün ve zorluk için deterministik', () {
      for (final diff in QueensDifficulty.values) {
        final a = QueensGenerator.generate(levelId: '2026-10-06', difficulty: diff);
        final b = QueensGenerator.generate(levelId: '2026-10-06', difficulty: diff);
        expect(QueensGenerator.fingerprint(a), QueensGenerator.fingerprint(b));
      }
    });

    test('üretilen her tahta geçerli ve TEK çözümlü', () {
      final start = DateTime.utc(2026, 10, 6);
      for (var i = 0; i < 40; i++) {
        final id = _dateId(start.add(Duration(days: i)));
        for (final diff in QueensDifficulty.values) {
          final level = QueensGenerator.generate(levelId: id, difficulty: diff);
          final n = diff.gridSize;
          expect(level.gridSize, n);

          // Bölge sayısı N ve her hücre atanmış.
          final regions = level.regionMap.expand((r) => r).toSet();
          expect(regions.length, n, reason: '$id ${diff.name}');
          expect(regions.every((r) => r >= 0 && r < n), isTrue);

          // Tek çözüm ve verilen çözümle aynı.
          final sols = QueensLogic.solveBacktracking(n, level.regionMap, maxSolutions: 5);
          expect(sols.length, 1, reason: '$id ${diff.name}');
          final expected = sols.first.map((p) => [p.x, p.y]).toList();
          expect(level.solution, expected);
        }
      }
    });

    test('kolay seviye tahmin gerektirmeden çözülebilir', () {
      for (var i = 0; i < 40; i++) {
        final id = _dateId(DateTime.utc(2026, 11, 1).add(Duration(days: i)));
        final level = QueensGenerator.generate(levelId: id, difficulty: QueensDifficulty.kolay);
        expect(QueensLogic.solveDeductively(level.gridSize, level.regionMap).isSolvable, isTrue);
      }
    });

    test('3 yıl boyunca günler birbirinin aynısı olmaz (zor seviye)', () {
      final seen = <String>{};
      final start = DateTime.utc(2029, 10, 6); // yayından ~3 yıl sonra
      for (var i = 0; i < 120; i++) {
        final id = _dateId(start.add(Duration(days: i)));
        final level = QueensGenerator.generate(levelId: id, difficulty: QueensDifficulty.zor);
        expect(seen.add(QueensGenerator.fingerprint(level)), isTrue, reason: 'tekrar: $id');
      }
    });
  });

  group('QueensDifficultyScheduler', () {
    test('365 gün boyunca art arda 3 aynı zorluk gelmez', () {
      final startDate = DateTime(2026, 1, 1);
      QueensDifficulty? prev1;
      QueensDifficulty? prev2;
      var violationCount = 0;

      for (var i = 0; i < 365; i++) {
        final diff = QueensDifficultyScheduler.getDifficultyForDate(
          _dateId(startDate.add(Duration(days: i))),
        );
        if (prev1 != null && prev2 != null && prev1 == prev2 && prev1 == diff) {
          violationCount++;
        }
        prev2 = prev1;
        prev1 = diff;
      }

      expect(violationCount, 0);
    });
  });

  test('LocalQueensPuzzleRepository günlük seviyeyi döner', () async {
    final level = await const LocalQueensPuzzleRepository().getDaily('2026-10-06');
    expect(level.id, '2026-10-06');
    expect(level.solution.length, level.gridSize);
  });
}
