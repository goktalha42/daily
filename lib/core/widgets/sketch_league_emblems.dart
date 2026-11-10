import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/league_service.dart';
import '../theme/app_colors.dart';

/// 10 Lig Kademesi (Demir → Şampiyonluk) için %100 el çizimi (hand-drawn doodle)
/// arma ve sembol bileşeni.
///
/// Rozetlerde, yatay lig adımlarında, üst barlarda ve sıralama etiketlerinde
/// her boyutta (16px - 64px) keskin ve karakteristik görünür.
class SketchLeagueEmblem extends StatelessWidget {
  final LeagueLevel level;
  final double size;
  final bool isLocked;
  final Color? strokeColor;

  const SketchLeagueEmblem({
    super.key,
    required this.level,
    this.size = 24,
    this.isLocked = false,
    this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedStroke = isLocked
        ? (isDark
            ? AppColors.pencilWhite.withValues(alpha: 0.42)
            : AppColors.pencilGraphite.withValues(alpha: 0.48))
        : (strokeColor ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack));

    return CustomPaint(
      size: Size(size, size),
      painter: _SketchLeagueEmblemPainter(
        level: level,
        strokeColor: resolvedStroke,
        isLocked: isLocked,
      ),
    );
  }
}

/// Ana Lig Kartı, Profil Lig Kartı ve Terfi Kutlaması için
/// el çizimi taramalı, çift konturlu ve gölgeli Heralded Arma Madalyonu.
class SketchLeagueCrestMedallion extends StatelessWidget {
  final LeagueLevel level;
  final double size;
  final bool isLocked;

  const SketchLeagueCrestMedallion({
    super.key,
    required this.level,
    this.size = 58,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SketchLeagueCrestMedallionPainter(
          level: level,
          isDark: isDark,
          isLocked: isLocked,
        ),
        child: Center(
          child: SketchLeagueEmblem(
            level: level,
            size: size * 0.64,
            isLocked: isLocked,
            strokeColor: isLocked ? null : AppColors.inkBlack,
          ),
        ),
      ),
    );
  }
}

class _SketchLeagueCrestMedallionPainter extends CustomPainter {
  final LeagueLevel level;
  final bool isDark;
  final bool isLocked;

