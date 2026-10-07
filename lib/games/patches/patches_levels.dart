import '../../core/puzzle/puzzle_repository.dart';
import '../../core/puzzle/puzzle_seed.dart';
import 'patches_generator.dart';
import 'patches_models.dart';

/// Patches (Alan Bölme / Shikaku) için gün bazlı zorluk takvimi.
/// Art arda 3 gün aynı zorluk seviyesi gelmez.
class PatchesDifficultyScheduler {
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);
  static final List<PatchesDifficulty> _cache = [];

  static PatchesDifficulty getDifficultyForDate(String levelId) {
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

  static PatchesDifficulty getDifficultyForDays(int days) {
    final target = days.abs();
    while (_cache.length <= target) {
      _cache.add(_pick(_cache.length));
    }
    return _cache[target];
  }

  static PatchesDifficulty _pick(int dayIndex) {
    final candidates = PatchesDifficulty.values.toList();
    if (dayIndex >= 2 && _cache[dayIndex - 1] == _cache[dayIndex - 2]) {
      candidates.remove(_cache[dayIndex - 1]);
    }
    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('patches-difficulty', '$dayIndex'));
    return candidates[seed % candidates.length];
  }
}

class PatchesLevelRepository {
  static final List<PatchesLevel> _presets = [
    // Seviye 1: 4x4 (Kolay)
    PatchesLevel(
      id: 'patches_1',
      gridSize: 4,
      difficulty: PatchesDifficulty.kolay,
      clues: [
        const PatchesClue(row: 1, col: 0, targetArea: 4),
        const PatchesClue(row: 0, col: 3, targetArea: 3),
        const PatchesClue(row: 1, col: 1, targetArea: 6),
        const PatchesClue(row: 2, col: 3, targetArea: 2),
        const PatchesClue(row: 3, col: 3, targetArea: 1),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 3, rightCol: 0),
        const PatchRect(topRow: 0, leftCol: 1, bottomRow: 0, rightCol: 3),
        const PatchRect(topRow: 1, leftCol: 1, bottomRow: 3, rightCol: 2),
        const PatchRect(topRow: 1, leftCol: 3, bottomRow: 2, rightCol: 3),
        const PatchRect(topRow: 3, leftCol: 3, bottomRow: 3, rightCol: 3),
      ],
    ),

    // Seviye 2: 4x4 (Orta)
    PatchesLevel(
      id: 'patches_2',
      gridSize: 4,
      difficulty: PatchesDifficulty.kolay,
      clues: [
        const PatchesClue(row: 1, col: 0, targetArea: 4),
        const PatchesClue(row: 0, col: 2, targetArea: 3),
        const PatchesClue(row: 2, col: 1, targetArea: 4),
        const PatchesClue(row: 3, col: 3, targetArea: 3),
        const PatchesClue(row: 3, col: 2, targetArea: 2),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 3, rightCol: 0), // 4x1 = 4
        const PatchRect(topRow: 0, leftCol: 1, bottomRow: 0, rightCol: 3), // 1x3 = 3
        const PatchRect(topRow: 1, leftCol: 1, bottomRow: 2, rightCol: 2), // 2x2 = 4
        const PatchRect(topRow: 1, leftCol: 3, bottomRow: 3, rightCol: 3), // 3x1 = 3
        const PatchRect(topRow: 3, leftCol: 1, bottomRow: 3, rightCol: 2), // 1x2 = 2
      ],
    ),

    // Seviye 3: 5x5 (Dengeli)
    PatchesLevel(
      id: 'patches_3',
      gridSize: 5,
      difficulty: PatchesDifficulty.orta,
      clues: [
        const PatchesClue(row: 0, col: 0, targetArea: 2),
        const PatchesClue(row: 2, col: 1, targetArea: 8),
        const PatchesClue(row: 1, col: 4, targetArea: 6),
        const PatchesClue(row: 4, col: 0, targetArea: 3),
        const PatchesClue(row: 3, col: 4, targetArea: 2),
        const PatchesClue(row: 4, col: 2, targetArea: 3),
        const PatchesClue(row: 4, col: 4, targetArea: 1),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 1, rightCol: 0),
        const PatchRect(topRow: 0, leftCol: 1, bottomRow: 3, rightCol: 2),
        const PatchRect(topRow: 0, leftCol: 3, bottomRow: 2, rightCol: 4),
        const PatchRect(topRow: 2, leftCol: 0, bottomRow: 4, rightCol: 0),
        const PatchRect(topRow: 3, leftCol: 3, bottomRow: 3, rightCol: 4),
        const PatchRect(topRow: 4, leftCol: 1, bottomRow: 4, rightCol: 3),
        const PatchRect(topRow: 4, leftCol: 4, bottomRow: 4, rightCol: 4),
      ],
    ),

    // Seviye 4: 6x6 (Usta)
    PatchesLevel(
      id: 'patches_4',
      gridSize: 6,
      difficulty: PatchesDifficulty.zor,
      clues: [
        const PatchesClue(row: 4, col: 1, targetArea: 10),
        const PatchesClue(row: 3, col: 2, targetArea: 5),
        const PatchesClue(row: 3, col: 3, targetArea: 4),
        const PatchesClue(row: 3, col: 4, targetArea: 8),
        const PatchesClue(row: 4, col: 4, targetArea: 3),
        const PatchesClue(row: 5, col: 0, targetArea: 4),
        const PatchesClue(row: 5, col: 5, targetArea: 2),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 4, rightCol: 1),
        const PatchRect(topRow: 0, leftCol: 2, bottomRow: 4, rightCol: 2),
        const PatchRect(topRow: 0, leftCol: 3, bottomRow: 3, rightCol: 3),
        const PatchRect(topRow: 0, leftCol: 4, bottomRow: 3, rightCol: 5),
        const PatchRect(topRow: 4, leftCol: 3, bottomRow: 4, rightCol: 5),
        const PatchRect(topRow: 5, leftCol: 0, bottomRow: 5, rightCol: 3),
        const PatchRect(topRow: 5, leftCol: 4, bottomRow: 5, rightCol: 5),
      ],
    ),
  ];


  static List<PatchesLevel> get presets => _presets;

  static final Map<String, PatchesLevel> _cache = {};

  /// Belirli bir tarih ve zorluk için üretilmiş tek çözümlü seviyeyi döner.
  static PatchesLevel getLevelForDateAndDifficulty(
    String levelId,
    PatchesDifficulty difficulty,
  ) {
    return _cache.putIfAbsent(
      '$levelId|${difficulty.name}',
      () {
        try {
          return PatchesGenerator.generate(
            levelId: levelId,
            difficulty: difficulty,
          );
        } catch (_) {
          final hash = levelId.hashCode.abs();
          return _presets[hash % _presets.length];
        }
      },
    );
  }

  /// Varsayılan günlük seviyeyi (tarihe göre programlanmış zorluk) döner.
  static PatchesLevel getLevelForDate(String levelId) {
    final difficulty = PatchesDifficultyScheduler.getDifficultyForDate(levelId);
    return getLevelForDateAndDifficulty(levelId, difficulty);
  }
}

/// Aşama A (yerel geliştirme): bulmaca cihazdaki jeneratörden gelir.
/// Aşama B'de `RemotePatchesPuzzleRepository` ile değiştirilecek.
class LocalPatchesPuzzleRepository implements PuzzleRepository<PatchesLevel> {
  const LocalPatchesPuzzleRepository();

  @override
  Future<PatchesLevel> getDaily(String dateId) async {
    return PatchesLevelRepository.getLevelForDate(dateId);
  }
}

