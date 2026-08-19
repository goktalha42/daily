import 'zip_models.dart';

class ZipLevelRepository {
  // Her seviye doğrulanmış bir yola sahiptir.
  // Oyuncu 1'den başlayıp sayıları sırayla izleyen kesişmeyen bir yol çizmelidir.

  static final List<ZipLevel> _presets = [
    // Seviye 1: 4x4, Kolay
    ZipLevel(
      id: 'zip_1',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 3): 2,
        const Point(3, 3): 3,
        const Point(3, 0): 4,
      },
    ),
    // Seviye 2: 4x4, Orta
    ZipLevel(
      id: 'zip_2',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 2): 2,
        const Point(2, 2): 3,
        const Point(2, 0): 4,
        const Point(3, 3): 5,
      },
    ),
    // Seviye 3: 4x4, Salyangoz
    ZipLevel(
      id: 'zip_3',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 3): 2,
        const Point(3, 3): 3,
        const Point(3, 1): 4,
        const Point(1, 1): 5,
        const Point(2, 2): 6,
      },
    ),
    // Seviye 4: 5x5, Zor
    ZipLevel(
      id: 'zip_4',
      gridSize: 5,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 4): 2,
        const Point(2, 2): 3,
        const Point(4, 4): 4,
        const Point(4, 0): 5,
      },
    ),
    // Seviye 5: 5x5, Usta
    ZipLevel(
      id: 'zip_5',
      gridSize: 5,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(1, 4): 2,
        const Point(3, 4): 3,
        const Point(4, 1): 4,
        const Point(2, 0): 5,
        const Point(2, 2): 6,
      },
    ),
  ];

  static ZipLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
