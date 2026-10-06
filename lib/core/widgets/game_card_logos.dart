import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../games/common/base_game.dart';
import '../theme/app_colors.dart';

/// Her oyun için özel olarak çizilmiş, buton arka planlarını dolduran
/// TAMAMEN ORGANİK, serbest el (freehand doodle) eskiz sanatı.
/// Geometrik şekiller (elmaslar, dik açılı devreler, sert kareler) barındırmaz.
class GameBackgroundLogo extends StatelessWidget {
  final GameType gameType;
  final double opacity;
  final bool animate;

  const GameBackgroundLogo({
    super.key,
    required this.gameType,
    this.opacity = 0.85,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size.infinite,
          painter: _getPainter(gameType),
        ),
      ),
    );
  }

  CustomPainter _getPainter(GameType type) {
    switch (type) {
      case GameType.queens:
        return OrganicQueensLogoPainter();
      case GameType.pinpoint:
        return OrganicPinpointLogoPainter();
      case GameType.crossclimb:
        return OrganicCrossclimbLogoPainter();
      case GameType.tango:
        return OrganicTangoLogoPainter();
      case GameType.zipPath:
        return OrganicZipPathLogoPainter();
      case GameType.patches:
        return OrganicPatchesLogoPainter();
    }
  }
}

/// 1. VEZİRLER (QUEENS): Organik Serbest El Taç, Yumuşak Kurdele Kıvrımları & Işıltı Karalamaları
class OrganicQueensLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.50);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Tacın altındaki dalgalı serbest el kadife yastık / kurdele kıvrımı
    final pillow = Path();
    pillow.moveTo(center.dx - 55, center.dy + 35);
    pillow.cubicTo(center.dx - 30, center.dy + 48, center.dx + 30, center.dy + 48, center.dx + 55, center.dy + 35);
    pillow.cubicTo(center.dx + 65, center.dy + 25, center.dx + 45, center.dy + 18, center.dx + 35, center.dy + 20);
    pillow.cubicTo(center.dx + 10, center.dy + 24, center.dx - 10, center.dy + 24, center.dx - 35, center.dy + 20);
    pillow.cubicTo(center.dx - 45, center.dy + 18, center.dx - 65, center.dy + 25, center.dx - 55, center.dy + 35);
    pillow.close();

    canvas.drawPath(
      pillow,
      Paint()..color = const Color(0xFFFF3366).withValues(alpha: 0.20)..style = PaintingStyle.fill,
    );
    canvas.drawPath(pillow, pencil);

    // Yastık altı kurşun kalem tarama gölgesi (karalama)
    for (double i = -40; i <= 40; i += 7) {
      canvas.drawLine(
        Offset(center.dx + i, center.dy + 34),
        Offset(center.dx + i + 4, center.dy + 44),
        softPencil,
      );
    }

    // 2. Organik El Çizimi Taç Gövdesi (Sivri uçları hafif kavisli ve doğal)
    final crown = Path();
    crown.moveTo(center.dx - 42, center.dy + 18); // Sol taban
    // Sol dış kıvrım
    crown.cubicTo(center.dx - 48, center.dy - 5, center.dx - 58, center.dy - 20, center.dx - 52, center.dy - 32);
    // Sol iç vadi
    crown.cubicTo(center.dx - 40, center.dy - 18, center.dx - 28, center.dy - 5, center.dx - 22, center.dy - 2);
    // Orta ana tepe (hafif sağa meyleden doğal çizim)
    crown.cubicTo(center.dx - 12, center.dy - 25, center.dx - 4, center.dy - 48, center.dx + 2, center.dy - 52);
    // Orta sağ iniş
    crown.cubicTo(center.dx + 8, center.dy - 46, center.dx + 16, center.dy - 22, center.dx + 24, center.dy - 2);
    // Sağ dış tepe
    crown.cubicTo(center.dx + 30, center.dy - 8, center.dx + 42, center.dy - 22, center.dx + 50, center.dy - 32);
    // Sağ iniş tabana
    crown.cubicTo(center.dx + 56, center.dy - 18, center.dx + 46, center.dy - 2, center.dx + 42, center.dy + 18);
    // Taban çizgisi (hafif yay)
    crown.quadraticBezierTo(center.dx, center.dy + 24, center.dx - 42, center.dy + 18);
    crown.close();

    canvas.drawPath(
      crown,
      Paint()..color = AppColors.highlighterYellow.withValues(alpha: 0.60)..style = PaintingStyle.fill,
    );
    canvas.drawPath(crown, pencil);

    // İkinci serbest el kalem vuruşu (çizgiyi iki kere çekmiş gibi)
    final crownDraft = Path()
      ..moveTo(center.dx - 40, center.dy + 16)
      ..cubicTo(center.dx - 46, center.dy - 3, center.dx - 56, center.dy - 18, center.dx - 50, center.dy - 30)
      ..cubicTo(center.dx - 38, center.dy - 16, center.dx - 26, center.dy - 3, center.dx - 20, center.dy)
      ..cubicTo(center.dx - 10, center.dy - 23, center.dx - 2, center.dy - 46, center.dx + 4, center.dy - 50)
      ..cubicTo(center.dx + 10, center.dy - 44, center.dx + 18, center.dy - 20, center.dx + 26, center.dy)
      ..cubicTo(center.dx + 32, center.dy - 6, center.dx + 44, center.dy - 20, center.dx + 52, center.dy - 30);
    canvas.drawPath(crownDraft, softPencil);

    // Taç tepelerindeki organik el çizimi inciler
    final pearlTips = [
      Offset(center.dx - 52, center.dy - 32),
      Offset(center.dx + 2, center.dy - 52),
      Offset(center.dx + 50, center.dy - 32),
    ];
    for (var tip in pearlTips) {
      canvas.drawCircle(tip, 5.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(tip, 5.0, pencil);
      canvas.drawCircle(Offset(tip.dx - 1.5, tip.dy - 1.5), 1.5, Paint()..color = AppColors.pencilBlack);
    }

    // Taç etrafında uçuşan serbest el ışıltı yıldızları (✦) ve noktalar
    _drawFreehandSparkle(canvas, Offset(center.dx - 62, center.dy - 12), 10, pencil);
    _drawFreehandSparkle(canvas, Offset(center.dx + 58, center.dy - 10), 12, pencil);
    _drawFreehandSparkle(canvas, Offset(center.dx + 18, center.dy - 64), 8, pencil);
  }

  void _drawFreehandSparkle(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    path.moveTo(c.dx, c.dy - r);
    path.quadraticBezierTo(c.dx + r * 0.15, c.dy - r * 0.15, c.dx + r, c.dy);
    path.quadraticBezierTo(c.dx + r * 0.15, c.dy + r * 0.15, c.dx, c.dy + r);
    path.quadraticBezierTo(c.dx - r * 0.15, c.dy + r * 0.15, c.dx - r, c.dy);
    path.quadraticBezierTo(c.dx - r * 0.15, c.dy - r * 0.15, c.dx, c.dy - r);
    canvas.drawPath(path, p..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. KELİME İZLERİ (PINPOINT): Serbest El Büyüteç, Kıvrımlı Parmak İzi & İpucu Karalaması
class OrganicPinpointLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.46);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Yana yatık Organik Ahşap Büyüteç Sapı
    final handle = Path();
    final hStart = Offset(center.dx + 26, center.dy + 26);
    final hEnd = Offset(center.dx + 62, center.dy + 62);

    handle.moveTo(hStart.dx - 5, hStart.dy + 5);
    handle.quadraticBezierTo(hStart.dx + 16, hStart.dy + 22, hEnd.dx - 6, hEnd.dy);
    handle.cubicTo(hEnd.dx, hEnd.dy + 6, hEnd.dx + 6, hEnd.dy, hEnd.dx, hEnd.dy - 6);
    handle.quadraticBezierTo(hStart.dx + 22, hStart.dy + 16, hStart.dx + 5, hStart.dy - 5);
    handle.close();

    canvas.drawPath(
      handle,
      Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.35)..style = PaintingStyle.fill,
    );
    canvas.drawPath(handle, pencil);

    // Sap içi ahşap karalama çizgileri
    canvas.drawLine(Offset(hStart.dx + 4, hStart.dy + 12), Offset(hEnd.dx - 12, hEnd.dy - 4), softPencil);

    // 2. Organik Serbest El Büyüteç Çerçevesi (Kusursuz daire DEĞİL, doğal el kıvrımı)
    final lensPath = Path();
    const double r = 38.0;
    for (double a = 0; a <= math.pi * 2 + 0.1; a += 0.25) {
      final wobble = math.sin(a * 3) * 1.8 + math.cos(a * 2) * 1.2;
      final rad = r + wobble;
      final x = center.dx + rad * math.cos(a);
      final y = center.dy + rad * math.sin(a);
      if (a == 0) {
        lensPath.moveTo(x, y);
      } else {
        lensPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      lensPath,
      Paint()..color = AppColors.highlighterCyan.withValues(alpha: 0.40)..style = PaintingStyle.fill,
    );
    canvas.drawPath(lensPath, pencil..strokeWidth = 2.5);

    // Çift çizgi konturu
    final lensDraft = Path();
    for (double a = 0; a <= math.pi * 2 + 0.1; a += 0.3) {
      final wobble = math.cos(a * 4) * 1.5;
      final rad = r - 4 + wobble;
      final x = center.dx + rad * math.cos(a);
      final y = center.dy + rad * math.sin(a);
      if (a == 0) {
        lensDraft.moveTo(x, y);
      } else {
        lensDraft.lineTo(x, y);
      }
    }
    canvas.drawPath(lensDraft, softPencil);

    // 3. Büyüteç Camı İçindeki Organik Kıvrımlı Parmak İzi / Gizli İpucu Karalaması
    final fingerprint = Path();
    fingerprint.moveTo(center.dx - 18, center.dy + 8);
    fingerprint.cubicTo(center.dx - 16, center.dy - 12, center.dx + 12, center.dy - 16, center.dx + 16, center.dy + 6);

    fingerprint.moveTo(center.dx - 12, center.dy + 12);
    fingerprint.cubicTo(center.dx - 10, center.dy - 6, center.dx + 8, center.dy - 10, center.dx + 12, center.dy + 8);

    fingerprint.moveTo(center.dx - 6, center.dy + 14);
    fingerprint.cubicTo(center.dx - 4, center.dy - 1, center.dx + 4, center.dy - 4, center.dx + 6, center.dy + 10);
    canvas.drawPath(fingerprint, pencil..strokeWidth = 1.8);

    // Camın üstündeki ışık yansıması (Glance squiggle)
    final reflection = Path()
      ..moveTo(center.dx - 22, center.dy - 18)
      ..cubicTo(center.dx - 16, center.dy - 28, center.dx - 2, center.dy - 28, center.dx + 8, center.dy - 24);
    canvas.drawPath(reflection, Paint()..color = Colors.white..strokeWidth = 3.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Minik gizemli soru işareti karalaması (?)
    _drawDoodleQuestion(canvas, Offset(center.dx - 48, center.dy - 26), pencil);
  }

  void _drawDoodleQuestion(Canvas canvas, Offset c, Paint p) {
    final q = Path();
    q.moveTo(c.dx - 6, c.dy - 4);
    q.cubicTo(c.dx - 6, c.dy - 14, c.dx + 8, c.dy - 14, c.dx + 6, c.dy - 4);
    q.cubicTo(c.dx + 4, c.dy + 2, c.dx, c.dy + 4, c.dx, c.dy + 10);
    canvas.drawPath(q, p..strokeWidth = 1.8);
    canvas.drawCircle(Offset(c.dx, c.dy + 16), 1.8, Paint()..color = AppColors.pencilBlack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. KELİME TIRMANIŞI (CROSSCLIMB): Kıvrımlı Dağ Patikası & Eğri Büğrü Ahşap Merdiven
class OrganicCrossclimbLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.50);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Arkadaki organik dağ zirvesi silueti (Serbest el eğrisi)
    final mountain = Path();
    mountain.moveTo(center.dx - 65, center.dy + 48);
    mountain.cubicTo(center.dx - 45, center.dy + 20, center.dx - 25, center.dy - 15, center.dx - 8, center.dy - 42); // Zirveye tırmanış
    mountain.cubicTo(center.dx + 5, center.dy - 25, center.dx + 35, center.dy + 10, center.dx + 65, center.dy + 48);
    mountain.close();

    canvas.drawPath(
      mountain,
      Paint()..color = AppColors.highlighterPurple.withValues(alpha: 0.22)..style = PaintingStyle.fill,
    );
    canvas.drawPath(mountain, pencil);

    // Dağ yamacındaki serbest el taramalar
    for (double i = -30; i <= 30; i += 9) {
      canvas.drawLine(
        Offset(center.dx - 8 + i * 0.7, center.dy - 30 + (i.abs() * 1.2)),
        Offset(center.dx - 14 + i * 0.7, center.dy - 15 + (i.abs() * 1.2)),
        softPencil,
      );
    }

    // 2. Hafif eğri, organik Ahşap Merdiven (Tilted rustic ladder)
    // Sol ve sağ merdiven direkleri
    final leftPole = Path()
      ..moveTo(center.dx - 32, center.dy + 45)
      ..quadraticBezierTo(center.dx - 22, center.dy + 5, center.dx - 12, center.dy - 35);

    final rightPole = Path()
      ..moveTo(center.dx - 12, center.dy + 47)
      ..quadraticBezierTo(center.dx - 2, center.dy + 7, center.dx + 8, center.dy - 33);

    canvas.drawPath(leftPole, pencil..strokeWidth = 2.4);
    canvas.drawPath(rightPole, pencil);

    // Basamaklar (Eğri büğrü, uçları direklerden hafif taşan basamaklar)
    final rungs = [
      [Offset(center.dx - 34, center.dy + 35), Offset(center.dx - 10, center.dy + 37)],
      [Offset(center.dx - 29, center.dy + 18), Offset(center.dx - 5, center.dy + 20)],
      [Offset(center.dx - 24, center.dy + 1), Offset(center.dx, center.dy + 3)],
      [Offset(center.dx - 19, center.dy - 16), Offset(center.dx + 5, center.dy - 14)],
    ];

    for (var rung in rungs) {
      canvas.drawLine(rung[0], rung[1], pencil..strokeWidth = 2.0);
      // İp düğümü karalaması
      canvas.drawCircle(rung[0], 2.0, Paint()..color = AppColors.pencilBlack);
      canvas.drawCircle(rung[1], 2.0, Paint()..color = AppColors.pencilBlack);
    }

    // 3. Dağın Zirvesindeki El Çizimi Zafer Bayrağı (Fluttering Flag Doodle)
    final pole = Offset(center.dx - 8, center.dy - 42);
    canvas.drawLine(pole, Offset(pole.dx, pole.dy - 24), pencil..strokeWidth = 2.2);

    final flag = Path();
    flag.moveTo(pole.dx, pole.dy - 24);
    flag.cubicTo(pole.dx + 10, pole.dy - 28, pole.dx + 16, pole.dy - 20, pole.dx + 26, pole.dy - 24);
    flag.cubicTo(pole.dx + 18, pole.dy - 14, pole.dx + 10, pole.dy - 18, pole.dx, pole.dy - 12);
    flag.close();

    canvas.drawPath(
      flag,
      Paint()..color = AppColors.highlighterYellow..style = PaintingStyle.fill,
    );
    canvas.drawPath(flag, pencil);

    // Rüzgar ve hareket kıvrımları (Wind squiggles)
    final wind1 = Path()
      ..moveTo(pole.dx + 30, pole.dy - 26)
      ..quadraticBezierTo(pole.dx + 42, pole.dy - 28, pole.dx + 46, pole.dy - 22);
    canvas.drawPath(wind1, softPencil);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. GÜNEŞ & AY (TANGO): Dalgalı Alev Işınlı Güneş & Sarılan Hilal (Whimsical Celestial Doodle)
class OrganicTangoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.50);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Organik Dalgalı Güneş Işınları (Serbest el alev kıvrımları / taç yaprakları)
    final rays = Path();
    const double numRays = 10;
    for (int i = 0; i < numRays; i++) {
      final a = (i * (360 / numRays)) * math.pi / 180;
      final aNext = ((i + 1) * (360 / numRays)) * math.pi / 180;
      final aMid = (a + aNext) / 2;

      final pStart = Offset(center.dx + 28 * math.cos(a), center.dy + 28 * math.sin(a));
      final pTip = Offset(center.dx + 46 * math.cos(aMid), center.dy + 46 * math.sin(aMid));
      final pEnd = Offset(center.dx + 28 * math.cos(aNext), center.dy + 28 * math.sin(aNext));

      if (i == 0) rays.moveTo(pStart.dx, pStart.dy);
      rays.quadraticBezierTo(pTip.dx + math.sin(i) * 3, pTip.dy - math.cos(i) * 3, pTip.dx, pTip.dy);
      rays.quadraticBezierTo(pEnd.dx, pEnd.dy, pEnd.dx, pEnd.dy);
    }
    rays.close();

    canvas.drawPath(
      rays,
      Paint()..color = AppColors.highlighterYellow.withValues(alpha: 0.50)..style = PaintingStyle.fill,
    );
    canvas.drawPath(rays, pencil);

    // 2. Güneş Gövdesi (Hafif yumuşak yuvarlak)
    final sunCircle = Path()..addOval(Rect.fromCircle(center: center, radius: 26));
    canvas.drawPath(sunCircle, Paint()..color = const Color(0xFFFDE047)..style = PaintingStyle.fill);
    canvas.drawPath(sunCircle, pencil);

    // 3. Güneşe Sarılan Uykucu Hilal Doodle'ı (Serene sleeping crescent)
    final moonCenter = Offset(center.dx + 8, center.dy - 6);
    final moon = Path();
    moon.moveTo(moonCenter.dx + 6, moonCenter.dy - 28);
    // Dış hilal kıvrımı
    moon.cubicTo(moonCenter.dx + 35, moonCenter.dy - 12, moonCenter.dx + 35, moonCenter.dy + 22, moonCenter.dx + 4, moonCenter.dy + 32);
    // İç hilal kıvrımı
    moon.cubicTo(moonCenter.dx + 20, moonCenter.dy + 18, moonCenter.dx + 20, moonCenter.dy - 10, moonCenter.dx + 6, moonCenter.dy - 28);
    moon.close();

    canvas.drawPath(moon, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawPath(moon, pencil..strokeWidth = 2.4);

    // Ayın gözü (Kapalı, uykulu kirpik çizgisi)
    final eye = Path()
      ..moveTo(moonCenter.dx + 18, moonCenter.dy + 2)
      ..quadraticBezierTo(moonCenter.dx + 22, moonCenter.dy + 6, moonCenter.dx + 26, moonCenter.dy + 2);
    canvas.drawPath(eye, pencil..strokeWidth = 1.8);

    // Ay içi krater karalaması
    canvas.drawCircle(Offset(moonCenter.dx + 16, moonCenter.dy + 16), 3.0, softPencil);

    // 4. Etrafta süzülen el çizimi minik bulut pufu ve yıldızlar
    _drawDoodlePuffCloud(canvas, Offset(center.dx - 48, center.dy + 26), pencil);
    _drawFreehandLittleStar(canvas, Offset(center.dx + 36, center.dy - 36), pencil);
  }

  void _drawDoodlePuffCloud(Canvas canvas, Offset c, Paint p) {
    final cloud = Path();
    cloud.moveTo(c.dx - 14, c.dy);
    cloud.cubicTo(c.dx - 18, c.dy - 8, c.dx - 6, c.dy - 14, c.dx, c.dy - 10);
    cloud.cubicTo(c.dx + 6, c.dy - 16, c.dx + 16, c.dy - 10, c.dx + 16, c.dy - 2);
    cloud.cubicTo(c.dx + 20, c.dy + 4, c.dx + 12, c.dy + 8, c.dx + 4, c.dy + 6);
    cloud.cubicTo(c.dx - 2, c.dy + 8, c.dx - 12, c.dy + 6, c.dx - 14, c.dy);
    cloud.close();

    canvas.drawPath(cloud, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawPath(cloud, p..strokeWidth = 1.6);
  }

  void _drawFreehandLittleStar(Canvas canvas, Offset c, Paint p) {
    canvas.drawLine(Offset(c.dx - 5, c.dy), Offset(c.dx + 5, c.dy), p..strokeWidth = 1.6);
    canvas.drawLine(Offset(c.dx, c.dy - 5), Offset(c.dx, c.dy + 5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. SAYI YOLU (ZIP PATH): Kıvrımlı Macera Patikası & Numaralı Dere Taşları
class OrganicZipPathLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.50);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Kıvrılan Doğal Dere / Macera Patikası (S-Curve organic ribbon)
    final path = Path();
    final p1 = Offset(center.dx - 55, center.dy + 38);
    final p2 = Offset(center.dx - 25, center.dy + 10);
    final p3 = Offset(center.dx + 10, center.dy + 25);
    final p4 = Offset(center.dx + 45, center.dy - 20);
    final p5 = Offset(center.dx + 15, center.dy - 44);

    path.moveTo(p1.dx, p1.dy);
    path.cubicTo(center.dx - 45, center.dy + 15, center.dx - 35, center.dy + 15, p2.dx, p2.dy);
    path.cubicTo(center.dx - 12, center.dy + 5, center.dx - 5, center.dy + 35, p3.dx, p3.dy);
    path.cubicTo(center.dx + 25, center.dy + 15, center.dx + 35, center.dy - 5, p4.dx, p4.dy);
    path.cubicTo(center.dx + 48, center.dy - 35, center.dx + 30, center.dy - 48, p5.dx, p5.dy);

    // Arkasındaki fosforlu su/yol akıntısı
    final wideTrail = Paint()
      ..color = AppColors.highlighterCyan.withValues(alpha: 0.35)
      ..strokeWidth = 18.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, wideTrail);

    // Kesikli patika çizgisi (Dashed path)
    canvas.drawPath(path, pencil);

    // İkinci serbest el kurşun kalem geçişi
    final subPath = Path()
      ..moveTo(p1.dx + 2, p1.dy - 2)
      ..cubicTo(center.dx - 43, center.dy + 13, center.dx - 33, center.dy + 13, p2.dx + 2, p2.dy - 2);
    canvas.drawPath(subPath, softPencil);

    // 2. Patika Üzerindeki Organik Dere Çakıl Taşları (①, ②, ③, ④)
    final stones = [
      {'pos': p1, 'num': '1', 'color': AppColors.highlighterYellow},
      {'pos': p2, 'num': '2', 'color': Colors.white},
      {'pos': p3, 'num': '3', 'color': Colors.white},
      {'pos': p4, 'num': '4', 'color': AppColors.highlighterYellow},
    ];

    for (var s in stones) {
      final pos = s['pos'] as Offset;
      final num = s['num'] as String;
      final fill = s['color'] as Color;

      // Taş gövdesi (Organik asimetrik çakıl taşı)
      final stonePath = Path();
      stonePath.moveTo(pos.dx - 11, pos.dy - 2);
      stonePath.cubicTo(pos.dx - 12, pos.dy - 10, pos.dx + 2, pos.dy - 12, pos.dx + 10, pos.dy - 6);
      stonePath.cubicTo(pos.dx + 14, pos.dy + 4, pos.dx + 4, pos.dy + 12, pos.dx - 6, pos.dy + 11);
      stonePath.close();

      canvas.drawPath(stonePath, Paint()..color = fill..style = PaintingStyle.fill);
      canvas.drawPath(stonePath, pencil);

      // Taş gölgesi (karalama)
      canvas.drawLine(Offset(pos.dx - 8, pos.dy + 12), Offset(pos.dx + 8, pos.dy + 12), softPencil);

      // Üstündeki el yazısı numara
      final textSpan = TextSpan(
        text: num,
        style: const TextStyle(
          color: AppColors.pencilBlack,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'PatrickHand',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // 3. Patika Bitişindeki El Çizimi Bitiş Bayrağı (Goal Flag)
    canvas.drawLine(p5, Offset(p5.dx, p5.dy - 18), pencil..strokeWidth = 2.0);
    final flag = Path();
    flag.moveTo(p5.dx, p5.dy - 18);
    flag.lineTo(p5.dx + 12, p5.dy - 12);
    flag.lineTo(p5.dx, p5.dy - 6);
    flag.close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFF3366)..style = PaintingStyle.fill);
    canvas.drawPath(flag, pencil);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. ALAN BÖLME (PATCHES / SHIKAKU): Organik El Çizimi Dikdörtgen Bloklar & Alan Sayıları
class OrganicPatchesLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.50);

    final pencil = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPencil = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Ana Dikdörtgen Blok 1 (Sarı Fosforlu 2x2 alan)
    final r1 = Rect.fromCenter(center: Offset(center.dx - 12, center.dy - 12), width: 44, height: 44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r1, const Radius.circular(6)),
      Paint()..color = AppColors.highlighterYellow.withValues(alpha: 0.35)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r1, const Radius.circular(6)),
      pencil,
    );

    // İçine 4 sayısı
    final tp1 = TextPainter(
      text: const TextSpan(
        text: '4',
        style: TextStyle(
          color: AppColors.pencilBlack,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'PatrickHand',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(r1.center.dx - tp1.width / 2, r1.center.dy - tp1.height / 2));

    // 2. İkinci Dikdörtgen Blok (Yatay 1x2 alan, açık turkuaz/yeşil)
    final r2 = Rect.fromCenter(center: Offset(center.dx + 22, center.dy - 12), width: 22, height: 44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r2, const Radius.circular(5)),
      Paint()..color = AppColors.highlighterGreen.withValues(alpha: 0.25)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r2, const Radius.circular(5)),
      pencil,
    );

    // İçine 2 sayısı
    final tp2 = TextPainter(
      text: const TextSpan(
        text: '2',
        style: TextStyle(
          color: AppColors.pencilBlack,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'PatrickHand',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(r2.center.dx - tp2.width / 2, r2.center.dy - tp2.height / 2));

    // 3. Üçüncü Dikdörtgen Blok (Yatay 3x1 alan, alt kısım)
    final r3 = Rect.fromCenter(center: Offset(center.dx, center.dy + 24), width: 66, height: 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r3, const Radius.circular(6)),
      Paint()..color = AppColors.highlighterOrange.withValues(alpha: 0.25)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r3, const Radius.circular(6)),
      pencil,
    );

    // İçine 3 sayısı
    final tp3 = TextPainter(
      text: const TextSpan(
        text: '3',
        style: TextStyle(
          color: AppColors.pencilBlack,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'PatrickHand',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp3.paint(canvas, Offset(r3.center.dx - tp3.width / 2, r3.center.dy - tp3.height / 2));

    // Kenar karalamaları ve tarama gölgeleri
    for (double i = -20; i <= 20; i += 8) {
      canvas.drawLine(
        Offset(center.dx + i, center.dy + 38),
        Offset(center.dx + i + 4, center.dy + 44),
        softPencil,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
