import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/queens/queens_models.dart';
import 'package:daily_games/games/queens/queens_logic.dart';
import 'package:daily_games/games/tango/tango_models.dart';
import 'package:daily_games/games/tango/tango_logic.dart';
import 'package:daily_games/games/zip_path/zip_models.dart';
import 'package:daily_games/games/zip_path/zip_logic.dart';
import 'package:daily_games/games/crossclimb/crossclimb_levels.dart';

void main() {
  group('Queens Logic Tests', () {
    test('Detects conflict when two Queens share the same row', () {
      final grid = List.generate(
        4,
        (r) => List.generate(4, (c) => QueensCell(row: r, col: c, regionId: r)),
      );

      grid[0][0].content = CellContent.queen;
      grid[0][2].content = CellContent.queen;

      final isSolved = QueensLogic.validateGrid(grid, 4);

      expect(isSolved, isFalse);
      expect(grid[0][0].isConflict, isTrue);
      expect(grid[0][2].isConflict, isTrue);
    });

    test('Detects conflict when two Queens touch diagonally', () {
      final grid = List.generate(
        4,
        (r) => List.generate(4, (c) => QueensCell(row: r, col: c, regionId: r)),
      );

      grid[0][0].content = CellContent.queen;
      grid[1][1].content = CellContent.queen;

      final isSolved = QueensLogic.validateGrid(grid, 4);

      expect(isSolved, isFalse);
      expect(grid[0][0].isConflict, isTrue);
      expect(grid[1][1].isConflict, isTrue);
    });
  });

  group('Tango Logic Tests', () {
    test('Detects conflict when 3 identical symbols are adjacent in a row', () {
      final grid = List.generate(
        4,
        (r) => List.generate(4, (c) => TangoCell(row: r, col: c)),
      );

      grid[0][0].symbol = TangoSymbol.sun;
      grid[0][1].symbol = TangoSymbol.sun;
      grid[0][2].symbol = TangoSymbol.sun;

      final isSolved = TangoLogic.validateGrid(grid, 4, []);

      expect(isSolved, isFalse);
      expect(grid[0][0].isConflict, isTrue);
      expect(grid[0][1].isConflict, isTrue);
      expect(grid[0][2].isConflict, isTrue);
    });
  });

  group('Zip Path Logic Tests', () {
    test('Validates continuous path starting from 1 with full grid traversal', () {
      final points = {
        const Point(0, 0): 1,
        const Point(1, 0): 2,
      };

      final validPath = [
        const Point(0, 0),
        const Point(0, 1),
        const Point(1, 1),
        const Point(1, 0),
      ];

      final isSolved = ZipLogic.validatePath(validPath, points, 2);
      expect(isSolved, isTrue);
    });

    test('Fails when path skips or starts at wrong number', () {
      final points = {
        const Point(0, 0): 1,
        const Point(1, 0): 2,
      };

      final invalidPath = [
        const Point(0, 1), // Did not start at 1
        const Point(1, 1),
        const Point(1, 0),
        const Point(0, 0),
      ];

      final isSolved = ZipLogic.validatePath(invalidPath, points, 2);
      expect(isSolved, isFalse);
    });
  });

  group('Crossclimb Word Chain Validation', () {
    test('All preset levels have valid 1-letter change chains', () {
      // Use the first 3 preset levels  
      final levels = [
        CrossclimbLevelRepository.getLevelForDate('2026-08-17'),
        CrossclimbLevelRepository.getLevelForDate('2026-08-18'),
        CrossclimbLevelRepository.getLevelForDate('2026-08-19'),
      ];

      for (final level in levels) {
        String prev = level.startWord;
        for (final step in level.steps) {
          final current = step.targetWord;
          
          // Both words must have the same length
          expect(prev.length, equals(current.length),
              reason: 'Word length mismatch: $prev → $current in level ${level.id}');
          
          // Count differing characters
          int diffCount = 0;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != current[i]) diffCount++;
          }
          
          expect(diffCount, equals(1),
              reason: 'Expected exactly 1 char diff: $prev → $current (got $diffCount) in level ${level.id}');
          
          prev = current;
        }
        
        // Last step should reach endWord
        expect(level.steps.last.targetWord, equals(level.endWord),
            reason: 'Chain does not reach endWord in level ${level.id}');
      }
    });
  });
}
