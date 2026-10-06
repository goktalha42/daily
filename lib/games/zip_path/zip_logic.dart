import 'zip_models.dart';

class ZipLogic {
  static bool validatePath(
    List<Point> path,
    Map<Point, int> numberPoints,
    int gridSize, {
    Set<Point> walls = const {},
  }) {
    if (path.isEmpty) return false;

    // Kendini kesme kontrolü
    if (path.toSet().length != path.length) return false;

    // Duvara basma kontrolü
    for (final pt in path) {
      if (walls.contains(pt)) return false;
    }

    // Kural: Tüm erişilebilir boş kareleri tam bir kez geçer (README Bölüm 3.3)
    // Eğer seviyede duvar tanımlanmışsa açık kare sayısı, tanımlanmamışsa en azından sayılar
    if (walls.isNotEmpty) {
      final accessibleCells = (gridSize * gridSize) - walls.length;
      if (path.length != accessibleCells) return false;
    }

    final maxNumber = numberPoints.values.reduce((a, b) => a > b ? a : b);

    // Yol 1 numaralı noktadan başlamalı
    if (numberPoints[path.first] != 1) return false;

    int currentTarget = 1;

    for (int i = 0; i < path.length; i++) {
      final point = path[i];

      // Nokta bir numara içeriyor mu?
      if (numberPoints.containsKey(point)) {
        final numVal = numberPoints[point]!;
        if (numVal == currentTarget) {
          currentTarget++;
        } else if (numVal > currentTarget) {
          return false;
        }
      }

      // Adımlar arası bitişiklik (yalnızca yatay/dikey)
      if (i < path.length - 1) {
        final next = path[i + 1];
        final dr = (point.row - next.row).abs();
        final dc = (point.col - next.col).abs();

        if (dr + dc != 1) {
          return false;
        }
      }
    }

    return currentTarget > maxNumber;
  }

  /// 1'den başlayıp maxNumber'a kadar tüm açık kareleri gezen yolları sayar.
  /// [maxCount]: 2 çözüm bulunduğunda erken döner.
  static int countSolutions(
    int gridSize,
    Map<Point, int> numberPoints, {
    Set<Point> walls = const {},
    int maxCount = 2,
  }) {
    if (numberPoints.isEmpty) return 0;

    // 1 numaralı noktayı bul
    Point? start;
    for (final entry in numberPoints.entries) {
      if (entry.value == 1) {
        start = entry.key;
        break;
      }
    }
    if (start == null) return 0;

    final maxNumber = numberPoints.values.reduce((a, b) => a > b ? a : b);
    final targetTotal = (gridSize * gridSize) - walls.length;
    final visited = <Point>{start};
    int solutions = 0;

    final dirs = const [
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    bool backtrack(Point current, int target) {
      if (numberPoints[current] == maxNumber) {
        if (target > maxNumber) {
          // Eğer duvar varsa tüm açık kareler gezilmiş olmalı; duvar yoksa yol tamamlanmış olmalı
          if (walls.isEmpty || visited.length == targetTotal) {
            solutions++;
          }
        }
        return solutions >= maxCount;
      }

      for (final d in dirs) {
        final nr = current.row + d.row;
        final nc = current.col + d.col;
        if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) continue;

        final next = Point(nr, nc);
        if (walls.contains(next)) continue;
        if (visited.contains(next)) continue;

        final nextNum = numberPoints[next];
        int nextTarget = target;

        if (nextNum != null) {
          if (nextNum != target) {
            continue;
          }
          nextTarget = target + 1;
        }

        visited.add(next);
        final stop = backtrack(next, nextTarget);
        visited.remove(next);

        if (stop) return true;
      }

      return false;
    }

    backtrack(start, 2);
    return solutions;
  }
}
