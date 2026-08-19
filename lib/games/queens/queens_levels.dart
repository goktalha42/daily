import 'dart:math';
import 'queens_models.dart';

class QueensDifficultyScheduler {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// Günlük seviye ID'sinden (örn. "2026-08-18") o günün zorluğunu belirler.
  static QueensDifficulty getDifficultyForDate(String levelId) {
    DateTime date;
    try {
      date = DateTime.parse(levelId);
    } catch (_) {
      date = DateTime.now();
    }
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final days = normalizedDate.difference(_epoch).inDays;
    return getDifficultyForDays(days);
  }

  static QueensDifficulty getDifficultyForDays(int days) {
    final rand = Random(202608);
    QueensDifficulty? prev1;
    QueensDifficulty? prev2;
    QueensDifficulty current = QueensDifficulty.kolay;

    final count = days.abs();
    for (int i = 0; i <= count; i++) {
      final candidates = QueensDifficulty.values.toList();
      if (prev1 != null && prev2 != null && prev1 == prev2) {
        candidates.remove(prev1);
      }
      current = candidates[rand.nextInt(candidates.length)];
      prev2 = prev1;
      prev1 = current;
    }
    return current;
  }
}

class QueensLevelRepository {
  // ==========================================
  // 1. KOLAY (6x6) SEVİYELER - %100 SAF MANTIKLA ÇÖZÜLEBİLİR
  // ==========================================
  static const List<Map<String, dynamic>> _kolayPresets = [
    // K1: Çözüm: (0,0), (1,3), (2,1), (3,4), (4,2), (5,5)
    {
      'gridSize': 6,
      'regionMap': [
        [0, 0, 1, 1, 1, 1],
        [0, 0, 1, 1, 1, 1],
        [0, 2, 2, 2, 1, 3],
        [2, 2, 2, 2, 3, 3],
        [2, 2, 4, 4, 3, 5],
        [4, 4, 4, 4, 3, 5],
      ],
      'solution': [[0, 0], [1, 3], [2, 1], [3, 4], [4, 2], [5, 5]],
    },
    // K2: Çözüm: (0,2), (1,0), (2,3), (3,5), (4,1), (5,4)
    {
      'gridSize': 6,
      'regionMap': [
        [1, 1, 0, 0, 0, 2],
        [1, 1, 0, 2, 2, 2],
        [1, 1, 0, 2, 2, 2],
        [1, 4, 4, 4, 5, 3],
        [1, 4, 4, 4, 5, 3],
        [1, 4, 4, 4, 5, 3],
      ],
      'solution': [[0, 2], [1, 0], [2, 3], [3, 5], [4, 1], [5, 4]],
    },
    // K3: Çözüm: (0,2), (1,5), (2,3), (3,1), (4,4), (5,0)
    {
      'gridSize': 6,
      'regionMap': [
        [3, 0, 0, 0, 1, 1],
        [3, 3, 0, 2, 1, 1],
        [3, 3, 2, 2, 4, 4],
        [5, 3, 3, 4, 4, 4],
        [5, 5, 5, 4, 4, 4],
        [5, 5, 5, 4, 4, 4],
      ],
      'solution': [[0, 2], [1, 5], [2, 3], [3, 1], [4, 4], [5, 0]],
    },
    // K4: Çözüm: (0,0), (1,2), (2,4), (3,1), (4,3), (5,5)
    {
      'gridSize': 6,
      'regionMap': [
        [0, 0, 0, 1, 1, 2],
        [0, 1, 1, 1, 1, 2],
        [0, 1, 1, 1, 2, 2],
        [3, 3, 3, 2, 2, 2],
        [3, 3, 3, 4, 4, 4],
        [3, 3, 4, 4, 5, 5],
      ],
      'solution': [[0, 0], [1, 2], [2, 4], [3, 1], [4, 3], [5, 5]],
    },
    // K5: Çözüm: (0,0), (1,4), (2,1), (3,3), (4,5), (5,2)
    {
      'gridSize': 6,
      'regionMap': [
        [0, 0, 3, 1, 1, 1],
        [0, 2, 3, 1, 1, 1],
        [0, 2, 3, 1, 1, 1],
        [0, 2, 3, 3, 4, 4],
        [0, 5, 5, 4, 4, 4],
        [5, 5, 5, 4, 4, 4],
      ],
      'solution': [[0, 0], [1, 4], [2, 1], [3, 3], [4, 5], [5, 2]],
    },
  ];

