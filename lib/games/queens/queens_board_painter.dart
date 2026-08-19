import 'package:flutter/material.dart';
import 'queens_models.dart';
import '../../core/theme/app_colors.dart';

/// LinkedIn Queens tarzı kalın bölge sınırları (Thick Outer Region Borders) ve
/// aynı bölge içi yumuşak ayrım çizgilerini çizen CustomPainter.
class QueensBoardPainter extends CustomPainter {
  final int gridSize;
  final List<List<int>> regionMap;
  final List<List<QueensCell>> grid;
  final List<Color> palette;
  final bool isDark;

  QueensBoardPainter({
    required this.gridSize,
    required this.regionMap,
    required this.grid,
    required this.palette,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // 1. Hücre Arka Planlarını Boya
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final regionId = regionMap[r][c];
        final baseColor = palette[regionId % palette.length];
        final cell = grid[r][c];

        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );

        final bgPaint = Paint()..color = baseColor;
        canvas.drawRect(rect, bgPaint);

        // Kural İhlali / Çakışma Arka Plan Parlaması
        if (cell.isConflict) {
          final conflictPaint = Paint()
            ..color = AppColors.error.withOpacity(isDark ? 0.45 : 0.35);
          canvas.drawRect(rect, conflictPaint);
        } else if (cell.isHighlighted) {
          final highlightPaint = Paint()
            ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
          canvas.drawRect(rect, highlightPaint);
        }
      }
    }

    // 2. İç İnce Çizgiler (Aynı Bölge Hücreleri Arası)
    final thinBorderPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF0F172A)).withOpacity(0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final currentRegion = regionMap[r][c];

        // Sağ komşu kontrolü
        if (c + 1 < gridSize && regionMap[r][c + 1] == currentRegion) {
          canvas.drawLine(
            Offset((c + 1) * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thinBorderPaint,
          );
        }

        // Alt komşu kontrolü
        if (r + 1 < gridSize && regionMap[r + 1][c] == currentRegion) {
          canvas.drawLine(
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thinBorderPaint,
          );
        }
      }
    }

    // 3. Kalın Bölge Sınırları (Thick Outer Region Borders)
    final thickBorderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFF0F172A);
    final thickBorderPaint = Paint()
      ..color = thickBorderColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // Dikey Sınırlar (Farklı bölgeler arası)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 1; c++) {
        if (regionMap[r][c] != regionMap[r][c + 1]) {
          canvas.drawLine(
            Offset((c + 1) * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thickBorderPaint,
          );
        }
      }
    }

    // Yatay Sınırlar (Farklı bölgeler arası)
    for (int r = 0; r < gridSize - 1; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (regionMap[r][c] != regionMap[r + 1][c]) {
          canvas.drawLine(
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thickBorderPaint,
          );
        }
      }
    }

    // 4. Tahta Dış Çerçevesi (Outer Border)
    final outerFramePaint = Paint()
      ..color = thickBorderColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      outerFramePaint,
    );
  }

  @override
  bool shouldRepaint(covariant QueensBoardPainter oldDelegate) {
    return oldDelegate.grid != grid ||
        oldDelegate.isDark != isDark ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.regionMap != regionMap;
  }
}
