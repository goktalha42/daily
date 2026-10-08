import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'zip_logic.dart';
import 'zip_models.dart';

/// Zip (Sayı Yolu) bulmacalarını tohumdan sıfırdan üretir.
///
/// LinkedIn Sayı Yolu Mantığı:
/// - Engelli veya duvar hücreleri YOKTUR (walls = {}).
/// - Kullanıcı tahtadaki istisnasız TÜM kareleri gezmek zorundadır (Hamiltonian Path).
/// - 1. ve 2. seviyeler 4x4 (16 kare), 3. seviye 5x5 (25 kare).
/// - 1'den başlayıp sıralı kontrol noktalarından geçerek tek bir çizgide bitirilir.
class ZipGenerator {
  static const int maxAttempts = 1200;

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

      // 2. Yol üzerinden sıralı kontrol noktaları seç (LinkedIn tarzı)
      final checkpoints = _placeCheckpoints(path, difficulty, rng);
      if (checkpoints == null) continue;

      // 3. Tek çözüm garantisi doğrula
      final solCount = ZipLogic.countSolutions(
        n,
        checkpoints,
        walls: const {},
        maxCount: 2,
      );

      if (solCount == 1) {
        return ZipLevel(
          id: levelId,
          gridSize: n,
          numberPoints: checkpoints,
          walls: const {},
          solutionPath: path,
          difficulty: difficulty,
        );
      }
    }

    // Beklenmedik durumda güvenli varsayılan seviye oluştur
    return _createDeterministicFallback(levelId, difficulty);
  }

  /// Warnsdorff kuralı destekli DFS ile Hamiltonian Yol (tüm tahtayı kapsayan yol) üretimi
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

      // Warnsdorff kuralı: en az açık komşusu kalan hücreye öncelik ver
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

      // Komşuları kalan serbestlik derecesine göre sırala (azdan çoğa) + küçük rastgele karıştırma
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

    // Bitiş noktası da her zaman son kontrol noktası adayıdır
    if (!cornerIndices.contains(len - 1)) {
      cornerIndices.add(len - 1);
    }

    // Zorluğa göre hedef numara sayısı
    final targetCount = switch (difficulty) {
      ZipDifficulty.kolay => (cornerIndices.length > 6 ? 6 : cornerIndices.length).clamp(4, 7),
      ZipDifficulty.orta => (cornerIndices.length > 5 ? 5 : cornerIndices.length).clamp(4, 6),
      ZipDifficulty.zor => (cornerIndices.length > 7 ? 7 : cornerIndices.length).clamp(5, 8),
    };

    // Eğer virajlar targetCount'tan fazlaysa aralarından dengeli dağılmış olanları seç
    final selectedIndices = <int>[0];
    if (cornerIndices.length > 2) {
      final middleCandidates = cornerIndices.sublist(1, cornerIndices.length - 1);
      final needed = (targetCount - 2).clamp(1, middleCandidates.length);

      // Eşit aralıklarla seç
      final step = middleCandidates.length / needed;
      for (int i = 0; i < needed; i++) {
        final idx = (i * step).floor();
        selectedIndices.add(middleCandidates[idx]);
      }
    }
    selectedIndices.add(len - 1);
    selectedIndices.sort();

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
    // S-şeklinde tam Hamiltonian yol
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

    final checkpoints = <Point, int>{
      path.first: 1,
      path[n - 1]: 2,
      path[2 * n - 1]: 3,
      path.last: 4,
    };

    return ZipLevel(
      id: levelId,
      gridSize: n,
      numberPoints: checkpoints,
      walls: const {},
      solutionPath: path,
      difficulty: difficulty,
    );
  }
}
