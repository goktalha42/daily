import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/queens/queens_levels.dart';
import 'package:daily_games/games/queens/queens_models.dart';

void main() {
  test('QueensDifficultyScheduler - 365 gün kural testi', () {
    final startDate = DateTime(2026, 1, 1);
    QueensDifficulty? prev1;
    QueensDifficulty? prev2;
    int violationCount = 0;

    for (int i = 0; i < 365; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final diff = QueensDifficultyScheduler.getDifficultyForDate(dateStr);

      if (prev1 != null && prev2 != null && prev1 == prev2 && prev1 == diff) {
        violationCount++;
      }

      prev2 = prev1;
      prev1 = diff;
    }

    expect(violationCount, 0);
  });

  test('Tek tek tüm presetleri doğrula', () {
    // Basit Presets Test
    for (int idx = 0; idx < 365; idx++) {
      final date = DateTime(2026, 1, 1).add(Duration(days: idx));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final level = QueensLevelRepository.getLevelForDate(dateStr);
      
      final n = level.gridSize;
      final sol = level.solution;
      final map = level.regionMap;

      final rows = <int>{};
      final cols = <int>{};
      final regions = <int>{};

      for (final q in sol) {
        rows.add(q[0]);
        cols.add(q[1]);
        regions.add(map[q[0]][q[1]]);
      }

      if (rows.length != n || cols.length != n || regions.length != n) {
        fail('HATA: $dateStr, zorluk: ${level.difficulty.label}, grid: ${n}x$n, rows: ${rows.length}, cols: ${cols.length}, regions: ${regions.length}');
      }
    }
  });
}
