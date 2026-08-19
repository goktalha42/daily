import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CellContent {
  empty,
  cross,
  queen,
}

enum QueensDifficulty {
  kolay(
    label: 'KOLAY',
    gridSize: 6,
    color: AppColors.accentCyan,
    description: '6x6 - Net mantıksal bloklar',
  ),
  orta(
    label: 'ORTA',
    gridSize: 8,
    color: AppColors.accentPurple,
    description: '8x8 - Dengeli kısıtlar',
  ),
  zor(
    label: 'ZOR',
    gridSize: 9,
    color: AppColors.accentOrange,
    description: '9x9 - İleri düzey girintili bölgeler',
  );

  final String label;
  final int gridSize;
  final Color color;
  final String description;

  const QueensDifficulty({
    required this.label,
    required this.gridSize,
    required this.color,
    required this.description,
  });
}

class QueensCell {
  final int row;
  final int col;
  final int regionId;
  CellContent content;
  bool isConflict;
  bool isHighlighted;

  QueensCell({
    required this.row,
    required this.col,
    required this.regionId,
    this.content = CellContent.empty,
    this.isConflict = false,
    this.isHighlighted = false,
  });

  QueensCell copyWith({
    int? row,
    int? col,
    int? regionId,
    CellContent? content,
    bool? isConflict,
    bool? isHighlighted,
  }) {
    return QueensCell(
      row: row ?? this.row,
      col: col ?? this.col,
      regionId: regionId ?? this.regionId,
      content: content ?? this.content,
      isConflict: isConflict ?? this.isConflict,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }
}

class QueensLevel {
  final String id;
  final int gridSize;
  final QueensDifficulty difficulty;
  final List<List<int>> regionMap; // N x N grid containing region IDs (0 .. N-1)
  final List<List<int>> solution; // Array of [row, col] positions for queens

  const QueensLevel({
    required this.id,
    required this.gridSize,
    required this.difficulty,
    required this.regionMap,
    required this.solution,
  });
}

/// Sınır hesaplamaları (LinkedIn tarzı kalın ve ince çizgiler için)
class CellBorders {
  final bool hasTopBorder;
  final bool hasBottomBorder;
  final bool hasLeftBorder;
  final bool hasRightBorder;

  const CellBorders({
    required this.hasTopBorder,
    required this.hasBottomBorder,
    required this.hasLeftBorder,
    required this.hasRightBorder,
  });

  static CellBorders compute(List<List<int>> regionMap, int r, int c, int size) {
    final currentRegion = regionMap[r][c];
    final top = r == 0 || regionMap[r - 1][c] != currentRegion;
    final bottom = r == size - 1 || regionMap[r + 1][c] != currentRegion;
    final left = c == 0 || regionMap[r][c - 1] != currentRegion;
    final right = c == size - 1 || regionMap[r][c + 1] != currentRegion;

    return CellBorders(
      hasTopBorder: top,
      hasBottomBorder: bottom,
      hasLeftBorder: left,
      hasRightBorder: right,
    );
  }
}