  // ==========================================
  // 2. ORTA (8x8) SEVİYELER - DENGELİ KISITLAR
  // ==========================================
  static const List<Map<String, dynamic>> _ortaPresets = [
    // O1: Çözüm: (0,6), (1,4), (2,7), (3,5), (4,1), (5,3), (6,0), (7,2)
    {
      'gridSize': 8,
      'regionMap': [
        [4, 1, 1, 1, 1, 1, 0, 0],
        [4, 4, 5, 5, 1, 1, 0, 2],
        [4, 4, 5, 5, 1, 3, 3, 2],
        [4, 4, 4, 5, 5, 3, 3, 3],
        [4, 4, 4, 5, 5, 5, 3, 3],
        [6, 6, 6, 5, 7, 7, 3, 3],
        [6, 6, 6, 7, 7, 7, 3, 3],
        [7, 7, 7, 7, 7, 7, 7, 3],
      ],
      'solution': [[0, 6], [1, 4], [2, 7], [3, 5], [4, 1], [5, 3], [6, 0], [7, 2]],
    },
    // O2: Çözüm: (0,6), (1,3), (2,7), (3,5), (4,0), (5,2), (6,4), (7,1)
    {
      'gridSize': 8,
      'regionMap': [
        [1, 1, 1, 1, 1, 0, 0, 0],
        [1, 1, 1, 1, 1, 0, 0, 0],
        [1, 1, 1, 1, 2, 2, 2, 2],
        [1, 1, 1, 1, 1, 3, 2, 2],
        [4, 4, 4, 3, 3, 3, 2, 2],
        [4, 4, 5, 5, 5, 3, 3, 3],
        [4, 4, 5, 7, 6, 6, 6, 3],
        [4, 7, 7, 7, 6, 6, 6, 6],
      ],
      'solution': [[0, 6], [1, 3], [2, 7], [3, 5], [4, 0], [5, 2], [6, 4], [7, 1]],
    },
    // O3: Çözüm: (0,3), (1,6), (2,0), (3,5), (4,7), (5,1), (6,4), (7,2)
    {
      'gridSize': 8,
      'regionMap': [
        [0, 0, 0, 0, 1, 1, 1, 1],
        [2, 0, 0, 0, 1, 1, 1, 1],
        [2, 2, 2, 3, 3, 1, 4, 4],
        [2, 2, 3, 3, 3, 3, 4, 4],
        [5, 5, 5, 3, 3, 4, 4, 4],
        [5, 5, 5, 6, 6, 6, 4, 4],
        [7, 7, 6, 6, 6, 6, 6, 4],
        [7, 7, 7, 7, 6, 6, 6, 6],
      ],
      'solution': [[0, 3], [1, 6], [2, 0], [3, 5], [4, 7], [5, 1], [6, 4], [7, 2]],
    },
    // O4: Çözüm: (0,2), (1,5), (2,7), (3,0), (4,3), (5,6), (6,4), (7,1)
    {
      'gridSize': 8,
      'regionMap': [
        [0, 0, 0, 0, 1, 1, 1, 2],
        [0, 0, 0, 1, 1, 1, 2, 2],
        [3, 0, 4, 4, 1, 2, 2, 2],
        [3, 3, 4, 4, 4, 5, 5, 2],
        [3, 3, 4, 4, 4, 5, 5, 5],
        [3, 7, 7, 4, 6, 6, 5, 5],
        [7, 7, 7, 6, 6, 6, 6, 5],
        [7, 7, 7, 7, 6, 6, 6, 6],
      ],
      'solution': [[0, 2], [1, 5], [2, 7], [3, 0], [4, 3], [5, 6], [6, 4], [7, 1]],
    },
  ];

