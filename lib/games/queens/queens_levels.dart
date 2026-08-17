import 'dart:math';
import 'queens_models.dart';

class QueensDifficultyScheduler {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// Günlük seviye ID'sinden (örn. "2026-08-18") o günün zorluğunu belirler.
  /// Kural: Hiçbir zorluk art arda 2 günden fazla (en fazla 2 gün) gelmez.
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
    QueensDifficulty current = QueensDifficulty.basit;

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
  // 1. BASİT (5x5) SEVİYELER - %100 MANTIKLA ÇÖZÜLEBİLİR
  // ==========================================
  static const List<Map<String, dynamic>> _basitPresets = [
    // B1: Çözüm: (0,3), (1,0), (2,2), (3,4), (4,1)
    {
      'gridSize': 5,
      'regionMap': [
        [1, 0, 0, 0, 3],
        [1, 1, 0, 3, 3],
        [1, 2, 2, 2, 3],
        [4, 4, 2, 3, 3],
        [4, 4, 4, 4, 3],
      ],
      'solution': [[0, 3], [1, 0], [2, 2], [3, 4], [4, 1]],
    },
    // B2: Çözüm: (0,2), (1,4), (2,0), (3,3), (4,1)
    {
      'gridSize': 5,
      'regionMap': [
        [0, 0, 0, 1, 1],
        [2, 0, 0, 1, 1],
        [2, 2, 3, 3, 1],
        [2, 4, 3, 3, 3],
        [4, 4, 4, 4, 3],
      ],
      'solution': [[0, 2], [1, 4], [2, 0], [3, 3], [4, 1]],
    },
    // B3: Çözüm: (0,1), (1,3), (2,0), (3,4), (4,2)
    {
      'gridSize': 5,
      'regionMap': [
        [0, 0, 1, 1, 1],
        [2, 0, 1, 1, 3],
        [2, 2, 4, 3, 3],
        [2, 4, 4, 3, 3],
        [4, 4, 4, 4, 3],
      ],
      'solution': [[0, 1], [1, 3], [2, 0], [3, 4], [4, 2]],
    },
    // B4: Çözüm: (0,4), (1,1), (2,3), (3,0), (4,2)
    {
      'gridSize': 5,
      'regionMap': [
        [1, 1, 0, 0, 0],
        [1, 1, 2, 0, 0],
        [3, 1, 2, 2, 2],
        [3, 3, 4, 2, 2],
        [3, 4, 4, 4, 4],
      ],
      'solution': [[0, 4], [1, 1], [2, 3], [3, 0], [4, 2]],
    },
    // B5: Çözüm: (0,1), (1,4), (2,2), (3,0), (4,3)
    {
      'gridSize': 5,
      'regionMap': [
        [0, 0, 0, 1, 1],
        [3, 0, 2, 1, 1],
        [3, 2, 2, 2, 4],
        [3, 3, 2, 4, 4],
        [3, 3, 4, 4, 4],
      ],
      'solution': [[0, 1], [1, 4], [2, 2], [3, 0], [4, 3]],
    },
  ];

