import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Eskiz Defteri Kağıt Dokusu (Hafif kurşun kalem ızgara, sol marjin çizgisi ve kenar eskiz karalamaları)
class SketchPaperBackground extends StatelessWidget {
  final Widget child;

  const SketchPaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SketchNotebookPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SketchNotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Defter Kareli Izgarası (hafif kurşun kalem tonu)
    final gridPaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.032)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 2. Sol Defter Kırmızı Marjin Çizgisi (hafif yamuk el çizimi havası)
    final marginPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.14)
      ..strokeWidth = 1.5;
    
    final marginPath = Path();
    marginPath.moveTo(14, 0);
    for (double y = 0; y <= size.height; y += 40) {
      final wobble = math.sin(y * 0.05) * 0.8;
      marginPath.lineTo(14 + wobble, y);
    }
    canvas.drawPath(marginPath, marginPaint);

    // 3. Kenarlarda hafif karalama / eskiz yıldız ve ok detayları
    final doodlePaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.045)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Sağ üst köşe minik eskiz yıldızı
    _drawDoodleStar(canvas, Offset(size.width - 24, 48), 8, doodlePaint);
    // Sol alt köşe minik spiral karalama
    _drawDoodleSpiral(canvas, Offset(26, size.height - 40), 10, doodlePaint);
  }

  void _drawDoodleStar(Canvas canvas, Offset center, double r, Paint paint) {
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), paint);
    canvas.drawLine(Offset(center.dx - r * 0.7, center.dy - r * 0.7), Offset(center.dx + r * 0.7, center.dy + r * 0.7), paint);
    canvas.drawLine(Offset(center.dx - r * 0.7, center.dy + r * 0.7), Offset(center.dx + r * 0.7, center.dy - r * 0.7), paint);
  }

  void _drawDoodleSpiral(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (double a = 0; a < math.pi * 3; a += 0.2) {
      final rad = (a / (math.pi * 3)) * r;
      final x = center.dx + rad * math.cos(a);
      final y = center.dy + rad * math.sin(a);
      if (a == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Organik ve Yamuk Çizgili Kara Kalem Kart (Hand-Drawn Sketch Box)
/// - Çizgiler cetvelle çizilmiş gibi dümdüz değil, elle çizilmiş gibi hafif dalgalıdır.
/// - Köşelerde çizgiler birbirinin üzerinden taşar (Architectural Corner Overrun).
/// - Kurşun kalemle iki kere geçilmiş hissi veren çift vuruş detayı vardır.
/// - Sert veya taramalı kurşun kalem gölgesi vardır.
class SketchCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool enableHatching;

  const SketchCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.pencilBlack,
    this.borderWidth = 2.2,
    this.borderRadius = 12.0,
    this.shadowOffset = const Offset(3.5, 3.5),
    this.padding = const EdgeInsets.all(14.0),
    this.onTap,
    this.enableHatching = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      painter: _WobblySketchBoxPainter(
        fillColor: backgroundColor,
        strokeColor: borderColor,
        strokeWidth: borderWidth,
        shadowOffset: shadowOffset,
        borderRadius: borderRadius,
        enableHatching: enableHatching,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

class _WobblySketchBoxPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Offset shadowOffset;
  final double borderRadius;
  final bool enableHatching;

  _WobblySketchBoxPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.shadowOffset,
    required this.borderRadius,
    this.enableHatching = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. GÖLGE: Sert veya taramalı kara kalem gölgesi
    if (shadowOffset != Offset.zero) {
      final shadowPath = _buildWobblyPath(
        Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, w, h),
        wobbleSeed: 1.2,
      );
      final shadowPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 2. GÖVDE DOLGUSU (İç renk)
    final mainRect = Rect.fromLTWH(0, 0, w, h);
    final fillPath = _buildWobblyPath(mainRect, wobbleSeed: 0.0);
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2.1 İsteğe bağlı karalama taraması (Hatching)
    if (enableHatching) {
      final hatchPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.12)
        ..strokeWidth = 1.2;
      canvas.save();
      canvas.clipPath(fillPath);
      for (double x = -h; x < w + h; x += 12) {
        canvas.drawLine(Offset(x, 0), Offset(x + h, h), hatchPaint);
      }
      canvas.restore();
    }

    // 3. BİRİNCİ ÇİZGİ KATMANI (Ana organik serbest el kara kalem hat)
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fillPath, strokePaint);

    // 3.1 İKİNCİ SERBEST EL TASLAK VURUŞU (Hafifçe ayrılan serbest el çizgisi)
    final draftPath = _buildWobblyPath(mainRect, wobbleSeed: 3.5, amplitude: 3.0);
    final draftPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.35)
      ..strokeWidth = math.max(1.0, strokeWidth * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(draftPath, draftPaint);

    // 4. KÖŞE TAŞMALARI (Architectural Overshoots)
    _drawSketchCornerOverruns(canvas, mainRect, strokeColor, strokeWidth);
  }

  Path _buildWobblyPath(Rect rect, {double wobbleSeed = 0.0, double amplitude = 2.8}) {
    final path = Path();
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final rad = math.min(borderRadius, math.min(rect.width, rect.height) / 2);

    // Üst kenar: Gerçek bir el çizimi gibi doğal olarak kavisli ve hafif yaylanan
    path.moveTo(l + rad, t + amplitude * 0.5 * math.sin(wobbleSeed + 1.0));
    path.cubicTo(
      l + rect.width * 0.35,
      t - amplitude * math.cos(wobbleSeed + 1.2),
      l + rect.width * 0.70,
      t + amplitude * 0.8 * math.sin(wobbleSeed + 1.8),
      r - rad,
      t + amplitude * 0.4 * math.cos(wobbleSeed + 2.2),
    );

    // Sağ üst köşe (yumuşak serbest el kıvrımı)
    path.quadraticBezierTo(r + amplitude * 0.3, t + amplitude * 0.3, r + amplitude * 0.4, t + rad);

    // Sağ kenar
    path.cubicTo(
      r + amplitude * math.sin(wobbleSeed + 2.6),
      t + rect.height * 0.35,
      r - amplitude * 0.7 * math.cos(wobbleSeed + 3.2),
      t + rect.height * 0.70,
      r - amplitude * 0.3,
      b - rad,
    );

    // Sağ alt köşe
    path.quadraticBezierTo(r, b + amplitude * 0.5, r - rad, b + amplitude * 0.6);

    // Alt kenar
    path.cubicTo(
      l + rect.width * 0.70,
      b + amplitude * math.sin(wobbleSeed + 4.0),
      l + rect.width * 0.35,
      b - amplitude * 0.8 * math.cos(wobbleSeed + 4.6),
      l + rad,
      b + amplitude * 0.2 * math.sin(wobbleSeed + 5.0),
    );

    // Sol alt köşe
    path.quadraticBezierTo(l - amplitude * 0.4, b, l - amplitude * 0.5, b - rad);

    // Sol kenar
    path.cubicTo(
      l - amplitude * math.cos(wobbleSeed + 5.2),
      t + rect.height * 0.70,
      l + amplitude * 0.7 * math.sin(wobbleSeed + 5.8),
      t + rect.height * 0.35,
      l - amplitude * 0.2,
      t + rad,
    );

    // Sol üst köşe ve kapanış
    path.quadraticBezierTo(l, t - amplitude * 0.3, l + rad, t);
    path.close();
    return path;
  }

  void _drawSketchCornerOverruns(Canvas canvas, Rect rect, Color color, double width) {
    final overrunPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = math.max(1.2, width * 0.75)
      ..strokeCap = StrokeCap.round;

    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    const ov = 6.0; // Belirgin taşan kurşun kalem mesafesi

    // Sol-Üst taşmalar (X kesişimi)
    canvas.drawLine(Offset(l - ov, t + 2.0), Offset(l + 14, t - 1.0), overrunPaint);
    canvas.drawLine(Offset(l + 1.0, t - ov), Offset(l - 1.0, t + 14), overrunPaint);

    // Sağ-Üst taşmalar
    canvas.drawLine(Offset(r - 14, t - 1.0), Offset(r + ov, t + 2.0), overrunPaint);
    canvas.drawLine(Offset(r - 1.0, t - ov), Offset(r + 1.0, t + 14), overrunPaint);

    // Sol-Alt taşmalar
    canvas.drawLine(Offset(l - ov, b - 2.0), Offset(l + 14, b + 1.0), overrunPaint);
    canvas.drawLine(Offset(l - 1.0, b - 14), Offset(l + 1.0, b + ov), overrunPaint);

    // Sağ-Alt taşmalar
    canvas.drawLine(Offset(r - 14, b + 1.0), Offset(r + ov, b - 2.0), overrunPaint);
    canvas.drawLine(Offset(r + 1.0, b - 14), Offset(r - 1.0, b + ov), overrunPaint);
  }

  @override
  bool shouldRepaint(covariant _WobblySketchBoxPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.shadowOffset != shadowOffset ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.enableHatching != enableHatching;
}

/// Fotoğraftaki İkonik "İçinde Çapraz X Olan El Çizimi Skeç Kutusu"
/// (Tamamen serbest el kıvrımları, RRect yok, doğal fırça/kalem darbeleri)
class SketchPlaceholderBox extends StatelessWidget {
  final double width;
  final double height;
  final Color fillColor;
  final Color lineColor;
  final double lineWidth;
  final Widget? child;
  final double borderRadius;

  const SketchPlaceholderBox({
    super.key,
    required this.width,
    required this.height,
    this.fillColor = AppColors.highlighterYellow,
    this.lineColor = AppColors.pencilBlack,
    this.lineWidth = 2.2,
    this.child,
    this.borderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SketchPlaceholderPainter(
          fillColor: fillColor,
          lineColor: lineColor,
          lineWidth: lineWidth,
          borderRadius: borderRadius,
        ),
        child: child != null ? Center(child: child!) : null,
      ),
    );
  }
}

