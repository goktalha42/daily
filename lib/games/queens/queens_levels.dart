import '../../core/puzzle/puzzle_repository.dart';
import '../../core/puzzle/puzzle_seed.dart';
import 'queens_generator.dart';
import 'queens_models.dart';

class QueensDifficultyScheduler {
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);
  static final List<QueensDifficulty> _cache = [];

  /// Günlük seviye ID'sinden (örn. "2026-08-18") o günün zorluğunu belirler.
  static QueensDifficulty getDifficultyForDate(String levelId) {
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

  /// Zorluk her gün için HMAC tohumundan seçilir; art arda 3 gün aynı zorluk gelmez.
  static QueensDifficulty getDifficultyForDays(int days) {
    final target = days.abs();
    while (_cache.length <= target) {
      _cache.add(_pick(_cache.length));
    }
    return _cache[target];
  }

  static QueensDifficulty _pick(int dayIndex) {
    final candidates = QueensDifficulty.values.toList();
    if (dayIndex >= 2 && _cache[dayIndex - 1] == _cache[dayIndex - 2]) {
      candidates.remove(_cache[dayIndex - 1]);
    }
    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('queens-difficulty', '$dayIndex'));
    return candidates[seed % candidates.length];
  }
}

/// Queens günlük seviyeleri: her gün tohumdan sıfırdan üretilir (sabit havuz yok).
class QueensLevelRepository {
  static final Map<String, QueensLevel> _cache = {};

  /// Verilen levelId (tarih) ve zorluk için üretilmiş, tek çözümlü seviyeyi döner.
  static QueensLevel getLevelForDateAndDifficulty(String levelId, QueensDifficulty difficulty) {
    return _cache.putIfAbsent(
      '$levelId|${difficulty.name}',
      () => QueensGenerator.generate(levelId: levelId, difficulty: difficulty),
    );
  }

  /// Varsayılan günlük seviyeyi (tarihe göre programlanmış zorluk) döner.
  static QueensLevel getLevelForDate(String levelId) {
    final difficulty = QueensDifficultyScheduler.getDifficultyForDate(levelId);
    return getLevelForDateAndDifficulty(levelId, difficulty);
  }
}

/// Aşama A (yerel geliştirme): bulmaca cihazdaki jeneratörden gelir.
/// Aşama B'de `RemoteQueensPuzzleRepository` ile değiştirilecek.
class LocalQueensPuzzleRepository implements PuzzleRepository<QueensLevel> {
  const LocalQueensPuzzleRepository();

  @override
  Future<QueensLevel> getDaily(String dateId) async {
    return QueensLevelRepository.getLevelForDate(dateId);
  }
}
