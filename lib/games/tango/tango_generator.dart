import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'tango_logic.dart';
import 'tango_models.dart';

/// Tango (Güneş & Ay / Takuzu) bulmacalarını tohumdan sıfırdan üretir.
///
/// Şablon veya sabit liste yoktur. Belirli bir gün kimliği ve zorluk için
/// her zaman deterministik, tek çözümlü ve tutarlı bir bulmaca üretir.
class TangoGenerator {
  static const int maxAttempts = 1000;

  const TangoGenerator._();

  static TangoLevel generate({
    required String levelId,
    TangoDifficulty difficulty = TangoDifficulty.orta,
  }) {
    final n = difficulty.gridSize;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'tango-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      // 1. Rastgele geçerli tam çözüm matrisi üret
      final solution = _generateFullSolution(n, rng);
      if (solution == null) continue;

      // 2. Çözümden potansiyel komşu kısıtlarını (= ve x) topla
      final allConstraints = _extractPotentialConstraints(solution, n);
      allConstraints.shuffle(rng);

      // Zorluk derecesine göre hedef kısıt sayısı
      final targetConstraintsCount = switch (difficulty) {
        TangoDifficulty.kolay => 5 + rng.nextInt(3), // 5-7
        TangoDifficulty.orta => 4 + rng.nextInt(3),  // 4-6
        TangoDifficulty.zor => 4 + rng.nextInt(2),   // 4-5
      };

      final chosenConstraints = allConstraints.take(targetConstraintsCount).toList();

      // 3. Başlangıçta tüm hücreleri ipucu olarak başlatıp tek çözümlülüğü bozmadan buda
      final initialGrid = List.generate(
        n,
        (r) => List<TangoSymbol>.from(solution[r]),
      );

      // Rastgele sırada hücre koordinatları
      final cellCoords = <Point<int>>[];
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          cellCoords.add(Point(r, c));
        }
      }
      cellCoords.shuffle(rng);

      // Hedef kalan sabit hücre sayısı aralığı (oyuncunun tıkanmasını önler)
      final minClues = switch (difficulty) {
        TangoDifficulty.kolay => 12,
        TangoDifficulty.orta => 8,
        TangoDifficulty.zor => 6,
      };

      int currentClues = n * n;
      for (final p in cellCoords) {
        if (currentClues <= minClues) break;

        final original = initialGrid[p.x][p.y];
        initialGrid[p.x][p.y] = TangoSymbol.empty;

        // 1. Tek çözümlülük bozuldu mu kontrol et
        final solCount = TangoLogic.countSolutions(
          initialGrid,
          n,
          chosenConstraints,
          maxCount: 2,
        );

        if (solCount != 1) {
          initialGrid[p.x][p.y] = original;
          continue;
        }

        // 2. İnsan mantığıyla (tahmin/deneme yanılma olmadan) çözülebilirlik korundu mu?
        final deductive = TangoLogic.solveDeductively(
          initialGrid,
          n,
          chosenConstraints,
        );

        if (!deductive.isSolvable) {
          // İnsan oyuncu saf mantıkla çözemez, tahmin gerekir -> Hücreyi geri koy!
          initialGrid[p.x][p.y] = original;
        } else {
          currentClues--;
        }
      }

      // Son kontrol: Hem tek çözüm olmalı HEM DE saf mantıkla %100 çözülebilir olmalı!
      final finalDeductive = TangoLogic.solveDeductively(
        initialGrid,
        n,
        chosenConstraints,
      );

      if (finalDeductive.isSolvable &&
          TangoLogic.countSolutions(initialGrid, n, chosenConstraints, maxCount: 2) == 1) {
        return TangoLevel(
          id: levelId,
          gridSize: n,
          initialGrid: initialGrid,
          constraints: chosenConstraints,
          solution: solution,
          difficulty: difficulty,
        );
      }
    }

    throw StateError(
      'Tango bulmacası üretilemedi: $levelId (${difficulty.name}) $maxAttempts denemede tek çözüm bulunamadı.',
    );
  }

  /// Backtracking ile rastgele geçerli tam bir çözüm matrisi üretir.
  static List<List<TangoSymbol>>? _generateFullSolution(int n, Random rng) {
    final grid = List.generate(
      n,
      (_) => List.filled(n, TangoSymbol.empty),
    );

    bool backtrack(int r, int c) {
      if (r == n) {
        // Satır ve sütun benzersizliği kontrolü
        return true;
      }

      final nextR = (c + 1 == n) ? r + 1 : r;
      final nextC = (c + 1 == n) ? 0 : c + 1;

      final symbols = [TangoSymbol.sun, TangoSymbol.moon];
      symbols.shuffle(rng);

      for (final sym in symbols) {
        if (TangoLogic.isPlacementValid(grid, n, const [], r, c, sym)) {
          grid[r][c] = sym;

          // Satır tamamlandığında önceki satırlarla aynı olup olmadığı kontrolü
          if (c == n - 1 && _rowMatchesAnyPrevious(grid, r, n)) {
            grid[r][c] = TangoSymbol.empty;
            continue;
          }

          if (backtrack(nextR, nextC)) return true;
          grid[r][c] = TangoSymbol.empty;
        }
      }

      return false;
    }

    if (backtrack(0, 0)) {
      return grid;
    }
    return null;
  }

  static bool _rowMatchesAnyPrevious(List<List<TangoSymbol>> grid, int r, int n) {
    for (int prev = 0; prev < r; prev++) {
      bool same = true;
      for (int c = 0; c < n; c++) {
        if (grid[prev][c] != grid[r][c]) {
          same = false;
          break;
        }
      }
      if (same) return true;
    }
    return false;
  }

  /// Çözüm matrisindeki geçerli tüm komşu kısıtlarını çıkarır.
  static List<TangoConstraint> _extractPotentialConstraints(
    List<List<TangoSymbol>> solution,
    int n,
  ) {
    final list = <TangoConstraint>[];

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        // Yatay komşu (sağ)
        if (c + 1 < n) {
          final s1 = solution[r][c];
          final s2 = solution[r][c + 1];
          final type = (s1 == s2) ? ConstraintType.equal : ConstraintType.opposite;
          list.add(TangoConstraint(r1: r, c1: c, r2: r, c2: c + 1, type: type));
        }

        // Dikey komşu (alt)
        if (r + 1 < n) {
          final s1 = solution[r][c];
          final s2 = solution[r + 1][c];
          final type = (s1 == s2) ? ConstraintType.equal : ConstraintType.opposite;
          list.add(TangoConstraint(r1: r, c1: c, r2: r + 1, c2: c, type: type));
        }
      }
    }

    return list;
  }
}
