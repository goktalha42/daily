import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'zip_logic.dart';
import 'zip_models.dart';

/// Zip (Sayı Yolu) bulmacalarını tohumdan sıfırdan üretir.
///
/// README Bölüm 4.2 standardı:
/// "Rastgele Hamilton yolu → kontrol noktaları ve duvarlar yoldan türetilir."
/// Yolun geçmediği kareler duvar yapılır, böylece tüm açık karelerin tek bir
/// çizgiyle gezilmesi %100 tek çözüm garantisi sağlar.
class ZipGenerator {
  static const int maxAttempts = 1000;

  const ZipGenerator._();

  static ZipLevel generate({
    required String levelId,
    ZipDifficulty difficulty = ZipDifficulty.orta,
  }) {
    final n = difficulty.gridSize;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'zip-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      // Hedef yol uzunluğu
      final minLength = switch (difficulty) {
        ZipDifficulty.kolay => 10,
        ZipDifficulty.orta => 16,
        ZipDifficulty.zor => 24,
      };

      // 1. Rastgele kendini kesmeyen ortogonal yol üret
      final path = _generateRandomWalk(n, minLength, rng);
      if (path == null) continue;

      // 2. Yolun dışındaki tüm hücreleri duvar yap
      final pathSet = path.toSet();
      final walls = <Point>{};
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          final pt = Point(r, c);
          if (!pathSet.contains(pt)) {
            walls.add(pt);
          }
        }
      }

      // 3. Yol üzerinden sıralı kontrol noktaları seç (1...K)
      final checkpoints = _placeCheckpoints(path, difficulty, rng);
      if (checkpoints == null) continue;

      // 4. Tek çözüm garantisi doğrula
      final solCount = ZipLogic.countSolutions(
        n,
        checkpoints,
        walls: walls,
        maxCount: 2,
      );

      if (solCount == 1) {
        return ZipLevel(
          id: levelId,
          gridSize: n,
          numberPoints: checkpoints,
          walls: walls,
          solutionPath: path,
          difficulty: difficulty,
        );
      }
    }

    throw StateError(
      'Zip bulmacası üretilemedi: $levelId (${difficulty.name}) $maxAttempts denemede tek çözüm bulunamadı.',
    );
  }

  /// Rastgele kendini kesmeyen ortogonal yürüyüş (Self-Avoiding Walk)
  static List<Point>? _generateRandomWalk(int n, int targetLength, Random rng) {
    final dirs = const [
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    // Kenar ve köşelerden başla
    final startPoints = [
      const Point(0, 0),
      Point(0, n - 1),
      Point(n - 1, 0),
      Point(n - 1, n - 1),
    ];
    final start = startPoints[rng.nextInt(startPoints.length)];

    final path = <Point>[start];
    final visited = <Point>{start};

    bool dfs(Point current) {
      if (path.length >= targetLength) return true;

      final shuffledDirs = List<Point>.from(dirs)..shuffle(rng);

      for (final d in shuffledDirs) {
        final nr = current.row + d.row;
        final nc = current.col + d.col;

        if (nr >= 0 && nr < n && nc >= 0 && nc < n) {
          final next = Point(nr, nc);
          if (!visited.contains(next)) {
            visited.add(next);
            path.add(next);

            if (dfs(next)) return true;

            path.removeLast();
            visited.remove(next);
          }
        }
      }

      return false;
    }

    if (dfs(start)) {
      return path;
    }
    return null;
  }

  /// Yol üzerine kontrol noktaları yerleştirir
  static Map<Point, int>? _placeCheckpoints(
    List<Point> path,
    ZipDifficulty difficulty,
    Random rng,
  ) {
    final len = path.length;
    final cornerIndices = <int>[0];

    // Köşe (dönüş) noktalarını tespit et
    for (int i = 1; i < len - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];

      final dr1 = curr.row - prev.row;
      final dc1 = curr.col - prev.col;
      final dr2 = next.row - curr.row;
      final dc2 = next.col - curr.col;

      if (dr1 != dr2 || dc1 != dc2) {
        cornerIndices.add(i);
      }
    }

    if (!cornerIndices.contains(len - 1)) {
      cornerIndices.add(len - 1);
    }

    cornerIndices.sort();

    // Kontrol noktası haritası oluştur
    final map = <Point, int>{};
    for (int i = 0; i < cornerIndices.length; i++) {
      map[path[cornerIndices[i]]] = i + 1;
    }

    return map;
  }
}
