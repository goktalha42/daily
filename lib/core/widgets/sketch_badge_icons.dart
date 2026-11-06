import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Uygulama genelindeki tüm Rozetler, Başarılar ve IQ Mertebeleri için
/// tek merkezli, çakışmasız el çizimi (hand-drawn doodle) sanat tipleri.
enum BadgeArtType {
  // 1. Kişisel Başarılar & Oyun Ustalıkları (15)
  sprout,          // İlk Zafer
  bullseye,        // Mükemmel Gün (6/6)
  rocket,          // Işık Hızı Efendisi (<20sn)
  lightning,       // Şimşek Zihin (<35sn)
  doubleCrown,     // Vezir Hükümdarı (Master Çift Vezir)
  queenPiece,      // Vezir Ustası (3 Galibiyet)
  magnifier,       // Kelime Dedektifi (Pinpoint)
  mountainFlag,    // Tırmanış Kralı (Crossclimb)
  sunMoon,         // Güneş & Ay Dengesi (Tango)
  compass,         // Labirent Gezgini (Zip Path)
  puzzlePatch,     // Bölge Mimarı (Patches)
  hexagramStar,    // Çok Yönlü Deha (6/6 Oyun)
  centuryLaurel,   // 100 Oyun Kulübü
  nightOwl,        // Gece Baykuşu
  sunrise,         // Erken Kalkan Deha

  // 2. İstikrar Serileri (7)
  sparkFlame,      // 3 Günlük Kıvılcım
  torch,           // Haftalık Meşale (7 Gün)
  campfire,        // 2 Haftalık Alışkanlık (14 Gün)
  steelShield,     // Aylık Çelik İrade (30 Gün)
  diamondGem,      // 60 Günlük Bilge
  honorMedal,      // Yüzyıl Efsanesi (100 Gün)
  eternalHourglass,// 1 Yıllık Ölümsüz Zihin (365 Gün)

  // 3. Arena, Şampiyonluk & Ortak IQ Mertebeleri (9)
  royalCrown,      // Günün Zirve Şampiyonu (#1)
  podiumTrophy,    // Podyum Yıldızı (İlk 3)
  einsteinBrain,   // Einstein Zekâ Endeksi / Mertebesi (148+ IQ)
  lightbulb,       // Büyük Usta Endeksi / Mertebesi (120+ IQ)
  mortarboard,     // Dahi Kulübü (Kalıcı 120+ IQ Diploması)
  balanceScale,    // Dengeli Zihin (100 IQ Mertebesi)
  sharpStar,       // Keskin Zihin (110 IQ Mertebesi)
  mensaCrest,      // Üstün Mantık - Mensa (130 IQ Mertebesi)
  zuhtuGenius,     // Zühtü Dahisi (140 IQ Mertebesi)
}

/// Her bir [BadgeArtType] için varsayılan vurgu rengi.
extension BadgeArtTypeExt on BadgeArtType {
  Color get defaultAccentColor {
    switch (this) {
      case BadgeArtType.sprout:
        return AppColors.success;
      case BadgeArtType.bullseye:
        return AppColors.sunYellow;
      case BadgeArtType.rocket:
        return AppColors.skyBlue;
      case BadgeArtType.lightning:
        return AppColors.highlighterOrange;
      case BadgeArtType.doubleCrown:
        return AppColors.highlighterPurple;
      case BadgeArtType.queenPiece:
        return AppColors.highlighterPink;
      case BadgeArtType.magnifier:
        return AppColors.highlighterCyan;
      case BadgeArtType.mountainFlag:
        return AppColors.highlighterPurple;
      case BadgeArtType.sunMoon:
        return AppColors.highlighterOrange;
      case BadgeArtType.compass:
        return AppColors.skyBlue;
      case BadgeArtType.puzzlePatch:
        return AppColors.patchesGame;
      case BadgeArtType.hexagramStar:
        return AppColors.sunYellow;
      case BadgeArtType.centuryLaurel:
        return AppColors.sunYellow;
      case BadgeArtType.nightOwl:
        return AppColors.highlighterPurple;
      case BadgeArtType.sunrise:
        return AppColors.highlighterOrange;
      case BadgeArtType.sparkFlame:
        return AppColors.highlighterOrange;
      case BadgeArtType.torch:
        return AppColors.sunYellow;
      case BadgeArtType.campfire:
        return AppColors.highlighterCyan;
      case BadgeArtType.steelShield:
        return AppColors.highlighterPurple;
      case BadgeArtType.diamondGem:
        return AppColors.skyBlue;
      case BadgeArtType.honorMedal:
        return AppColors.success;
      case BadgeArtType.eternalHourglass:
        return AppColors.sunYellow;
      case BadgeArtType.royalCrown:
        return AppColors.sunYellow;
      case BadgeArtType.podiumTrophy:
        return AppColors.highlighterOrange;
      case BadgeArtType.einsteinBrain:
        return AppColors.highlighterPurple;
      case BadgeArtType.lightbulb:
        return AppColors.sunYellow;
      case BadgeArtType.mortarboard:
        return AppColors.success;
      case BadgeArtType.balanceScale:
        return AppColors.highlighterCyan;
      case BadgeArtType.sharpStar:
        return AppColors.highlighterOrange;
      case BadgeArtType.mensaCrest:
        return AppColors.skyBlue;
      case BadgeArtType.zuhtuGenius:
        return AppColors.sunYellow;
    }
  }
}

/// Yalın el çizimi başarı/rozet sembolü.
/// Etiketlerde (14-18px), kartlarda (26-32px) ve diyaloglarda (48-56px) keskin ölçeklenir.
class SketchBadgeIcon extends StatelessWidget {
  final BadgeArtType type;
  final double size;
  final Color? strokeColor;
  final Color? accentColor;
  final bool isLocked;

  const SketchBadgeIcon({
    super.key,
    required this.type,
    this.size = 26,
    this.strokeColor,
    this.accentColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStroke = isLocked
        ? (isDark
            ? AppColors.pencilWhite.withValues(alpha: 0.42)
            : AppColors.pencilGraphite.withValues(alpha: 0.50))
        : (strokeColor ?? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack));

    return CustomPaint(
      size: Size(size, size),
      painter: _SketchBadgeArtPainter(
        type: type,
        strokeColor: defaultStroke,
        accentColor: accentColor ?? type.defaultAccentColor,
        isLocked: isLocked,
      ),
    );
  }
}

/// Rozet listeleri, vitrin ve detay penceresi için el çizimi dalgalı madalyon / mühür çerçevesi.
/// Açıkken: Renkli dolgu, kurşun kalem çapraz tarama, çift mürekkep kontur ve sert gölge.
/// Kilitliyken: Eskiz defteri kurşun kalem taslağı + sağ altta el çizimi mini kilit mührü.
class SketchBadgeMedallion extends StatelessWidget {
  final BadgeArtType type;
  final Color accentColor;
  final bool isUnlocked;
  final double size;
  final int seed;

  const SketchBadgeMedallion({
    super.key,
    required this.type,
    required this.accentColor,
    required this.isUnlocked,
    this.size = 50,
    int? seed,
  }) : seed = seed ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedSeed = seed != 0 ? seed : (type.index * 13 + 7);
    final borderStroke = isUnlocked
        ? AppColors.inkBlack
        : (isDark
            ? AppColors.pencilWhite.withValues(alpha: 0.35)
            : AppColors.pencilGraphite.withValues(alpha: 0.45));

