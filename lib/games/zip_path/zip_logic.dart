import 'zip_models.dart';

class ZipLogic {
  static bool validatePath(
    List<Point> path,
    Map<Point, int> numberPoints,
    int gridSize,
  ) {
    if (path.isEmpty) return false;

    final maxNumber = numberPoints.values.reduce((a, b) => a > b ? a : b);

    // Path must start at number 1
    if (numberPoints[path.first] != 1) return false;

    int currentTarget = 1;

    for (int i = 0; i < path.length; i++) {
      final point = path[i];

      // Check if point has a number
      if (numberPoints.containsKey(point)) {
        final numVal = numberPoints[point]!;
        if (numVal == currentTarget) {
          currentTarget++;
        } else if (numVal > currentTarget) {
          // Visited higher number out of sequence
          return false;
        }
      }

      // Check adjacency with next step
      if (i < path.length - 1) {
        final next = path[i + 1];
        final dr = (point.row - next.row).abs();
        final dc = (point.col - next.col).abs();

        if (dr + dc != 1) {
          // Not adjacent
          return false;
        }
      }
    }

    // Win condition: All numbers visited in order up to maxNumber
    return currentTarget > maxNumber;
  }
}
