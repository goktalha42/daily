import 'dart:math' as math;

class PatchPoint {
  final int row;
  final int col;

  const PatchPoint(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchPoint &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class PatchRect {
  final int topRow;
  final int leftCol;
  final int bottomRow;
  final int rightCol;
  final int colorIndex;

  const PatchRect({
    required this.topRow,
    required this.leftCol,
    required this.bottomRow,
    required this.rightCol,
    this.colorIndex = 0,
  });

  factory PatchRect.fromPoints(PatchPoint p1, PatchPoint p2, {int colorIndex = 0}) {
    final top = math.min(p1.row, p2.row);
    final bottom = math.max(p1.row, p2.row);
    final left = math.min(p1.col, p2.col);
    final right = math.max(p1.col, p2.col);

    return PatchRect(
      topRow: top,
      leftCol: left,
      bottomRow: bottom,
      rightCol: right,
      colorIndex: colorIndex,
    );
  }

  int get width => rightCol - leftCol + 1;
  int get height => bottomRow - topRow + 1;
  int get area => width * height;

  bool contains(int r, int c) {
    return r >= topRow && r <= bottomRow && c >= leftCol && c <= rightCol;
  }

  bool overlaps(PatchRect other) {
    return !(rightCol < other.leftCol ||
        leftCol > other.rightCol ||
        bottomRow < other.topRow ||
        topRow > other.bottomRow);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchRect &&
          runtimeType == other.runtimeType &&
          topRow == other.topRow &&
          leftCol == other.leftCol &&
          bottomRow == other.bottomRow &&
          rightCol == other.rightCol;

  @override
  int get hashCode =>
      topRow.hashCode ^
      leftCol.hashCode ^
      bottomRow.hashCode ^
      rightCol.hashCode;
}

enum PatchShapeType {
  square('Kare'),
  tall('Uzun dikdörtgen'),
  wide('Geniş dikdörtgen'),
  any('Herhangi biri');

  final String label;
  const PatchShapeType(this.label);
}

class PatchesClue {
  final int row;
  final int col;
  final int targetArea;
  final PatchShapeType shapeType;

  const PatchesClue({
    required this.row,
    required this.col,
    required this.targetArea,
    this.shapeType = PatchShapeType.any,
  });
}

enum PatchesDifficulty {
  kolay(4, 'Kolay'),
  orta(5, 'Orta'),
  zor(6, 'Zor');

  final int gridSize;
  final String label;

  const PatchesDifficulty(this.gridSize, this.label);
}

class PatchesLevel {
  final String id;
  final int gridSize;
  final List<PatchesClue> clues;
  final List<PatchRect>? solution;
  final PatchesDifficulty difficulty;

  const PatchesLevel({
    required this.id,
    required this.gridSize,
    required this.clues,
    this.solution,
    this.difficulty = PatchesDifficulty.orta,
  });
}

