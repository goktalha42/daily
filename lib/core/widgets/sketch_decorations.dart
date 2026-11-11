import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Eskiz Defteri Kağıt Dokusu (Hafif kurşun kalem ızgara, sol marjin çizgisi ve kenar eskiz karalamaları)
/// Koyu modda otomatik olarak koyu arduvaz / grafit kağıt dokusuna ve tebeşir ızgarasına geçer.
class SketchPaperBackground extends StatelessWidget {
  final Widget child;

  const SketchPaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final defaultText = isDark ? AppColors.inkWhite : AppColors.inkBlack;
    final defaultSubtitle = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF44403C);

    return Container(
      color: paperColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SketchNotebookPainter(isDark: isDark),
            ),
          ),
          SketchSurfaceScope(
            backgroundColor: paperColor,
            isLightSurface: !isDark,
            textColor: defaultText,
            subtitleColor: defaultSubtitle,
            child: IconTheme.merge(
              data: IconThemeData(color: defaultText),
              child: DefaultTextStyle.merge(
                style: GoogleFonts.patrickHand(color: defaultText),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchNotebookPainter extends CustomPainter {
  final bool isDark;

  _SketchNotebookPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Defter Kareli Izgarası (Açık modda hafif kurşun kalem, Koyu modda hafif beyaz/gümüş tebeşir)
    final gridColor = isDark ? Colors.white : AppColors.pencilBlack;
    final gridAlpha = isDark ? 0.038 : 0.032;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: gridAlpha)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 2. Sol Defter Kırmızı Marjin Çizgisi (hafif yamuk el çizimi havası)
    final marginColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    final marginAlpha = isDark ? 0.22 : 0.14;

    final marginPaint = Paint()
      ..color = marginColor.withValues(alpha: marginAlpha)
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
      ..color = gridColor.withValues(alpha: isDark ? 0.06 : 0.045)
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
  bool shouldRepaint(covariant _SketchNotebookPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Kart ve zeminlerin arka plan aydınlığını (luminance) altındaki tüm çocuklara aktaran scope.
/// Açık renkli zeminlerde (sarı, camgöbeği, pembe, açık pastel vb.) yazıları otomatik SİYAH,
/// Koyu renkli zeminlerde (koyu arduvaz, koyu grafit, gece modu) yazıları otomatik BEYAZ yapar.
class SketchSurfaceScope extends InheritedWidget {
  final Color backgroundColor;
  final bool isLightSurface;
  final Color textColor;
  final Color subtitleColor;

  const SketchSurfaceScope({
    super.key,
    required this.backgroundColor,
    required this.isLightSurface,
    required this.textColor,
    required this.subtitleColor,
    required super.child,
  });

  static bool isLight(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SketchSurfaceScope>();
    if (scope != null) return scope.isLightSurface;
    return Theme.of(context).brightness == Brightness.light;
  }

  static Color textColorOf(BuildContext context, {Color? fallback}) {
    final scope = context.dependOnInheritedWidgetOfExactType<SketchSurfaceScope>();
    if (scope != null) return scope.textColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fallback ?? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1917));
  }

  static Color subtitleColorOf(BuildContext context, {Color? fallback}) {
    final scope = context.dependOnInheritedWidgetOfExactType<SketchSurfaceScope>();
    if (scope != null) return scope.subtitleColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fallback ?? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF44403C));
  }

  @override
  bool updateShouldNotify(SketchSurfaceScope oldWidget) =>
      oldWidget.backgroundColor != backgroundColor ||
      oldWidget.isLightSurface != isLightSurface ||
      oldWidget.textColor != textColor;
}

