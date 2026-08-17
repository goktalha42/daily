import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum CellContent { empty, cross, queen }

enum QueensDifficulty {
  basit(
    label: 'BASİT',
    gridSize: 5,
    color: AppColors.accentCyan,
    description: '5x5 - Kolay mantıksal başlangıç',
  ),
  temel(
    label: 'TEMEL',
    gridSize: 6,
    color: AppColors.accentPurple,
    description: '6x6 - Dengeli mantık bulmacası',
  ),
  zor(
    label: 'ZOR',
    gridSize: 8,
    color: AppColors.accentOrange,
    description: '8x8 - İleri düzey eleme stratejisi',
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

  QueensCell({
    required this.row,
    required this.col,
    required this.regionId,
    this.content = CellContent.empty,
    this.isConflict = false,
  });
}

class QueensLevel {
  final String id;
  final int gridSize;
  final QueensDifficulty difficulty;
  final List<List<int>> regionMap; // Grid size N x N mapping region IDs (0 to N-1)
  final List<List<int>> solution; // Array of [row, col] for correct queen positions

  QueensLevel({
    required this.id,
    required this.gridSize,
    required this.difficulty,
    required this.regionMap,
    required this.solution,
  });
}
