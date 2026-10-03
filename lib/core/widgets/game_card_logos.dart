import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../games/common/base_game.dart';

/// Her oyun için özel olarak çizilmiş, buton arka planlarını dolduran
/// yüksek kaliteli, fütüristik ve yarışma ruhuna sahip amblem logoları.
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
        return QueensLogoPainter();
      case GameType.pinpoint:
        return PinpointLogoPainter();
      case GameType.crossclimb:
        return CrossclimbLogoPainter();
      case GameType.tango:
        return TangoLogoPainter();
      case GameType.zipPath:
        return ZipPathLogoPainter();
    }
  }
}

/// 1. VEZİRLER (QUEENS): Kristal Kraliyet Tacı & Vezir Geometrisi
class QueensLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.72, h * 0.50);
    final radius = math.min(w, h) * 0.44;

    // Arka plan ışıltı halkası
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF3366).withOpacity(0.28),
          const Color(0xFFFF7096).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Dış koruyucu geometrik elmas kalkan
    final shieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF3366), Color(0xFFFFD000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final diamondPath = Path();
    diamondPath.moveTo(center.dx, center.dy - radius);
    diamondPath.lineTo(center.dx + radius * 0.9, center.dy);
    diamondPath.lineTo(center.dx, center.dy + radius * 0.9);
    diamondPath.lineTo(center.dx - radius * 0.9, center.dy);
    diamondPath.close();
    canvas.drawPath(diamondPath, shieldPaint);

    // Çapraz vezir saldırı eksen çizgileri (Grid Ray)
    final rayPaint = Paint()
      ..color = const Color(0xFFFF3366).withOpacity(0.18)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx - radius * 1.2, center.dy - radius * 1.2), Offset(center.dx + radius * 1.2, center.dy + radius * 1.2), rayPaint);
    canvas.drawLine(Offset(center.dx - radius * 1.2, center.dy + radius * 1.2), Offset(center.dx + radius * 1.2, center.dy - radius * 1.2), rayPaint);

    // Özel Kristal Taç Gövdesi
    final crownPath = Path();
    final cw = radius * 0.85;
    final ch = radius * 0.65;
    final baseTop = center.dy + ch * 0.4;
    final baseBottom = center.dy + ch * 0.65;

    // Taç tabanı
    crownPath.moveTo(center.dx - cw * 0.6, baseBottom);
    crownPath.lineTo(center.dx + cw * 0.6, baseBottom);
    crownPath.lineTo(center.dx + cw * 0.5, baseTop);
    crownPath.lineTo(center.dx - cw * 0.5, baseTop);
    crownPath.close();

    // Taç sivri uçları (5 sivri kraliyet ucu)
    crownPath.moveTo(center.dx - cw * 0.5, baseTop);
    crownPath.lineTo(center.dx - cw * 0.55, center.dy - ch * 0.2); // Sol uç
    crownPath.lineTo(center.dx - cw * 0.25, center.dy + ch * 0.1);
    crownPath.lineTo(center.dx, center.dy - ch * 0.6); // Orta ana zirve uç
    crownPath.lineTo(center.dx + cw * 0.25, center.dy + ch * 0.1);
    crownPath.lineTo(center.dx + cw * 0.55, center.dy - ch * 0.2); // Sağ uç
    crownPath.lineTo(center.dx + cw * 0.5, baseTop);

    final crownFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2A6D), Color(0xFFFFB300)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: center, width: cw, height: ch))
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownFill);

    // Taç tepelerindeki kraliyet incileri
    final jewelPaint = Paint()..color = const Color(0xFFFFFFFF);
    final jewelGlow = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final tips = [
      Offset(center.dx - cw * 0.55, center.dy - ch * 0.2),
      Offset(center.dx, center.dy - ch * 0.6),
      Offset(center.dx + cw * 0.55, center.dy - ch * 0.2),
    ];
    for (var tip in tips) {
      canvas.drawCircle(tip, 5.0, jewelGlow);
      canvas.drawCircle(tip, 3.5, jewelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. KELİME İZLERİ (PINPOINT): Radar Hedef Nişangahı & Şifre Ağı
class PinpointLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.72, h * 0.50);
    final radius = math.min(w, h) * 0.44;

    // Turkuaz radar ışıltısı
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.30),
          const Color(0xFF0077B6).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Konsantrik radar çemberleri
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF00E5FF).withOpacity(0.5);

    canvas.drawCircle(center, radius * 0.95, ringPaint);
    ringPaint.strokeWidth = 1.2;
    ringPaint.color = const Color(0xFF00E5FF).withOpacity(0.3);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.35, ringPaint);

    // Hedef Crosshair (Nişangah çizgileri)
    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx - radius * 1.1, center.dy), Offset(center.dx - radius * 0.2, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + radius * 0.2, center.dy), Offset(center.dx + radius * 1.1, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius * 1.1), Offset(center.dx, center.dy - radius * 0.2), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + radius * 0.2), Offset(center.dx, center.dy + radius * 1.1), crossPaint);

    // 4 köşe hedef çerçeve braketleri [ ]
    final bracketPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final bDist = radius * 0.8;
    final bLen = radius * 0.22;

    // Sol Üst
    canvas.drawPath(Path()..moveTo(center.dx - bDist, center.dy - bDist + bLen)..lineTo(center.dx - bDist, center.dy - bDist)..lineTo(center.dx - bDist + bLen, center.dy - bDist), bracketPaint);
    // Sağ Üst
    canvas.drawPath(Path()..moveTo(center.dx + bDist - bLen, center.dy - bDist)..lineTo(center.dx + bDist, center.dy - bDist)..lineTo(center.dx + bDist, center.dy - bDist + bLen), bracketPaint);
    // Sol Alt
    canvas.drawPath(Path()..moveTo(center.dx - bDist, center.dy + bDist - bLen)..lineTo(center.dx - bDist, center.dy + bDist)..lineTo(center.dx - bDist + bLen, center.dy + bDist), bracketPaint);
    // Sağ Alt
    canvas.drawPath(Path()..moveTo(center.dx + bDist - bLen, center.dy + bDist)..lineTo(center.dx + bDist, center.dy + bDist)..lineTo(center.dx + bDist, center.dy + bDist - bLen), bracketPaint);

    // Merkez parlayan kilitlenme çekirdeği (Target Locked)
    final lockCore = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, 5.0, lockCore);
    final coreRing = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 10.0, coreRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. KELİME TIRMANIŞI (CROSSCLIMB): Yükselen Piramit Basamakları & Zirve Vektörü
class CrossclimbLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.72, h * 0.50);
    final radius = math.min(w, h) * 0.44;

    // Mor / Pembe ışıltı
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFA855F7).withOpacity(0.32),
          const Color(0xFFEC4899).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Yükselen 3D basamaklar (Merdiven / Ladder)
    final stepColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF8B5CF6),
      const Color(0xFFA855F7),
      const Color(0xFFC084FC),
    ];

    for (int i = 0; i < 4; i++) {
      final stepW = radius * (1.2 - i * 0.22);
      final stepH = radius * 0.24;
      final stepY = center.dy + radius * 0.65 - i * (stepH + 4);
      final stepX = center.dx - stepW / 2 + (i * 4);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(stepX, stepY, stepW, stepH),
        const Radius.circular(6),
      );

      final stepPaint = Paint()
        ..shader = LinearGradient(
          colors: [stepColors[i], const Color(0xFFEC4899)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rrect.outerRect);

      canvas.drawRRect(rrect, stepPaint);

      // Basamak üstü parlama çizgisi
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(stepX + 8, stepY + 3), Offset(stepX + stepW - 8, stepY + 3), highlightPaint);
    }

    // Zirveye Tırmanan Enerji Oku
    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFD600)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(center.dx - 12, center.dy - radius * 0.9, 24, radius * 0.8))
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final topY = center.dy - radius * 0.9;
    arrowPath.moveTo(center.dx, topY);
    arrowPath.lineTo(center.dx - 16, topY + 22);
    arrowPath.lineTo(center.dx - 6, topY + 20);
    arrowPath.lineTo(center.dx - 6, topY + 45);
    arrowPath.lineTo(center.dx + 6, topY + 45);
    arrowPath.lineTo(center.dx + 6, topY + 20);
    arrowPath.lineTo(center.dx + 16, topY + 22);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. GÜNEŞ & AY (TANGO): Solar Flare & Lunar Eclipse İkili Dengesi
class TangoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.72, h * 0.50);
    final radius = math.min(w, h) * 0.44;

    // Altın sarısı & amber ışıltısı
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E00).withOpacity(0.35),
          const Color(0xFFFFD000).withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Güneş Işınları (Dairesel 8 alev mızrağı)
    final rayPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFF5E00)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final startR = radius * 0.72;
      final endR = (i % 2 == 0) ? radius * 1.05 : radius * 0.90;
      final p1 = Offset(center.dx + math.cos(angle) * startR, center.dy + math.sin(angle) * startR);
      final p2 = Offset(center.dx + math.cos(angle) * endR, center.dy + math.sin(angle) * endR);
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Güneş Çekirdeği (Altın Yarımküre)
    final sunPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6));
    canvas.drawCircle(center, radius * 0.6, sunPaint);

    // İç içe geçen Ay Tutulması Hilali (Lunar Eclipse Crescent)
    final moonCenter = Offset(center.dx + radius * 0.22, center.dy - radius * 0.12);
    final moonCutPaint = Paint()
      ..color = const Color(0xFF16181F) // Gece gökyüzü / zıt renk
      ..style = PaintingStyle.fill;

    // Hilal oluşturmak için ClipPath
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.58));
    final moonCut = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: radius * 0.50));

    final crescent = Path.combine(PathOperation.difference, moonPath, moonCut);
    final crescentPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.58));

    canvas.drawPath(crescent, crescentPaint);

    // Ay üzerindeki yıldız ışıltısı
    final starCenter = Offset(center.dx + radius * 0.15, center.dy + radius * 0.15);
    final starPaint = Paint()..color = Colors.white;
    canvas.drawCircle(starCenter, 3.5, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. SAYI YOLU (ZIP PATH): Siber Devre Kartı & Kesişmeyen Enerji Yolu
class ZipPathLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.72, h * 0.50);
    final radius = math.min(w, h) * 0.44;

    // Zümrüt Yeşili / Turkuaz neon ışıltısı
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FA9A).withOpacity(0.32),
          const Color(0xFF00D2D3).withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Izgara kesişim noktaları (Grid background dots)
    final dotPaint = Paint()..color = const Color(0xFF00FA9A).withOpacity(0.25);
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        canvas.drawCircle(Offset(center.dx + c * 20, center.dy + r * 20), 2.0, dotPaint);
      }
    }

    // Kıvrılan Kesişmeyen Devre Yolu (Neon Circuit Line)
    final path = Path();
    final p1 = Offset(center.dx - radius * 0.75, center.dy + radius * 0.50);
    final p2 = Offset(center.dx - radius * 0.20, center.dy + radius * 0.50);
    final p3 = Offset(center.dx - radius * 0.20, center.dy - radius * 0.10);
    final p4 = Offset(center.dx + radius * 0.40, center.dy - radius * 0.10);
    final p5 = Offset(center.dx + radius * 0.40, center.dy + radius * 0.40);
    final p6 = Offset(center.dx + radius * 0.85, center.dy + radius * 0.40);
    final p7 = Offset(center.dx + radius * 0.85, center.dy - radius * 0.65);

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.lineTo(p4.dx, p4.dy);
    path.lineTo(p5.dx, p5.dy);
    path.lineTo(p6.dx, p6.dy);
    path.lineTo(p7.dx, p7.dy);

    // Dış Neon Parlaması
    final circuitGlow = Paint()
      ..color = const Color(0xFF00FA9A).withOpacity(0.4)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, circuitGlow);

    // Ana Enerji Yolu
    final circuitPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00FA9A), Color(0xFF00D2D3), Color(0xFFFFFFFF)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, circuitPaint);

    // Sayı Düğümleri (Node Pins: 1, 2, 3...)
    final nodes = [p1, p3, p5, p7];
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // Dış halka
      final ring = Paint()
        ..color = const Color(0xFF00FA9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(node, 7.0, ring);

      // İç çekirdek
      final core = Paint()..color = (i == nodes.length - 1) ? const Color(0xFFFFD700) : const Color(0xFFFFFFFF);
      canvas.drawCircle(node, 4.0, core);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