class _SketchPlaceholderPainter extends CustomPainter {
  final Color fillColor;
  final Color lineColor;
  final double lineWidth;
  final double borderRadius;

  _SketchPlaceholderPainter({
    required this.fillColor,
    required this.lineColor,
    required this.lineWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Gölge (Organik serbest el gölgesi)
    const shadowOffset = Offset(3.0, 3.0);
    final shadowPath = _buildOrganicPath(Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, w, h), seed: 1.5);
    canvas.drawPath(shadowPath, Paint()..color = lineColor..style = PaintingStyle.fill);

    // 2. Gövde Dolgusu
    final mainRect = Rect.fromLTWH(0, 0, w, h);
    final bodyPath = _buildOrganicPath(mainRect, seed: 0.0);
    canvas.drawPath(bodyPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    // 3. İçerideki Çapraz "X" El Çizimi Çizgileri (Hafif yaylanan iki serbest el vuruşu)
    final xPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.55)
      ..strokeWidth = lineWidth * 0.90
      ..strokeCap = StrokeCap.round;

    // Vuruş 1: Sol-Üst -> Sağ-Alt (hafifçe içeri doğru bükülen doğal yay)
    final p1 = Path();
    p1.moveTo(8, 7);
    p1.cubicTo(w * 0.40, h * 0.55, w * 0.60, h * 0.45, w - 8, h - 8);
    canvas.drawPath(p1, xPaint);

    // Vuruş 1 gölgesi (ikinci hafif kurşun kalem geçişi)
    final p1Draft = Path();
    p1Draft.moveTo(9, 6);
    p1Draft.cubicTo(w * 0.45, h * 0.50, w * 0.55, h * 0.42, w - 6, h - 9);
    canvas.drawPath(p1Draft, xPaint..color = lineColor.withValues(alpha: 0.28));

    // Vuruş 2: Sağ-Üst -> Sol-Alt
    final p2 = Path();
    p2.moveTo(w - 8, 7);
    p2.cubicTo(w * 0.60, h * 0.55, w * 0.40, h * 0.45, 8, h - 8);
    canvas.drawPath(p2, xPaint..color = lineColor.withValues(alpha: 0.55));

    final p2Draft = Path();
    p2Draft.moveTo(w - 7, 6);
    p2Draft.cubicTo(w * 0.55, h * 0.50, w * 0.45, h * 0.42, 6, h - 9);
    canvas.drawPath(p2Draft, xPaint..color = lineColor.withValues(alpha: 0.28));

    // 4. Dış Sınır Çizgisi (Serbest el organik hat)
    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, borderPaint);

