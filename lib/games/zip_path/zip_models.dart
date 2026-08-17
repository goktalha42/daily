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

class ZipLevel {
  final String id;
  final int gridSize;
  final Map<Point, int> numberPoints; // Map of grid point -> target number (1, 2, 3...)

  ZipLevel({
    required this.id,
    required this.gridSize,
    required this.numberPoints,
  });
}
