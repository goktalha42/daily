import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ADHD dostu, yüksek dopaminli dinamik ekran sarsıntısı (Camera Shake) bileşeni.
class ScreenShake extends StatefulWidget {
  final Widget child;

  const ScreenShake({
    super.key,
    required this.child,
  });

  /// Ekran sarsıntısını tetiklemek için global yardımcı
  static void shake(BuildContext context, {double intensity = 12.0, Duration duration = const Duration(milliseconds: 650)}) {
    final state = context.findAncestorStateOfType<ScreenShakeState>();
    state?.triggerShake(intensity: intensity, duration: duration);
  }

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _intensity = 12.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void triggerShake({double intensity = 12.0, Duration duration = const Duration(milliseconds: 650)}) {
    _intensity = intensity;
    _controller.duration = duration;
    _controller.forward(from: 0.0);
    
    // Güçlü haptik geri bildirim
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 220), () => HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) {
      return widget.child;
    }

    // Sönümlü sinüs sarsıntı matematiği
    final progress = _controller.value;
    final decay = 1.0 - progress; // Zamanla azalan şiddet
    final dx = math.sin(progress * math.pi * 14) * _intensity * decay;
    final dy = math.cos(progress * math.pi * 12) * (_intensity * 0.7) * decay;
    final rotation = math.sin(progress * math.pi * 8) * (0.015 * decay);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotation,
        child: widget.child,
      ),
    );
  }
}

/// Dopamin patlaması sağlayan konfeti / parçacık patlaması efekti
class GeniusConfettiOverlay extends StatefulWidget {
  final Widget child;

  const GeniusConfettiOverlay({super.key, required this.child});

  static void explode(BuildContext context) {
    final state = context.findAncestorStateOfType<_GeniusConfettiOverlayState>();
    state?.explode();
  }

  @override
  State<GeniusConfettiOverlay> createState() => _GeniusConfettiOverlayState();
}

class _GeniusConfettiOverlayState extends State<GeniusConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void explode() {
    _particles.clear();
    final colors = [
      const Color(0xFFFFB800), // Gold
      const Color(0xFFFF3366), // Pink
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF00FA9A), // Emerald
      Colors.white,
    ];

    for (int i = 0; i < 65; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 180 + _random.nextDouble() * 450;
      final size = 6.0 + _random.nextDouble() * 8.0;
      final color = colors[_random.nextInt(colors.length)];
      final rotationSpeed = (_random.nextDouble() - 0.5) * 15;

      _particles.add(_ConfettiParticle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 200, // Yukarı doğru ilk fırlama
        size: size,
        color: color,
        rotationSpeed: rotationSpeed,
      ));
    }

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_animController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  progress: _animController.value,
                  particles: _particles,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final gravity = 550.0 * progress; // Yerçekimi ivmesi
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (var p in particles) {
      final x = center.dx + p.vx * progress;
      final y = center.dy + (p.vy * progress) + (0.5 * gravity * progress);
      final rot = progress * p.rotationSpeed;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
