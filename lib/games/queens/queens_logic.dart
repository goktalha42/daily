import 'dart:math';
import 'queens_models.dart';

class QueensLogic {
  /// Tahtadaki çakışmaları kontrol eder ve işaretler.
  /// Kazanma koşulu: Tam N * queensPerUnit vezir ve 0 çakışma.
  static bool validateGrid(
    List<List<QueensCell>> grid,
    int gridSize, {
    int queensPerUnit = 1,
  }) {
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

    // 1. 8-Yönlü Bitişiklik (Yatay, dikey veya çapraz komşu asla dokunamaz)
    for (int i = 0; i < queenCells.length; i++) {
      for (int j = i + 1; j < queenCells.length; j++) {
        final q1 = queenCells[i];
        final q2 = queenCells[j];
        final dr = (q1.row - q2.row).abs();
        final dc = (q1.col - q2.col).abs();
        if (dr <= 1 && dc <= 1) {
          q1.isConflict = true;
          q2.isConflict = true;
          hasConflict = true;
        }
      }
    }

    // 2. Satır Kotası
    for (int r = 0; r < gridSize; r++) {
      final inRow = queenCells.where((q) => q.row == r).toList();
      if (inRow.length > queensPerUnit) {
        hasConflict = true;
        for (final q in inRow) {
          q.isConflict = true;
        }
      }
    }

    // 3. Sütun Kotası
    for (int c = 0; c < gridSize; c++) {
      final inCol = queenCells.where((q) => q.col == c).toList();
      if (inCol.length > queensPerUnit) {
        hasConflict = true;
        for (final q in inCol) {
          q.isConflict = true;
        }
      }
    }

    // 4. Renk Bölgesi Kotası
    final regionQueens = <int, List<QueensCell>>{};
    for (final q in queenCells) {
      regionQueens.putIfAbsent(q.regionId, () => []).add(q);
    }
    for (final entry in regionQueens.entries) {
      if (entry.value.length > queensPerUnit) {
        hasConflict = true;
        for (final q in entry.value) {
          q.isConflict = true;
        }
      }
    }

    return queenCells.length == (gridSize * queensPerUnit) && !hasConflict;
  }

