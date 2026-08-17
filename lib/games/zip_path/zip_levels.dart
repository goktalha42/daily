import 'zip_models.dart';

class ZipLevelRepository {
  // Her seviye doğrulanmış bir yola sahiptir.
  // Oyuncu 1'den başlayıp sayıları sırayla izleyen kesişmeyen bir yol çizmelidir.
  // Tüm numara noktalarından geçmek yeterlidir, tüm hücrelerden geçmek gerekmez.

  static final List<ZipLevel> _presets = [
    // Seviye 1: 4x4, Kolay
    // Sayılar: 1(0,0) → 2(0,3) → 3(3,3) → 4(3,0)
    // Çözüm yol: (0,0)→(0,1)→(0,2)→(0,3)→(1,3)→(2,3)→(3,3)→(3,2)→(3,1)→(3,0)
    ZipLevel(
      id: '2026-08-17',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 3): 2,
        const Point(3, 3): 3,
        const Point(3, 0): 4,
      },
    ),
    // Seviye 2: 4x4, Orta
    // Sayılar: 1(0,0) → 2(0,2) → 3(2,2) → 4(2,0) → 5(3,3)
    // Çözüm yol: (0,0)→(0,1)→(0,2)→(1,2)→(2,2)→(2,1)→(2,0)→(3,0)→(3,1)→(3,2)→(3,3)
    ZipLevel(
      id: '2026-08-18',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 2): 2,
        const Point(2, 2): 3,
        const Point(2, 0): 4,
        const Point(3, 3): 5,
      },
    ),
    // Seviye 3: 5x5, Zor
    // Sayılar: 1(0,0) → 2(0,4) → 3(2,2) → 4(4,4) → 5(4,0)
    ZipLevel(
      id: '2026-08-19',
      gridSize: 5,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 4): 2,
        const Point(2, 2): 3,
        const Point(4, 4): 4,
        const Point(4, 0): 5,
      },
    ),
  ];

  static ZipLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