    // İkinci taslak konturu
    final draftBorder = _buildOrganicPath(mainRect, seed: 2.0);
    canvas.drawPath(draftBorder, borderPaint..color = lineColor.withValues(alpha: 0.35)..strokeWidth = 1.2);

    // Taşan köşe uçları (Corner overshoots)
    const ov = 5.0;
    final overrunPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(-ov, 3), const Offset(10, -1), overrunPaint);
    canvas.drawLine(const Offset(3, -ov), const Offset(-1, 10), overrunPaint);
    canvas.drawLine(Offset(w - 10, -1), Offset(w + ov, 3), overrunPaint);
    canvas.drawLine(Offset(w - 1, -ov), Offset(w + 2, 10), overrunPaint);
  }

  Path _buildOrganicPath(Rect rect, {double seed = 0.0}) {
    final path = Path();
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    const amp = 2.6;

    path.moveTo(l + borderRadius, t + amp * math.sin(seed));
    path.cubicTo(
      l + rect.width * 0.4,
      t - amp * math.cos(seed + 1),
      l + rect.width * 0.7,
      t + amp * 0.8 * math.sin(seed + 2),
      r - borderRadius,
      t + amp * 0.4,
    );
    path.quadraticBezierTo(r + amp * 0.5, t, r + amp * 0.4, t + borderRadius);

    path.cubicTo(
      r + amp * math.sin(seed + 3),
      t + rect.height * 0.4,
      r - amp * 0.6 * math.cos(seed + 4),
      t + rect.height * 0.7,
      r - amp * 0.2,
      b - borderRadius,
    );
    path.quadraticBezierTo(r, b + amp * 0.5, r - borderRadius, b + amp * 0.5);

    path.cubicTo(
      l + rect.width * 0.7,
      b + amp * math.sin(seed + 5),
      l + rect.width * 0.3,
      b - amp * 0.7 * math.cos(seed + 6),
      l + borderRadius,
      b + amp * 0.3,
    );
    path.quadraticBezierTo(l - amp * 0.4, b, l - amp * 0.4, b - borderRadius);

    path.cubicTo(
      l - amp * math.cos(seed + 7),
      t + rect.height * 0.7,
      l + amp * 0.6 * math.sin(seed + 8),
      t + rect.height * 0.3,
      l - amp * 0.2,
      t + borderRadius,
    );
    path.quadraticBezierTo(l, t, l + borderRadius, t + amp * math.sin(seed));
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SketchPlaceholderPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.borderRadius != borderRadius;
}

