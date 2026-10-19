import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'queens_logic.dart';
import 'queens_models.dart';

/// Queens bulmacasını tohumdan sıfırdan üretir (şablon / sabit liste yok).
///
/// Adımlar:
/// 1. Rastgele geçerli vezir yerleşimi üret (sütun tekil, komşu yok).
/// 2. Her veziri bir bölgenin çekirdeği yapıp bölgeleri rastgele büyüt.
/// 3. Çözücü ile **tek çözüm** doğrula; değilse yeni deneme yap.
/// 4. Kolay seviyede ayrıca tahmin gerektirmeyen (deductive) çözüm şartı aranır.
class QueensGenerator {
  static const int maxAttempts = 3000;

  const QueensGenerator._();

  static QueensLevel generate({
    required String levelId,
    required QueensDifficulty difficulty,
  }) {
    final n = difficulty.gridSize;
    final queensPerUnit = difficulty.queensPerUnit;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'queens-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      if (queensPerUnit == 2) {
        final queens = _randomPlacement2Queens(n, rng);
        if (queens == null) continue;
        final pairs = _pairQueens(queens, rng);
        final regionMap = _growRegionsFromPairs(n, pairs, rng);
        final solutions = QueensLogic.solveBacktracking(
          n,
          regionMap,
          queensPerUnit: 2,
        );
        if (solutions.length != 1) continue;

        // İnsan aklıyla çözülebilirlik kontrolü:
        // Kör tahmin gerektiren bölümleri tamamen filtrele; sadece %100 mantıksal çıkarımla
        // baştan sona çözülebilen (deductive.isSolvable == true) seviyeleri kabul et.
        final deductive = QueensLogic.solveDeductively(n, regionMap, queensPerUnit: 2);
        if (!deductive.isSolvable) {
          continue;
        }

        final solution = solutions.first.map((p) => [p.x, p.y]).toList();
        return QueensLevel(
          id: levelId,
          gridSize: n,
          difficulty: difficulty,
          queensPerUnit: 2,
          regionMap: regionMap,
          solution: solution,
        );
      } else {
        final queens = _randomPlacement(n, rng);
        if (queens == null) continue;

        final regionMap = _growRegions(n, queens, rng);
        if (!_repairToUnique(n, regionMap, queens, rng)) continue;

        final solutions = QueensLogic.solveBacktracking(n, regionMap, queensPerUnit: 1);
        if (solutions.length != 1) continue;

        if (difficulty == QueensDifficulty.kolay &&
            !QueensLogic.solveDeductively(n, regionMap).isSolvable) {
          continue;
        }

        final solution = solutions.first.map((p) => [p.x, p.y]).toList();
        return QueensLevel(
          id: levelId,
          gridSize: n,
          difficulty: difficulty,
          queensPerUnit: 1,
          regionMap: regionMap,
          solution: solution,
        );
      }
    }

    throw StateError(
      'Queens üretilemedi: $levelId (${difficulty.name}) $maxAttempts denemede tek çözüm bulunamadı.',
    );
  }

  /// Tahtanın kanonik metni (bölge haritası); parmak izi için kullanılır.
  static String canonical(QueensLevel level) {
    return level.regionMap.map((row) => row.join(',')).join('|');
  }

  static String fingerprint(QueensLevel level) {
    return PuzzleSeed.fingerprint('queens:${canonical(level)}');
  }

  /// Birden fazla çözüm varsa, fazladan çözümün bir vezir hücresini komşu bölgeye
  /// aktararak o çözümü bozar. Amaçlanan çözüm (queens) hiçbir zaman bozulmaz;
  /// bölgeler bağlantılı ve boş olmayan kalır.
  static bool _repairToUnique(
    int n,
    List<List<int>> map,
    List<Point<int>> queens,
    Random rng,
  ) {
    final intended = queens.toSet();

    for (var i = 0; i < 150; i++) {
      final sols = QueensLogic.solveBacktracking(n, map);
      if (sols.length == 1) return true;

      final other = sols.firstWhere(
        (s) => !(s.length == intended.length && s.every(intended.contains)),
        orElse: () => sols.last,
      );
      final targets = other.where((p) => !intended.contains(p)).toList()..shuffle(rng);

      var changed = false;
      for (final p in targets) {
        final region = map[p.x][p.y];
        final neighborRegions = <int>{};
        for (final d in const [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          final nr = p.x + d[0];
          final nc = p.y + d[1];
          if (nr < 0 || nc < 0 || nr >= n || nc >= n) continue;
          if (map[nr][nc] != region) neighborRegions.add(map[nr][nc]);
        }
        if (neighborRegions.isEmpty) continue;
        if (!_staysConnected(n, map, p.x, p.y, region)) continue;

        final options = neighborRegions.toList()..shuffle(rng);
        map[p.x][p.y] = options.first;
        changed = true;
        break;
      }
      if (!changed) return false;
    }
    return QueensLogic.solveBacktracking(n, map).length == 1;
  }

  /// (r,c) hücresi bölgeden çıkarılırsa bölgenin kalanı bağlantılı ve boş değil mi?
  static bool _staysConnected(int n, List<List<int>> map, int r, int c, int region) {
    final cells = <Point<int>>[];
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (map[i][j] == region && !(i == r && j == c)) cells.add(Point(i, j));
      }
    }
    if (cells.isEmpty) return false;

    final remaining = cells.toSet();
    final stack = [cells.first];
    final visited = <Point<int>>{cells.first};
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      for (final d in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final next = Point(cur.x + d[0], cur.y + d[1]);
        if (remaining.contains(next) && visited.add(next)) stack.add(next);
      }
    }
    return visited.length == remaining.length;
  }

  /// Her satırda 1 vezir; sütunlar tekil, ardışık satırlarda komşu değil.
  static List<Point<int>>? _randomPlacement(int n, Random rng) {
    final queens = <Point<int>>[];
    final usedCols = List<bool>.filled(n, false);

    bool place(int row) {
      if (row == n) return true;
      final cols = List<int>.generate(n, (i) => i)..shuffle(rng);
      for (final c in cols) {
        if (usedCols[c]) continue;
        if (row > 0 && (queens[row - 1].y - c).abs() <= 1) continue;
        queens.add(Point(row, c));
        usedCols[c] = true;
        if (place(row + 1)) return true;
        queens.removeLast();
        usedCols[c] = false;
      }
      return false;
    }

    return place(0) ? queens : null;
  }

  /// Vezir hücrelerinden başlayıp rastgele komşu hücreleri bölgeye katarak büyütür.
  /// Bölgeler bağlantılıdır ve bölge numaraları satırlara bağlı değildir.
  static List<List<int>> _growRegions(int n, List<Point<int>> queens, Random rng) {
    final regionIds = List<int>.generate(n, (i) => i)..shuffle(rng);
    final map = List.generate(n, (_) => List<int>.filled(n, -1));

    for (var i = 0; i < n; i++) {
      map[queens[i].x][queens[i].y] = regionIds[i];
    }

    const dirs = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    var remaining = n * n - n;
    while (remaining > 0) {
      final candidates = <List<int>>[];
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (map[r][c] != -1) continue;
          final neighbors = <int>[];
          for (final d in dirs) {
            final nr = r + d[0];
            final nc = c + d[1];
            if (nr < 0 || nc < 0 || nr >= n || nc >= n) continue;
            if (map[nr][nc] != -1) neighbors.add(map[nr][nc]);
          }
          if (neighbors.isNotEmpty) {
            candidates.add([r, c, neighbors[rng.nextInt(neighbors.length)]]);
          }
        }
      }
      final pick = candidates[rng.nextInt(candidates.length)];
      map[pick[0]][pick[1]] = pick[2];
      remaining--;
    }

    return map;
  }

  static List<Point<int>>? _randomPlacement2Queens(int n, Random rng) {
    for (var att = 0; att < 50; att++) {
      final queens = <Point<int>>[];
      final colCounts = List<int>.filled(n, 0);

      bool placeRow(int r) {
        if (r == n) return true;
        final validCols = <int>[];
        for (int c = 0; c < n; c++) {
          if (colCounts[c] >= 2) continue;
          bool touches = false;
          for (final q in queens) {
            if ((q.x - r).abs() <= 1 && (q.y - c).abs() <= 1) {
              touches = true;
              break;
            }
          }
          if (!touches) validCols.add(c);
        }
        final pairs = <List<int>>[];
        for (int i = 0; i < validCols.length; i++) {
          for (int j = i + 1; j < validCols.length; j++) {
            if ((validCols[i] - validCols[j]).abs() > 1) {
              pairs.add([validCols[i], validCols[j]]);
            }
          }
        }
        pairs.shuffle(rng);
        for (final pair in pairs) {
          queens.add(Point(r, pair[0]));
          queens.add(Point(r, pair[1]));
          colCounts[pair[0]]++;
          colCounts[pair[1]]++;
          if (placeRow(r + 1)) return true;
          queens.removeLast();
          queens.removeLast();
          colCounts[pair[0]]--;
          colCounts[pair[1]]--;
        }
        return false;
      }

      if (placeRow(0)) return queens;
    }
    return null;
  }

  static List<List<Point<int>>> _pairQueens(List<Point<int>> queens, Random rng) {
    final available = List<Point<int>>.from(queens)..shuffle(rng);
    final pairs = <List<Point<int>>>[];
    while (available.isNotEmpty) {
      final q1 = available.removeLast();
      available.sort((a, b) {
        final d1 = (a.x - q1.x).abs() + (a.y - q1.y).abs();
        final d2 = (b.x - q1.x).abs() + (b.y - q1.y).abs();
        return d1.compareTo(d2);
      });
      final q2 = available.removeAt(0);
      pairs.add([q1, q2]);
    }
    return pairs;
  }

  static List<List<int>> _growRegionsFromPairs(int n, List<List<Point<int>>> pairs, Random rng) {
    final map = List.generate(n, (_) => List<int>.filled(n, -1));
    for (int reg = 0; reg < pairs.length; reg++) {
      for (final q in pairs[reg]) {
        map[q.x][q.y] = reg;
      }
    }
    const dirs = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    int remaining = n * n - 2 * n;
    while (remaining > 0) {
      final candidates = <List<int>>[];
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          if (map[r][c] != -1) continue;
          final neighborRegs = <int>[];
          for (final d in dirs) {
            final nr = r + d[0];
            final nc = c + d[1];
            if (nr >= 0 && nr < n && nc >= 0 && nc < n && map[nr][nc] != -1) {
              neighborRegs.add(map[nr][nc]);
            }
          }
          if (neighborRegs.isNotEmpty) {
            candidates.add([r, c, neighborRegs[rng.nextInt(neighborRegs.length)]]);
          }
        }
      }
      if (candidates.isEmpty) break;
      final pick = candidates[rng.nextInt(candidates.length)];
      map[pick[0]][pick[1]] = pick[2];
      remaining--;
    }
    return map;
  }
}