  /// Vezir yerleştirildiğinde etrafını otomatik 'X' ile doldurur.
  /// 8 komşu her zaman X yapılır; satır, sütun ve bölge ise kotası dolduğunda X ile kapatılır.
  static List<Point<int>> autoCrossNeighbors(
    List<List<QueensCell>> grid,
    int qRow,
    int qCol,
    int gridSize, {
    int queensPerUnit = 1,
  }) {
    final modified = <Point<int>>[];
    final regionId = grid[qRow][qCol].regionId;

    // 1. 8-Yönlü komşular her zaman ✖ yapılır (vezirler asla temas edemez)
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = qRow + dr;
        final nc = qCol + dc;
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          if (grid[nr][nc].content == CellContent.empty) {
            grid[nr][nc].content = CellContent.cross;
            modified.add(Point(nr, nc));
          }
        }
      }
    }

    // 2. Satır kotası dolduysa kalan boşluklar ✖
    int rowQueens = 0;
    for (int c = 0; c < gridSize; c++) {
      if (grid[qRow][c].content == CellContent.queen) rowQueens++;
    }
    if (rowQueens >= queensPerUnit) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[qRow][c].content == CellContent.empty) {
          grid[qRow][c].content = CellContent.cross;
          modified.add(Point(qRow, c));
        }
      }
    }

    // 3. Sütun kotası dolduysa kalan boşluklar ✖
    int colQueens = 0;
    for (int r = 0; r < gridSize; r++) {
      if (grid[r][qCol].content == CellContent.queen) colQueens++;
    }
    if (colQueens >= queensPerUnit) {
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][qCol].content == CellContent.empty) {
          grid[r][qCol].content = CellContent.cross;
          modified.add(Point(r, qCol));
        }
      }
    }

    // 4. Bölge kotası dolduysa kalan boşluklar ✖
    int regQueens = 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c].regionId == regionId && grid[r][c].content == CellContent.queen) {
          regQueens++;
        }
      }
    }
    if (regQueens >= queensPerUnit) {
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (grid[r][c].regionId == regionId && grid[r][c].content == CellContent.empty) {
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
    int queensPerUnit = 1,
    int maxSolutions = 2,
  }) {
    if (queensPerUnit == 2) {
      return _solve2QueensBacktracking(gridSize, regionMap, maxSolutions: maxSolutions);
    }

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

  static List<List<Point<int>>> _solve2QueensBacktracking(
    int gridSize,
    List<List<int>> regionMap, {
    int maxSolutions = 2,
  }) {
    final solutions = <List<Point<int>>>[];
    final queens = <Point<int>>[];
    final colCounts = List<int>.filled(gridSize, 0);
    final regionCounts = List<int>.filled(gridSize, 0);

    bool place(int r, int queensInRow, int startCol) {
      if (solutions.length >= maxSolutions) return true;
      if (r == gridSize) {
        solutions.add(List.from(queens));
        return solutions.length >= maxSolutions;
      }
      if (queensInRow == 2) {
        return place(r + 1, 0, 0);
      }

      for (int c = startCol; c < gridSize; c++) {
        if (colCounts[c] >= 2) continue;
        final reg = regionMap[r][c];
        if (regionCounts[reg] >= 2) continue;

        bool touches = false;
        for (final q in queens) {
          if ((q.x - r).abs() <= 1 && (q.y - c).abs() <= 1) {
            touches = true;
            break;
          }
        }
        if (touches) continue;

        queens.add(Point(r, c));
        colCounts[c]++;
        regionCounts[reg]++;

        if (place(r, queensInRow + 1, c + 2)) {
          if (solutions.length >= maxSolutions) return true;
        }

        queens.removeLast();
        colCounts[c]--;
        regionCounts[reg]--;
      }
      return false;
    }

    place(0, 0, 0);
    return solutions;
  }

  /// Saf insan mantığıyla (Deductive Elimination) tahtanın tahmin yapmadan çözülebilirliğini doğrular.
  static DeductiveResult solveDeductively(
    int gridSize,
    List<List<int>> regionMap, {
    int queensPerUnit = 1,
  }) {
    final targetQueens = gridSize * queensPerUnit;
    // Olası adaylar tablosu (her hücre true = aday olabilir)
    final candidates = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => true),
    );
    final placedQueens = <Point<int>>[];
    final rowQueens = List<int>.filled(gridSize, 0);
    final colQueens = List<int>.filled(gridSize, 0);
    final regQueens = List<int>.filled(gridSize, 0);
    int steps = 0;

    void placeQueen(int r, int c) {
      placedQueens.add(Point(r, c));
      candidates[r][c] = false;
      final reg = regionMap[r][c];
      rowQueens[r]++;
      colQueens[c]++;
      regQueens[reg]++;

      // 8-yönlü komşular asla vezir olamaz
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = r + dr;
          final nc = c + dc;
          if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
            candidates[nr][nc] = false;
          }
        }
      }

      // Kota dolduysa satır, sütun ve bölgedeki tüm adayları ele
      if (rowQueens[r] >= queensPerUnit) {
        for (int col = 0; col < gridSize; col++) {
          candidates[r][col] = false;
        }
      }
      if (colQueens[c] >= queensPerUnit) {
        for (int row = 0; row < gridSize; row++) {
          candidates[row][c] = false;
        }
      }
      if (regQueens[reg] >= queensPerUnit) {
        for (int ro = 0; ro < gridSize; ro++) {
          for (int co = 0; co < gridSize; co++) {
            if (regionMap[ro][co] == reg) {
              candidates[ro][co] = false;
            }
          }
        }
      }
    }

    bool changed = true;
    while (changed && placedQueens.length < targetQueens) {
      changed = false;
      steps++;

      // KURAL 1: Kalan ihtiyaç ile kalan aday sayısı eşitse -> Hepsi VEZİR
      // Satırlar
      for (int r = 0; r < gridSize; r++) {
        final needed = queensPerUnit - rowQueens[r];
        if (needed <= 0) continue;
        final possibleCols = <int>[];
        for (int c = 0; c < gridSize; c++) {
          if (candidates[r][c]) possibleCols.add(c);
        }
        if (possibleCols.length == needed) {
          // Birbirine temas etmeyen geçerli yerleşim mi?
          bool touches = false;
          for (int i = 0; i < possibleCols.length; i++) {
            for (int j = i + 1; j < possibleCols.length; j++) {
              if ((possibleCols[i] - possibleCols[j]).abs() <= 1) {
                touches = true;
                break;
              }
            }
          }
          if (!touches) {
            for (final c in possibleCols) {
              placeQueen(r, c);
              changed = true;
            }
          }
        }
      }
      if (changed) continue;

      // Sütunlar
      for (int c = 0; c < gridSize; c++) {
        final needed = queensPerUnit - colQueens[c];
        if (needed <= 0) continue;
        final possibleRows = <int>[];
        for (int r = 0; r < gridSize; r++) {
          if (candidates[r][c]) possibleRows.add(r);
        }
        if (possibleRows.length == needed) {
          bool touches = false;
          for (int i = 0; i < possibleRows.length; i++) {
            for (int j = i + 1; j < possibleRows.length; j++) {
              if ((possibleRows[i] - possibleRows[j]).abs() <= 1) {
                touches = true;
                break;
              }
            }
          }
          if (!touches) {
            for (final r in possibleRows) {
              placeQueen(r, c);
              changed = true;
            }
          }
        }
      }
      if (changed) continue;

      // Bölgeler
      for (int reg = 0; reg < gridSize; reg++) {
        final needed = queensPerUnit - regQueens[reg];
        if (needed <= 0) continue;
        final possibleCells = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[r][c] == reg && candidates[r][c]) {
              possibleCells.add(Point(r, c));
            }
          }
        }
        if (possibleCells.length == needed) {
          bool touches = false;
          for (int i = 0; i < possibleCells.length; i++) {
            for (int j = i + 1; j < possibleCells.length; j++) {
              if ((possibleCells[i].x - possibleCells[j].x).abs() <= 1 &&
                  (possibleCells[i].y - possibleCells[j].y).abs() <= 1) {
                touches = true;
                break;
              }
            }
          }
          if (!touches) {
            for (final pt in possibleCells) {
              placeQueen(pt.x, pt.y);
              changed = true;
            }
          }
        }
      }
      if (changed) continue;

      // KURAL 2: Çift Temas ve Bağımsız Küme İndirgemesi (Touching Pair / Independent Set Exclusion)
      // Master modunda (2 vezir):
      if (queensPerUnit == 2) {
        // A) Bölgeler
        for (int reg = 0; reg < gridSize; reg++) {
          final needed = 2 - regQueens[reg];
          if (needed == 2) {
            final possibleCells = <Point<int>>[];
            for (int r = 0; r < gridSize; r++) {
              for (int c = 0; c < gridSize; c++) {
                if (regionMap[r][c] == reg && candidates[r][c]) {
                  possibleCells.add(Point(r, c));
                }
              }
            }
            if (possibleCells.length >= 2) {
              // 1. Partner İmkânsızlığı: Eğer bir hücre diğer tüm adaylara temas ediyorsa vezir olamaz
              for (final p in possibleCells) {
                final hasPartner = possibleCells.any((other) =>
                    other != p &&
                    (other.x - p.x).abs() > 1 || (other.y - p.y).abs() > 1);
                if (!hasPartner) {
                  candidates[p.x][p.y] = false;
                  changed = true;
                }
              }
              // 2. 3 adaydan 2'si temas ediyorsa 3. hücre kesin vezirdir
              if (possibleCells.length == 3) {
                for (int i = 0; i < 3; i++) {
                  for (int j = i + 1; j < 3; j++) {
                    final p1 = possibleCells[i];
                    final p2 = possibleCells[j];
                    if ((p1.x - p2.x).abs() <= 1 && (p1.y - p2.y).abs() <= 1) {
                      final k = 3 - i - j;
                      final forced = possibleCells[k];
                      placeQueen(forced.x, forced.y);
                      changed = true;
                      break;
                    }
                  }
                  if (changed) break;
                }
              }
            }
          }
        }
        if (changed) continue;

        // B) Satırlar
        for (int r = 0; r < gridSize; r++) {
          final needed = 2 - rowQueens[r];
          if (needed == 2) {
            final possibleCols = <int>[];
            for (int c = 0; c < gridSize; c++) {
              if (candidates[r][c]) possibleCols.add(c);
            }
            if (possibleCols.length == 3) {
              for (int i = 0; i < 3; i++) {
                for (int j = i + 1; j < 3; j++) {
                  if ((possibleCols[i] - possibleCols[j]).abs() <= 1) {
                    final k = 3 - i - j;
                    placeQueen(r, possibleCols[k]);
                    changed = true;
                    break;
                  }
                }
                if (changed) break;
              }
            }
          }
        }
        if (changed) continue;

        // C) Sütunlar
        for (int c = 0; c < gridSize; c++) {
          final needed = 2 - colQueens[c];
          if (needed == 2) {
            final possibleRows = <int>[];
            for (int r = 0; r < gridSize; r++) {
              if (candidates[r][c]) possibleRows.add(r);
            }
            if (possibleRows.length == 3) {
              for (int i = 0; i < 3; i++) {
                for (int j = i + 1; j < 3; j++) {
                  if ((possibleRows[i] - possibleRows[j]).abs() <= 1) {
                    final k = 3 - i - j;
                    placeQueen(possibleRows[k], c);
                    changed = true;
                    break;
                  }
                }
                if (changed) break;
              }
            }
          }
        }
        if (changed) continue;
      }

      // KURAL 3: Çizgi-Bölge İndirgemesi (Pointing & Claiming Line-Region Reduction)
      // 3A. Pointing (Bölge -> Satır / Sütun)
      for (int reg = 0; reg < gridSize; reg++) {
        final needed = queensPerUnit - regQueens[reg];
        if (needed <= 0) continue;
        final regCells = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (regionMap[r][c] == reg && candidates[r][c]) {
              regCells.add(Point(r, c));
            }
          }
        }
        if (regCells.isEmpty) continue;

        // Bölgenin tüm adayları tek satırda mı?
        final firstRow = regCells.first.x;
        if (regCells.every((pt) => pt.x == firstRow)) {
          final rowNeeded = queensPerUnit - rowQueens[firstRow];
          if (rowNeeded == needed) {
            for (int c = 0; c < gridSize; c++) {
              if (regionMap[firstRow][c] != reg && candidates[firstRow][c]) {
                candidates[firstRow][c] = false;
                changed = true;
              }
            }
          }
        }

        // Bölgenin tüm adayları tek sütunda mı?
        final firstCol = regCells.first.y;
        if (regCells.every((pt) => pt.y == firstCol)) {
          final colNeeded = queensPerUnit - colQueens[firstCol];
          if (colNeeded == needed) {
            for (int r = 0; r < gridSize; r++) {
              if (regionMap[r][firstCol] != reg && candidates[r][firstCol]) {
                candidates[r][firstCol] = false;
                changed = true;
              }
            }
          }
        }
      }
      if (changed) continue;

      // 3B. Claiming (Satır / Sütun -> Bölge)
      for (int r = 0; r < gridSize; r++) {
        final needed = queensPerUnit - rowQueens[r];
        if (needed <= 0) continue;
        final rowCandidates = <Point<int>>[];
        for (int c = 0; c < gridSize; c++) {
          if (candidates[r][c]) rowCandidates.add(Point(r, c));
        }
        if (rowCandidates.isNotEmpty) {
          final targetReg = regionMap[r][rowCandidates.first.y];
          if (rowCandidates.every((pt) => regionMap[r][pt.y] == targetReg)) {
            final regNeeded = queensPerUnit - regQueens[targetReg];
            if (regNeeded == needed) {
              for (int ro = 0; ro < gridSize; ro++) {
                if (ro == r) continue;
                for (int co = 0; co < gridSize; co++) {
                  if (regionMap[ro][co] == targetReg && candidates[ro][co]) {
                    candidates[ro][co] = false;
                    changed = true;
                  }
                }
              }
            }
          }
        }
      }
      if (changed) continue;

      for (int c = 0; c < gridSize; c++) {
        final needed = queensPerUnit - colQueens[c];
        if (needed <= 0) continue;
        final colCandidates = <Point<int>>[];
        for (int r = 0; r < gridSize; r++) {
          if (candidates[r][c]) colCandidates.add(Point(r, c));
        }
        if (colCandidates.isNotEmpty) {
          final targetReg = regionMap[colCandidates.first.x][c];
          if (colCandidates.every((pt) => regionMap[pt.x][c] == targetReg)) {
            final regNeeded = queensPerUnit - regQueens[targetReg];
            if (regNeeded == needed) {
              for (int ro = 0; ro < gridSize; ro++) {
                for (int co = 0; co < gridSize; co++) {
                  if (co == c) continue;
                  if (regionMap[ro][co] == targetReg && candidates[ro][co]) {
                    candidates[ro][co] = false;
                    changed = true;
                  }
                }
              }
            }
          }
        }
      }
      if (changed) continue;

      // KURAL 4: Ortak Komşuluk Gölgesi (Adjacency Dominance)
      for (int reg = 0; reg < gridSize; reg++) {
        final needed = queensPerUnit - regQueens[reg];
        if (needed <= 0) continue;
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
      if (changed) continue;

      // KURAL 5: Birim Açlığı / Kontradiksiyon Tespiti (Unit Starvation Contradiction)
      // Bir adaya vezir konulması başka bir bölgenin/satırın/sütunun kotasını doldurmasını engelliyorsa o aday elenir.
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (!candidates[r][c]) continue;

          bool impossible = false;

          // Bu (r,c) karesine vezir konulursa, herhangi bir bölge kotasını doldurabilir mi?
          for (int reg = 0; reg < gridSize; reg++) {
            if (regionMap[r][c] == reg) continue;
            final needed = queensPerUnit - regQueens[reg];
            if (needed <= 0) continue;

            // (r,c)'ye vezir koyduğumuzda bu bölgede kalan geçerli adaylar
            final valid = <Point<int>>[];
            for (int ro = 0; ro < gridSize; ro++) {
              for (int co = 0; co < gridSize; co++) {
                if (regionMap[ro][co] == reg && candidates[ro][co]) {
                  if ((ro - r).abs() > 1 || (co - c).abs() > 1) {
                    valid.add(Point(ro, co));
                  }
                }
              }
            }

            if (valid.length < needed) {
              impossible = true;
              break;
            }

            if (needed == 2) {
              // Kalan adaylar arasında en az bir bağımsız (temas etmeyen) çift var mı?
              bool hasIndependentPair = false;
              for (int i = 0; i < valid.length; i++) {
                for (int j = i + 1; j < valid.length; j++) {
                  if ((valid[i].x - valid[j].x).abs() > 1 ||
                      (valid[i].y - valid[j].y).abs() > 1) {
                    hasIndependentPair = true;
                    break;
                  }
                }
                if (hasIndependentPair) break;
              }
              if (!hasIndependentPair) {
                impossible = true;
                break;
              }
            }
          }

          if (impossible) {
            candidates[r][c] = false;
            changed = true;
          }
        }
      }
    }

    final isSolvable = placedQueens.length == targetQueens;
    return DeductiveResult(
      isSolvable: isSolvable,
      solution: placedQueens,
      steps: steps,
    );
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