/// Fotoğraftaki El Çizimi Dairesel Yüzde Halkası (%92 Başarı Göstergesi)
/// - Kusursuz yuvarlak değil, elle çizilmiş gibi hafif basık/oval ve çift vuruşlu.
class SketchCircularDoodle extends StatelessWidget {
  final double size;
  final double percentage;
  final Color strokeColor;
  final Color fillColor;
  final Widget? centerChild;

  const SketchCircularDoodle({
    super.key,
    required this.size,
    required this.percentage,
    this.strokeColor = AppColors.pencilBlack,
    this.fillColor = AppColors.highlighterCyan,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _WobblySketchCirclePainter(
              percentage: percentage,
              strokeColor: strokeColor,
              fillColor: fillColor,
            ),
          ),
          ?centerChild,
        ],
      ),
    );
  }
}

class _WobblySketchCirclePainter extends CustomPainter {
  final double percentage;
  final Color strokeColor;
  final Color fillColor;

  _WobblySketchCirclePainter({
    required this.percentage,
    required this.strokeColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;

    // 1. Arka plan hafif açık gri karalama çemberi (iki kez geçilmiş)
    final bgPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.16)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final bgSubPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(center.dx + 0.8, center.dy - 0.6), radius + 1.5, bgSubPaint);

    // 2. Fosforlu Kalem Dolgu Yayı (Elle boyanmış gibi kalın ve uçları yuvarlak)
    final progressPaint = Paint()
      ..color = fillColor
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * (percentage / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // 3. Dış Kara Kalem Çerçevesi (Elle çizilmiş gibi hafif dalgalı)
    final outlinePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final outlinePath = Path();
    for (double a = 0; a <= math.pi * 2 + 0.2; a += 0.2) {
      final wobble = math.sin(a * 4) * 0.8;
      final r = radius + 3.5 + wobble;
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      if (a == 0) {
        outlinePath.moveTo(x, y);
      } else {
        outlinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(outlinePath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _WobblySketchCirclePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.fillColor != fillColor;
}

// ============================================================================
// ÖZEL KARA KALEM DOODLE İKONLARI (Hand-Drawn Doodle Widgets)
// ============================================================================

/// El Çizimi Taç (Crown Doodle)
class SketchDoodleCrown extends StatelessWidget {
  final double size;
  final Color color;
  final Color? fillColor;

  const SketchDoodleCrown({
    super.key,
    this.size = 24,
    this.color = AppColors.pencilBlack,
    this.fillColor = AppColors.highlighterYellow,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleCrownPainter(color: color, fillColor: fillColor),
    );
  }
}

class _DoodleCrownPainter extends CustomPainter {
  final Color color;
  final Color? fillColor;

  _DoodleCrownPainter({required this.color, this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.15, h * 0.75); // sol taban
    path.lineTo(w * 0.85, h * 0.75); // sağ taban
    path.lineTo(w * 0.90, h * 0.35); // sağ zirve
    path.lineTo(w * 0.65, h * 0.52); // sağ çukur
    path.lineTo(w * 0.50, h * 0.20); // orta zirve
    path.lineTo(w * 0.35, h * 0.52); // sol çukur
    path.lineTo(w * 0.10, h * 0.35); // sol zirve
    path.close();

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Çift vuruş kurşun kalem çizgisi
    final doubleStroke = Path()
      ..moveTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.82, h * 0.72);
    canvas.drawPath(doubleStroke, strokePaint..strokeWidth = 1.0);

    // Zirve incileri
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(w * 0.10, h * 0.35), 1.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.20), 2.2, dotPaint);
    canvas.drawCircle(Offset(w * 0.90, h * 0.35), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// El Çizimi Alev (Flame / Streak Doodle)
class SketchDoodleFlame extends StatelessWidget {
  final double size;
  final Color color;
  final Color? fillColor;

  const SketchDoodleFlame({
    super.key,
    this.size = 28,
    this.color = AppColors.pencilBlack,
    this.fillColor = AppColors.highlighterOrange,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleFlamePainter(color: color, fillColor: fillColor),
    );
  }
}

class _DoodleFlamePainter extends CustomPainter {
  final Color color;
  final Color? fillColor;

  _DoodleFlamePainter({required this.color, this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPath = Path();
    outerPath.moveTo(w * 0.5, h * 0.08); // Zirve
    outerPath.cubicTo(w * 0.25, h * 0.30, w * 0.08, h * 0.55, w * 0.20, h * 0.80);
    outerPath.cubicTo(w * 0.28, h * 0.95, w * 0.72, h * 0.95, w * 0.80, h * 0.80);
    outerPath.cubicTo(w * 0.92, h * 0.55, w * 0.75, h * 0.30, w * 0.5, h * 0.08);
    outerPath.close();

    if (fillColor != null) {
      canvas.drawPath(outerPath, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerPath, strokePaint);

    // İç alev karalaması
    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.45);
    innerPath.cubicTo(w * 0.35, h * 0.60, w * 0.32, h * 0.75, w * 0.42, h * 0.84);
    innerPath.cubicTo(w * 0.58, h * 0.84, w * 0.65, h * 0.75, w * 0.58, h * 0.60);
    innerPath.close();
    canvas.drawPath(innerPath, strokePaint..strokeWidth = 1.3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// El Çizimi Beyin / Zeka (Brain Doodle)
class SketchDoodleBrain extends StatelessWidget {
  final double size;
  final Color color;
  final Color? fillColor;

  const SketchDoodleBrain({
    super.key,
    this.size = 28,
    this.color = AppColors.pencilBlack,
    this.fillColor = AppColors.highlighterCyan,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleBrainPainter(color: color, fillColor: fillColor),
    );
  }
}

class _DoodleBrainPainter extends CustomPainter {
  final Color color;
  final Color? fillColor;

  _DoodleBrainPainter({required this.color, this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    // Beyin dış hat kıvrımları
    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.3, h * 0.90, w * 0.1, h * 0.75, w * 0.15, h * 0.55);
    path.cubicTo(w * 0.05, h * 0.35, w * 0.25, h * 0.15, w * 0.45, h * 0.20);
    path.cubicTo(w * 0.48, h * 0.15, w * 0.52, h * 0.15, w * 0.55, h * 0.20);
    path.cubicTo(w * 0.75, h * 0.15, w * 0.95, h * 0.35, w * 0.85, h * 0.55);
    path.cubicTo(w * 0.90, h * 0.75, w * 0.70, h * 0.90, w * 0.5, h * 0.85);
    path.close();

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    // Orta çizgi
    canvas.drawLine(Offset(w * 0.5, h * 0.20), Offset(w * 0.5, h * 0.85), stroke);

    // Kıvrım karalamaları (Sulcus & Gyri)
    final folds = Path();
    folds.moveTo(w * 0.30, h * 0.40);
    folds.quadraticBezierTo(w * 0.45, h * 0.42, w * 0.35, h * 0.65);

    folds.moveTo(w * 0.70, h * 0.40);
    folds.quadraticBezierTo(w * 0.55, h * 0.42, w * 0.65, h * 0.65);

    canvas.drawPath(folds, stroke..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// El Çizimi Kupa (Trophy Doodle)
class SketchDoodleTrophy extends StatelessWidget {
  final double size;
  final Color color;
  final Color? fillColor;

  const SketchDoodleTrophy({
    super.key,
    this.size = 28,
    this.color = AppColors.pencilBlack,
    this.fillColor = AppColors.highlighterYellow,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleTrophyPainter(color: color, fillColor: fillColor),
    );
  }
}

class _DoodleTrophyPainter extends CustomPainter {
  final Color color;
  final Color? fillColor;

  _DoodleTrophyPainter({required this.color, this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kupa kadehi
    final cup = Path();
    cup.moveTo(w * 0.28, h * 0.20);
    cup.lineTo(w * 0.72, h * 0.20);
    cup.cubicTo(w * 0.72, h * 0.55, w * 0.60, h * 0.62, w * 0.50, h * 0.65);
    cup.cubicTo(w * 0.40, h * 0.62, w * 0.28, h * 0.55, w * 0.28, h * 0.20);
    cup.close();

    if (fillColor != null) {
      canvas.drawPath(cup, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cup, stroke);

    // Kupa kolları (Kulplar)
    final handleLeft = Path();
    handleLeft.moveTo(w * 0.28, h * 0.26);
    handleLeft.cubicTo(w * 0.10, h * 0.26, w * 0.10, h * 0.48, w * 0.32, h * 0.48);
    canvas.drawPath(handleLeft, stroke);

    final handleRight = Path();
    handleRight.moveTo(w * 0.72, h * 0.26);
    handleRight.cubicTo(w * 0.90, h * 0.26, w * 0.90, h * 0.48, w * 0.68, h * 0.48);
    canvas.drawPath(handleRight, stroke);

    // Kupa boynu ve kaidesi
    canvas.drawLine(Offset(w * 0.50, h * 0.65), Offset(w * 0.50, h * 0.78), stroke..strokeWidth = 2.2);
    // Alt taban
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.78, w * 0.36, h * 0.10), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
