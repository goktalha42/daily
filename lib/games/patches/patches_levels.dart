import 'patches_models.dart';

class PatchesLevelRepository {
  static final List<PatchesLevel> _presets = [
    // Seviye 1: 4x4 (Kolay)
    PatchesLevel(
      id: 'patches_1',
      gridSize: 4,
      clues: [
        const PatchesClue(row: 0, col: 0, targetArea: 4),
        const PatchesClue(row: 0, col: 2, targetArea: 2),
        const PatchesClue(row: 1, col: 3, targetArea: 2),
        const PatchesClue(row: 3, col: 1, targetArea: 4),
        const PatchesClue(row: 2, col: 3, targetArea: 4),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 1, rightCol: 1), // 2x2 = 4
        const PatchRect(topRow: 0, leftCol: 2, bottomRow: 0, rightCol: 3), // 1x2 = 2
        const PatchRect(topRow: 1, leftCol: 2, bottomRow: 1, rightCol: 3), // 1x2 = 2
        const PatchRect(topRow: 2, leftCol: 0, bottomRow: 3, rightCol: 1), // 2x2 = 4
        const PatchRect(topRow: 2, leftCol: 2, bottomRow: 3, rightCol: 3), // 2x2 = 4
      ],
    ),

    // Seviye 2: 4x4 (Orta)
    PatchesLevel(
      id: 'patches_2',
      gridSize: 4,
      clues: [
        const PatchesClue(row: 1, col: 0, targetArea: 4),
        const PatchesClue(row: 0, col: 2, targetArea: 3),
        const PatchesClue(row: 2, col: 1, targetArea: 4),
        const PatchesClue(row: 3, col: 3, targetArea: 3),
        const PatchesClue(row: 3, col: 2, targetArea: 2),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 3, rightCol: 0), // 4x1 = 4
        const PatchRect(topRow: 0, leftCol: 1, bottomRow: 0, rightCol: 3), // 1x3 = 3
        const PatchRect(topRow: 1, leftCol: 1, bottomRow: 2, rightCol: 2), // 2x2 = 4
        const PatchRect(topRow: 1, leftCol: 3, bottomRow: 3, rightCol: 3), // 3x1 = 3
        const PatchRect(topRow: 3, leftCol: 1, bottomRow: 3, rightCol: 2), // 1x2 = 2
      ],
    ),

    // Seviye 3: 5x5 (Dengeli)
    PatchesLevel(
      id: 'patches_3',
      gridSize: 5,
      clues: [
        const PatchesClue(row: 0, col: 1, targetArea: 6),
        const PatchesClue(row: 0, col: 4, targetArea: 4),
        const PatchesClue(row: 3, col: 0, targetArea: 3),
        const PatchesClue(row: 2, col: 2, targetArea: 6),
        const PatchesClue(row: 2, col: 4, targetArea: 2),
        const PatchesClue(row: 4, col: 3, targetArea: 4),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 1, rightCol: 2), // 2x3 = 6
        const PatchRect(topRow: 0, leftCol: 3, bottomRow: 1, rightCol: 4), // 2x2 = 4
        const PatchRect(topRow: 2, leftCol: 0, bottomRow: 4, rightCol: 0), // 3x1 = 3
        const PatchRect(topRow: 2, leftCol: 1, bottomRow: 3, rightCol: 3), // 2x3 = 6
        const PatchRect(topRow: 2, leftCol: 4, bottomRow: 3, rightCol: 4), // 2x1 = 2
        const PatchRect(topRow: 4, leftCol: 1, bottomRow: 4, rightCol: 4), // 1x4 = 4
      ],
    ),

    // Seviye 4: 5x5 (Usta)
    PatchesLevel(
      id: 'patches_4',
      gridSize: 5,
      clues: [
        const PatchesClue(row: 1, col: 1, targetArea: 6),
        const PatchesClue(row: 0, col: 3, targetArea: 3),
        const PatchesClue(row: 1, col: 3, targetArea: 4),
        const PatchesClue(row: 2, col: 4, targetArea: 3),
        const PatchesClue(row: 4, col: 0, targetArea: 4),
        const PatchesClue(row: 3, col: 2, targetArea: 4),
        const PatchesClue(row: 4, col: 4, targetArea: 1),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 2, rightCol: 1), // 3x2 = 6
        const PatchRect(topRow: 0, leftCol: 2, bottomRow: 0, rightCol: 4), // 1x3 = 3
        const PatchRect(topRow: 1, leftCol: 2, bottomRow: 2, rightCol: 3), // 2x2 = 4
        const PatchRect(topRow: 1, leftCol: 4, bottomRow: 3, rightCol: 4), // 3x1 = 3
        const PatchRect(topRow: 3, leftCol: 0, bottomRow: 4, rightCol: 1), // 2x2 = 4
        const PatchRect(topRow: 3, leftCol: 2, bottomRow: 4, rightCol: 3), // 2x2 = 4
        const PatchRect(topRow: 4, leftCol: 4, bottomRow: 4, rightCol: 4), // 1x1 = 1
      ],
    ),

    // Seviye 5: 6x6 (Büyük Izgara)
    PatchesLevel(
      id: 'patches_5',
      gridSize: 6,
      clues: [
        const PatchesClue(row: 0, col: 1, targetArea: 6),
        const PatchesClue(row: 1, col: 4, targetArea: 6),
        const PatchesClue(row: 2, col: 0, targetArea: 4),
        const PatchesClue(row: 3, col: 3, targetArea: 4),
        const PatchesClue(row: 2, col: 5, targetArea: 4),
        const PatchesClue(row: 5, col: 0, targetArea: 4),
        const PatchesClue(row: 4, col: 2, targetArea: 4),
        const PatchesClue(row: 5, col: 4, targetArea: 4),
      ],
      solution: [
        const PatchRect(topRow: 0, leftCol: 0, bottomRow: 1, rightCol: 2), // 2x3 = 6
        const PatchRect(topRow: 0, leftCol: 3, bottomRow: 1, rightCol: 5), // 2x3 = 6
        const PatchRect(topRow: 2, leftCol: 0, bottomRow: 3, rightCol: 1), // 2x2 = 4
        const PatchRect(topRow: 2, leftCol: 2, bottomRow: 3, rightCol: 3), // 2x2 = 4
        const PatchRect(topRow: 2, leftCol: 4, bottomRow: 3, rightCol: 5), // 2x2 = 4
        const PatchRect(topRow: 4, leftCol: 0, bottomRow: 5, rightCol: 1), // 2x2 = 4
        const PatchRect(topRow: 4, leftCol: 2, bottomRow: 5, rightCol: 3), // 2x2 = 4
        const PatchRect(topRow: 4, leftCol: 4, bottomRow: 5, rightCol: 5), // 2x2 = 4
      ],
    ),
  ];

  static List<PatchesLevel> get presets => _presets;

  static PatchesLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