  _SketchLeagueCrestMedallionPainter({
    required this.level,
    required this.isDark,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = (math.min(w, h) / 56.0).clamp(0.65, 1.8);
    final seed = level.index * 17 + 11;

    final shieldPath = _buildHeraldicCrestPath(
      Rect.fromLTWH(2.0 * scale, 2.0 * scale, w - 5.0 * scale, h - 5.0 * scale),
      seed: seed,
    );

    if (!isLocked) {
      // 1. Sert kurşun kalem gölgesi
      final shadowPath = _buildHeraldicCrestPath(
        Rect.fromLTWH(4.4 * scale, 4.4 * scale, w - 5.0 * scale, h - 5.0 * scale),
        seed: seed,
      );
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = AppColors.inkBlack.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );

      // 2. Kademeye özel zengin arka plan dolgusu
      final bgFill = Color.lerp(level.primaryColor, const Color(0xFFFFFDF7), 0.58)!;
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = bgFill
          ..style = PaintingStyle.fill,
      );

      // 3. Üst sol vurgu kuşağı ve kurşun kalem çapraz tarama (Hatching)
      canvas.save();
      canvas.clipPath(shieldPath);

      final highlightPath = Path()
        ..moveTo(0, 0)
        ..lineTo(w * 0.65, 0)
        ..lineTo(0, h * 0.65)
        ..close();
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );

      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.10)
        ..strokeWidth = 0.95 * scale;
      final step = 5.5 * scale;
      for (double x = -h; x < w + h; x += step) {
        canvas.drawLine(
          Offset(x, h),
          Offset(x + h * 0.65, 0),
          hatchPaint,
        );
      }
      canvas.restore();

      // 4. Ana dış mürekkep konturu + ikinci serbest el taslak konturu
      final strokeColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 2.1 * scale
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final innerPath = _buildHeraldicCrestPath(
        Rect.fromLTWH(5.2 * scale, 5.2 * scale, w - 11.4 * scale, h - 11.4 * scale),
        seed: seed + 5,
      );
      canvas.drawPath(
        innerPath,
        Paint()
          ..color = AppColors.inkBlack.withValues(alpha: 0.28)
          ..strokeWidth = 1.0 * scale
          ..style = PaintingStyle.stroke,
      );
    } else {
      // Kilitli taslak görünümü
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF3EFE6).withValues(alpha: 0.75)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = isDark
              ? AppColors.pencilWhite.withValues(alpha: 0.32)
              : AppColors.pencilGraphite.withValues(alpha: 0.42)
          ..strokeWidth = 1.5 * scale
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _buildHeraldicCrestPath(Rect r, {required int seed}) {
    final l = r.left;
    final t = r.top;
    final right = r.right;
    final b = r.bottom;
    final cx = r.center.dx;
    final w = r.width;
    final h = r.height;
    final wob = math.sin(seed.toDouble()) * 0.8;

    // Üstü hafif kavisli, yanları dolgun, altı kalkan uçlu (heater/octagonal crest) çerçeve
    final path = Path();
    path.moveTo(l + w * 0.14, t + h * 0.06);
    path.quadraticBezierTo(cx, t - h * 0.02 + wob, right - w * 0.14, t + h * 0.06);
    path.quadraticBezierTo(right + w * 0.01, t + h * 0.10, right - w * 0.02, t + h * 0.46);
    path.cubicTo(
      right - w * 0.04,
      t + h * 0.74,
      cx + w * 0.22,
      b - h * 0.08,
      cx,
      b,
    );
    path.cubicTo(
      cx - w * 0.22,
      b - h * 0.08,
      l + w * 0.04,
      t + h * 0.74,
      l + w * 0.02,
      t + h * 0.46,
    );
    path.quadraticBezierTo(l - w * 0.01, t + h * 0.10, l + w * 0.14, t + h * 0.06);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SketchLeagueCrestMedallionPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isLocked != isLocked;
  }
}

class _SketchLeagueEmblemPainter extends CustomPainter {
  final LeagueLevel level;
  final Color strokeColor;
  final bool isLocked;

