import 'tango_models.dart';

// S = Sun, M = Moon, E = Empty
// Kural: Her satır ve sütunda eşit sayıda S ve M olmalı
// Kural: Aynı sembolden 3 tanesi yan yana (yatay/dikey) gelemez
// Kısıtlamalar: '=' (aynı olmalı), 'x' (farklı olmalı) komşu hücre çiftleri

class TangoLevelRepository {
  static final List<TangoLevel> _presets = [
    // ---- Seviye 1: 4x4, Kolay ----
    TangoLevel(
      id: 'tango_1',
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
    ),

    // ---- Seviye 2: 4x4, Orta ----
    TangoLevel(
      id: 'tango_2',
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

    // ---- Seviye 3: 4x4, Dengeli ----
    TangoLevel(
      id: 'tango_3',
      gridSize: 4,
      initialGrid: [
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun  ],
        [TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty],
        [TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun  ],
      ],
      constraints: [
        TangoConstraint(r1: 0, c1: 2, r2: 0, c2: 3, type: ConstraintType.equal),
        TangoConstraint(r1: 2, c1: 0, r2: 3, c2: 0, type: ConstraintType.opposite),
        TangoConstraint(r1: 1, c1: 1, r2: 1, c2: 2, type: ConstraintType.opposite),
      ],
    ),

    // ---- Seviye 4: 6x6, Zor ----
    TangoLevel(
      id: 'tango_4',
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

    // ---- Seviye 5: 6x6, Usta ----
    TangoLevel(
      id: 'tango_5',
      gridSize: 6,
      initialGrid: [
        [TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun  ],
        [TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty],
        [TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.moon ],
        [TangoSymbol.empty, TangoSymbol.moon,  TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty],
        [TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.sun,   TangoSymbol.empty, TangoSymbol.empty, TangoSymbol.moon ],
      ],
      constraints: [
        TangoConstraint(r1: 0, c1: 1, r2: 0, c2: 2, type: ConstraintType.equal),
        TangoConstraint(r1: 1, c1: 0, r2: 2, c2: 0, type: ConstraintType.opposite),
        TangoConstraint(r1: 3, c1: 4, r2: 4, c2: 4, type: ConstraintType.opposite),
        TangoConstraint(r1: 4, c1: 2, r2: 4, c2: 3, type: ConstraintType.equal),
      ],
    ),
  ];

  static TangoLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
