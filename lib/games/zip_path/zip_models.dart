class Point {
  final int row;
  final int col;

  const Point(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

/// LinkedIn Zip tarzı kareler arasındaki geçilmez kenar hattı (duvar/çit)
class ZipEdgeWall {
  final Point p1;
  final Point p2;

  const ZipEdgeWall(this.p1, this.p2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ZipEdgeWall) return false;
    return (p1 == other.p1 && p2 == other.p2) || (p1 == other.p2 && p2 == other.p1);
  }

  @override
  int get hashCode => p1.hashCode ^ p2.hashCode;

  Map<String, dynamic> toJson() => {
        'r1': p1.row,
        'c1': p1.col,
        'r2': p2.row,
        'c2': p2.col,
      };

  factory ZipEdgeWall.fromJson(Map<String, dynamic> json) => ZipEdgeWall(
        Point(json['r1'] as int, json['c1'] as int),
        Point(json['r2'] as int, json['c2'] as int),
      );
}

enum ZipDifficulty {
  kolay,
  orta,
  zor;

  int get gridSize => switch (this) {
        ZipDifficulty.kolay => 4,
        ZipDifficulty.orta => 5,
        ZipDifficulty.zor => 5,
      };
}

class ZipLevel {
  final String id;
  final int gridSize;
  final Map<Point, int> numberPoints; // Map of grid point -> target number (1, 2, 3...)
  final Set<Point> walls; // Hücre bazlı duvarlar (varsa)
  final Set<ZipEdgeWall> edgeWalls; // LinkedIn Zip tarzı kareler arası hatlar (oralardan geçilmez)
  final List<Point>? solutionPath;
  final ZipDifficulty? difficulty;

  ZipLevel({
    required this.id,
    required this.gridSize,
    required this.numberPoints,
    this.walls = const {},
    this.edgeWalls = const {},
    this.solutionPath,
    this.difficulty,
  });
}
