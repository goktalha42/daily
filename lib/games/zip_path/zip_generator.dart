import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'zip_logic.dart';
import 'zip_models.dart';

/// Zip (Sayı Yolu) bulmacalarını tohumdan sıfırdan üretir.
///
/// LinkedIn Sayı Yolu Mantığı:
/// - Hücre silinmez; kullanıcı tahtadaki TÜM kareleri gezmek zorundadır (Hamiltonian Path).
/// - Bazı karelerin arasına hatlar (çit/duvar) çekilir ve oyuncu bu hatların üzerinden geçemez, etrafından dolanır.
/// - Kolay: 4x4 tahta, 4-6 nokta.
/// - Orta: 5x5 tahta, 7-10 nokta, 2-4 hat.
/// - Zor: 5x5 tahta, 12-16 nokta, 4-8 hat!
class ZipGenerator {
  static const int maxAttempts = 1500;

  const ZipGenerator._();

  static ZipLevel generate({
    required String levelId,
    ZipDifficulty difficulty = ZipDifficulty.orta,
  }) {
    final n = difficulty.gridSize;
    final totalCells = n * n;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'zip-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      // 1. Tüm tahtayı gezen Hamiltonian yol üret (kendini kesmeyen n*n ortogonal yol)
      final path = _generateHamiltonianPath(n, rng);
      if (path == null || path.length != totalCells) continue;

      // 2. Çözüm yolunu engellemeyen kareler arası hatlar (çitler) oluştur
      final edgeWalls = _generateEdgeWalls(n, path, difficulty, rng);

      // 3. Yol üzerinden sıralı kontrol noktaları seç (LinkedIn tarzı)
      final checkpoints = _placeCheckpoints(path, difficulty, rng);
      if (checkpoints == null) continue;

      // 4. Tek çözüm garantisi doğrula
      final solCount = ZipLogic.countSolutions(
        n,
        checkpoints,
        walls: const {},
        edgeWalls: edgeWalls,
        maxCount: 2,
      );

      if (solCount == 1) {
        return ZipLevel(
          id: levelId,
          gridSize: n,
          numberPoints: checkpoints,
          walls: const {},
          edgeWalls: edgeWalls,
          solutionPath: path,
          difficulty: difficulty,
        );
      }
    }