    final iconSize = size * 0.56;
    final lockBadgeSize = (size * 0.34).clamp(15.0, 26.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WobblyBadgeMedallionPainter(
                accentColor: accentColor,
                strokeColor: isUnlocked
                    ? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack)
                    : borderStroke,
                isUnlocked: isUnlocked,
                isDark: isDark,
                seed: resolvedSeed,
              ),
              child: Center(
                child: SketchBadgeIcon(
                  type: type,
                  size: iconSize,
                  strokeColor: isUnlocked ? AppColors.inkBlack : null,
                  accentColor: accentColor,
                  isLocked: !isUnlocked,
                ),
              ),
            ),
          ),
          if (!isUnlocked)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: lockBadgeSize,
                height: lockBadgeSize,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.pencilWhite.withValues(alpha: 0.65) : AppColors.pencilBlack,
                    width: 1.3,
                  ),
                ),
                child: Center(
                  child: SketchDoodleLock(
                    size: lockBadgeSize * 0.62,
                    color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGraphite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kilitli rozet etiketleri için el çizimi asma kilit sembolü.
class SketchDoodleLock extends StatelessWidget {
  final double size;
  final Color? color;

  const SketchDoodleLock({
    super.key,
    this.size = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.pencil(context);
    return CustomPaint(
      size: Size(size, size),
      painter: _DoodleLockPainter(color: resolved),
    );
  }
}

class _DoodleLockPainter extends CustomPainter {
  final Color color;
  _DoodleLockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = (w / 14.0).clamp(0.85, 2.0) * 1.45;
    final p = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Kilit kemeri
    final shackle = Path()
      ..moveTo(w * 0.30, h * 0.46)
      ..lineTo(w * 0.30, h * 0.30)
      ..arcToPoint(
        Offset(w * 0.70, h * 0.30),
        radius: Radius.circular(w * 0.20),
        clockwise: true,
      )
      ..lineTo(w * 0.70, h * 0.46);
    canvas.drawPath(shackle, p);

    // Kilit gövdesi
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.46, w * 0.64, h * 0.44),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(body, p);

    // Anahtar deliği
    canvas.drawCircle(Offset(w * 0.50, h * 0.64), sw * 0.65, Paint()..color = color);
    canvas.drawLine(Offset(w * 0.50, h * 0.66), Offset(w * 0.50, h * 0.78), p);
  }

  @override
  bool shouldRepaint(covariant _DoodleLockPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WobblyBadgeMedallionPainter extends CustomPainter {
  final Color accentColor;
  final Color strokeColor;
  final bool isUnlocked;
  final bool isDark;
  final int seed;

  _WobblyBadgeMedallionPainter({
    required this.accentColor,
    required this.strokeColor,
    required this.isUnlocked,
    required this.isDark,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 2.6;
    final scale = (size.width / 50.0).clamp(0.7, 1.9);

    final mainPath = _buildWobblySeal(center, radius, seed);

    if (isUnlocked) {
      // 1. Sert kurşun kalem gölgesi
      final shadowOffset = Offset(2.0 * scale, 2.0 * scale);
      canvas.drawPath(
        _buildWobblySeal(center + shadowOffset, radius, seed),
        Paint()
          ..color = AppColors.inkBlack.withValues(alpha: 0.82)
          ..style = PaintingStyle.fill,
      );

      // 2. Zengin pastel rozet zemini (açık fildişi ile harmanlanmış vurgu rengi)
      final bgFill = Color.lerp(accentColor, const Color(0xFFFFFDF7), 0.30)!;
      canvas.drawPath(
        mainPath,
        Paint()
          ..color = bgFill
          ..style = PaintingStyle.fill,
      );

      // 3. Diyagonal kurşun kalem tarama dokusu
      canvas.save();
      canvas.clipPath(mainPath);
      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.11)
        ..strokeWidth = 0.9 * scale;
      final step = 5.8 * scale;
      for (double x = -size.height; x < size.width + size.height; x += step) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.68, 0),
          hatchPaint,
        );
      }
      canvas.restore();

      // 4. Çift vuruşlu el çizimi dış ve iç çember
      canvas.drawPath(
        mainPath,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 1.9 * scale
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        _buildWobblySeal(center, radius * 0.87, seed + 19),
        Paint()
          ..color = AppColors.inkBlack.withValues(alpha: 0.32)
          ..strokeWidth = 0.9 * scale
          ..style = PaintingStyle.stroke,
      );
    } else {
      // Kilitli: Eskiz kağıdı üzerinde hafif taslak çemberi
      final draftFill = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF3EFE6).withValues(alpha: 0.75);
      canvas.drawPath(
        mainPath,
        Paint()
          ..color = draftFill
          ..style = PaintingStyle.fill,
      );

      // Kesikli el çizimi taslak konturu
      _drawDashedPath(
        canvas,
        mainPath,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 1.35 * scale
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dashWidth: 4.2 * scale,
        gapWidth: 2.8 * scale,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double gapWidth,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + gapWidth;
      }
    }
  }

  Path _buildWobblySeal(Offset center, double radius, int s) {
    final rnd = math.Random(s);
    const steps = 16;
    final pts = List.generate(steps, (i) {
      final angle = (i / steps) * math.pi * 2;
      final wobble = (rnd.nextDouble() - 0.5) * (radius * 0.09);
      return Offset(
        center.dx + math.cos(angle) * (radius + wobble),
        center.dy + math.sin(angle) * (radius + wobble),
      );
    });

    final path = Path();
    final firstMid = Offset(
      (pts.last.dx + pts.first.dx) / 2,
      (pts.last.dy + pts.first.dy) / 2,
    );
    path.moveTo(firstMid.dx, firstMid.dy);
    for (int i = 0; i < steps; i++) {
      final next = pts[(i + 1) % steps];
      final mid = Offset((pts[i].dx + next.dx) / 2, (pts[i].dy + next.dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _WobblyBadgeMedallionPainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.isDark != isDark;
  }
}

/// 31 benzersiz rozet & mertebe sembolünü kara kalem eskiz defteri estetiğiyle çizen ana ressam.
class _SketchBadgeArtPainter extends CustomPainter {
  final BadgeArtType type;
  final Color strokeColor;
  final Color accentColor;
  final bool isLocked;

  _SketchBadgeArtPainter({
    required this.type,
    required this.strokeColor,
    required this.accentColor,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = (math.min(w, h) / 28.0).clamp(0.50, 2.2);

    final stroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.85 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinStroke = Paint()
      ..color = strokeColor.withValues(alpha: isLocked ? 0.75 : 0.65)
      ..strokeWidth = 1.15 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Paint fill(Color c, [double unlockedAlpha = 0.85]) => Paint()
      ..color = isLocked
          ? strokeColor.withValues(alpha: 0.10)
          : c.withValues(alpha: unlockedAlpha)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    switch (type) {
      case BadgeArtType.sprout:
        _paintSprout(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.bullseye:
        _paintBullseye(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.rocket:
        _paintRocket(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.lightning:
        _paintLightning(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.doubleCrown:
        _paintDoubleCrown(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.queenPiece:
        _paintQueenPiece(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.magnifier:
        _paintMagnifier(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.mountainFlag:
        _paintMountainFlag(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.sunMoon:
        _paintSunMoon(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.compass:
        _paintCompass(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.puzzlePatch:
        _paintPuzzlePatch(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.hexagramStar:
        _paintHexagramStar(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.centuryLaurel:
        _paintCenturyLaurel(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.nightOwl:
        _paintNightOwl(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.sunrise:
        _paintSunrise(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.sparkFlame:
        _paintSparkFlame(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.torch:
        _paintTorch(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.campfire:
        _paintCampfire(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.steelShield:
        _paintSteelShield(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.diamondGem:
        _paintDiamondGem(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.honorMedal:
        _paintHonorMedal(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.eternalHourglass:
        _paintEternalHourglass(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.royalCrown:
        _paintRoyalCrown(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.podiumTrophy:
        _paintPodiumTrophy(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.einsteinBrain:
        _paintEinsteinBrain(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.lightbulb:
        _paintLightbulb(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.mortarboard:
        _paintMortarboard(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.balanceScale:
        _paintBalanceScale(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.sharpStar:
        _paintSharpStar(canvas, w, h, stroke, thinStroke, fill);
        break;
      case BadgeArtType.mensaCrest:
        _paintMensaCrest(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
      case BadgeArtType.zuhtuGenius:
        _paintZuhtuGenius(canvas, w, h, stroke, thinStroke, fill, dotPaint);
        break;
    }
  }

  // 1. İLK ZAFER — Topraktan Filizlenen İki Yapraklı Fidan
  void _paintSprout(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Toprak tümseği
    final soil = Path()
      ..moveTo(w * 0.22, h * 0.84)
      ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.78, h * 0.84);
    canvas.drawPath(soil, stroke);

    // Gövde sapı
    final stem = Path()
      ..moveTo(w * 0.50, h * 0.80)
      ..quadraticBezierTo(w * 0.48, h * 0.56, w * 0.52, h * 0.34);
    canvas.drawPath(stem, stroke);

    // Sol yaprak
    final leftLeaf = Path()
      ..moveTo(w * 0.50, h * 0.56)
      ..cubicTo(w * 0.20, h * 0.54, w * 0.14, h * 0.28, w * 0.34, h * 0.26)
      ..cubicTo(w * 0.46, h * 0.28, w * 0.50, h * 0.44, w * 0.50, h * 0.56);
    canvas.drawPath(leftLeaf, fill(AppColors.success, 0.80));
    canvas.drawPath(leftLeaf, stroke);
    canvas.drawLine(Offset(w * 0.47, h * 0.51), Offset(w * 0.33, h * 0.35), thin);

    // Sağ yaprak
    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.45)
      ..cubicTo(w * 0.55, h * 0.22, w * 0.84, h * 0.18, w * 0.82, h * 0.38)
      ..cubicTo(w * 0.78, h * 0.52, w * 0.60, h * 0.50, w * 0.51, h * 0.45);
    canvas.drawPath(rightLeaf, fill(AppColors.accentGreen, 0.85));
    canvas.drawPath(rightLeaf, stroke);
    canvas.drawLine(Offset(w * 0.55, h * 0.43), Offset(w * 0.72, h * 0.32), thin);

    // Üst parıltı
    _drawMiniSpark(canvas, Offset(w * 0.50, h * 0.15), w * 0.06, thin);
  }

  // 2. MÜKEMMEL GÜN (6/6) — Hedef Tahtası ve Tam On İkiden Vuran Ok
  void _paintBullseye(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.46, h * 0.54);
    final rOuter = w * 0.33;
    final rMid = w * 0.20;
    final rInner = w * 0.08;

    canvas.drawCircle(c, rOuter, fill(AppColors.highlighterPink, 0.75));
    canvas.drawCircle(c, rOuter, stroke);

    canvas.drawCircle(c, rMid, fill(Colors.white, 0.92));
    canvas.drawCircle(c, rMid, thin);

    canvas.drawCircle(c, rInner, fill(AppColors.sunYellow, 0.95));
    canvas.drawCircle(c, rInner, stroke);

    // Merkeze saplanan ok
    final tip = c;
    final tail = Offset(w * 0.88, h * 0.14);
    canvas.drawLine(tip, tail, stroke);

    // Ok ucu
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + w * 0.11, tip.dy - h * 0.02)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + w * 0.02, tip.dy - h * 0.11);
    canvas.drawPath(head, stroke);

    // Ok tüyleri
    canvas.drawLine(Offset(w * 0.80, h * 0.22), Offset(w * 0.80, h * 0.11), thin);
    canvas.drawLine(Offset(w * 0.80, h * 0.22), Offset(w * 0.91, h * 0.22), thin);
  }

  // 3. IŞIK HIZI EFENDİSİ (<20sn) — Alev Püskürten Hız Roketi
  void _paintRocket(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // İtki alevi
    final flame = Path()
      ..moveTo(w * 0.26, h * 0.64)
      ..quadraticBezierTo(w * 0.10, h * 0.72, w * 0.12, h * 0.88)
      ..quadraticBezierTo(w * 0.28, h * 0.88, w * 0.36, h * 0.74)
      ..close();
    canvas.drawPath(flame, fill(AppColors.highlighterOrange, 0.90));
    canvas.drawPath(flame, stroke);

    // Kanatçıklar
    final leftFin = Path()
      ..moveTo(w * 0.34, h * 0.50)
      ..lineTo(w * 0.18, h * 0.54)
      ..lineTo(w * 0.26, h * 0.65);
    final rightFin = Path()
      ..moveTo(w * 0.50, h * 0.66)
      ..lineTo(w * 0.46, h * 0.82)
      ..lineTo(w * 0.35, h * 0.74);
    canvas.drawPath(leftFin, fill(AppColors.highlighterPink, 0.85));
    canvas.drawPath(leftFin, stroke);
    canvas.drawPath(rightFin, fill(AppColors.highlighterPink, 0.85));
    canvas.drawPath(rightFin, stroke);

    // Roket gövdesi
    final body = Path()
      ..moveTo(w * 0.86, h * 0.14)
      ..cubicTo(w * 0.62, h * 0.16, w * 0.38, h * 0.38, w * 0.26, h * 0.64)
      ..lineTo(w * 0.36, h * 0.74)
      ..cubicTo(w * 0.62, h * 0.62, w * 0.84, h * 0.38, w * 0.86, h * 0.14)
      ..close();
    canvas.drawPath(body, fill(AppColors.skyBlue, 0.85));
    canvas.drawPath(body, stroke);

    // Gözlem penceresi
    final winCenter = Offset(w * 0.58, h * 0.42);
    canvas.drawCircle(winCenter, w * 0.08, fill(AppColors.sunYellow, 0.95));
    canvas.drawCircle(winCenter, w * 0.08, stroke);

    // Hız çizgileri
    canvas.drawLine(Offset(w * 0.16, h * 0.34), Offset(w * 0.28, h * 0.22), thin);
    canvas.drawLine(Offset(w * 0.66, h * 0.84), Offset(w * 0.78, h * 0.72), thin);
  }

  // 4. ŞİMŞEK ZİHİN (<35sn) — Keskin Yıldırım Çakması
  void _paintLightning(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final bolt = Path()
      ..moveTo(w * 0.58, h * 0.10)
      ..lineTo(w * 0.24, h * 0.53)
      ..lineTo(w * 0.48, h * 0.53)
      ..lineTo(w * 0.38, h * 0.90)
      ..lineTo(w * 0.76, h * 0.44)
      ..lineTo(w * 0.52, h * 0.44)
      ..close();

    canvas.drawPath(bolt, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(bolt, stroke);

    // Elektrik kıvılcım çizgileri
    canvas.drawLine(Offset(w * 0.18, h * 0.28), Offset(w * 0.27, h * 0.33), thin);
    canvas.drawLine(Offset(w * 0.82, h * 0.68), Offset(w * 0.72, h * 0.63), thin);
  }

  // 5. VEZİR HÜKÜMDARI (Master) — Çift Vezir Kuralını Temsil Eden İkiz Kraliyet Tacı
  void _paintDoubleCrown(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Arka sol taç (Master moru)
    final backCrown = Path()
      ..moveTo(w * 0.10, h * 0.62)
      ..lineTo(w * 0.58, h * 0.62)
      ..lineTo(w * 0.62, h * 0.28)
      ..lineTo(w * 0.45, h * 0.42)
      ..lineTo(w * 0.34, h * 0.18)
      ..lineTo(w * 0.23, h * 0.42)
      ..lineTo(w * 0.08, h * 0.28)
      ..close();
    canvas.drawPath(backCrown, fill(AppColors.highlighterPurple, 0.85));
    canvas.drawPath(backCrown, stroke);

    // Ön sağ taç (Altın sarısı)
    final frontCrown = Path()
      ..moveTo(w * 0.34, h * 0.82)
      ..lineTo(w * 0.88, h * 0.82)
      ..lineTo(w * 0.92, h * 0.44)
      ..lineTo(w * 0.74, h * 0.58)
      ..lineTo(w * 0.61, h * 0.30)
      ..lineTo(w * 0.48, h * 0.58)
      ..lineTo(w * 0.30, h * 0.44)
      ..close();
    canvas.drawPath(frontCrown, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(frontCrown, stroke);

    final r = (w * 0.032).clamp(1.1, 2.8);
    canvas.drawCircle(Offset(w * 0.34, h * 0.18), r, dot);
    canvas.drawCircle(Offset(w * 0.61, h * 0.30), r * 1.1, dot);
    canvas.drawCircle(Offset(w * 0.92, h * 0.44), r, dot);
  }

  // 6. VEZİR USTASI (3 Galibiyet) — Zarif Satranç Vezir Taşı
  void _paintQueenPiece(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final piece = Path()
      ..moveTo(w * 0.26, h * 0.86)
      ..lineTo(w * 0.74, h * 0.86)
      ..quadraticBezierTo(w * 0.74, h * 0.76, w * 0.64, h * 0.74)
      ..cubicTo(w * 0.58, h * 0.60, w * 0.58, h * 0.48, w * 0.66, h * 0.38)
      ..lineTo(w * 0.74, h * 0.26)
      ..lineTo(w * 0.58, h * 0.34)
      ..lineTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.42, h * 0.34)
      ..lineTo(w * 0.26, h * 0.26)
      ..lineTo(w * 0.34, h * 0.38)
      ..cubicTo(w * 0.42, h * 0.48, w * 0.42, h * 0.60, w * 0.36, h * 0.74)
      ..quadraticBezierTo(w * 0.26, h * 0.76, w * 0.26, h * 0.86)
      ..close();

    canvas.drawPath(piece, fill(AppColors.highlighterPink, 0.85));
    canvas.drawPath(piece, stroke);

    // Tepe küresi ve yaka çizgisi
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.055, fill(AppColors.sunYellow, 0.95));
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.055, stroke);
    canvas.drawLine(Offset(w * 0.36, h * 0.42), Offset(w * 0.64, h * 0.42), thin);
    canvas.drawLine(Offset(w * 0.34, h * 0.76), Offset(w * 0.66, h * 0.76), thin);
  }

  // 7. KELİME DEDEKTİFİ — Büyüteç ve İpucu İzi
  void _paintMagnifier(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final c = Offset(w * 0.42, h * 0.42);
    final r = w * 0.26;

    // Sap
    final handle = Path()
      ..moveTo(w * 0.58, h * 0.62)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.90, h * 0.82)
      ..lineTo(w * 0.64, h * 0.56)
      ..close();
    canvas.drawPath(handle, fill(AppColors.sunYellow, 0.88));
    canvas.drawPath(handle, stroke);

    // Mercek
    canvas.drawCircle(c, r, fill(AppColors.highlighterCyan, 0.78));
    canvas.drawCircle(c, r, stroke);

    // Mercek içi ipucu kıvrımları
    final clue = Path()
      ..moveTo(c.dx - r * 0.45, c.dy + r * 0.20)
      ..cubicTo(c.dx - r * 0.35, c.dy - r * 0.45, c.dx + r * 0.35, c.dy - r * 0.45, c.dx + r * 0.42, c.dy + r * 0.18)
      ..moveTo(c.dx - r * 0.20, c.dy + r * 0.32)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.18, c.dx + r * 0.20, c.dy + r * 0.26);
    canvas.drawPath(clue, thin);
  }

  // 8. TIRMANIŞ KRALI — Zirve, Merdiven ve Zafer Bayrağı
  void _paintMountainFlag(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Dağ gövdesi
    final mtn = Path()
      ..moveTo(w * 0.10, h * 0.86)
      ..lineTo(w * 0.48, h * 0.28)
      ..lineTo(w * 0.66, h * 0.54)
      ..lineTo(w * 0.76, h * 0.42)
      ..lineTo(w * 0.92, h * 0.86)
      ..close();
    canvas.drawPath(mtn, fill(AppColors.highlighterPurple, 0.82));
    canvas.drawPath(mtn, stroke);

    // Tırmanış merdiveni
    canvas.drawLine(Offset(w * 0.26, h * 0.84), Offset(w * 0.43, h * 0.44), thin);
    canvas.drawLine(Offset(w * 0.36, h * 0.85), Offset(w * 0.51, h * 0.46), thin);
    canvas.drawLine(Offset(w * 0.30, h * 0.72), Offset(w * 0.40, h * 0.73), thin);
    canvas.drawLine(Offset(w * 0.35, h * 0.59), Offset(w * 0.45, h * 0.60), thin);

    // Zirve bayrağı
    canvas.drawLine(Offset(w * 0.48, h * 0.28), Offset(w * 0.48, h * 0.10), stroke);
    final flag = Path()
      ..moveTo(w * 0.48, h * 0.10)
      ..lineTo(w * 0.72, h * 0.16)
      ..lineTo(w * 0.48, h * 0.23)
      ..close();
    canvas.drawPath(flag, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(flag, stroke);
  }

  // 9. GÜNEŞ & AY DENGESİ — Işınlı Güneş ve Sarılan Hilal
  void _paintSunMoon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final sunC = Offset(w * 0.42, h * 0.48);
    final sunR = w * 0.22;

    // Güneş ışınları
    for (int i = 0; i < 8; i++) {
      final a = (i * math.pi / 4);
      canvas.drawLine(
        Offset(sunC.dx + math.cos(a) * (sunR + w * 0.04), sunC.dy + math.sin(a) * (sunR + w * 0.04)),
        Offset(sunC.dx + math.cos(a) * (sunR + w * 0.11), sunC.dy + math.sin(a) * (sunR + w * 0.11)),
        thin,
      );
    }

    canvas.drawCircle(sunC, sunR, fill(AppColors.sunYellow, 0.90));
    canvas.drawCircle(sunC, sunR, stroke);

    // Hilal
    final moon = Path()
      ..moveTo(w * 0.54, h * 0.20)
      ..cubicTo(w * 0.88, h * 0.26, w * 0.88, h * 0.74, w * 0.52, h * 0.80)
      ..cubicTo(w * 0.72, h * 0.66, w * 0.72, h * 0.34, w * 0.54, h * 0.20)
      ..close();
    canvas.drawPath(moon, fill(AppColors.skyBlue, 0.90));
    canvas.drawPath(moon, stroke);
  }

  // 10. LABİRENT GEZGİNİ — Pusula ve Kuzey İbresi
  void _paintCompass(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.50, h * 0.52);
    final r = w * 0.35;

    // Üst halka kulpu
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.50, h * 0.14), radius: w * 0.06),
      math.pi,
      math.pi,
      false,
      stroke,
    );

    canvas.drawCircle(c, r, fill(AppColors.skyBlue, 0.35));
    canvas.drawCircle(c, r, stroke);

    // Yön çentikleri
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy - r * 0.78), thin);
    canvas.drawLine(Offset(c.dx, c.dy + r), Offset(c.dx, c.dy + r * 0.78), thin);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx - r * 0.78, c.dy), thin);
    canvas.drawLine(Offset(c.dx + r, c.dy), Offset(c.dx + r * 0.78, c.dy), thin);

    // Kuzey-Doğu / Güney-Batı ibresi
    final northHalf = Path()
      ..moveTo(w * 0.67, h * 0.35)
      ..lineTo(w * 0.55, h * 0.57)
      ..lineTo(w * 0.45, h * 0.47)
      ..close();
    final southHalf = Path()
      ..moveTo(w * 0.33, h * 0.69)
      ..lineTo(w * 0.55, h * 0.57)
      ..lineTo(w * 0.45, h * 0.47)
      ..close();

    canvas.drawPath(northHalf, fill(AppColors.highlighterOrange, 0.95));
    canvas.drawPath(northHalf, stroke);
    canvas.drawPath(southHalf, fill(Colors.white, 0.90));
    canvas.drawPath(southHalf, stroke);
    canvas.drawCircle(c, (w * 0.035).clamp(1.0, 2.5), dot);
  }

  // 11. BÖLGE MİMARI — Geometrik Parsel / Yapboz Bölmeleri
  void _paintPuzzlePatch(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final rect = Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.12));

    // Sol üst bölge
    final p1 = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.38, h * 0.34),
        topLeft: Radius.circular(w * 0.12),
      ));
    // Sağ üst bölge
    final p2 = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.54, h * 0.16, w * 0.30, h * 0.42),
        topRight: Radius.circular(w * 0.12),
      ));
    // Sol alt bölge
    final p3 = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.16, h * 0.50, w * 0.38, h * 0.34),
        bottomLeft: Radius.circular(w * 0.12),
      ));
    // Sağ alt bölge
    final p4 = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.54, h * 0.58, w * 0.30, h * 0.26),
        bottomRight: Radius.circular(w * 0.12),
      ));

    canvas.drawPath(p1, fill(AppColors.patchesGame, 0.85));
    canvas.drawPath(p2, fill(AppColors.sunYellow, 0.85));
    canvas.drawPath(p3, fill(AppColors.highlighterCyan, 0.85));
    canvas.drawPath(p4, fill(AppColors.highlighterPink, 0.85));

    canvas.drawRRect(rrect, stroke);

    // Yapboz girintili bölme çizgileri
    final vDiv = Path()
      ..moveTo(w * 0.54, h * 0.16)
      ..lineTo(w * 0.54, h * 0.30)
      ..arcToPoint(Offset(w * 0.54, h * 0.42), radius: Radius.circular(w * 0.06), clockwise: true)
      ..lineTo(w * 0.54, h * 0.84);
    canvas.drawPath(vDiv, stroke);

    canvas.drawLine(Offset(w * 0.16, h * 0.50), Offset(w * 0.54, h * 0.50), stroke);
    canvas.drawLine(Offset(w * 0.54, h * 0.58), Offset(w * 0.84, h * 0.58), stroke);
  }

  // 12. ÇOK YÖNLÜ DEHA — 6 Bilişsel Alanı Simgeleyen 6 Köşeli Prizma Yıldız
  void _paintHexagramStar(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.50, h * 0.50);
    final outerR = w * 0.38;
    final innerR = w * 0.19;

    final star = Path();
    for (int i = 0; i < 12; i++) {
      final a = (i * math.pi / 6) - (math.pi / 2);
      final r = i.isEven ? outerR : innerR;
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();

    canvas.drawPath(star, fill(AppColors.sunYellow, 0.90));
    canvas.drawPath(star, stroke);

    // Merkez altıgen çekirdek
    canvas.drawCircle(c, w * 0.11, fill(AppColors.highlighterCyan, 0.92));
    canvas.drawCircle(c, w * 0.11, thin);
    canvas.drawCircle(c, (w * 0.03).clamp(0.9, 2.2), dot);
  }

  // 13. 100 OYUN KULÜBÜ — Defne Çelengi İçinde El Çizimi "100" Mührü
  void _paintCenturyLaurel(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Sol ve sağ defne dalları
    final leftBranch = Path()
      ..moveTo(w * 0.44, h * 0.84)
      ..cubicTo(w * 0.14, h * 0.76, w * 0.10, h * 0.30, w * 0.32, h * 0.16);
    final rightBranch = Path()
      ..moveTo(w * 0.56, h * 0.84)
      ..cubicTo(w * 0.86, h * 0.76, w * 0.90, h * 0.30, w * 0.68, h * 0.16);
    canvas.drawPath(leftBranch, stroke);
    canvas.drawPath(rightBranch, stroke);

    // Defne yaprak tırnakları
    for (final t in [0.32, 0.50, 0.68]) {
      canvas.drawLine(Offset(w * 0.19, h * t), Offset(w * 0.12, h * (t - 0.07)), thin);
      canvas.drawLine(Offset(w * 0.81, h * t), Offset(w * 0.88, h * (t - 0.07)), thin);
    }

    // Merkez altın plaka + "100" çizgileri
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.50), width: w * 0.48, height: h * 0.34),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(badgeRect, fill(AppColors.sunYellow, 0.92));
    canvas.drawRRect(badgeRect, thin);

    // "1"
    canvas.drawLine(Offset(w * 0.34, h * 0.41), Offset(w * 0.34, h * 0.59), stroke);
    // İlk "0"
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.47, h * 0.50), width: w * 0.10, height: h * 0.18),
      stroke,
    );
    // İkinci "0"
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.62, h * 0.50), width: w * 0.10, height: h * 0.18),
      stroke,
    );
  }

  // 14. GECE BAYKUŞU — İri Gözlü Bilge Baykuş
  void _paintNightOwl(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final owl = Path()
      ..moveTo(w * 0.24, h * 0.20) // sol kulak tüyü
      ..lineTo(w * 0.36, h * 0.28)
      ..quadraticBezierTo(w * 0.50, h * 0.24, w * 0.64, h * 0.28)
      ..lineTo(w * 0.76, h * 0.20) // sağ kulak tüyü
      ..cubicTo(w * 0.84, h * 0.42, w * 0.80, h * 0.78, w * 0.64, h * 0.86)
      ..quadraticBezierTo(w * 0.50, h * 0.90, w * 0.36, h * 0.86)
      ..cubicTo(w * 0.20, h * 0.78, w * 0.16, h * 0.42, w * 0.24, h * 0.20)
      ..close();

    canvas.drawPath(owl, fill(AppColors.highlighterPurple, 0.85));
    canvas.drawPath(owl, stroke);

    // İri baykuş gözleri
    final eyeL = Offset(w * 0.39, h * 0.46);
    final eyeR = Offset(w * 0.61, h * 0.46);
    final eyeRads = w * 0.11;
    canvas.drawCircle(eyeL, eyeRads, fill(Colors.white, 0.95));
    canvas.drawCircle(eyeR, eyeRads, fill(Colors.white, 0.95));
    canvas.drawCircle(eyeL, eyeRads, stroke);
    canvas.drawCircle(eyeR, eyeRads, stroke);

    final pupilR = (w * 0.042).clamp(1.1, 3.0);
    canvas.drawCircle(eyeL, pupilR, dot);
    canvas.drawCircle(eyeR, pupilR, dot);

    // Gaga
    final beak = Path()
      ..moveTo(w * 0.46, h * 0.54)
      ..lineTo(w * 0.54, h * 0.54)
      ..lineTo(w * 0.50, h * 0.63)
      ..close();
    canvas.drawPath(beak, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(beak, stroke);

    // Göğüs tüyleri
    canvas.drawArc(Rect.fromLTWH(w * 0.38, h * 0.66, w * 0.10, h * 0.08), 0, math.pi, false, thin);
    canvas.drawArc(Rect.fromLTWH(w * 0.52, h * 0.66, w * 0.10, h * 0.08), 0, math.pi, false, thin);
  }

  // 15. ERKEN KALKAN DEHA — Ufuktan Doğan Sabah Güneşi
  void _paintSunrise(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final horizonY = h * 0.68;

    // Doğan yarım güneş
    final sunArc = Path()
      ..moveTo(w * 0.24, horizonY)
      ..arcToPoint(
        Offset(w * 0.76, horizonY),
        radius: Radius.circular(w * 0.26),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(sunArc, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(sunArc, stroke);

    // Sabah ışınları
    final rayAngles = [-math.pi * 0.85, -math.pi * 0.68, -math.pi * 0.50, -math.pi * 0.32, -math.pi * 0.15];
    for (final a in rayAngles) {
      canvas.drawLine(
        Offset(w * 0.50 + math.cos(a) * w * 0.32, horizonY + math.sin(a) * h * 0.32),
        Offset(w * 0.50 + math.cos(a) * w * 0.42, horizonY + math.sin(a) * h * 0.42),
        stroke,
      );
    }

    // Ufuk çizgisi ve alt dalga
    canvas.drawLine(Offset(w * 0.10, horizonY), Offset(w * 0.90, horizonY), stroke);
    final wave = Path()
      ..moveTo(w * 0.20, h * 0.80)
      ..quadraticBezierTo(w * 0.36, h * 0.75, w * 0.50, h * 0.80)
      ..quadraticBezierTo(w * 0.64, h * 0.85, w * 0.80, h * 0.80);
    canvas.drawPath(wave, thin);
  }

  // 16. 3 GÜNLÜK KIVILCIM — Canlı Kıvılcım Alevi ve 3 Kor Noktası
  void _paintSparkFlame(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final outer = Path()
      ..moveTo(w * 0.50, h * 0.14)
      ..cubicTo(w * 0.26, h * 0.36, w * 0.16, h * 0.60, w * 0.28, h * 0.80)
      ..cubicTo(w * 0.38, h * 0.92, w * 0.64, h * 0.92, w * 0.72, h * 0.80)
      ..cubicTo(w * 0.84, h * 0.60, w * 0.74, h * 0.36, w * 0.50, h * 0.14)
      ..close();
    canvas.drawPath(outer, fill(AppColors.highlighterOrange, 0.90));
    canvas.drawPath(outer, stroke);

    final inner = Path()
      ..moveTo(w * 0.50, h * 0.46)
      ..cubicTo(w * 0.38, h * 0.58, w * 0.38, h * 0.74, w * 0.50, h * 0.82)
      ..cubicTo(w * 0.62, h * 0.74, w * 0.62, h * 0.58, w * 0.50, h * 0.46)
      ..close();
    canvas.drawPath(inner, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(inner, thin);

    // 3 günü simgeleyen 3 kıvılcım noktası
    final r = (w * 0.032).clamp(1.0, 2.5);
    canvas.drawCircle(Offset(w * 0.22, h * 0.32), r, dot);
    canvas.drawCircle(Offset(w * 0.78, h * 0.30), r, dot);
    canvas.drawCircle(Offset(w * 0.50, h * 0.07), r, dot);
  }

  // 17. HAFTALIK MEŞALE (7 Gün) — Olimpiyat Meşalesi
  void _paintTorch(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Meşale alevi
    final flame = Path()
      ..moveTo(w * 0.52, h * 0.08)
      ..cubicTo(w * 0.32, h * 0.20, w * 0.28, h * 0.38, w * 0.38, h * 0.48)
      ..lineTo(w * 0.62, h * 0.48)
      ..cubicTo(w * 0.72, h * 0.36, w * 0.68, h * 0.20, w * 0.52, h * 0.08)
      ..close();
    canvas.drawPath(flame, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(flame, stroke);

    // Çanak bileziği
    final bowl = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.48, w * 0.40, h * 0.09),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(bowl, fill(AppColors.highlighterOrange, 0.90));
    canvas.drawRRect(bowl, stroke);

    // Konik sap
    final handle = Path()
      ..moveTo(w * 0.38, h * 0.57)
      ..lineTo(w * 0.62, h * 0.57)
      ..lineTo(w * 0.55, h * 0.90)
      ..lineTo(w * 0.45, h * 0.90)
      ..close();
    canvas.drawPath(handle, fill(AppColors.surfaceSecondaryLight, 0.90));
    canvas.drawPath(handle, stroke);
    canvas.drawLine(Offset(w * 0.50, h * 0.58), Offset(w * 0.50, h * 0.88), thin);
  }

  // 18. 2 HAFTALIK ALIŞKANLIK (14 Gün) — Odunlu Kamp Ateşi
  void _paintCampfire(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Çapraz odunlar
    final log1 = Path()
      ..moveTo(w * 0.16, h * 0.78)
      ..lineTo(w * 0.80, h * 0.90)
      ..lineTo(w * 0.84, h * 0.81)
      ..lineTo(w * 0.20, h * 0.69)
      ..close();
    final log2 = Path()
      ..moveTo(w * 0.84, h * 0.78)
      ..lineTo(w * 0.20, h * 0.90)
      ..lineTo(w * 0.16, h * 0.81)
      ..lineTo(w * 0.80, h * 0.69)
      ..close();
    canvas.drawPath(log1, fill(AppColors.highlighterOrange, 0.75));
    canvas.drawPath(log1, stroke);
    canvas.drawPath(log2, fill(AppColors.sunYellow, 0.80));
    canvas.drawPath(log2, stroke);

    // Çifte kamp alevi
    final fire = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..cubicTo(w * 0.34, h * 0.28, w * 0.24, h * 0.48, w * 0.32, h * 0.68)
      ..lineTo(w * 0.68, h * 0.68)
      ..cubicTo(w * 0.78, h * 0.48, w * 0.68, h * 0.28, w * 0.50, h * 0.12)
      ..close();
    canvas.drawPath(fire, fill(AppColors.highlighterCyan, 0.85));
    canvas.drawPath(fire, stroke);

    final core = Path()
      ..moveTo(w * 0.50, h * 0.38)
      ..quadraticBezierTo(w * 0.38, h * 0.54, w * 0.44, h * 0.68)
      ..lineTo(w * 0.56, h * 0.68)
      ..quadraticBezierTo(w * 0.62, h * 0.54, w * 0.50, h * 0.38);
    canvas.drawPath(core, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(core, thin);
  }

  // 19. AYLIK ÇELİK İRADE (30 Gün) — Perçinli Şövalye Çelik Kalkanı
  void _paintSteelShield(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final shield = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.82, h * 0.22)
      ..cubicTo(w * 0.82, h * 0.56, w * 0.68, h * 0.78, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.32, h * 0.78, w * 0.18, h * 0.56, w * 0.18, h * 0.22)
      ..close();

    canvas.drawPath(shield, fill(AppColors.highlighterPurple, 0.85));
    canvas.drawPath(shield, stroke);

    // Dikey omurga çizgisi + merkez yıldız arması
    canvas.drawLine(Offset(w * 0.50, h * 0.14), Offset(w * 0.50, h * 0.88), thin);
    _drawMiniSpark(canvas, Offset(w * 0.50, h * 0.48), w * 0.14, stroke);

    final r = (w * 0.028).clamp(0.9, 2.2);
    canvas.drawCircle(Offset(w * 0.28, h * 0.28), r, dot);
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), r, dot);
  }

  // 20. 60 GÜNLÜK BİLGE — Kesme Kristal Elmas
  void _paintDiamondGem(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final gem = Path()
      ..moveTo(w * 0.30, h * 0.20)
      ..lineTo(w * 0.70, h * 0.20)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.50, h * 0.88)
      ..lineTo(w * 0.12, h * 0.42)
      ..close();

    canvas.drawPath(gem, fill(AppColors.skyBlue, 0.86));
    canvas.drawPath(gem, stroke);

    // Kristal faset çizgileri
    canvas.drawLine(Offset(w * 0.12, h * 0.42), Offset(w * 0.88, h * 0.42), thin);
    canvas.drawLine(Offset(w * 0.30, h * 0.20), Offset(w * 0.36, h * 0.42), thin);
    canvas.drawLine(Offset(w * 0.70, h * 0.20), Offset(w * 0.64, h * 0.42), thin);
    canvas.drawLine(Offset(w * 0.36, h * 0.42), Offset(w * 0.50, h * 0.88), thin);
    canvas.drawLine(Offset(w * 0.64, h * 0.42), Offset(w * 0.50, h * 0.88), thin);
  }

  // 21. YÜZYIL EFSANESİ (100 Gün) — Kurdeleli Şeref Madalyası
  void _paintHonorMedal(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Üst V-kurdele
    final leftRibbon = Path()
      ..moveTo(w * 0.24, h * 0.12)
      ..lineTo(w * 0.44, h * 0.12)
      ..lineTo(w * 0.52, h * 0.44)
      ..lineTo(w * 0.36, h * 0.44)
      ..close();
    final rightRibbon = Path()
      ..moveTo(w * 0.56, h * 0.12)
      ..lineTo(w * 0.76, h * 0.12)
      ..lineTo(w * 0.64, h * 0.44)
      ..lineTo(w * 0.48, h * 0.44)
      ..close();
    canvas.drawPath(leftRibbon, fill(AppColors.success, 0.85));
    canvas.drawPath(leftRibbon, stroke);
    canvas.drawPath(rightRibbon, fill(AppColors.highlighterCyan, 0.85));
    canvas.drawPath(rightRibbon, stroke);

    // Madalya diski
    final c = Offset(w * 0.50, h * 0.64);
    final r = w * 0.24;
    canvas.drawCircle(c, r, fill(AppColors.sunYellow, 0.95));
    canvas.drawCircle(c, r, stroke);
    _drawFivePointStar(canvas, c, r * 0.55, stroke, fill(Colors.white, 0.90));
  }

  // 22. 1 YILLIK ÖLÜMSÜZ ZİHİN (365 Gün) — Sonsuzluk Kum Saati
  void _paintEternalHourglass(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Alt ve üst ahşap/altın kaideler
    canvas.drawLine(Offset(w * 0.24, h * 0.14), Offset(w * 0.76, h * 0.14), stroke);
    canvas.drawLine(Offset(w * 0.24, h * 0.86), Offset(w * 0.76, h * 0.86), stroke);

    // Kum saati cam hazneleri
    final topBulb = Path()
      ..moveTo(w * 0.28, h * 0.14)
      ..cubicTo(w * 0.28, h * 0.38, w * 0.46, h * 0.44, w * 0.50, h * 0.50)
      ..cubicTo(w * 0.54, h * 0.44, w * 0.72, h * 0.38, w * 0.72, h * 0.14)
      ..close();
    final botBulb = Path()
      ..moveTo(w * 0.28, h * 0.86)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.46, h * 0.56, w * 0.50, h * 0.50)
      ..cubicTo(w * 0.54, h * 0.56, w * 0.72, h * 0.62, w * 0.72, h * 0.86)
      ..close();

    canvas.drawPath(topBulb, fill(AppColors.skyBlue, 0.45));
    canvas.drawPath(botBulb, fill(AppColors.sunYellow, 0.88));
    canvas.drawPath(topBulb, stroke);
    canvas.drawPath(botBulb, stroke);

    // Yanlarda zaman kanatçıkları
    final wingL = Path()
      ..moveTo(w * 0.28, h * 0.50)
      ..quadraticBezierTo(w * 0.10, h * 0.40, w * 0.14, h * 0.54);
    final wingR = Path()
      ..moveTo(w * 0.72, h * 0.50)
      ..quadraticBezierTo(w * 0.90, h * 0.40, w * 0.86, h * 0.54);
    canvas.drawPath(wingL, thin);
    canvas.drawPath(wingR, thin);
  }

  // 23. GÜNÜN ZİRVE ŞAMPİYONU (#1) — Kadife Kaideli İncili Kraliyet Tacı
  void _paintRoyalCrown(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Alt kadife şerit
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.70, w * 0.64, h * 0.12),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(band, fill(AppColors.highlighterPink, 0.88));
    canvas.drawRRect(band, stroke);

    // Taç gövdesi
    final crown = Path()
      ..moveTo(w * 0.18, h * 0.70)
      ..lineTo(w * 0.82, h * 0.70)
      ..lineTo(w * 0.88, h * 0.32)
      ..lineTo(w * 0.66, h * 0.50)
      ..lineTo(w * 0.50, h * 0.18)
      ..lineTo(w * 0.34, h * 0.50)
      ..lineTo(w * 0.12, h * 0.32)
      ..close();
    canvas.drawPath(crown, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(crown, stroke);

    // Merkez elmas & inciler
    final gem = Path()
      ..moveTo(w * 0.50, h * 0.45)
      ..lineTo(w * 0.56, h * 0.54)
      ..lineTo(w * 0.50, h * 0.63)
      ..lineTo(w * 0.44, h * 0.54)
      ..close();
    canvas.drawPath(gem, fill(AppColors.highlighterCyan, 0.95));
    canvas.drawPath(gem, thin);

    final r = (w * 0.036).clamp(1.1, 2.8);
    canvas.drawCircle(Offset(w * 0.12, h * 0.32), r, dot);
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), r * 1.15, dot);
    canvas.drawCircle(Offset(w * 0.88, h * 0.32), r, dot);
  }

  // 24. PODYUM YILDIZI (İlk 3) — 3 Basamaklı Kürsü ve Şampiyonluk Kupası
  void _paintPodiumTrophy(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Podyum basamakları (Sol: 2, Orta: 1, Sağ: 3)
    final step2 = Rect.fromLTWH(w * 0.12, h * 0.66, w * 0.24, h * 0.22);
    final step1 = Rect.fromLTWH(w * 0.36, h * 0.56, w * 0.28, h * 0.32);
    final step3 = Rect.fromLTWH(w * 0.64, h * 0.72, w * 0.24, h * 0.16);

    canvas.drawRect(step2, fill(AppColors.skyBlue, 0.75));
    canvas.drawRect(step3, fill(AppColors.highlighterOrange, 0.80));
    canvas.drawRect(step1, fill(AppColors.sunYellow, 0.95));
    canvas.drawRect(step2, stroke);
    canvas.drawRect(step3, stroke);
    canvas.drawRect(step1, stroke);

    // 1. basamak üstündeki kupa
    final cup = Path()
      ..moveTo(w * 0.36, h * 0.16)
      ..lineTo(w * 0.64, h * 0.16)
      ..cubicTo(w * 0.64, h * 0.38, w * 0.56, h * 0.42, w * 0.50, h * 0.44)
      ..cubicTo(w * 0.44, h * 0.42, w * 0.36, h * 0.38, w * 0.36, h * 0.16)
      ..close();
    canvas.drawPath(cup, fill(AppColors.sunYellow, 0.95));
    canvas.drawPath(cup, stroke);

    // Kulplar ve ayak
    canvas.drawArc(Rect.fromLTWH(w * 0.27, h * 0.19, w * 0.12, h * 0.14), math.pi * 0.5, math.pi, false, thin);
    canvas.drawArc(Rect.fromLTWH(w * 0.61, h * 0.19, w * 0.12, h * 0.14), -math.pi * 0.5, math.pi, false, thin);
    canvas.drawLine(Offset(w * 0.50, h * 0.44), Offset(w * 0.50, h * 0.56), stroke);
  }

  // 25. EINSTEIN MERTEBESİ / ENDEKSİ (148+ IQ) — Atom Yörüngeli & Taçlı Deha Beyni
  void _paintEinsteinBrain(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Çapraz atomik elektron yörüngesi (arkada)
    canvas.save();
    canvas.translate(w * 0.50, h * 0.56);
    canvas.rotate(-0.42);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.88, height: h * 0.30),
      thin,
    );
    canvas.restore();

    // İki yarımküreli kıvrımlı beyin
    final brain = Path()
      ..moveTo(w * 0.50, h * 0.84)
      ..cubicTo(w * 0.30, h * 0.88, w * 0.14, h * 0.74, w * 0.20, h * 0.56)
      ..cubicTo(w * 0.12, h * 0.40, w * 0.28, h * 0.28, w * 0.46, h * 0.32)
      ..cubicTo(w * 0.48, h * 0.28, w * 0.52, h * 0.28, w * 0.54, h * 0.32)
      ..cubicTo(w * 0.72, h * 0.28, w * 0.88, h * 0.40, w * 0.80, h * 0.56)
      ..cubicTo(w * 0.86, h * 0.74, w * 0.70, h * 0.88, w * 0.50, h * 0.84)
      ..close();

    canvas.drawPath(brain, fill(AppColors.highlighterPurple, 0.90));
    canvas.drawPath(brain, stroke);

    // Beyin orta çizgisi ve kıvrımları
    canvas.drawLine(Offset(w * 0.50, h * 0.32), Offset(w * 0.50, h * 0.84), stroke);
    final folds = Path()
      ..moveTo(w * 0.32, h * 0.48)
      ..quadraticBezierTo(w * 0.44, h * 0.52, w * 0.36, h * 0.68)
      ..moveTo(w * 0.68, h * 0.48)
      ..quadraticBezierTo(w * 0.56, h * 0.52, w * 0.64, h * 0.68);
    canvas.drawPath(folds, thin);

    // Beynin üzerinde mini altın deha tacı
    final crown = Path()
      ..moveTo(w * 0.34, h * 0.28)
      ..lineTo(w * 0.66, h * 0.28)
      ..lineTo(w * 0.70, h * 0.12)
      ..lineTo(w * 0.58, h * 0.20)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.42, h * 0.20)
      ..lineTo(w * 0.30, h * 0.12)
      ..close();
    canvas.drawPath(crown, fill(AppColors.sunYellow, 0.96));
    canvas.drawPath(crown, stroke);

    // Yörünge elektronu
    canvas.drawCircle(Offset(w * 0.86, h * 0.39), (w * 0.038).clamp(1.0, 2.6), dot);
  }

  // 26. BÜYÜK USTA ENDEKSİ / MERTEBESİ (120+ IQ) — Işık Huzmeli Deha Ampulü
  void _paintLightbulb(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    // Işık huzmeleri
    final c = Offset(w * 0.50, h * 0.42);
    for (final a in [-math.pi * 0.85, -math.pi * 0.5, -math.pi * 0.15, math.pi * 0.12, math.pi * 0.88]) {
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * w * 0.31, c.dy + math.sin(a) * h * 0.31),
        Offset(c.dx + math.cos(a) * w * 0.40, c.dy + math.sin(a) * h * 0.40),
        thin,
      );
    }

    // Ampul cam küresi
    final bulb = Path()
      ..moveTo(w * 0.38, h * 0.68)
      ..cubicTo(w * 0.34, h * 0.58, w * 0.24, h * 0.52, w * 0.24, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.76, h * 0.38),
        radius: Radius.circular(w * 0.26),
        clockwise: true,
      )
      ..cubicTo(w * 0.76, h * 0.52, w * 0.66, h * 0.58, w * 0.62, h * 0.68)
      ..close();
    canvas.drawPath(bulb, fill(AppColors.sunYellow, 0.92));
    canvas.drawPath(bulb, stroke);

    // İç filaman teli
    final filament = Path()
      ..moveTo(w * 0.44, h * 0.66)
      ..lineTo(w * 0.44, h * 0.46)
      ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.56, h * 0.46)
      ..lineTo(w * 0.56, h * 0.66);
    canvas.drawPath(filament, thin);

    // Duy (vida yivleri)
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.68, w * 0.24, h * 0.16),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(base, fill(AppColors.skyBlue, 0.65));
    canvas.drawRRect(base, stroke);
    canvas.drawLine(Offset(w * 0.40, h * 0.76), Offset(w * 0.60, h * 0.76), thin);
  }

  // 27. DAHİ KULÜBÜ (Kalıcı) — Akademik Mezuniyet Kepi & Diploma
  void _paintMortarboard(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Kep üst eşkenar dörtgeni
    final top = Path()
      ..moveTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.88, h * 0.34)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.12, h * 0.34)
      ..close();
    canvas.drawPath(top, fill(AppColors.success, 0.88));
    canvas.drawPath(top, stroke);

    // Kep alt başlığı
    final skull = Path()
      ..moveTo(w * 0.28, h * 0.41)
      ..lineTo(w * 0.28, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.68, w * 0.72, h * 0.58)
      ..lineTo(w * 0.72, h * 0.41);
    canvas.drawPath(skull, fill(AppColors.highlighterCyan, 0.75));
    canvas.drawPath(skull, stroke);

    // Püskül
    canvas.drawLine(Offset(w * 0.50, h * 0.33), Offset(w * 0.82, h * 0.42), thin);
    canvas.drawLine(Offset(w * 0.82, h * 0.42), Offset(w * 0.82, h * 0.62), stroke);
    canvas.drawCircle(Offset(w * 0.82, h * 0.64), (w * 0.04).clamp(1.0, 2.8), dot);

    // Alt diploma tomarı
    final scroll = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.73, w * 0.52, h * 0.13),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(scroll, fill(AppColors.sunYellow, 0.90));
    canvas.drawRRect(scroll, stroke);
    canvas.drawLine(Offset(w * 0.50, h * 0.73), Offset(w * 0.50, h * 0.86), stroke);
  }

  // 28. DENGELİ ZİHİN (100 IQ) — Simetrik Denge Terazisi
  void _paintBalanceScale(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    // Merkez direk ve taban
    canvas.drawLine(Offset(w * 0.50, h * 0.18), Offset(w * 0.50, h * 0.84), stroke);
    canvas.drawLine(Offset(w * 0.32, h * 0.84), Offset(w * 0.68, h * 0.84), stroke);

    // Yatay terazi kolu
    canvas.drawLine(Offset(w * 0.18, h * 0.30), Offset(w * 0.82, h * 0.30), stroke);
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), (w * 0.04).clamp(1.0, 2.6), dot);

    // Sol kefe
    canvas.drawLine(Offset(w * 0.24, h * 0.30), Offset(w * 0.14, h * 0.56), thin);
    canvas.drawLine(Offset(w * 0.24, h * 0.30), Offset(w * 0.34, h * 0.56), thin);
    final panL = Path()
      ..moveTo(w * 0.12, h * 0.56)
      ..arcToPoint(Offset(w * 0.36, h * 0.56), radius: Radius.circular(w * 0.13), clockwise: false)
      ..close();
    canvas.drawPath(panL, fill(AppColors.highlighterCyan, 0.88));
    canvas.drawPath(panL, stroke);

    // Sağ kefe
    canvas.drawLine(Offset(w * 0.76, h * 0.30), Offset(w * 0.66, h * 0.56), thin);
    canvas.drawLine(Offset(w * 0.76, h * 0.30), Offset(w * 0.86, h * 0.56), thin);
    final panR = Path()
      ..moveTo(w * 0.64, h * 0.56)
      ..arcToPoint(Offset(w * 0.88, h * 0.56), radius: Radius.circular(w * 0.13), clockwise: false)
      ..close();
    canvas.drawPath(panR, fill(AppColors.sunYellow, 0.88));
    canvas.drawPath(panR, stroke);
  }

  // 29. KESKİN ZİHİN (110 IQ) — 4 Uçlu Kutup Yıldızı
  void _paintSharpStar(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
  ) {
    final c = Offset(w * 0.50, h * 0.50);
    final rLong = w * 0.40;
    final rMid = w * 0.13;

    // Çapraz ara ışınlar
    for (final a in [-math.pi * 0.75, -math.pi * 0.25, math.pi * 0.25, math.pi * 0.75]) {
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * w * 0.14, c.dy + math.sin(a) * h * 0.14),
        Offset(c.dx + math.cos(a) * w * 0.28, c.dy + math.sin(a) * h * 0.28),
        thin,
      );
    }

    final star = Path()
      ..moveTo(c.dx, c.dy - rLong)
      ..lineTo(c.dx + rMid, c.dy - rMid)
      ..lineTo(c.dx + rLong, c.dy)
      ..lineTo(c.dx + rMid, c.dy + rMid)
      ..lineTo(c.dx, c.dy + rLong)
      ..lineTo(c.dx - rMid, c.dy + rMid)
      ..lineTo(c.dx - rLong, c.dy)
      ..lineTo(c.dx - rMid, c.dy - rMid)
      ..close();

    canvas.drawPath(star, fill(AppColors.highlighterOrange, 0.90));
    canvas.drawPath(star, stroke);
  }

  // 30. ÜSTÜN MANTIK - MENSA (130 IQ) — Sekizgen Mensa Yıldız Arması
  void _paintMensaCrest(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.50, h * 0.50);
    final outer = w * 0.38;

    final oct = Path();
    for (int i = 0; i < 8; i++) {
      final a = (i * math.pi / 4) + (math.pi / 8);
      final pt = Offset(c.dx + math.cos(a) * outer, c.dy + math.sin(a) * outer);
      if (i == 0) {
        oct.moveTo(pt.dx, pt.dy);
      } else {
        oct.lineTo(pt.dx, pt.dy);
      }
    }
    oct.close();
    canvas.drawPath(oct, fill(AppColors.skyBlue, 0.85));
    canvas.drawPath(oct, stroke);

    // İç parlayan yıldız
    _drawFivePointStar(canvas, c, w * 0.24, stroke, fill(AppColors.sunYellow, 0.95));
    canvas.drawCircle(c, (w * 0.03).clamp(0.9, 2.2), dot);
  }

  // 31. ZÜHTÜ DAHİSİ (140 IQ) — Sinaps Düğümlü Nöral Süpernova
  void _paintZuhtuGenius(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint thin,
    Paint Function(Color, [double]) fill,
    Paint dot,
  ) {
    final c = Offset(w * 0.50, h * 0.50);
    final nodes = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 2;
      final pt = Offset(c.dx + math.cos(a) * w * 0.37, c.dy + math.sin(a) * h * 0.37);
      nodes.add(pt);
      canvas.drawLine(c, pt, thin);
    }

    // Merkez zeka çekirdeği
    canvas.drawCircle(c, w * 0.22, fill(AppColors.sunYellow, 0.94));
    canvas.drawCircle(c, w * 0.22, stroke);

    // Merkezde yıldırım kıvılcımı
    final spark = Path()
      ..moveTo(w * 0.53, h * 0.36)
      ..lineTo(w * 0.43, h * 0.51)
      ..lineTo(w * 0.51, h * 0.51)
      ..lineTo(w * 0.47, h * 0.64)
      ..lineTo(w * 0.57, h * 0.49)
      ..lineTo(w * 0.49, h * 0.49)
      ..close();
    canvas.drawPath(spark, fill(Colors.white, 0.95));
    canvas.drawPath(spark, thin);

    final nodeR = (w * 0.042).clamp(1.1, 2.8);
    for (final pt in nodes) {
      canvas.drawCircle(pt, nodeR, fill(AppColors.highlighterCyan, 0.95));
      canvas.drawCircle(pt, nodeR, thin);
    }
  }

  void _drawMiniSpark(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r);
    canvas.drawPath(path, p);
  }

  void _drawFivePointStar(Canvas canvas, Offset c, double r, Paint stroke, Paint fillPaint) {
    final star = Path();
    final inner = r * 0.44;
    for (int i = 0; i < 10; i++) {
      final a = (i * math.pi / 5) - (math.pi / 2);
      final rad = i.isEven ? r : inner;
      final pt = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(star, fillPaint);
    canvas.drawPath(star, stroke);
  }

  @override
  bool shouldRepaint(covariant _SketchBadgeArtPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isLocked != isLocked;
  }
}

