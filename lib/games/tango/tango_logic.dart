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

  /// Belirli bir hücreye sembol konulmasının geçerli olup olmadığını hızlıca kontrol eder.
  static bool isPlacementValid(
    List<List<TangoSymbol>> grid,
    int gridSize,
    List<TangoConstraint> constraints,
    int r,
    int c,
    TangoSymbol symbol,
  ) {
    final half = gridSize ~/ 2;

    // 1. Satır ve Sütun kotası kontrolü
    int rowCount = 0;
    for (int j = 0; j < gridSize; j++) {
      final s = (j == c) ? symbol : grid[r][j];
      if (s == symbol) rowCount++;
    }
    if (rowCount > half) return false;

    int colCount = 0;
    for (int i = 0; i < gridSize; i++) {
      final s = (i == r) ? symbol : grid[i][c];
      if (s == symbol) colCount++;
    }
    if (colCount > half) return false;

    // 2. Ardışık 3 aynı sembol kuralı (Yatay)
    for (int start = c - 2; start <= c; start++) {
      if (start >= 0 && start + 2 < gridSize) {
        final s0 = (start == c) ? symbol : grid[r][start];
        final s1 = (start + 1 == c) ? symbol : grid[r][start + 1];
        final s2 = (start + 2 == c) ? symbol : grid[r][start + 2];
        if (s0 != TangoSymbol.empty && s0 == s1 && s1 == s2) {
          return false;
        }
      }
    }

    // 3. Ardışık 3 aynı sembol kuralı (Dikey)
    for (int start = r - 2; start <= r; start++) {
      if (start >= 0 && start + 2 < gridSize) {
        final s0 = (start == r) ? symbol : grid[start][c];
        final s1 = (start + 1 == r) ? symbol : grid[start + 1][c];
        final s2 = (start + 2 == r) ? symbol : grid[start + 2][c];
        if (s0 != TangoSymbol.empty && s0 == s1 && s1 == s2) {
          return false;
        }
      }
    }

    // 4. İlgili kısıtlar (= ve x)
    for (final cons in constraints) {
      if ((cons.r1 == r && cons.c1 == c) || (cons.r2 == r && cons.c2 == c)) {
        final s1 = (cons.r1 == r && cons.c1 == c) ? symbol : grid[cons.r1][cons.c1];
        final s2 = (cons.r2 == r && cons.c2 == c) ? symbol : grid[cons.r2][cons.c2];

        if (s1 != TangoSymbol.empty && s2 != TangoSymbol.empty) {
          if (cons.type == ConstraintType.equal && s1 != s2) return false;
          if (cons.type == ConstraintType.opposite && s1 == s2) return false;
        }
      }
    }

    return true;
  }

  /// Backtracking ile olası çözüm sayısını hesaplar.
  /// [maxCount]: Hızlı karar için 2 çözüm bulunduğunda erken döner.
  static int countSolutions(
    List<List<TangoSymbol>> initialGrid,
    int gridSize,
    List<TangoConstraint> constraints, {
    int maxCount = 2,
  }) {
    // Matrisi kopyala
    final grid = List.generate(
      gridSize,
      (r) => List<TangoSymbol>.from(initialGrid[r]),
    );

    int count = 0;

    bool backtrack(int r, int c) {
      if (r == gridSize) {
        // Satır ve sütunların özdeşlik kontrolü (Takuzu kuralı)
        if (_hasIdenticalLines(grid, gridSize)) return false;

        count++;
        return count >= maxCount;
      }

      final nextR = (c + 1 == gridSize) ? r + 1 : r;
      final nextC = (c + 1 == gridSize) ? 0 : c + 1;

      if (grid[r][c] != TangoSymbol.empty) {
        return backtrack(nextR, nextC);
      }

      for (final sym in [TangoSymbol.sun, TangoSymbol.moon]) {
        if (isPlacementValid(grid, gridSize, constraints, r, c, sym)) {
          grid[r][c] = sym;
          final stop = backtrack(nextR, nextC);
          grid[r][c] = TangoSymbol.empty;
          if (stop) return true;
        }
      }

      return false;
    }

    backtrack(0, 0);
    return count;
  }

  /// Tahtadaki çözümü bulur (varsa).
  static List<List<TangoSymbol>>? solve(
    List<List<TangoSymbol>> initialGrid,
    int gridSize,
    List<TangoConstraint> constraints,
  ) {
    final grid = List.generate(
      gridSize,
      (r) => List<TangoSymbol>.from(initialGrid[r]),
    );

    List<List<TangoSymbol>>? solution;

    bool backtrack(int r, int c) {
      if (r == gridSize) {
        if (_hasIdenticalLines(grid, gridSize)) return false;
        solution = List.generate(
          gridSize,
          (row) => List<TangoSymbol>.from(grid[row]),
        );
        return true;
      }

      final nextR = (c + 1 == gridSize) ? r + 1 : r;
      final nextC = (c + 1 == gridSize) ? 0 : c + 1;

      if (grid[r][c] != TangoSymbol.empty) {
        return backtrack(nextR, nextC);
      }

      for (final sym in [TangoSymbol.sun, TangoSymbol.moon]) {
        if (isPlacementValid(grid, gridSize, constraints, r, c, sym)) {
          grid[r][c] = sym;
          if (backtrack(nextR, nextC)) return true;
          grid[r][c] = TangoSymbol.empty;
        }
      }

      return false;
    }

    backtrack(0, 0);
    return solution;
  }

  /// Tamamlanmış satır veya sütunlarda birbirinin tıpatıp aynısı olan var mı?
  static bool _hasIdenticalLines(List<List<TangoSymbol>> grid, int gridSize) {
    // Satırlar arası karşılaştırma
    for (int i = 0; i < gridSize; i++) {
      for (int j = i + 1; j < gridSize; j++) {
        bool identical = true;
        for (int k = 0; k < gridSize; k++) {
          if (grid[i][k] != grid[j][k]) {
            identical = false;
            break;
          }
        }
        if (identical) return true;
      }
    }

    // Sütunlar arası karşılaştırma
    for (int i = 0; i < gridSize; i++) {
      for (int j = i + 1; j < gridSize; j++) {
        bool identical = true;
        for (int k = 0; k < gridSize; k++) {
          if (grid[k][i] != grid[k][j]) {
            identical = false;
            break;
          }
        }
        if (identical) return true;
      }
    }

    return false;
  }

  /// Sadece insan mantığı kurallarını (tahmin/bifurcation olmadan) uygulayarak
  /// bulmacanın çözülebilirliğini analiz eder.
  static TangoDeductiveResult solveDeductively(
    List<List<TangoSymbol>> initialGrid,
    int gridSize,
    List<TangoConstraint> constraints,
  ) {
    final grid = List.generate(
      gridSize,
      (r) => List<TangoSymbol>.from(initialGrid[r]),
    );

    final half = gridSize ~/ 2;
    bool progress = true;

    TangoSymbol opposite(TangoSymbol s) =>
        (s == TangoSymbol.sun) ? TangoSymbol.moon : TangoSymbol.sun;

    while (progress) {
      progress = false;

      // 1. Kısıtlar: Doğrudan yayılım (= ve x)
      for (final cons in constraints) {
        final s1 = grid[cons.r1][cons.c1];
        final s2 = grid[cons.r2][cons.c2];

        if (cons.type == ConstraintType.equal) {
          if (s1 != TangoSymbol.empty && s2 == TangoSymbol.empty) {
            grid[cons.r2][cons.c2] = s1;
            progress = true;
          } else if (s2 != TangoSymbol.empty && s1 == TangoSymbol.empty) {
            grid[cons.r1][cons.c1] = s2;
            progress = true;
          }
        } else if (cons.type == ConstraintType.opposite) {
          if (s1 != TangoSymbol.empty && s2 == TangoSymbol.empty) {
            grid[cons.r2][cons.c2] = opposite(s1);
            progress = true;
          } else if (s2 != TangoSymbol.empty && s1 == TangoSymbol.empty) {
            grid[cons.r1][cons.c1] = opposite(s2);
            progress = true;
          }
        }
      }

      // 2. Yan Yana İkililer (XX_ -> O veya _XX -> O)
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          final sym = grid[r][c];
          if (sym == TangoSymbol.empty) continue;

          // Yatay ikili
          if (c + 1 < gridSize && grid[r][c + 1] == sym) {
            if (c - 1 >= 0 && grid[r][c - 1] == TangoSymbol.empty) {
              grid[r][c - 1] = opposite(sym);
              progress = true;
            }
            if (c + 2 < gridSize && grid[r][c + 2] == TangoSymbol.empty) {
              grid[r][c + 2] = opposite(sym);
              progress = true;
            }
          }

          // Dikey ikili
          if (r + 1 < gridSize && grid[r + 1][c] == sym) {
            if (r - 1 >= 0 && grid[r - 1][c] == TangoSymbol.empty) {
              grid[r - 1][c] = opposite(sym);
              progress = true;
            }
            if (r + 2 < gridSize && grid[r + 2][c] == TangoSymbol.empty) {
              grid[r + 2][c] = opposite(sym);
              progress = true;
            }
          }
        }
      }

      // 3. Aralıklı İkililer (X_X -> O)
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          final sym = grid[r][c];
          if (sym == TangoSymbol.empty) continue;

          // Yatay sandviç
          if (c + 2 < gridSize && grid[r][c + 2] == sym && grid[r][c + 1] == TangoSymbol.empty) {
            grid[r][c + 1] = opposite(sym);
            progress = true;
          }

          // Dikey sandviç
          if (r + 2 < gridSize && grid[r + 2][c] == sym && grid[r + 1][c] == TangoSymbol.empty) {
            grid[r + 1][c] = opposite(sym);
            progress = true;
          }
        }
      }

      // 4. Satır ve Sütun Kotası (Kota dolunca kalan boşluklar zıt olur)
      for (int i = 0; i < gridSize; i++) {
        int rowSun = 0, rowMoon = 0;
        int colSun = 0, colMoon = 0;

        for (int j = 0; j < gridSize; j++) {
          if (grid[i][j] == TangoSymbol.sun) rowSun++;
          if (grid[i][j] == TangoSymbol.moon) rowMoon++;

          if (grid[j][i] == TangoSymbol.sun) colSun++;
          if (grid[j][i] == TangoSymbol.moon) colMoon++;
        }

        if (rowSun == half) {
          for (int j = 0; j < gridSize; j++) {
            if (grid[i][j] == TangoSymbol.empty) {
              grid[i][j] = TangoSymbol.moon;
              progress = true;
            }
          }
        } else if (rowMoon == half) {
          for (int j = 0; j < gridSize; j++) {
            if (grid[i][j] == TangoSymbol.empty) {
              grid[i][j] = TangoSymbol.sun;
              progress = true;
            }
          }
        }

        if (colSun == half) {
          for (int j = 0; j < gridSize; j++) {
            if (grid[j][i] == TangoSymbol.empty) {
              grid[j][i] = TangoSymbol.moon;
              progress = true;
            }
          }
        } else if (colMoon == half) {
          for (int j = 0; j < gridSize; j++) {
            if (grid[j][i] == TangoSymbol.empty) {
              grid[j][i] = TangoSymbol.sun;
              progress = true;
            }
          }
        }
      }

      // 5. İleri Kısıt Çıkarımları (= kısıtının yan komşuları)
      for (final cons in constraints) {
        if (cons.type == ConstraintType.equal) {
          // Yatay eşitlik
          if (cons.r1 == cons.r2 && (cons.c2 - cons.c1).abs() == 1) {
            final r = cons.r1;
            final minC = cons.c1 < cons.c2 ? cons.c1 : cons.c2;
            final maxC = cons.c1 < cons.c2 ? cons.c2 : cons.c1;

            if (grid[r][minC] == TangoSymbol.empty && grid[r][maxC] == TangoSymbol.empty) {
              if (minC - 1 >= 0 && grid[r][minC - 1] != TangoSymbol.empty) {
                final opp = opposite(grid[r][minC - 1]);
                grid[r][minC] = opp;
                grid[r][maxC] = opp;
                progress = true;
              } else if (maxC + 1 < gridSize && grid[r][maxC + 1] != TangoSymbol.empty) {
                final opp = opposite(grid[r][maxC + 1]);
                grid[r][minC] = opp;
                grid[r][maxC] = opp;
                progress = true;
              }
            }
          }

          // Dikey eşitlik
          if (cons.c1 == cons.c2 && (cons.r2 - cons.r1).abs() == 1) {
            final c = cons.c1;
            final minR = cons.r1 < cons.r2 ? cons.r1 : cons.r2;
            final maxR = cons.r1 < cons.r2 ? cons.r2 : cons.r1;

            if (grid[minR][c] == TangoSymbol.empty && grid[maxR][c] == TangoSymbol.empty) {
              if (minR - 1 >= 0 && grid[minR - 1][c] != TangoSymbol.empty) {
                final opp = opposite(grid[minR - 1][c]);
                grid[minR][c] = opp;
                grid[maxR][c] = opp;
                progress = true;
              } else if (maxR + 1 < gridSize && grid[maxR + 1][c] != TangoSymbol.empty) {
                final opp = opposite(grid[maxR + 1][c]);
                grid[minR][c] = opp;
                grid[maxR][c] = opp;
                progress = true;
              }
            }
          }
        }
      }
    }

    int filledCount = 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] != TangoSymbol.empty) filledCount++;
      }
    }

    final totalCells = gridSize * gridSize;
    return TangoDeductiveResult(
      isSolvable: filledCount == totalCells,
      filledCount: filledCount,
      totalCells: totalCells,
      finalGrid: grid,
    );
  }
}


