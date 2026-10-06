import '../../core/puzzle/puzzle_repository.dart';
import '../../core/puzzle/puzzle_seed.dart';
import 'tango_generator.dart';
import 'tango_models.dart';

/// Tango (Güneş & Ay) için gün bazlı zorluk takvimi.
/// Art arda 3 gün aynı zorluk seviyesi gelmez.
class TangoDifficultyScheduler {
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);
  static final List<TangoDifficulty> _cache = [];

  static TangoDifficulty getDifficultyForDate(String levelId) {
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

  static TangoDifficulty getDifficultyForDays(int days) {
    final target = days.abs();
    while (_cache.length <= target) {
      _cache.add(_pick(_cache.length));
    }
    return _cache[target];
  }

  static TangoDifficulty _pick(int dayIndex) {
    final candidates = TangoDifficulty.values.toList();
    if (dayIndex >= 2 && _cache[dayIndex - 1] == _cache[dayIndex - 2]) {
      candidates.remove(_cache[dayIndex - 1]);
    }
    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('tango-difficulty', '$dayIndex'));
    return candidates[seed % candidates.length];
  }
}

/// Tango günlük seviye deposu.
/// Her gün tohumdan sıfırdan, tek çözüm garantili üretilir.
class TangoLevelRepository {
  static final Map<String, TangoLevel> _cache = {};

  /// Belirli bir tarih ve zorluk için üretilmiş tek çözümlü seviyeyi döner.
  static TangoLevel getLevelForDateAndDifficulty(String levelId, TangoDifficulty difficulty) {
    return _cache.putIfAbsent(
      '$levelId|${difficulty.name}',
      () {
        try {
          return TangoGenerator.generate(levelId: levelId, difficulty: difficulty);
        } catch (_) {
          // Çok düşük ihtimalli hata durumunda fallback olarak presetlerden biri döner
          final hash = levelId.hashCode.abs();
          return _presets[hash % _presets.length];
        }
      },
    );
  }

  /// Varsayılan günlük seviyeyi (tarihe göre programlanmış zorluk) döner.
  static TangoLevel getLevelForDate(String levelId) {
    final difficulty = TangoDifficultyScheduler.getDifficultyForDate(levelId);
    return getLevelForDateAndDifficulty(levelId, difficulty);
  }

  /// Çevrimdışı ve test senaryoları için hazır şablonlar (fallback)
  static final List<TangoLevel> _presets = [
    TangoLevel(
      id: 'tango_preset_1',
      gridSize: 4,
      initialGrid: [
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun  ],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty],
      ],
      constraints: [
        TangoConstraint(r1: 0, c1: 0, r2: 0, c2: 1, type: ConstraintType.opposite),
        TangoConstraint(r1: 1, c1: 0, r2: 1, c2: 1, type: ConstraintType.opposite),
        TangoConstraint(r1: 2, c1: 1, r2: 3, c2: 1, type: ConstraintType.opposite),
        TangoConstraint(r1: 3, c1: 2, r2: 3, c2: 3, type: ConstraintType.opposite),
        TangoConstraint(r1: 2, c1: 2, r2: 2, c2: 3, type: ConstraintType.opposite),
      ],
      difficulty: TangoDifficulty.kolay,
    ),
    TangoLevel(
      id: 'tango_preset_2',
      gridSize: 4,
      initialGrid: [
        [TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.moon ],
        [TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon ],
      ],
      constraints: [
        TangoConstraint(r1: 0, c1: 0, r2: 0, c2: 1, type: ConstraintType.opposite),
        TangoConstraint(r1: 1, c1: 1, r2: 1, c2: 2, type: ConstraintType.opposite),
        TangoConstraint(r1: 2, c1: 0, r2: 3, c2: 0, type: ConstraintType.opposite),
        TangoConstraint(r1: 2, c1: 3, r2: 3, c2: 3, type: ConstraintType.opposite),
      ],
      difficulty: TangoDifficulty.orta,
    ),
  ];
}

/// Aşama A (yerel geliştirme): bulmaca cihazdaki jeneratörden gelir.
/// Aşama B'de `RemoteTangoPuzzleRepository` ile sunucu API'sine bağlanacak.
class LocalTangoPuzzleRepository implements PuzzleRepository<TangoLevel> {
  const LocalTangoPuzzleRepository();

  @override
  Future<TangoLevel> getDaily(String dateId) async {
    return TangoLevelRepository.getLevelForDate(dateId);
  }
}