  // ==========================================
  // 3. ZOR (9x9) SEVİYELER - İLERİ DÜZEY GİRİNTİLİ BÖLGELER
  // ==========================================
  static const List<Map<String, dynamic>> _zorPresets = [
    // Z1: Çözüm: (0,4), (1,7), (2,1), (3,8), (4,5), (5,2), (6,0), (7,3), (8,6)
    {
      'gridSize': 9,
      'regionMap': [
        [0, 0, 0, 0, 0, 1, 1, 1, 1],
        [2, 0, 0, 0, 1, 1, 1, 1, 1],
        [2, 2, 3, 3, 3, 4, 4, 1, 1],
        [2, 2, 3, 3, 3, 4, 4, 4, 4],
        [2, 5, 5, 5, 3, 4, 4, 4, 4],
        [2, 5, 5, 5, 6, 6, 6, 4, 4],
        [7, 7, 5, 5, 6, 6, 6, 8, 8],
        [7, 7, 7, 7, 6, 6, 6, 8, 8],
        [7, 7, 7, 7, 7, 7, 8, 8, 8],
      ],
      'solution': [[0, 4], [1, 7], [2, 1], [3, 8], [4, 5], [5, 2], [6, 0], [7, 3], [8, 6]],
    },
    // Z2: Çözüm: (0,2), (1,5), (2,8), (3,1), (4,4), (5,7), (6,0), (7,3), (8,6)
    {
      'gridSize': 9,
      'regionMap': [
        [0, 0, 0, 1, 1, 1, 2, 2, 2],
        [0, 0, 0, 1, 1, 1, 2, 2, 2],
        [3, 0, 0, 1, 1, 1, 2, 2, 2],
        [3, 3, 3, 4, 4, 4, 5, 5, 5],
        [3, 3, 3, 4, 4, 4, 5, 5, 5],
        [6, 3, 3, 4, 4, 4, 5, 5, 5],
        [6, 6, 6, 7, 7, 7, 8, 8, 8],
        [6, 6, 6, 7, 7, 7, 8, 8, 8],
        [6, 6, 6, 7, 7, 7, 8, 8, 8],
      ],
      'solution': [[0, 2], [1, 5], [2, 8], [3, 1], [4, 4], [5, 7], [6, 0], [7, 3], [8, 6]],
    },
    // Z3: Çözüm: (0,3), (1,6), (2,0), (3,8), (4,5), (5,2), (6,7), (7,1), (8,4)
    {
      'gridSize': 9,
      'regionMap': [
        [0, 0, 0, 0, 1, 1, 1, 1, 1],
        [2, 0, 0, 0, 1, 1, 1, 1, 1],
        [2, 2, 3, 3, 3, 1, 1, 4, 4],
        [2, 2, 3, 3, 3, 4, 4, 4, 4],
        [5, 5, 5, 3, 3, 4, 4, 4, 4],
        [5, 5, 5, 6, 6, 6, 4, 7, 7],
        [5, 5, 6, 6, 6, 6, 7, 7, 7],
        [8, 8, 8, 6, 6, 6, 7, 7, 7],
        [8, 8, 8, 8, 8, 7, 7, 7, 7],
      ],
      'solution': [[0, 3], [1, 6], [2, 0], [3, 8], [4, 5], [5, 2], [6, 7], [7, 1], [8, 4]],
    },
  ];

  /// Verilen levelId (tarih) ve zorluk için doğrulanmış seviyeyi döner
  static QueensLevel getLevelForDateAndDifficulty(String levelId, QueensDifficulty difficulty) {
    final List<Map<String, dynamic>> pool;
    switch (difficulty) {
      case QueensDifficulty.kolay:
        pool = _kolayPresets;
        break;
      case QueensDifficulty.orta:
        pool = _ortaPresets;
        break;
      case QueensDifficulty.zor:
        pool = _zorPresets;
        break;
    }

    final hash = (levelId + difficulty.name).hashCode.abs();
    final data = pool[hash % pool.length];

    return QueensLevel(
      id: levelId,
      gridSize: data['gridSize'] as int,
      difficulty: difficulty,
      regionMap: (data['regionMap'] as List<dynamic>)
          .map((row) => (row as List<dynamic>).map((cell) => cell as int).toList())
          .toList(),
      solution: (data['solution'] as List<dynamic>)
          .map((pt) => (pt as List<dynamic>).map((val) => val as int).toList())
          .toList(),
    );
  }

  /// Varsayılan günlük seviyeyi (tarihe göre programlanmış zorluk) döner
  static QueensLevel getLevelForDate(String levelId) {
    final difficulty = QueensDifficultyScheduler.getDifficultyForDate(levelId);
    return getLevelForDateAndDifficulty(levelId, difficulty);
  }
}
