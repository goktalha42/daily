import 'tango_models.dart';

class TangoLogic {
  static bool validateGrid(
    List<List<TangoCell>> grid,
    int gridSize,
    List<TangoConstraint> constraints,
  ) {
    // Reset conflicts
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        grid[r][c].isConflict = false;
      }
    }

    bool hasConflict = false;
    final half = gridSize ~/ 2;

    // 1. Check Row & Column Symbol Counts (max N/2 suns and N/2 moons)
    for (var i = 0; i < gridSize; i++) {
      int rowSun = 0, rowMoon = 0;
      int colSun = 0, colMoon = 0;

      for (var j = 0; j < gridSize; j++) {
        // Row check
        if (grid[i][j].symbol == TangoSymbol.sun) rowSun++;
        if (grid[i][j].symbol == TangoSymbol.moon) rowMoon++;

        // Col check
        if (grid[j][i].symbol == TangoSymbol.sun) colSun++;
        if (grid[j][i].symbol == TangoSymbol.moon) colMoon++;
      }

      if (rowSun > half || rowMoon > half) {
        for (var j = 0; j < gridSize; j++) {
          if (grid[i][j].symbol != TangoSymbol.empty) grid[i][j].isConflict = true;
        }
        hasConflict = true;
      }

      if (colSun > half || colMoon > half) {
        for (var j = 0; j < gridSize; j++) {
          if (grid[j][i].symbol != TangoSymbol.empty) grid[j][i].isConflict = true;
        }
        hasConflict = true;
      }
    }

    // 2. Check 3-in-a-row consecutive rule
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final sym = grid[r][c].symbol;
        if (sym == TangoSymbol.empty) continue;

        // Horizontal 3 in a row
        if (c <= gridSize - 3) {
          if (grid[r][c + 1].symbol == sym && grid[r][c + 2].symbol == sym) {
            grid[r][c].isConflict = true;
            grid[r][c + 1].isConflict = true;
            grid[r][c + 2].isConflict = true;
            hasConflict = true;
          }
        }

        // Vertical 3 in a row
        if (r <= gridSize - 3) {
          if (grid[r + 1][c].symbol == sym && grid[r + 2][c].symbol == sym) {
            grid[r][c].isConflict = true;
            grid[r + 1][c].isConflict = true;
            grid[r + 2][c].isConflict = true;
            hasConflict = true;
          }
        }
      }
    }

    // 3. Check Constraints (= and x)
    for (var cons in constraints) {
      final s1 = grid[cons.r1][cons.c1].symbol;
      final s2 = grid[cons.r2][cons.c2].symbol;

      if (s1 != TangoSymbol.empty && s2 != TangoSymbol.empty) {
        if (cons.type == ConstraintType.equal && s1 != s2) {
          grid[cons.r1][cons.c1].isConflict = true;
          grid[cons.r2][cons.c2].isConflict = true;
          hasConflict = true;
        }
        if (cons.type == ConstraintType.opposite && s1 == s2) {
          grid[cons.r1][cons.c1].isConflict = true;
          grid[cons.r2][cons.c2].isConflict = true;
          hasConflict = true;
        }
      }
    }

    // Check if fully filled
    bool isFilled = true;
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (grid[r][c].symbol == TangoSymbol.empty) {
          isFilled = false;
          break;
        }
      }
    }

    return isFilled && !hasConflict;
  }
}
