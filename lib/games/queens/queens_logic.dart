import 'dart:math';
import 'queens_models.dart';

class QueensLogic {
  /// Tahtadaki çakışmaları kontrol eder ve işaretler.
  /// Kazanma koşulu: Tam N vezir ve 0 çakışma.
  static bool validateGrid(List<List<QueensCell>> grid, int gridSize) {
    // Tüm çakışma bayraklarını sıfırla
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        grid[r][c].isConflict = false;
      }
    }

    final queenCells = <QueensCell>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (grid[r][c].content == CellContent.queen) {
          queenCells.add(grid[r][c]);
        }
      }
    }

    bool hasConflict = false;

    for (int i = 0; i < queenCells.length; i++) {
      for (int j = i + 1; j < queenCells.length; j++) {
        final q1 = queenCells[i];
        final q2 = queenCells[j];

        bool isConflicting = false;

        // 1. Aynı Satır
        if (q1.row == q2.row) isConflicting = true;

        // 2. Aynı Sütun
        if (q1.col == q2.col) isConflicting = true;

        // 3. Aynı Renk Bölgesi
        if (q1.regionId == q2.regionId) isConflicting = true;

        // 4. 8-Yönlü Bitişiklik (Yatay, dikey veya çapraz komşu)
        final dr = (q1.row - q2.row).abs();
        final dc = (q1.col - q2.col).abs();
        if (dr <= 1 && dc <= 1) isConflicting = true;

        if (isConflicting) {
          q1.isConflict = true;
          q2.isConflict = true;
          hasConflict = true;
        }
      }
    }

    return queenCells.length == gridSize && !hasConflict;
  }

  /// Vezir yerleştirildiğinde etrafını (satır, sütun, bölge ve 8 komşu) otomatik 'X' ile doldurur.
  /// Yapılan değişikliklerin koordinatlarını geri alabilmek için döner.
  static List<Point<int>> autoCrossNeighbors(
    List<List<QueensCell>> grid,
    int qRow,
    int qCol,
    int gridSize,
  ) {
    final modified = <Point<int>>[];
    final regionId = grid[qRow][qCol].regionId;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (r == qRow && c == qCol) continue;

        final isSameRow = r == qRow;
        final isSameCol = c == qCol;
        final isSameRegion = grid[r][c].regionId == regionId;
        final isAdjacent = (r - qRow).abs() <= 1 && (c - qCol).abs() <= 1;

        if (isSameRow || isSameCol || isSameRegion || isAdjacent) {
          if (grid[r][c].content == CellContent.empty) {
            grid[r][c].content = CellContent.cross;
            modified.add(Point(r, c));
          }
        }
      }
    }

    return modified;
  }

  /// Backtracking kullanarak tahtanın çözüm sayısını bulur (Tek Çözüm / Unique Solution kontrolü).
  static List<List<Point<int>>> solveBacktracking(
    int gridSize,
    List<List<int>> regionMap, {
    int maxSolutions = 2,
  }) {
    final solutions = <List<Point<int>>>[];
    final queens = <Point<int>>[];
    final usedCols = List<bool>.filled(gridSize, false);
    final usedRegions = List<bool>.filled(gridSize, false);

    void search(int row) {
      if (solutions.length >= maxSolutions) return;
      if (row == gridSize) {
        solutions.add(List.from(queens));
        return;
      }

      for (int col = 0; col < gridSize; col++) {
        if (usedCols[col]) continue;
        final region = regionMap[row][col];
        if (usedRegions[region]) continue;

        // 8-yönlü komşuluk kontrolü
        bool touches = false;
        for (final q in queens) {
          if ((q.x - row).abs() <= 1 && (q.y - col).abs() <= 1) {
            touches = true;
            break;
          }
        }
        if (touches) continue;

        // Yerleştir ve devam et
        queens.add(Point(row, col));
        usedCols[col] = true;
        usedRegions[region] = true;

        search(row + 1);

        queens.removeLast();
        usedCols[col] = false;
        usedRegions[region] = false;
      }
    }

    search(0);
    return solutions;
  }

  /// Saf insan mantığıyla (Deductive Elimination) tahtanın tahmin yapmadan çözülebilirliğini doğrular.
  static DeductiveResult solveDeductively(int gridSize, List<List<int>> regionMap) {
    // Olası adaylar tablosu (her hücre true = aday olabilir)
    final candidates = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => true),
    );
    final placedQueens = <Point<int>>[];
    int steps = 0;

    bool changed = true;
    while (changed && placedQueens.length < gridSize) {
      changed = false;
      steps++;

      // KURAL 1: Bir satırda, sütunda veya bölgede sadece 1 aday kalmışsa -> VEZİR
      // Satırlar
      for (int r = 0; r < gridSize; r++) {
        final possibleCols = <int>[];
        for (int c = 0; c < gridSize; c++) {
          if (candidates[r][c]) possibleCols.add(c);
        }
        if (possibleCols.length == 1) {
          final c = possibleCols.first;
          if (!placedQueens.contains(Point(r, c))) {
            _placeDeductiveQueen(r, c, gridSize, regionMap, candidates, placedQueens);
            changed = true;
          }
        }
      }

      // Sütunlar
      for (int c = 0; c < gridSize; c++) {
        final possibleRows = <int>[];
        for (int r = 0; r < gridSize; r++) {
          if (candidates[r][c]) possibleRows.add(r);
        }
        if (possibleRows.length == 1) {
          final r = possibleRows.first;
          if (!placedQueens.contains(Point(r, c))) {
            _placeDeductiveQueen(r, c, gridSize, regionMap, candidates, placedQueens);
            changed = true;
          }
        }
      }

      // Bölgeler
      for (int reg = 0; reg < gridSize; reg++) {
        final possibleCells = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[r][c] == reg && candidates[r][c]) {
              possibleCells.add(Point(r, c));
            }
          }
        }
        if (possibleCells.length == 1) {
          final pt = possibleCells.first;
          if (!placedQueens.contains(pt)) {
            _placeDeductiveQueen(pt.x, pt.y, gridSize, regionMap, candidates, placedQueens);
            changed = true;
          }
        }
      }

      if (changed) continue;

      // KURAL 2: Çizgi-Bölge İndirgemesi (Line-Region Reduction)
      // Eğer bir bölgenin tüm adayları tek bir satırda ise, o satırın bölge dışındaki tüm adaylarını ele.
      for (int reg = 0; reg < gridSize; reg++) {
        final regCells = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[r][c] == reg && candidates[r][c]) {
              regCells.add(Point(r, c));
            }
          }
        }
        if (regCells.isEmpty) continue;

        final firstRow = regCells.first.x;
        if (regCells.every((pt) => pt.x == firstRow)) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[firstRow][c] != reg && candidates[firstRow][c]) {
              candidates[firstRow][c] = false;
              changed = true;
            }
          }
        }

        final firstCol = regCells.first.y;
        if (regCells.every((pt) => pt.y == firstCol)) {
          for (int r = 0; r < gridSize; r++) {
            if (regionMap[r][firstCol] != reg && candidates[r][firstCol]) {
              candidates[r][firstCol] = false;
              changed = true;
            }
          }
        }
      }

      if (changed) continue;

      // KURAL 3: Ortak Komşuluk Gölgesi (Adjacency Dominance)
      // Bir bölgenin tüm olası adaylarına bitişik olan herhangi bir hücre asla vezir olamaz -> Ele
      for (int reg = 0; reg < gridSize; reg++) {
        final regCells = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[r][c] == reg && candidates[r][c]) {
              regCells.add(Point(r, c));
            }
          }
        }
        if (regCells.length <= 1) continue;

        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (!candidates[r][c]) continue;
            if (regionMap[r][c] == reg) continue;

            // Bu (r,c) hücresi bölgedeki TÜM adaylara 8-yönlü komşu mu?
            bool touchesAll = true;
            for (final cand in regCells) {
              if ((cand.x - r).abs() > 1 || (cand.y - c).abs() > 1) {
                touchesAll = false;
                break;
              }
            }
            if (touchesAll) {
              candidates[r][c] = false;
              changed = true;
            }
          }
        }
      }
    }

    final isSolvable = placedQueens.length == gridSize;
    return DeductiveResult(
      isSolvable: isSolvable,
      solution: placedQueens,
      steps: steps,
    );
  }

  static void _placeDeductiveQueen(
    int qr,
    int qc,
    int gridSize,
    List<List<int>> regionMap,
    List<List<bool>> candidates,
    List<Point<int>> placedQueens,
  ) {
    placedQueens.add(Point(qr, qc));
    final reg = regionMap[qr][qc];

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (r == qr && c == qc) continue;
        if (r == qr || c == qc || regionMap[r][c] == reg) {
          candidates[r][c] = false;
        } else if ((r - qr).abs() <= 1 && (c - qc).abs() <= 1) {
          candidates[r][c] = false;
        }
      }
    }
  }
}

class DeductiveResult {
  final bool isSolvable;
  final List<Point<int>> solution;
  final int steps;

  const DeductiveResult({
    required this.isSolvable,
    required this.solution,
    required this.steps,
  });
}