  _SketchLeagueEmblemPainter({
    required this.level,
    required this.strokeColor,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = (math.min(w, h) / 26.0).clamp(0.50, 2.5);

    final stroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.75 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thin = Paint()
      ..color = strokeColor.withValues(alpha: isLocked ? 0.55 : 0.68)
      ..strokeWidth = 1.05 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Paint fill(Color c, [double alpha = 0.88]) => Paint()
      ..color = isLocked
          ? strokeColor.withValues(alpha: 0.10)
          : c.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final dot = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    switch (level) {
      case LeagueLevel.iron:
        _paintIronAnvilShield(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.bronze:
        _paintBronzeGladiatorCrest(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.silver:
        _paintSilverWingedShield(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.gold:
        _paintGoldLaurelChalice(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.platinum:
        _paintPlatinumStarCrest(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.emerald:
        _paintEmeraldRoyalGem(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.diamond:
        _paintDiamondRadiantCrown(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.master:
        _paintMasterArcaneOrb(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.grandmaster:
        _paintGrandmasterPhoenixEagle(canvas, w, h, stroke, thin, fill, dot);
        break;
      case LeagueLevel.champion:
        _paintChampionSovereignCrown(canvas, w, h, stroke, thin, fill, dot);
        break;
    }
  }

  // 1. DEMİR LİGİ — Perçinli Ağır Demir Kalkan & Örs/Çekiç Arması
  void _paintIronAnvilShield(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final shield = Path()
      ..moveTo(w * 0.18, h * 0.14)
      ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.82, h * 0.14)
      ..lineTo(w * 0.80, h * 0.54)
      ..quadraticBezierTo(w * 0.74, h * 0.78, w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.26, h * 0.78, w * 0.20, h * 0.54)
      ..close();

    canvas.drawPath(shield, fill(const Color(0xFF64748B), 0.85));

    // Sol yarı daha açık çelik tonu
    final leftHalf = Path()
      ..moveTo(w * 0.18, h * 0.14)
      ..quadraticBezierTo(w * 0.34, h * 0.10, w * 0.50, h * 0.11)
      ..lineTo(w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.26, h * 0.78, w * 0.20, h * 0.54)
      ..close();
    canvas.drawPath(leftHalf, fill(const Color(0xFF94A3B8), 0.85));
    canvas.drawPath(shield, stroke);

    // Merkez demir şevron (V şeridi) ve örs silüeti
    final chevron = Path()
      ..moveTo(w * 0.27, h * 0.42)
      ..lineTo(w * 0.50, h * 0.62)
      ..lineTo(w * 0.73, h * 0.42)
      ..lineTo(w * 0.73, h * 0.53)
      ..lineTo(w * 0.50, h * 0.73)
      ..lineTo(w * 0.27, h * 0.53)
      ..close();
    canvas.drawPath(chevron, fill(const Color(0xFFCBD5E1), 0.92));
    canvas.drawPath(chevron, stroke);

    // Dikey kalkan omurgası
    canvas.drawLine(Offset(w * 0.50, h * 0.14), Offset(w * 0.50, h * 0.86), thin);

    // Köşe perçin çivileri
    final r = w * 0.028;
    canvas.drawCircle(Offset(w * 0.27, h * 0.22), r, dot);
    canvas.drawCircle(Offset(w * 0.73, h * 0.22), r, dot);
    canvas.drawCircle(Offset(w * 0.50, h * 0.28), r, dot);
  }

  // 2. BRONZ LİGİ — Antik Bronz Savaşçı Miğferi & Çapraz Kılıçlar
  void _paintBronzeGladiatorCrest(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Arka çapraz kılıç uçları
    canvas.drawLine(Offset(w * 0.14, h * 0.84), Offset(w * 0.86, h * 0.18), stroke);
    canvas.drawLine(Offset(w * 0.86, h * 0.84), Offset(w * 0.14, h * 0.18), stroke);

    // Miğfer üst sorgucu (Plume)
    final plume = Path()
      ..moveTo(w * 0.36, h * 0.26)
      ..quadraticBezierTo(w * 0.50, h * 0.04, w * 0.64, h * 0.26)
      ..close();
    canvas.drawPath(plume, fill(const Color(0xFFEA580C), 0.88));
    canvas.drawPath(plume, stroke);

    // Bronz miğfer kubbesi ve yanak zırhları
    final helm = Path()
      ..moveTo(w * 0.24, h * 0.44)
      ..cubicTo(w * 0.24, h * 0.18, w * 0.76, h * 0.18, w * 0.76, h * 0.44)
      ..lineTo(w * 0.74, h * 0.74)
      ..lineTo(w * 0.56, h * 0.86)
      ..lineTo(w * 0.56, h * 0.62)
      ..lineTo(w * 0.44, h * 0.62)
      ..lineTo(w * 0.44, h * 0.86)
      ..lineTo(w * 0.26, h * 0.74)
      ..close();
    canvas.drawPath(helm, fill(const Color(0xFFCD7F32), 0.90));
    canvas.drawPath(helm, stroke);

    // Miğfer alın kemeri ve T-vizör göz yarığı
    final visor = Path()
      ..moveTo(w * 0.30, h * 0.48)
      ..lineTo(w * 0.50, h * 0.53)
      ..lineTo(w * 0.70, h * 0.48);
    canvas.drawPath(visor, stroke);
    canvas.drawLine(Offset(w * 0.50, h * 0.53), Offset(w * 0.50, h * 0.78), stroke);

    // Parlak bakır-bronz tarama çizgileri
    canvas.drawLine(Offset(w * 0.34, h * 0.32), Offset(w * 0.42, h * 0.26), thin);
  }

  // 3. GÜMÜŞ LİGİ — Kanatlı Gümüş Şövalye Arması & Kutup Yıldızı
  void _paintSilverWingedShield(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Sol kanat
    final leftWing = Path()
      ..moveTo(w * 0.32, h * 0.44)
      ..quadraticBezierTo(w * 0.06, h * 0.24, w * 0.08, h * 0.16)
      ..quadraticBezierTo(w * 0.22, h * 0.20, w * 0.32, h * 0.32)
      ..moveTo(w * 0.30, h * 0.54)
      ..quadraticBezierTo(w * 0.08, h * 0.44, w * 0.10, h * 0.34)
      ..quadraticBezierTo(w * 0.22, h * 0.38, w * 0.32, h * 0.46)
      ..moveTo(w * 0.32, h * 0.64)
      ..quadraticBezierTo(w * 0.14, h * 0.62, w * 0.15, h * 0.52)
      ..quadraticBezierTo(w * 0.24, h * 0.54, w * 0.34, h * 0.58);
    canvas.drawPath(leftWing, fill(const Color(0xFFE2E8F0), 0.92));
    canvas.drawPath(leftWing, stroke);

    // Sağ kanat
    final rightWing = Path()
      ..moveTo(w * 0.68, h * 0.44)
      ..quadraticBezierTo(w * 0.94, h * 0.24, w * 0.92, h * 0.16)
      ..quadraticBezierTo(w * 0.78, h * 0.20, w * 0.68, h * 0.32)
      ..moveTo(w * 0.70, h * 0.54)
      ..quadraticBezierTo(w * 0.92, h * 0.44, w * 0.90, h * 0.34)
      ..quadraticBezierTo(w * 0.78, h * 0.38, w * 0.68, h * 0.46)
      ..moveTo(w * 0.68, h * 0.64)
      ..quadraticBezierTo(w * 0.86, h * 0.62, w * 0.85, h * 0.52)
      ..quadraticBezierTo(w * 0.76, h * 0.54, w * 0.66, h * 0.58);
    canvas.drawPath(rightWing, fill(const Color(0xFFE2E8F0), 0.92));
    canvas.drawPath(rightWing, stroke);

    // Merkez gümüş şövalye kalkanı
    final shield = Path()
      ..moveTo(w * 0.30, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.16, w * 0.70, h * 0.22)
      ..lineTo(w * 0.68, h * 0.56)
      ..quadraticBezierTo(w * 0.62, h * 0.76, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.38, h * 0.76, w * 0.32, h * 0.56)
      ..close();
    canvas.drawPath(shield, fill(const Color(0xFF94A3B8), 0.88));
    canvas.drawPath(shield, stroke);

    // Kalkan içi 4 uçlu şövalye yıldızı
    final star = _buildFourPointStar(Offset(w * 0.50, h * 0.49), w * 0.15, w * 0.05);
    canvas.drawPath(star, fill(Colors.white, 0.95));
    canvas.drawPath(star, stroke);
  }

  // 4. ALTIN LİGİ — Defne Çelenkli Altın Zafer Kupası
  void _paintGoldLaurelChalice(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Sol ve sağ altın defne dalları
    final leftBranch = Path()
      ..moveTo(w * 0.42, h * 0.86)
      ..cubicTo(w * 0.14, h * 0.78, w * 0.08, h * 0.40, w * 0.26, h * 0.18);
    final rightBranch = Path()
      ..moveTo(w * 0.58, h * 0.86)
      ..cubicTo(w * 0.86, h * 0.78, w * 0.92, h * 0.40, w * 0.74, h * 0.18);
    canvas.drawPath(leftBranch, stroke);
    canvas.drawPath(rightBranch, stroke);

    // Defne yaprakları
    for (final t in [0.28, 0.50, 0.72]) {
      final ly = h * (0.80 - t * 0.62);
      final lx = w * (0.20 - (0.5 - (t - 0.5).abs()) * 0.12);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: w * 0.09, height: h * 0.055),
        fill(const Color(0xFFFACC15), 0.90),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: w * 0.09, height: h * 0.055),
        thin,
      );
      final rx = w - lx;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ly), width: w * 0.09, height: h * 0.055),
        fill(const Color(0xFFFACC15), 0.90),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ly), width: w * 0.09, height: h * 0.055),
        thin,
      );
    }

    // Altın kupa çanağı
    final cup = Path()
      ..moveTo(w * 0.30, h * 0.24)
      ..lineTo(w * 0.70, h * 0.24)
      ..quadraticBezierTo(w * 0.68, h * 0.56, w * 0.50, h * 0.58)
      ..quadraticBezierTo(w * 0.32, h * 0.56, w * 0.30, h * 0.24)
      ..close();
    canvas.drawPath(cup, fill(const Color(0xFFF59E0B), 0.92));
    canvas.drawPath(cup, stroke);

    // Kupa ayak ve kaidesi
    canvas.drawLine(Offset(w * 0.50, h * 0.58), Offset(w * 0.50, h * 0.74), stroke);
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.74, w * 0.32, h * 0.10),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(base, fill(const Color(0xFFFACC15), 0.95));
    canvas.drawRRect(base, stroke);

