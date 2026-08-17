import 'queens_models.dart';

class QueensLogic {
  /// Evaluates conflicts across the grid and marks cells. Returns true if solved.
  static bool validateGrid(List<List<QueensCell>> grid, int gridSize) {
    // Reset all conflicts
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        grid[r][c].isConflict = false;
      }
    }

    final queenCells = <QueensCell>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (grid[r][c].content == CellContent.queen) {
          queenCells.add(grid[r][c]);
        }
      }
    }

    bool hasConflict = false;

    for (int i = 0; i < queenCells.length; i++) {
      for (int j = i + 1; j < queenCells.length; j++) {
        final q1 = queenCells[i];
        final q2 = queenCells[j];

        bool isConflicting = false;

        // 1. Same row
        if (q1.row == q2.row) isConflicting = true;

        // 2. Same column
        if (q1.col == q2.col) isConflicting = true;

        // 3. Same region
        if (q1.regionId == q2.regionId) isConflicting = true;

        // 4. Touch/Adjacency (8-directional)
        final dr = (q1.row - q2.row).abs();
        final dc = (q1.col - q2.col).abs();
        if (dr <= 1 && dc <= 1) isConflicting = true;

        if (isConflicting) {
          q1.isConflict = true;
          q2.isConflict = true;
          hasConflict = true;
        }
      }
    }

    // Win condition: Exactly N queens placed, no conflicts
    return queenCells.length == gridSize && !hasConflict;
  }
}
