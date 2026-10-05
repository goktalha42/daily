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

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'queens-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      final queens = _randomPlacement(n, rng);
      if (queens == null) continue;

      final regionMap = _growRegions(n, queens, rng);
      if (!_repairToUnique(n, regionMap, queens, rng)) continue;

      final solutions = QueensLogic.solveBacktracking(n, regionMap);
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
        regionMap: regionMap,
        solution: solution,
      );
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
}