    // Kupa üstü yıldız
    final star = _buildFourPointStar(Offset(w * 0.50, h * 0.38), w * 0.10, w * 0.035);
    canvas.drawPath(star, fill(Colors.white, 0.95));
    canvas.drawPath(star, thin);
  }

  // 5. PLATİN LİGİ — Sekizgen Platin Kutup Yıldızı & Kristal Kalkan
  void _paintPlatinumStarCrest(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.50, h * 0.50);

    // Dış sekizgen platin zırh çerçevesi
    final oct = Path();
    for (int i = 0; i < 8; i++) {
      final a = (i * math.pi / 4) - math.pi / 8;
      final pt = Offset(c.dx + math.cos(a) * w * 0.38, c.dy + math.sin(a) * h * 0.38);
      if (i == 0) {
        oct.moveTo(pt.dx, pt.dy);
      } else {
        oct.lineTo(pt.dx, pt.dy);
      }
    }
    oct.close();
    canvas.drawPath(oct, fill(const Color(0xFF06B6D4), 0.82));
    canvas.drawPath(oct, stroke);

    // Çapraz alt yıldız uçları
    final diagStar = _buildFourPointStar(c, w * 0.28, w * 0.09, rotation: math.pi / 4);
    canvas.drawPath(diagStar, fill(const Color(0xFF67E8F9), 0.90));
    canvas.drawPath(diagStar, thin);

    // Ana dikey/yatay Platin Kutup Yıldızı
    final mainStar = _buildFourPointStar(c, w * 0.42, w * 0.11);
    canvas.drawPath(mainStar, fill(const Color(0xFFECFEFF), 0.96));
    canvas.drawPath(mainStar, stroke);

    // Merkez kristal çekirdek
    canvas.drawCircle(c, w * 0.06, fill(const Color(0xFF06B6D4), 0.95));
    canvas.drawCircle(c, w * 0.06, stroke);
  }

  // 6. ZÜMRÜT LİGİ — Kraliyet Kesim Zümrüt Cevheri & Asil Yapraklar
  void _paintEmeraldRoyalGem(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Yanlarda kraliyet sarmaşık yaprakları
    final leftLeaf = Path()
      ..moveTo(w * 0.26, h * 0.64)
      ..quadraticBezierTo(w * 0.06, h * 0.56, w * 0.10, h * 0.36)
      ..quadraticBezierTo(w * 0.24, h * 0.42, w * 0.26, h * 0.56);
    final rightLeaf = Path()
      ..moveTo(w * 0.74, h * 0.64)
      ..quadraticBezierTo(w * 0.94, h * 0.56, w * 0.90, h * 0.36)
      ..quadraticBezierTo(w * 0.76, h * 0.42, w * 0.74, h * 0.56);
    canvas.drawPath(leftLeaf, fill(const Color(0xFF34D399), 0.85));
    canvas.drawPath(leftLeaf, stroke);
    canvas.drawPath(rightLeaf, fill(const Color(0xFF34D399), 0.85));
    canvas.drawPath(rightLeaf, stroke);

    // Sekizgen Zümrüt Kesim (Emerald Step-Cut) dış gövde
    final gem = Path()
      ..moveTo(w * 0.34, h * 0.14)
      ..lineTo(w * 0.66, h * 0.14)
      ..lineTo(w * 0.80, h * 0.30)
      ..lineTo(w * 0.80, h * 0.68)
      ..lineTo(w * 0.64, h * 0.88)
      ..lineTo(w * 0.36, h * 0.88)
      ..lineTo(w * 0.20, h * 0.68)
      ..lineTo(w * 0.20, h * 0.30)
      ..close();
    canvas.drawPath(gem, fill(const Color(0xFF10B981), 0.90));
    canvas.drawPath(gem, stroke);

    // İç faset tablası
    final table = Path()
      ..moveTo(w * 0.40, h * 0.28)
      ..lineTo(w * 0.60, h * 0.28)
      ..lineTo(w * 0.66, h * 0.38)
      ..lineTo(w * 0.66, h * 0.60)
      ..lineTo(w * 0.58, h * 0.72)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.34, h * 0.60)
      ..lineTo(w * 0.34, h * 0.38)
      ..close();
    canvas.drawPath(table, fill(const Color(0xFF6EE7B7), 0.92));
    canvas.drawPath(table, stroke);

    // Köşe faset çizgileri
    canvas.drawLine(Offset(w * 0.34, h * 0.14), Offset(w * 0.40, h * 0.28), thin);
    canvas.drawLine(Offset(w * 0.66, h * 0.14), Offset(w * 0.60, h * 0.28), thin);
    canvas.drawLine(Offset(w * 0.80, h * 0.30), Offset(w * 0.66, h * 0.38), thin);
    canvas.drawLine(Offset(w * 0.20, h * 0.30), Offset(w * 0.34, h * 0.38), thin);
    canvas.drawLine(Offset(w * 0.64, h * 0.88), Offset(w * 0.58, h * 0.72), thin);
    canvas.drawLine(Offset(w * 0.36, h * 0.88), Offset(w * 0.42, h * 0.72), thin);
  }

  // 7. ELMAS LİGİ — Işık Hüzmeli Pırlanta & Mini Taç
  void _paintDiamondRadiantCrown(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Üstte süzülen 3 uçlu mini pırlanta tacı
    final miniCrown = Path()
      ..moveTo(w * 0.34, h * 0.24)
      ..lineTo(w * 0.30, h * 0.10)
      ..lineTo(w * 0.43, h * 0.18)
      ..lineTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.57, h * 0.18)
      ..lineTo(w * 0.70, h * 0.10)
      ..lineTo(w * 0.66, h * 0.24)
      ..close();
    canvas.drawPath(miniCrown, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(miniCrown, stroke);

    // Pırlanta ana gövdesi (Brilliant-Cut)
    final diamond = Path()
      ..moveTo(w * 0.26, h * 0.32)
      ..lineTo(w * 0.74, h * 0.32)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.12, h * 0.48)
      ..close();
    canvas.drawPath(diamond, fill(const Color(0xFF38BDF8), 0.88));

    // Sol üst parlak faset yüzeyi
    final facetHighlight = Path()
      ..moveTo(w * 0.26, h * 0.32)
      ..lineTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.12, h * 0.48)
      ..close();
    canvas.drawPath(facetHighlight, fill(const Color(0xFFBAE6FD), 0.75));
    canvas.drawPath(diamond, stroke);

    // Pırlanta kuşak (girdle) ve faset kırılımları
    canvas.drawLine(Offset(w * 0.12, h * 0.48), Offset(w * 0.88, h * 0.48), stroke);
    canvas.drawLine(Offset(w * 0.26, h * 0.32), Offset(w * 0.36, h * 0.48), thin);
    canvas.drawLine(Offset(w * 0.74, h * 0.32), Offset(w * 0.64, h * 0.48), thin);
    canvas.drawLine(Offset(w * 0.50, h * 0.32), Offset(w * 0.36, h * 0.48), thin);
    canvas.drawLine(Offset(w * 0.50, h * 0.32), Offset(w * 0.64, h * 0.48), thin);
    canvas.drawLine(Offset(w * 0.36, h * 0.48), Offset(w * 0.50, h * 0.90), thin);
    canvas.drawLine(Offset(w * 0.64, h * 0.48), Offset(w * 0.50, h * 0.90), thin);
  }

  // 8. USTALIK LİGİ — Mistik Hilal Boynuzlu Asa & Parlayan Rün Küresi
  void _paintMasterArcaneOrb(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Alt mistik hilal beşiği (Arcane Crescent Cradle)
    final crescent = Path()
      ..moveTo(w * 0.12, h * 0.36)
      ..cubicTo(w * 0.08, h * 0.78, w * 0.92, h * 0.78, w * 0.88, h * 0.36)
      ..cubicTo(w * 0.80, h * 0.64, w * 0.20, h * 0.64, w * 0.12, h * 0.36)
      ..close();
    canvas.drawPath(crescent, fill(const Color(0xFF7C3AED), 0.90));
    canvas.drawPath(crescent, stroke);

    // Asa alt kaidesi
    final pedestal = Path()
      ..moveTo(w * 0.42, h * 0.66)
      ..lineTo(w * 0.58, h * 0.66)
      ..lineTo(w * 0.50, h * 0.90)
      ..close();
    canvas.drawPath(pedestal, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(pedestal, stroke);

    // Merkezde süzülen Ustalık Küresi
    final orbCenter = Offset(w * 0.50, h * 0.38);
    canvas.drawCircle(orbCenter, w * 0.23, fill(const Color(0xFFA78BFA), 0.92));
    canvas.drawCircle(orbCenter, w * 0.23, stroke);

    // Küre içi rün yıldızı
    final runeStar = _buildFourPointStar(orbCenter, w * 0.17, w * 0.05);
    canvas.drawPath(runeStar, fill(Colors.white, 0.96));
    canvas.drawPath(runeStar, thin);

    // Yanlarda süzülen mistik kristaller
    canvas.drawCircle(Offset(w * 0.18, h * 0.20), w * 0.035, dot);
    canvas.drawCircle(Offset(w * 0.82, h * 0.20), w * 0.035, dot);
  }

  // 9. ÜSTATLIK LİGİ — Kızıl İmparatorluk Anka / Çift Kanatlı Kartal Arması
  void _paintGrandmasterPhoenixEagle(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Görkemli açılmış kızıl kanatlar
    final wings = Path()
      ..moveTo(w * 0.50, h * 0.34)
      // Sol kanat üst kavisi
      ..quadraticBezierTo(w * 0.24, h * 0.14, w * 0.06, h * 0.18)
      ..lineTo(w * 0.16, h * 0.36)
      ..lineTo(w * 0.08, h * 0.44)
      ..lineTo(w * 0.22, h * 0.52)
      ..lineTo(w * 0.16, h * 0.62)
      ..quadraticBezierTo(w * 0.32, h * 0.64, w * 0.40, h * 0.60)
      // Kuyruk tüyleri
      ..lineTo(w * 0.36, h * 0.86)
      ..lineTo(w * 0.50, h * 0.78)
      ..lineTo(w * 0.64, h * 0.86)
      ..lineTo(w * 0.60, h * 0.60)
      // Sağ kanat telekleri
      ..quadraticBezierTo(w * 0.68, h * 0.64, w * 0.84, h * 0.62)
      ..lineTo(w * 0.78, h * 0.52)
      ..lineTo(w * 0.92, h * 0.44)
      ..lineTo(w * 0.84, h * 0.36)
      ..lineTo(w * 0.94, h * 0.18)
      ..quadraticBezierTo(w * 0.76, h * 0.14, w * 0.50, h * 0.34)
      ..close();

    canvas.drawPath(wings, fill(const Color(0xFFDC2626), 0.90));
    canvas.drawPath(wings, stroke);

    // Anka başı ve sorgucu
    final head = Path()
      ..moveTo(w * 0.42, h * 0.32)
      ..lineTo(w * 0.44, h * 0.14)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.56, h * 0.14)
      ..lineTo(w * 0.58, h * 0.32)
      ..close();
    canvas.drawPath(head, fill(const Color(0xFFF97316), 0.95));
    canvas.drawPath(head, stroke);

    // Göğüsteki altın Üstatlık kalkanı
    final chest = Path()
      ..moveTo(w * 0.38, h * 0.38)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w * 0.50, h * 0.68)
      ..close();
    canvas.drawPath(chest, fill(AppColors.sunYellow, 0.96));
    canvas.drawPath(chest, stroke);
  }

  // 10. ŞAMPİYONLUK LİGİ — Efsanevi Kanatlı İmparatorluk Tacı & Mücevherli Arma
  void _paintChampionSovereignCrown(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Arka zafer ışınları
    canvas.drawLine(Offset(w * 0.50, h * 0.04), Offset(w * 0.50, h * 0.13), thin);
    canvas.drawLine(Offset(w * 0.24, h * 0.08), Offset(w * 0.30, h * 0.16), thin);
    canvas.drawLine(Offset(w * 0.76, h * 0.08), Offset(w * 0.70, h * 0.16), thin);

    // Alt zafer kurdelesi (Banner Ribbon)
    final ribbon = Path()
      ..moveTo(w * 0.12, h * 0.80)
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.88, h * 0.80)
      ..lineTo(w * 0.82, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.18, h * 0.68)
      ..close();
    canvas.drawPath(ribbon, fill(const Color(0xFFDC2626), 0.90));
    canvas.drawPath(ribbon, stroke);

    // 5 Uçlu Görkemli Şampiyonluk Tacı
    final crown = Path()
      ..moveTo(w * 0.18, h * 0.68)
      ..lineTo(w * 0.82, h * 0.68)
      ..lineTo(w * 0.90, h * 0.30)
      ..lineTo(w * 0.72, h * 0.46)
      ..lineTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.50, h * 0.42)
      ..lineTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.28, h * 0.46)
      ..lineTo(w * 0.10, h * 0.30)
      ..close();
    canvas.drawPath(crown, fill(AppColors.sunYellow, 0.96));
    canvas.drawPath(crown, stroke);

    // Taç alt altın bandı
    canvas.drawLine(Offset(w * 0.19, h * 0.58), Offset(w * 0.81, h * 0.58), stroke);

    // Taç uçlarındaki altın küreler
    final tipRadius = w * 0.032;
    for (final pt in [
      Offset(w * 0.10, h * 0.28),
      Offset(w * 0.38, h * 0.20),
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.62, h * 0.20),
      Offset(w * 0.90, h * 0.28),
    ]) {
      canvas.drawCircle(pt, tipRadius, fill(AppColors.sunYellow, 1.0));
      canvas.drawCircle(pt, tipRadius, stroke);
    }

    // Merkez yakut ve yan pırlanta mücevherler
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.49),
      w * 0.055,
      fill(const Color(0xFFEF4444), 0.98),
    );
    canvas.drawCircle(Offset(w * 0.50, h * 0.49), w * 0.055, stroke);
    canvas.drawCircle(Offset(w * 0.33, h * 0.51), w * 0.035, dot);
    canvas.drawCircle(Offset(w * 0.67, h * 0.51), w * 0.035, dot);
  }

  Path _buildFourPointStar(
    Offset center,
    double outerR,
    double innerR, {
    double rotation = 0.0,
  }) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = rotation + (i * math.pi / 4) - math.pi / 2;
      final pt = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SketchLeagueEmblemPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.isLocked != isLocked;
  }
}

