enum TangoSymbol { empty, sun, moon }

class TangoCell {
  final int row;
  final int col;
  final bool isFixed;
  TangoSymbol symbol;
  bool isConflict;

  TangoCell({
    required this.row,
    required this.col,
    this.isFixed = false,
    this.symbol = TangoSymbol.empty,
    this.isConflict = false,
  });
}

enum ConstraintType { equal, opposite }

class TangoConstraint {
  final int r1, c1;
  final int r2, c2;
  final ConstraintType type;

  TangoConstraint({
    required this.r1,
    required this.c1,
    required this.r2,
    required this.c2,
    required this.type,
  });
}

enum TangoDifficulty {
  kolay,
  orta,
  zor;

  int get gridSize => 6;
}

class TangoLevel {
  final String id;
  final int gridSize;
  final List<List<TangoSymbol>> initialGrid;
  final List<TangoConstraint> constraints;
  final List<List<TangoSymbol>>? solution;
  final TangoDifficulty? difficulty;

  TangoLevel({
    required this.id,
    required this.gridSize,
    required this.initialGrid,
    required this.constraints,
    this.solution,
    this.difficulty,
  });
}

/// Sadece saf mantık kurallarıyla (tahmin/deneme yanılma olmadan) çözüm analiz sonucu
class TangoDeductiveResult {
  final bool isSolvable;
  final int filledCount;
  final int totalCells;
  final List<List<TangoSymbol>> finalGrid;

  const TangoDeductiveResult({
    required this.isSolvable,
    required this.filledCount,
    required this.totalCells,
    required this.finalGrid,
  });
}
