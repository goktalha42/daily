import '../../core/puzzle/puzzle_repository.dart';
import '../../core/puzzle/puzzle_seed.dart';
import 'zip_generator.dart';
import 'zip_models.dart';

/// Zip (Sayı Yolu) için gün bazlı zorluk takvimi.
/// Art arda 3 gün aynı zorluk seviyesi gelmez.
class ZipDifficultyScheduler {
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);
  static final List<ZipDifficulty> _cache = [];

  static ZipDifficulty getDifficultyForDate(String levelId) {
    DateTime date;
    try {
      date = DateTime.parse(levelId);
    } catch (_) {
      date = DateTime.now();
    }
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final days = normalizedDate.difference(_epoch).inDays;
    return getDifficultyForDays(days);
  }

  static ZipDifficulty getDifficultyForDays(int days) {
    final target = days.abs();
    while (_cache.length <= target) {
      _cache.add(_pick(_cache.length));
    }
    return _cache[target];
  }

  static ZipDifficulty _pick(int dayIndex) {
    final candidates = ZipDifficulty.values.toList();
    if (dayIndex >= 2 && _cache[dayIndex - 1] == _cache[dayIndex - 2]) {
      candidates.remove(_cache[dayIndex - 1]);
    }
    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('zip-difficulty', '$dayIndex'));
    return candidates[seed % candidates.length];
  }
}

/// Zip günlük seviye deposu.
/// Her gün tohumdan sıfırdan, tek çözüm garantili üretilir.
class ZipLevelRepository {
  static final Map<String, ZipLevel> _cache = {};

  /// Belirli bir tarih ve zorluk için üretilmiş tek çözümlü seviyeyi döner.
  static ZipLevel getLevelForDateAndDifficulty(String levelId, ZipDifficulty difficulty) {
    return _cache.putIfAbsent(
      '$levelId|${difficulty.name}',
      () {
        try {
          return ZipGenerator.generate(levelId: levelId, difficulty: difficulty);
        } catch (_) {
          final hash = levelId.hashCode.abs();
          return _presets[hash % _presets.length];
        }
      },
    );
  }

  /// Varsayılan günlük seviyeyi (tarihe göre programlanmış zorluk) döner.
  static ZipLevel getLevelForDate(String levelId) {
    final difficulty = ZipDifficultyScheduler.getDifficultyForDate(levelId);
    return getLevelForDateAndDifficulty(levelId, difficulty);
  }

  // Çevrimdışı / fallback seviyeleri
  static final List<ZipLevel> _presets = [
    ZipLevel(
      id: 'zip_1',
      gridSize: 4,
      numberPoints: {
        const Point(0, 0): 1,
        const Point(0, 3): 2,
        const Point(3, 3): 3,
        const Point(3, 0): 4,
      },
      difficulty: ZipDifficulty.kolay,
    ),
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
      difficulty: ZipDifficulty.orta,
    ),
  ];
}

/// Aşama A (yerel geliştirme): bulmaca cihazdaki jeneratörden gelir.
/// Aşama B'de `RemoteZipPuzzleRepository` ile değiştirilecek.
class LocalZipPuzzleRepository implements PuzzleRepository<ZipLevel> {
  const LocalZipPuzzleRepository();

  @override
  Future<ZipLevel> getDaily(String dateId) async {
    return ZipLevelRepository.getLevelForDate(dateId);
  }
}