/// Organik ve Yamuk Çizgili Kara Kalem Kart (Hand-Drawn Sketch Box)
/// - Çizgiler cetvelle çizilmiş gibi dümdüz değil, elle çizilmiş gibi hafif dalgalıdır.
/// - Köşelerde çizgiler birbirinin üzerinden taşar (Architectural Corner Overrun).
/// - Kurşun kalemle iki kere geçilmiş hissi veren çift vuruş detayı vardır.
/// - Sert veya taramalı kurşun kalem gölgesi vardır.
/// - Koyu temada otomatik olarak koyu arduvaz zemin, tebeşir/gümüş çizgi ve derin gölgeye uyarlanır.
class SketchCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool enableHatching;

  const SketchCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.borderWidth = 2.2,
    this.borderRadius = 12.0,
    this.shadowOffset = const Offset(3.5, 3.5),
    this.padding = const EdgeInsets.all(14.0),
    this.onTap,
    this.enableHatching = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color resolvedBg;
    Color resolvedBorder;
    Color resolvedShadow;
    bool isLightBg;
    Color onBgTextColor;
    Color onBgSubtitleColor;

    if (!isDark) {
      // AÇIK TEMADA: Orijinal skeç defteri ve beyaz kart tasarımı aynen korunur.
      resolvedBg = backgroundColor ?? Colors.white;
      resolvedBorder = borderColor ?? AppColors.pencilBlack;
      resolvedShadow = shadowColor ?? resolvedBorder;
      isLightBg = true;
      onBgTextColor = AppColors.pencilBlack;
      onBgSubtitleColor = AppColors.pencilGraphite;
    } else {
      // SADECE KOYU TEMA AKTİFKEN:
      if (backgroundColor == null ||
          backgroundColor == Colors.white ||
          backgroundColor == AppColors.surfaceLight) {
        resolvedBg = AppColors.surfaceDark;
      } else if (backgroundColor == AppColors.surfaceSecondaryLight) {
        resolvedBg = AppColors.surfaceSecondaryDark;
      } else if (backgroundColor == AppColors.backgroundLight) {
        resolvedBg = AppColors.backgroundDark;
      } else {
        resolvedBg = backgroundColor!;
      }

      final effectiveBg = resolvedBg.a < 1.0
          ? Color.alphaBlend(resolvedBg, AppColors.surfaceDark)
          : resolvedBg;
      isLightBg = effectiveBg.computeLuminance() > 0.35;
      onBgTextColor = isLightBg ? AppColors.inkBlack : AppColors.inkWhite;
      onBgSubtitleColor = isLightBg ? const Color(0xFF44403C) : const Color(0xFFE2E8F0);
      resolvedBorder = borderColor ?? (isLightBg ? AppColors.inkBlack : AppColors.sketchBorderDark);
      resolvedShadow = shadowColor ?? (isLightBg ? const Color(0xFF000000) : AppColors.cardShadowDark);
    }

    Widget content = CustomPaint(
      painter: _WobblySketchBoxPainter(
        fillColor: resolvedBg,
        strokeColor: resolvedBorder,
        shadowColor: resolvedShadow,
        strokeWidth: borderWidth,
        shadowOffset: shadowOffset,
        borderRadius: borderRadius,
        enableHatching: enableHatching,
        isDark: isDark,
      ),
      child: Padding(
        padding: padding,
        child: SketchSurfaceScope(
          backgroundColor: resolvedBg,
          isLightSurface: isLightBg,
          textColor: onBgTextColor,
          subtitleColor: onBgSubtitleColor,
          child: IconTheme.merge(
            data: IconThemeData(color: onBgTextColor),
            child: DefaultTextStyle.merge(
              style: GoogleFonts.patrickHand(color: onBgTextColor),
              child: child,
            ),
          ),
        ),
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
  final Color shadowColor;
  final double strokeWidth;
  final Offset shadowOffset;
  final double borderRadius;
  final bool enableHatching;
  final bool isDark;

  _WobblySketchBoxPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.shadowColor,
    required this.strokeWidth,
    required this.shadowOffset,
    required this.borderRadius,
    this.enableHatching = false,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. GÖLGE: Sert veya taramalı kara kalem / tebeşir gölgesi
    if (shadowOffset != Offset.zero) {
      final shadowPath = _buildWobblyPath(
        Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, w, h),
        wobbleSeed: 1.2,
      );
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 2. GÖVDE DOLGUSU (İç renk)
    final mainRect = Rect.fromLTWH(0, 0, w, h);
    final fillPath = _buildWobblyPath(mainRect, wobbleSeed: 0.0);

    // EĞER İÇ RENK YARI SAYDAMLIK (ALPHA) İÇERİYORSA:
    // Alttaki siyah gölgenin saydamlıktan sızıp rengi çamurlaştırmaması için
    // gövde yolunun altına önce temiz opak kağıt/kart tabanı çekilir.
    if (fillColor.a < 1.0) {
      final basePaint = Paint()
        ..color = isDark ? AppColors.surfaceDark : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, basePaint);
    }

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
      oldDelegate.shadowColor != shadowColor ||
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
  final Color? lineColor;
  final double lineWidth;
  final Widget? child;
  final double borderRadius;

  const SketchPlaceholderBox({
    super.key,
    required this.width,
    required this.height,
    this.fillColor = AppColors.sunYellow,
    this.lineColor,
    this.lineWidth = 2.2,
    this.child,
    this.borderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedLine = (lineColor == null || lineColor == AppColors.pencilBlack)
        ? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack)
        : lineColor!;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SketchPlaceholderPainter(
          fillColor: fillColor,
          lineColor: resolvedLine,
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
    final shadowColor = (lineColor == AppColors.pencilWhite) ? AppColors.cardShadowDark : lineColor;
    final shadowPath = _buildOrganicPath(Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, w, h), seed: 1.5);
    canvas.drawPath(shadowPath, Paint()..color = shadowColor..style = PaintingStyle.fill);

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
  final Color? strokeColor;
  final Color fillColor;
  final Widget? centerChild;

  const SketchCircularDoodle({
    super.key,
    required this.size,
    required this.percentage,
    this.strokeColor,
    this.fillColor = AppColors.highlighterCyan,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedStroke = strokeColor ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack);

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
              strokeColor: resolvedStroke,
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

    // 1. Arka plan hafif karalama çemberi (iki kez geçilmiş)
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

    // 3. Dış Kara Kalem / Tebeşir Çerçevesi (Elle çizilmiş gibi hafif dalgalı)
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
  final Color? color;
  final Color? fillColor;

  const SketchDoodleCrown({
    super.key,
    this.size = 24,
    this.color,
    this.fillColor = AppColors.sunYellow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack);

    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleCrownPainter(color: resolvedColor, fillColor: fillColor),
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
  bool shouldRepaint(covariant _DoodleCrownPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// El Çizimi Alev (Flame / Streak Doodle)
class SketchDoodleFlame extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodleFlame({
    super.key,
    this.size = 28,
    this.color,
    this.fillColor = const Color(0xFFF97316),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack);

    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleFlamePainter(color: resolvedColor, fillColor: fillColor),
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
    outerPath.moveTo(w * 0.48, h * 0.90);
    outerPath.cubicTo(w * 0.16, h * 0.90, w * 0.12, h * 0.56, w * 0.30, h * 0.40);
    outerPath.cubicTo(w * 0.24, h * 0.26, w * 0.40, h * 0.12, w * 0.50, h * 0.06);
    outerPath.cubicTo(w * 0.60, h * 0.22, w * 0.80, h * 0.30, w * 0.70, h * 0.50);
    outerPath.cubicTo(w * 0.84, h * 0.62, w * 0.78, h * 0.90, w * 0.48, h * 0.90);
    outerPath.close();

    if (fillColor != null) {
      canvas.drawPath(outerPath, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = (w * 0.075).clamp(1.4, 2.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerPath, strokePaint);

    // İç sarı alev çekirdeği
    final innerPath = Path();
    innerPath.moveTo(w * 0.48, h * 0.85);
    innerPath.cubicTo(w * 0.30, h * 0.85, w * 0.30, h * 0.64, w * 0.42, h * 0.52);
    innerPath.cubicTo(w * 0.45, h * 0.40, w * 0.50, h * 0.32, w * 0.50, h * 0.28);
    innerPath.cubicTo(w * 0.56, h * 0.38, w * 0.66, h * 0.45, w * 0.60, h * 0.58);
    innerPath.cubicTo(w * 0.66, h * 0.68, w * 0.62, h * 0.85, w * 0.48, h * 0.85);
    innerPath.close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = AppColors.sunYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(innerPath, strokePaint..strokeWidth = (w * 0.05).clamp(1.0, 1.5));
  }

  @override
  bool shouldRepaint(covariant _DoodleFlamePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// El Çizimi Beyin / Zeka (Brain Doodle)
class SketchDoodleBrain extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodleBrain({
    super.key,
    this.size = 28,
    this.color,
    this.fillColor = AppColors.highlighterCyan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack);

    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleBrainPainter(color: resolvedColor, fillColor: fillColor),
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
  bool shouldRepaint(covariant _DoodleBrainPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// El Çizimi Kupa (Trophy Doodle)
class SketchDoodleTrophy extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodleTrophy({
    super.key,
    this.size = 28,
    this.color,
    this.fillColor = AppColors.sunYellow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack);

    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleTrophyPainter(color: resolvedColor, fillColor: fillColor),
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
  bool shouldRepaint(covariant _DoodleTrophyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// Zühtü Temalı Merkezi Metin Bileşeni (Central Font Component)
/// Patrick Hand fontunu tek bir noktadan yönetir; karanlık temada otomatik
/// bembeyaz, açık temada ise kurşun kalem siyahı render eder.
class SketchText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? letterSpacing;
  final double? height;

  const SketchText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.letterSpacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.pencilBlack);
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: GoogleFonts.patrickHand(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }
}

/// Tamamen el çizimi, wobbly kenarlı, taramalı ve organik kaligrafik tik damgası.
class HandDrawnCheckBadge extends StatelessWidget {
  final bool isDone;
  final Color pencilColor;
  final bool isDark;
  final int seed;
  final double size;
  final Color? checkColor;
  final Color? fillColor;

  const HandDrawnCheckBadge({
    super.key,
    required this.isDone,
    required this.pencilColor,
    required this.isDark,
    this.seed = 0,
    this.size = 24,
    this.checkColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HandDrawnCheckBadgePainter(
          isDone: isDone,
          pencilColor: pencilColor,
          isDark: isDark,
          seed: seed,
          checkColor: checkColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _HandDrawnCheckBadgePainter extends CustomPainter {
  final bool isDone;
  final Color pencilColor;
  final bool isDark;
  final int seed;
  final Color? checkColor;
  final Color? fillColor;

  _HandDrawnCheckBadgePainter({
    required this.isDone,
    required this.pencilColor,
    required this.isDark,
    required this.seed,
    this.checkColor,
    this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = (math.min(size.width, size.height) / 2) - 2.5;

    // 1. Organik Wobbly Daire Yolu
    const pointsCount = 12;
    final path = Path();
    for (int i = 0; i < pointsCount; i++) {
      final angle = (i * 2 * math.pi) / pointsCount;
      final jitter = (rng.nextDouble() - 0.5) * 1.6;
      final r = baseRadius + jitter;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 2. Sert El Çizimi Eskiz Gölgesi
    final shadowPath = path.shift(const Offset(1.5, 1.5));
    final shadowPaint = Paint()
      ..color = pencilColor.withValues(alpha: isDark ? 0.35 : 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, shadowPaint);

    // 3. Arka Plan Dolgusu
    if (isDone) {
      final effectiveFill = fillColor ??
          (isDark ? const Color(0xFF16A34A) : const Color(0xFF22C55E));
      final fillPaint = Paint()
        ..color = effectiveFill
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Skeç taraması (hatching)
      canvas.save();
      canvas.clipPath(path);
      final hatchPaint = Paint()
        ..color = (isDark ? const Color(0xFF14532D) : const Color(0xFF15803D))
            .withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      for (double x = -10; x < size.width + 10; x += 3.5) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + 8, size.height),
          hatchPaint,
        );
      }
      canvas.restore();
    } else {
      final emptyPaint = Paint()
        ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, emptyPaint);
    }

    // 4. Ana Eskiz Dış Konturu
    final borderPaint = Paint()
      ..color = pencilColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 5. İkinci Serbest El Eskiz Konturu (Taslak Havası)
    final sketchBorderPaint = Paint()
      ..color = pencilColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final secondaryPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8 + 0.3;
      final jitter = (rng.nextDouble() - 0.5) * 1.8;
      final r = baseRadius + jitter;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        secondaryPath.moveTo(x, y);
      } else {
        secondaryPath.lineTo(x, y);
      }
    }
    canvas.drawPath(secondaryPath, sketchBorderPaint);

    // 6. İç İkon: El Çizimi Kaligrafik Tik ya da Pasif Çizgi
    if (isDone) {
      final effectiveCheck = checkColor ?? Colors.white;
      final tickPath = Path();
      final p1 = Offset(cx - 4.6 + (rng.nextDouble() - 0.5) * 0.4, cy + 0.2);
      final p2 = Offset(cx - 1.2 + (rng.nextDouble() - 0.5) * 0.4, cy + 4.2);
      final p3 = Offset(cx + 4.8 + (rng.nextDouble() - 0.5) * 0.4, cy - 3.8);

      tickPath.moveTo(p1.dx, p1.dy);
      tickPath.lineTo(p2.dx, p2.dy);
      tickPath.lineTo(p3.dx, p3.dy);

      final tickShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(tickPath.shift(const Offset(0.6, 0.6)), tickShadowPaint);

      final tickPaint = Paint()
        ..color = effectiveCheck
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(tickPath, tickPaint);

      final tickSubPaint = Paint()
        ..color = effectiveCheck.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(p2.dx - 0.3, p2.dy - 0.2),
        Offset(p3.dx - 0.8, p3.dy + 0.5),
        tickSubPaint,
      );
    } else {
      final dashPaint = Paint()
        ..color = pencilColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx - 3.5, cy),
        Offset(cx + 3.5, cy),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandDrawnCheckBadgePainter oldDelegate) {
    return oldDelegate.isDone != isDone ||
        oldDelegate.pencilColor != pencilColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.seed != seed ||
        oldDelegate.checkColor != checkColor ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Tamamen el çizimi, wobbly hatlı, sert gölgeli ve taramalı skeç rozeti/kutusu (Badge).
/// Oyun kartlarının altındaki "BİTTİ • 1940P" veya seviye rozetleri için kullanılır.
class HandDrawnBadge extends StatelessWidget {
  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final bool isDark;
  final int seed;
  final EdgeInsetsGeometry padding;
  final bool showHatching;

  const HandDrawnBadge({
    super.key,
    required this.child,
    required this.fillColor,
    required this.borderColor,
    this.isDark = false,
    this.seed = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.showHatching = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandDrawnBadgePainter(
        fillColor: fillColor,
        borderColor: borderColor,
        isDark: isDark,
        seed: seed,
        showHatching: showHatching,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _HandDrawnBadgePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool isDark;
  final int seed;
  final bool showHatching;

  _HandDrawnBadgePainter({
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
    required this.seed,
    required this.showHatching,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rng = math.Random(seed);
    const double radius = 7.0;
    final w = size.width;
    final h = size.height;

    // Organik wobbly yuvarlatılmış dikdörtgen
    final path = Path();
    // Sol üstten sağ üste
    path.moveTo(radius + (rng.nextDouble() - 0.5) * 1.2, (rng.nextDouble() - 0.5) * 1.0);
    path.quadraticBezierTo(
      w * 0.5,
      (rng.nextDouble() - 0.5) * 1.5,
      w - radius + (rng.nextDouble() - 0.5) * 1.2,
      (rng.nextDouble() - 0.5) * 1.0,
    );
    // Sağ üst köşe
    path.quadraticBezierTo(w + (rng.nextDouble() - 0.5) * 1.0, 0, w, radius);
    // Sağ kenar
    path.quadraticBezierTo(
      w + (rng.nextDouble() - 0.5) * 1.5,
      h * 0.5,
      w + (rng.nextDouble() - 0.5) * 0.8,
      h - radius,
    );
    // Sağ alt köşe
    path.quadraticBezierTo(w, h + (rng.nextDouble() - 0.5) * 1.0, w - radius, h);
    // Alt kenar
    path.quadraticBezierTo(
      w * 0.5,
      h + (rng.nextDouble() - 0.5) * 1.5,
      radius + (rng.nextDouble() - 0.5) * 1.2,
      h + (rng.nextDouble() - 0.5) * 0.8,
    );
    // Sol alt köşe
    path.quadraticBezierTo(0, h + (rng.nextDouble() - 0.5) * 1.0, 0, h - radius);
    // Sol kenar
    path.quadraticBezierTo(
      (rng.nextDouble() - 0.5) * 1.5,
      h * 0.5,
      (rng.nextDouble() - 0.5) * 0.8,
      radius,
    );
    // Sol üst köşe kapanışı
    path.quadraticBezierTo(0, 0, radius, (rng.nextDouble() - 0.5) * 1.0);
    path.close();

    // 1. Sert Eskiz Gölgesi
    final shadowOffset = const Offset(1.8, 1.8);
    final shadowPath = path.shift(shadowOffset);
    final shadowPaint = Paint()
      ..color = isDark ? AppColors.cardShadowDark : borderColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Opak taban (saydamlık durumunda gölgenin çamurlaşmasını engeller)
    if (fillColor.a < 1.0) {
      final baseColor = isDark ? const Color(0xFF1C1917) : Colors.white;
      canvas.drawPath(path, Paint()..color = baseColor..style = PaintingStyle.fill);
    }

    // 3. Gövde Renk Dolgusu
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);

    // 4. İnce Skeç Taraması (Hatching)
    if (showHatching) {
      canvas.save();
      canvas.clipPath(path);
      final hatchPaint = Paint()
        ..color = (isDark ? Colors.white : AppColors.inkBlack).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;

      for (double x = -h; x < w + h; x += 5.0) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + h * 0.8, h),
          hatchPaint,
        );
      }
      canvas.restore();
    }

    // 5. Ana Kurşun Kalem Dış Kontur
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 6. İkinci Serbest El Taslak Konturu (Köşelerde hafif kaçıklık)
    final sketchStrokePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final secondPath = Path();
    secondPath.moveTo(radius + 1, -0.5);
    secondPath.lineTo(w - radius - 1, 0.5);
    secondPath.quadraticBezierTo(w + 0.8, 0.5, w - 0.5, radius);
    secondPath.lineTo(w + 0.5, h - radius);
    secondPath.quadraticBezierTo(w + 0.5, h + 0.8, w - radius, h - 0.5);
    secondPath.lineTo(radius, h + 0.5);
    secondPath.quadraticBezierTo(-0.5, h - 0.5, 0.5, h - radius);
    secondPath.lineTo(-0.5, radius);
    secondPath.close();

    canvas.drawPath(secondPath, sketchStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _HandDrawnBadgePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.seed != seed ||
        oldDelegate.showHatching != showHatching;
  }
}

/// 1. El Çizimi Kum Saati Doodle (Zaman Makinesi ve Arşiv Simgesi)
class SketchDoodleHourglass extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodleHourglass({
    super.key,
    this.size = 20,
    this.color,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.pencilBlack);
    final effectiveFill = fillColor ?? AppColors.sunYellow;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodleHourglassPainter(
          color: effectiveColor,
          fillColor: effectiveFill,
        ),
      ),
    );
  }
}

class _DoodleHourglassPainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _DoodleHourglassPainter({
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sand = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Sert gölge
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Üst ve alt tablalar (ahşap el çizimi kapaklar)
    final topBar = Path()
      ..moveTo(w * 0.15, h * 0.10)
      ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.85, h * 0.10);
    final btmBar = Path()
      ..moveTo(w * 0.15, h * 0.90)
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.85, h * 0.90);

    canvas.drawPath(topBar.shift(const Offset(0.8, 0.8)), shadowPaint);
    canvas.drawPath(btmBar.shift(const Offset(0.8, 0.8)), shadowPaint);
    canvas.drawPath(topBar, stroke..strokeWidth = 2.0);
    canvas.drawPath(btmBar, stroke);

    // Cam Gövde (Üst ve alt hazneler, ortada dar boğum)
    final glass = Path();
    glass.moveTo(w * 0.22, h * 0.12);
    // Sol üstten ortaya iniş
    glass.quadraticBezierTo(w * 0.28, h * 0.35, w * 0.46, h * 0.50);
    // Sol ortadan alt sola iniş
    glass.quadraticBezierTo(w * 0.28, h * 0.65, w * 0.22, h * 0.88);
    // Alt taban birleşimi
    glass.lineTo(w * 0.78, h * 0.88);
    // Sağ alttan ortaya çıkış
    glass.quadraticBezierTo(w * 0.72, h * 0.65, w * 0.54, h * 0.50);
    // Sağ ortadan üst sağa çıkış
    glass.quadraticBezierTo(w * 0.72, h * 0.35, w * 0.78, h * 0.12);
    glass.close();

    // Alt haznedeki biriken kum
    final btmSand = Path();
    btmSand.moveTo(w * 0.28, h * 0.85);
    btmSand.quadraticBezierTo(w * 0.50, h * 0.64, w * 0.72, h * 0.85);
    btmSand.close();
    canvas.drawPath(btmSand, sand);

    // Üst haznede kalan kum
    final topSand = Path();
    topSand.moveTo(w * 0.30, h * 0.24);
    topSand.quadraticBezierTo(w * 0.50, h * 0.26, w * 0.70, h * 0.24);
    topSand.quadraticBezierTo(w * 0.60, h * 0.42, w * 0.50, h * 0.48);
    topSand.quadraticBezierTo(w * 0.40, h * 0.42, w * 0.30, h * 0.24);
    topSand.close();
    canvas.drawPath(topSand, sand);

    // Ortadan damlayan kum çizgisi
    final dropStream = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.48), Offset(w * 0.50, h * 0.72), dropStream);

    // Cam dış hat
    canvas.drawPath(glass.shift(const Offset(0.8, 0.8)), shadowPaint);
    canvas.drawPath(glass, stroke..strokeWidth = 1.5);

    // İkinci serbest el eskiz hattı
    final sketchLine = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(w * 0.26, h * 0.16), Offset(w * 0.44, h * 0.46), sketchLine);
    canvas.drawLine(Offset(w * 0.56, h * 0.54), Offset(w * 0.74, h * 0.84), sketchLine);
  }

  @override
  bool shouldRepaint(covariant _DoodleHourglassPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// 2. El Çizimi Hedef / Nişangah Doodle (Analiz Seçili Gün ve Tavsiye Simgesi)
class SketchDoodleTarget extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodleTarget({
    super.key,
    this.size = 20,
    this.color,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.pencilBlack);
    final effectiveFill = fillColor ?? AppColors.highlighterPink;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodleTargetPainter(
          color: effectiveColor,
          fillColor: effectiveFill,
        ),
      ),
    );
  }
}

class _DoodleTargetPainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _DoodleTargetPainter({
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOut = size.width * 0.42;
    final rMid = size.width * 0.26;
    final rIn = size.width * 0.12;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final centerDot = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Dış Halka (Organik serbest el çemberi)
    final outPath = Path();
    for (int i = 0; i <= 10; i++) {
      final angle = (i * 2 * math.pi) / 10;
      final wobble = (i % 2 == 0 ? 0.6 : -0.5);
      final x = cx + (rOut + wobble) * math.cos(angle);
      final y = cy + (rOut + wobble) * math.sin(angle);
      if (i == 0) {
        outPath.moveTo(x, y);
      } else {
        outPath.lineTo(x, y);
      }
    }
    outPath.close();
    canvas.drawPath(outPath, stroke);

    // Orta Halka
    final midPath = Path();
    for (int i = 0; i <= 8; i++) {
      final angle = (i * 2 * math.pi) / 8 + 0.2;
      final wobble = (i % 2 == 0 ? -0.4 : 0.5);
      final x = cx + (rMid + wobble) * math.cos(angle);
      final y = cy + (rMid + wobble) * math.sin(angle);
      if (i == 0) {
        midPath.moveTo(x, y);
      } else {
        midPath.lineTo(x, y);
      }
    }
    midPath.close();
    canvas.drawPath(midPath, stroke..strokeWidth = 1.2);

    // Boğa Gözü (Merkez kırmızı/renkli nokta)
    canvas.drawCircle(Offset(cx, cy), rIn, centerDot);
    canvas.drawCircle(Offset(cx, cy), rIn, stroke..strokeWidth = 1.2);

    // Dışarı taşan 4 nişangah çizgisi (üst, alt, sol, sağ)
    final crossHair = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy - rOut - 2.5), Offset(cx, cy - rMid + 1), crossHair);
    canvas.drawLine(Offset(cx, cy + rMid - 1), Offset(cx, cy + rOut + 2.5), crossHair);
    canvas.drawLine(Offset(cx - rOut - 2.5, cy), Offset(cx - rMid + 1, cy), crossHair);
    canvas.drawLine(Offset(cx + rMid - 1, cy), Offset(cx + rOut + 2.5, cy), crossHair);
  }

  @override
  bool shouldRepaint(covariant _DoodleTargetPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// 3. El Çizimi Madalya Doodle (Sıralama Podyumu 2. Gümüş & 3. Bronz)
class SketchDoodleMedal extends StatelessWidget {
  final int rank; // 1, 2, 3
  final double size;
  final Color? pencilColor;

  const SketchDoodleMedal({
    super.key,
    required this.rank,
    this.size = 24,
    this.pencilColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePencil = pencilColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.pencilBlack);

    final medalFill = rank == 2
        ? const Color(0xFFCBD5E1) // Gümüş
        : (rank == 3
            ? const Color(0xFFFDBA74) // Bronz
            : AppColors.sunYellow); // Altın

    final ribbonFill = rank == 2
        ? const Color(0xFF38BDF8) // Gök mavisi kurdele
        : (rank == 3
            ? const Color(0xFFF87171) // Kırmızı kurdele
            : const Color(0xFFA855F7)); // Mor kurdele

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodleMedalPainter(
          rank: rank,
          pencilColor: effectivePencil,
          medalFill: medalFill,
          ribbonFill: ribbonFill,
        ),
      ),
    );
  }
}

class _DoodleMedalPainter extends CustomPainter {
  final int rank;
  final Color pencilColor;
  final Color medalFill;
  final Color ribbonFill;

  const _DoodleMedalPainter({
    required this.rank,
    required this.pencilColor,
    required this.medalFill,
    required this.ribbonFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = pencilColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. V Kurdele
    final leftRibbon = Path()
      ..moveTo(w * 0.22, 0)
      ..lineTo(w * 0.44, h * 0.45)
      ..lineTo(w * 0.32, h * 0.45)
      ..lineTo(w * 0.12, 0)
      ..close();
    final rightRibbon = Path()
      ..moveTo(w * 0.78, 0)
      ..lineTo(w * 0.56, h * 0.45)
      ..lineTo(w * 0.68, h * 0.45)
      ..lineTo(w * 0.88, 0)
      ..close();

    canvas.drawPath(leftRibbon, Paint()..color = ribbonFill..style = PaintingStyle.fill);
    canvas.drawPath(rightRibbon, Paint()..color = ribbonFill.withValues(alpha: 0.85)..style = PaintingStyle.fill);
    canvas.drawPath(leftRibbon, stroke..strokeWidth = 1.1);
    canvas.drawPath(rightRibbon, stroke);

    // 2. Madalyon Dairesi
    final mcx = w * 0.50;
    final mcy = h * 0.62;
    final mr = w * 0.34;

    // Sert gölge
    canvas.drawCircle(Offset(mcx + 1.2, mcy + 1.2), mr, Paint()..color = pencilColor.withValues(alpha: 0.25)..style = PaintingStyle.fill);

    // Madalya Gövdesi
    canvas.drawCircle(Offset(mcx, mcy), mr, Paint()..color = medalFill..style = PaintingStyle.fill);

    // İç halka & dış kontur
    canvas.drawCircle(Offset(mcx, mcy), mr, stroke..strokeWidth = 1.5);
    canvas.drawCircle(Offset(mcx, mcy), mr * 0.72, Paint()..color = pencilColor.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // 3. İç Yazı ("2" veya "3")
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: GoogleFonts.patrickHand(
          fontSize: size.width * 0.44,
          fontWeight: FontWeight.w800,
          color: AppColors.pencilBlack,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(mcx - textPainter.width / 2, mcy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleMedalPainter oldDelegate) =>
      oldDelegate.rank != rank ||
      oldDelegate.pencilColor != pencilColor ||
      oldDelegate.medalFill != medalFill;
}

/// 4. El Çizimi Yapboz (Puzzle) Parçası Doodle (Rapor Bulmaca Simgesi)
class SketchDoodlePuzzle extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? fillColor;

  const SketchDoodlePuzzle({
    super.key,
    this.size = 20,
    this.color,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.pencilBlack);
    final effectiveFill = fillColor ?? AppColors.skyBlue;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodlePuzzlePainter(
          color: effectiveColor,
          fillColor: effectiveFill,
        ),
      ),
    );
  }
}

class _DoodlePuzzlePainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _DoodlePuzzlePainter({
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Organik yapboz parçası (üst çıkıntı, sağ çıkıntı)
    final path = Path();
    path.moveTo(w * 0.15, h * 0.25);
    // Üst kenar & çıkıntı
    path.lineTo(w * 0.38, h * 0.25);
    path.quadraticBezierTo(w * 0.32, h * 0.04, w * 0.50, h * 0.04);
    path.quadraticBezierTo(w * 0.68, h * 0.04, w * 0.62, h * 0.25);
    path.lineTo(w * 0.85, h * 0.25);

    // Sağ kenar & çıkıntı
    path.lineTo(w * 0.85, h * 0.42);
    path.quadraticBezierTo(w * 1.05, h * 0.36, w * 1.05, h * 0.52);
    path.quadraticBezierTo(w * 1.05, h * 0.68, w * 0.85, h * 0.62);
    path.lineTo(w * 0.85, h * 0.85);

    // Alt kenar & içe girinti
    path.lineTo(w * 0.62, h * 0.85);
    path.quadraticBezierTo(w * 0.66, h * 0.68, w * 0.50, h * 0.68);
    path.quadraticBezierTo(w * 0.34, h * 0.68, w * 0.38, h * 0.85);
    path.lineTo(w * 0.15, h * 0.85);

    // Sol kenar
    path.lineTo(w * 0.15, h * 0.25);
    path.close();

    // Sert gölge
    canvas.drawPath(path.shift(const Offset(1.2, 1.2)), Paint()..color = color.withValues(alpha: 0.20)..style = PaintingStyle.fill);

    // Dolgu
    canvas.drawPath(path, fill);

    // İnce tarama
    canvas.save();
    canvas.clipPath(path);
    final hatch = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 0.9;
    for (double i = -h; i < w + h; i += 4.5) {
      canvas.drawLine(Offset(i, 0), Offset(i + h, h), hatch);
    }
    canvas.restore();

    // Dış kontur
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _DoodlePuzzlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// %100 El Çizimi Küçük Şimşek Simgesi
class SketchDoodleBolt extends StatelessWidget {
  final double size;
  final Color color;
  final Color fillColor;

  const SketchDoodleBolt({
    super.key,
    this.size = 16,
    this.color = AppColors.pencilBlack,
    this.fillColor = AppColors.sunYellow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodleBoltPainter(color: color, fillColor: fillColor),
      ),
    );
  }
}

class _DoodleBoltPainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _DoodleBoltPainter({
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.56, h * 0.06)
      ..lineTo(w * 0.18, h * 0.56)
      ..lineTo(w * 0.48, h * 0.56)
      ..lineTo(w * 0.40, h * 0.94)
      ..lineTo(w * 0.82, h * 0.42)
      ..lineTo(w * 0.52, h * 0.42)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleBoltPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// %100 El Çizimi Küçük Pano / Karne Listesi Simgesi
class SketchDoodleClipboard extends StatelessWidget {
  final double size;
  final Color color;
  final Color fillColor;

  const SketchDoodleClipboard({
    super.key,
    this.size = 16,
    this.color = AppColors.pencilBlack,
    this.fillColor = const Color(0xFFFEF3C7),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoodleClipboardPainter(color: color, fillColor: fillColor),
      ),
    );
  }
}

class _DoodleClipboardPainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _DoodleClipboardPainter({
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.16, h * 0.18, w * 0.84, h * 0.92),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(
      boardRect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(boardRect, stroke);

    // Üst mandal
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.34, h * 0.08, w * 0.66, h * 0.24),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(
      clipRect,
      Paint()
        ..color = AppColors.sunYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(clipRect, stroke);

    // Mini onay satırları
    canvas.drawLine(
      Offset(w * 0.30, h * 0.44),
      Offset(w * 0.70, h * 0.44),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.66, h * 0.62),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.30, h * 0.78),
      Offset(w * 0.56, h * 0.78),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleClipboardPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}