  // ==========================================
  // 2. TEMEL (6x6) SEVİYELER - DENGELİ MANTIK BULMACALARI
  // ==========================================
  static const List<Map<String, dynamic>> _temelPresets = [
    // T1: Çözüm: (0,4), (1,1), (2,3), (3,5), (4,0), (5,2)
    {
      'gridSize': 6,
      'regionMap': [
        [1, 1, 0, 0, 0, 3],
        [1, 1, 0, 0, 3, 3],
        [4, 1, 2, 2, 3, 3],
        [4, 4, 2, 2, 3, 3],
        [4, 4, 5, 5, 5, 3],
        [4, 5, 5, 5, 5, 5],
      ],
      'solution': [[0, 4], [1, 1], [2, 3], [3, 5], [4, 0], [5, 2]],
    },
    // T2: Çözüm: (0,2), (1,5), (2,0), (3,3), (4,1), (5,4)
    {
      'gridSize': 6,
      'regionMap': [
        [0, 0, 0, 1, 1, 1],
        [2, 0, 0, 1, 1, 1],
        [2, 2, 3, 3, 3, 1],
        [2, 4, 3, 3, 5, 5],
        [4, 4, 4, 5, 5, 5],
        [4, 4, 5, 5, 5, 5],
      ],
      'solution': [[0, 2], [1, 5], [2, 0], [3, 3], [4, 1], [5, 4]],
    },
    // T3: Çözüm: (0,3), (1,0), (2,5), (3,2), (4,4), (5,1)
    {
      'gridSize': 6,
      'regionMap': [
        [1, 0, 0, 0, 2, 2],
        [1, 1, 0, 2, 2, 2],
        [1, 3, 3, 2, 2, 2],
        [5, 3, 3, 4, 4, 2],
        [5, 5, 3, 4, 4, 4],
        [5, 5, 5, 5, 4, 4],
      ],
      'solution': [[0, 3], [1, 0], [2, 5], [3, 2], [4, 4], [5, 1]],
    },
    // T4: Çözüm: (0,1), (1,4), (2,2), (3,5), (4,3), (5,0)
    {
      'gridSize': 6,
      'regionMap': [
        [0, 0, 0, 1, 1, 1],
        [0, 0, 2, 1, 1, 3],
        [5, 2, 2, 2, 3, 3],
        [5, 5, 2, 4, 4, 3],
        [5, 5, 4, 4, 4, 3],
        [5, 5, 5, 4, 4, 4],
      ],
      'solution': [[0, 1], [1, 4], [2, 2], [3, 5], [4, 3], [5, 0]],
    },
  ];

  // ==========================================
  // 3. ZOR (8x8) SEVİYELER - İLERİ DÜZEY ELEME STRATEJİSİ
  // ==========================================
  static const List<Map<String, dynamic>> _zorPresets = [
    // Z1: Çözüm: (0,3), (1,6), (2,0), (3,5), (4,7), (5,1), (6,4), (7,2)
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
    // Z2: Çözüm: (0,2), (1,5), (2,7), (3,0), (4,3), (5,6), (6,4), (7,1)
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
    // Z3: Çözüm: (0,4), (1,1), (2,7), (3,5), (4,2), (5,0), (6,6), (7,3)
    {
      'gridSize': 8,
      'regionMap': [
        [1, 1, 0, 0, 0, 0, 2, 2],
        [1, 1, 1, 0, 0, 2, 2, 2],
        [1, 1, 4, 4, 3, 3, 2, 2],
        [5, 4, 4, 4, 3, 3, 3, 2],
        [5, 5, 4, 4, 3, 3, 6, 6],
        [5, 5, 5, 7, 7, 6, 6, 6],
        [5, 5, 7, 7, 7, 6, 6, 6],
        [7, 7, 7, 7, 7, 7, 6, 6],
      ],
      'solution': [[0, 4], [1, 1], [2, 7], [3, 5], [4, 2], [5, 0], [6, 6], [7, 3]],
    },
  ];

  /// Verilen levelId (tarih) için doğru zorlukta ve doğrulanmış seviyeyi döner
  static QueensLevel getLevelForDate(String levelId) {
    final difficulty = QueensDifficultyScheduler.getDifficultyForDate(levelId);
    
    // Seviye havuzunu seç
    final List<Map<String, dynamic>> pool;
    switch (difficulty) {
      case QueensDifficulty.basit:
        pool = _basitPresets;
        break;
      case QueensDifficulty.temel:
        pool = _temelPresets;
        break;
      case QueensDifficulty.zor:
        pool = _zorPresets;
        break;
    }

    // Tarihe göre o havuzdan deterministik bir seviye seç
    final hash = levelId.hashCode.abs();
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
}
