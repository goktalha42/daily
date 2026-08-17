import 'tango_models.dart';

// S = Sun, M = Moon, E = Empty
// Kural: Her satır ve sütunda eşit sayıda S ve M olmalı (4x4 → 2 S, 2 M)
// Kural: Aynı sembolden 3 tanesi yan yana (yatay/dikey) gelemez
// Kısıtlamalar: '=' (aynı olmalı), 'x' (farklı olmalı) komşu hücre çiftleri

class TangoLevelRepository {
  static final List<TangoLevel> _presets = [
    // ---- Seviye 1: 4x4, Kolay ----
    // Çözüm:
    //   S M S M
    //   M S M S
    //   S M S M
    //   M S M S
    TangoLevel(
      id: '2026-08-17',
      gridSize: 4,
      initialGrid: [
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun  ],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty],
      ],
      constraints: [
        // Satır 0: (0,0) ve (0,1) farklı olmalı
        TangoConstraint(r1: 0, c1: 0, r2: 0, c2: 1, type: ConstraintType.opposite),
        // Satır 1: (1,0) ve (1,1) farklı olmalı
        TangoConstraint(r1: 1, c1: 0, r2: 1, c2: 1, type: ConstraintType.opposite),
        // Sütun: (2,1) ve (3,1) farklı olmalı
        TangoConstraint(r1: 2, c1: 1, r2: 3, c2: 1, type: ConstraintType.opposite),
        // Satır 3: (3,2) ve (3,3) farklı olmalı
        TangoConstraint(r1: 3, c1: 2, r2: 3, c2: 3, type: ConstraintType.opposite),
        // (0,3) ve (1,3) aynı olmalı → false: biri M biri S... hayır ikisi de different
        // Aslında: (2,2) ve (2,3) farklı olmalı
        TangoConstraint(r1: 2, c1: 2, r2: 2, c2: 3, type: ConstraintType.opposite),
      ],
    ),

    // ---- Seviye 2: 4x4, Orta ----
    // Çözüm:
    //   M S M S
    //   S M S M
    //   M S M S
    //   S M S M
    TangoLevel(
      id: '2026-08-18',
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
    ),

    // ---- Seviye 3: 6x6, Zor ----
    // Çözüm:
    //   S M S M S M
    //   M S M S M S
    //   S S M M S M
    //   M M S S M S
    //   S M M S S M
    //   M S S M M S
    TangoLevel(
      id: '2026-08-19',
      gridSize: 6,
      initialGrid: [
        [TangoSymbol.sun,   TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.sun  ],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon ],
        [TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.moon,  TangoSymbol.empty],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.moon ],
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.empty],
      ],
      constraints: [
        TangoConstraint(r1: 0, c1: 2, r2: 0, c2: 3, type: ConstraintType.opposite),
        TangoConstraint(r1: 1, c1: 2, r2: 1, c2: 3, type: ConstraintType.opposite),
        TangoConstraint(r1: 2, c1: 1, r2: 2, c2: 2, type: ConstraintType.opposite),
        TangoConstraint(r1: 3, c1: 0, r2: 3, c2: 1, type: ConstraintType.equal),
        TangoConstraint(r1: 4, c1: 1, r2: 4, c2: 2, type: ConstraintType.equal),
        TangoConstraint(r1: 5, c1: 3, r2: 5, c2: 4, type: ConstraintType.opposite),
      ],
    ),
  ];

  static TangoLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