    // Beklenmedik durumda güvenli varsayılan seviye oluştur
    return _createDeterministicFallback(levelId, difficulty);
  }

  /// Warnsdorff kuralı destekli DFS ile Hamiltonian Yol üretimi
  static List<Point>? _generateHamiltonianPath(int n, Random rng) {
    final dirs = const [
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    final startPoints = [
      const Point(0, 0),
      Point(0, n - 1),
      Point(n - 1, 0),
      Point(n - 1, n - 1),
      Point(rng.nextInt(n), rng.nextInt(n)),
    ];
    final start = startPoints[rng.nextInt(startPoints.length)];

    final path = <Point>[start];
    final visited = <Point>{start};
    final total = n * n;

    int countUnvisitedNeighbors(Point p) {
      int count = 0;
      for (final d in dirs) {
        final nr = p.row + d.row;
        final nc = p.col + d.col;
        if (nr >= 0 && nr < n && nc >= 0 && nc < n) {
          if (!visited.contains(Point(nr, nc))) count++;
        }
      }
      return count;
    }

    bool dfs(Point current) {
      if (path.length == total) return true;

      final neighbors = <Point>[];
      for (final d in dirs) {
        final nr = current.row + d.row;
        final nc = current.col + d.col;
        if (nr >= 0 && nr < n && nc >= 0 && nc < n) {
          final next = Point(nr, nc);
          if (!visited.contains(next)) {
            neighbors.add(next);
          }
        }
      }

      if (neighbors.isEmpty) return false;

      neighbors.shuffle(rng);
      neighbors.sort((a, b) => countUnvisitedNeighbors(a).compareTo(countUnvisitedNeighbors(b)));

      for (final next in neighbors) {
        visited.add(next);
        path.add(next);

        if (dfs(next)) return true;

        path.removeLast();
        visited.remove(next);
      }

      return false;
    }

    if (dfs(start)) {
      return path;
    }
    return null;
  }

  /// Çözüm yolunun KULLANMADIĞI bitişik hücre çiftleri arasına hatlar/çitler yerleştirir.
  /// Çözüm yolu bu kenarları kullanmadığından çözüm geçerliliği ASLA bozulmaz.
  static Set<ZipEdgeWall> _generateEdgeWalls(
    int n,
    List<Point> path,
    ZipDifficulty difficulty,
    Random rng,
  ) {
    final pathConsecutive = <ZipEdgeWall>{};
    for (int i = 0; i < path.length - 1; i++) {
      pathConsecutive.add(ZipEdgeWall(path[i], path[i + 1]));
    }

    final candidates = <ZipEdgeWall>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final p = Point(r, c);
        if (c + 1 < n) {
          final right = Point(r, c + 1);
          final wall = ZipEdgeWall(p, right);
          if (!pathConsecutive.contains(wall)) {
            candidates.add(wall);
          }
        }
        if (r + 1 < n) {
          final down = Point(r + 1, c);
          final wall = ZipEdgeWall(p, down);
          if (!pathConsecutive.contains(wall)) {
            candidates.add(wall);
          }
        }
      }
    }

    candidates.shuffle(rng);

    final targetWalls = switch (difficulty) {
      ZipDifficulty.kolay => rng.nextInt(2), // 0 veya 1
      ZipDifficulty.orta => 2 + rng.nextInt(3), // 2 ila 4
      ZipDifficulty.zor => 4 + rng.nextInt(4), // 4 ila 7
    };

    return candidates.take(targetWalls.clamp(0, candidates.length)).toSet();
  }

  /// Yol üzerine kontrol noktaları yerleştirir
  static Map<Point, int>? _placeCheckpoints(
    List<Point> path,
    ZipDifficulty difficulty,
    Random rng,
  ) {
    final len = path.length;
    final cornerIndices = <int>[0]; // 1. numara her zaman başlangıç

    // Viraj (dönüş) noktalarını topla
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

    // Hedef kontrol noktası sayısı
    // Zor günlerde 12-16 nokta (kullanıcının talebi: 'mesela bazı zor günlerde 16 tane nokta olsun')
    final targetCount = switch (difficulty) {
      ZipDifficulty.kolay => (cornerIndices.length > 6 ? 6 : cornerIndices.length).clamp(4, 6),
      ZipDifficulty.orta => (cornerIndices.length > 9 ? 9 : cornerIndices.length).clamp(6, 10),
      ZipDifficulty.zor => (12 + rng.nextInt(5)).clamp(12, 16),
    };

    final selectedSet = <int>{0, len - 1};

    // Önce virajlardan ekle
    final shuffledCorners = cornerIndices.where((idx) => idx != 0 && idx != len - 1).toList()..shuffle(rng);
    for (final c in shuffledCorners) {
      if (selectedSet.length >= targetCount) break;
      selectedSet.add(c);
    }

    // Yeterli değilse aradaki açık basamaklardan ekle
    if (selectedSet.length < targetCount) {
      final allIndices = List.generate(len, (i) => i)..shuffle(rng);
      for (final idx in allIndices) {
        if (selectedSet.length >= targetCount) break;
        selectedSet.add(idx);
      }
    }

    final selectedIndices = selectedSet.toList()..sort();

    final map = <Point, int>{};
    for (int i = 0; i < selectedIndices.length; i++) {
      map[path[selectedIndices[i]]] = i + 1;
    }

    return map;
  }

  /// Güvenli deterministik yedek
  static ZipLevel _createDeterministicFallback(String levelId, ZipDifficulty difficulty) {
    final n = difficulty.gridSize;
    final path = <Point>[];
    for (int r = 0; r < n; r++) {
      if (r % 2 == 0) {
        for (int c = 0; c < n; c++) {
          path.add(Point(r, c));
        }
      } else {
        for (int c = n - 1; c >= 0; c--) {
          path.add(Point(r, c));
        }
      }
    }

    final checkpoints = <Point, int>{};
    final edgeWalls = <ZipEdgeWall>{};

    if (difficulty == ZipDifficulty.zor && n == 5) {
      final indices = [0, 1, 2, 4, 5, 7, 9, 10, 12, 14, 15, 17, 19, 21, 23, 24];
      for (int i = 0; i < indices.length; i++) {
        checkpoints[path[indices[i]]] = i + 1;
      }
      edgeWalls.add(const ZipEdgeWall(Point(0, 0), Point(1, 0)));
      edgeWalls.add(const ZipEdgeWall(Point(0, 2), Point(1, 2)));
      edgeWalls.add(const ZipEdgeWall(Point(2, 2), Point(3, 2)));
      edgeWalls.add(const ZipEdgeWall(Point(2, 4), Point(3, 4)));
    } else {
      for (int i = 0; i < path.length; i += (n <= 4 ? 4 : 3)) {
        checkpoints[path[i]] = checkpoints.length + 1;
      }
      if (!checkpoints.containsKey(path.last)) {
        checkpoints[path.last] = checkpoints.length + 1;
      }
    }

    return ZipLevel(
      id: levelId,
      gridSize: n,
      numberPoints: checkpoints,
      walls: const {},
      edgeWalls: edgeWalls,
      solutionPath: path,
      difficulty: difficulty,
    );
  }
}
