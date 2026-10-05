import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'queens_models.dart';
import '../../core/theme/app_colors.dart';

/// Zühtü - Queens (Vezirler) Organik El Çizimi Tahta Çizicisi.
///
/// Kareli defter üzerine kurşun kalem ve fosforlu keçeli kalemle
/// serbest elle (wobbly/hand-drawn) çizilmiş organik bölge sınırları ve ızgara.
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

    // 1. BÖLGE ARKA PLANLARI (Fosforlu Keçeli Kalem Boyaması)
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

        // Fosforlu pastel dolgu
        final bgPaint = Paint()
          ..color = baseColor.withValues(alpha: 0.88)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, bgPaint);

        // Kural İhlali / Çakışma Arka Plan Karalaması
        if (cell.isConflict) {
          final conflictPaint = Paint()
            ..color = AppColors.error.withValues(alpha: 0.40)
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, conflictPaint);

          // Çakışan hücreye kırmızı çapraz skeç taraması
          final hatchPaint = Paint()
            ..color = AppColors.error.withValues(alpha: 0.5)
            ..strokeWidth = 1.4;
          for (double x = -cellSize; x < cellSize * 2; x += 8) {
            canvas.drawLine(
              Offset(rect.left + x, rect.top),
              Offset(rect.left + x + cellSize, rect.bottom),
              hatchPaint,
            );
          }
        } else if (cell.isHighlighted) {
          final highlightPaint = Paint()
            ..color = AppColors.highlighterYellow.withValues(alpha: 0.45);
          canvas.drawRect(rect, highlightPaint);
        }
      }
    }

    // 2. İÇ İNCE IZGARA (Hafif ve doğal el taslağı çizgileri)
    final thinBorderPaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final currentRegion = regionMap[r][c];

        // Sağ komşu (aynı bölgeyse)
        if (c + 1 < gridSize && regionMap[r][c + 1] == currentRegion) {
          _drawOrganicLine(
            canvas,
            Offset((c + 1) * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thinBorderPaint,
            wobble: 0.6,
            seed: r * 7 + c * 3,
          );
        }

        // Alt komşu (aynı bölgeyse)
        if (r + 1 < gridSize && regionMap[r + 1][c] == currentRegion) {
          _drawOrganicLine(
            canvas,
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thinBorderPaint,
            wobble: 0.6,
            seed: r * 5 + c * 11,
          );
        }
      }
    }

    // 3. KALIN BÖLGE SINIRLARI (Organik Çini Mürekkebi / Kurşun Kalem Vuruşu)
    final thickBorderPaint = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Dikey Sınırlar (Farklı bölgeler arası)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 1; c++) {
        if (regionMap[r][c] != regionMap[r][c + 1]) {
          _drawOrganicLine(
            canvas,
            Offset((c + 1) * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thickBorderPaint,
            wobble: 1.4,
            seed: r * 13 + c * 17,
            overshoot: 2.0,
          );
        }
      }
    }

    // Yatay Sınırlar (Farklı bölgeler arası)
    for (int r = 0; r < gridSize - 1; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (regionMap[r][c] != regionMap[r + 1][c]) {
          _drawOrganicLine(
            canvas,
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            thickBorderPaint,
            wobble: 1.4,
            seed: r * 19 + c * 23,
            overshoot: 2.0,
          );
        }
      }
    }

    // 4. TAHTA DIŞ ÇERÇEVESİ (Elle Çizilmiş Çift Vuruşlu Skeç Çerçeve)
    _drawHandDrawnOuterFrame(canvas, size);
  }

  /// Doğal serbest el çizgisi çizer (hafif dalgalanma + köşe taşması).
  void _drawOrganicLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double wobble = 1.2,
    int seed = 0,
    double overshoot = 0.0,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final ux = dx / len;
    final uy = dy / len;
    final nx = -uy;
    final ny = ux;

    final p0 = Offset(start.dx - ux * overshoot, start.dy - uy * overshoot);
    final p3 = Offset(end.dx + ux * overshoot, end.dy + uy * overshoot);

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final wAmount = math.sin(seed * 0.45 + len) * wobble;
    final pMid = Offset(mid.dx + nx * wAmount, mid.dy + ny * wAmount);

    final path = Path();
    path.moveTo(p0.dx, p0.dy);
    path.quadraticBezierTo(pMid.dx, pMid.dy, p3.dx, p3.dy);
    canvas.drawPath(path, paint);
  }

  /// Tahtanın etrafına serbest elle çizilmiş kurşun kalem çerçevesi ve köşe taşmaları ekler.
  void _drawHandDrawnOuterFrame(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final draftPaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    const over = 5.0; // Köşelerden hafif taşma (Mimari skeç detayı)

    // Üst kenar
    _drawOrganicLine(canvas, const Offset(0, 0), Offset(w, 0), framePaint, overshoot: over, wobble: 1.5, seed: 101);
    _drawOrganicLine(canvas, const Offset(0, 0.8), Offset(w, 0.4), draftPaint, overshoot: over * 0.7, wobble: 2.0, seed: 102);

    // Sağ kenar
    _drawOrganicLine(canvas, Offset(w, 0), Offset(w, h), framePaint, overshoot: over, wobble: 1.5, seed: 201);
    _drawOrganicLine(canvas, Offset(w - 0.6, 0), Offset(w + 0.4, h), draftPaint, overshoot: over * 0.7, wobble: 2.0, seed: 202);

    // Alt kenar
    _drawOrganicLine(canvas, Offset(0, h), Offset(w, h), framePaint, overshoot: over, wobble: 1.5, seed: 301);
    _drawOrganicLine(canvas, Offset(0, h - 0.7), Offset(w, h + 0.3), draftPaint, overshoot: over * 0.7, wobble: 2.0, seed: 302);

    // Sol kenar
    _drawOrganicLine(canvas, const Offset(0, 0), Offset(0, h), framePaint, overshoot: over, wobble: 1.5, seed: 401);
    _drawOrganicLine(canvas, const Offset(0.5, 0), Offset(-0.4, h), draftPaint, overshoot: over * 0.7, wobble: 2.0, seed: 402);
  }

  @override
  bool shouldRepaint(covariant QueensBoardPainter oldDelegate) {
    return oldDelegate.grid != grid ||
        oldDelegate.isDark != isDark ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.regionMap != regionMap;
  }
}
