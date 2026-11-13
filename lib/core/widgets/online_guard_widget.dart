import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../network/network_checker.dart';
import '../theme/app_colors.dart';
import 'sketch_decorations.dart';

/// İnternet bağlantısı olmadığında uygulamaya girişi tamamen engelleyen
/// ve el çizimi eskiz uyarısı gösteren koruyucu sarmalayıcı.
class OnlineGuardWidget extends ConsumerWidget {
  final Widget child;

  const OnlineGuardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkCheckerProvider);

    if (!isOnline) {
      return const NoInternetSketchScreen();
    }

    return child;
  }
}

/// İnternetsiz giriş denemelerinde gösterilen %100 el çizimi eskiz uyarı ekranı.
class NoInternetSketchScreen extends ConsumerStatefulWidget {
  const NoInternetSketchScreen({super.key});

  @override
  ConsumerState<NoInternetSketchScreen> createState() =>
      _NoInternetSketchScreenState();
}

class _NoInternetSketchScreenState
    extends ConsumerState<NoInternetSketchScreen> {
  bool _isChecking = false;

  Future<void> _retryConnection() async {
    if (_isChecking) return;
    HapticFeedback.mediumImpact();
    setState(() => _isChecking = true);

    final ok = await ref.read(networkCheckerProvider.notifier).checkNow();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hâlâ internet bağlantısı algılanamadı. Lütfen ağınızı kontrol edin.',
            style: GoogleFonts.patrickHand(fontSize: 15),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final pencilColor = AppColors.pencil(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Üst El Çizimi Durum Etiketi
                    SketchCard(
                      borderRadius: 10,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: AppColors.tangoGame,
                      borderColor: pencilColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 17,
                            color: AppColors.inkBlack,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ÇEVRİMDIŞI GİRİŞ KAPALI',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkBlack,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ana El Çizimi Eskiz Uyarı Kartı
                    SketchCard(
                      enableHatching: true,
                      borderRadius: 18,
                      borderWidth: 2.5,
                      shadowOffset: const Offset(4.0, 4.0),
                      backgroundColor: isDark
                          ? AppColors.cardBgDark
                          : AppColors.backgroundLight,
                      borderColor: pencilColor,
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // El çizimi kopuk bağlantı & bulut illüstrasyonu
                          SizedBox(
                            width: 150,
                            height: 112,
                            child: CustomPaint(
                              painter: _SketchOfflineIllustrationPainter(
                                pencilColor: pencilColor,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            'İnternetsiz Giriş Yapılamaz!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.patrickHand(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: pencilColor,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            'Zühtü Arenası’nda günlük bulmacalar, canlı lig puanları ve adil sıralama için aktif internet bağlantısı zorunludur. İnternet olmadan uygulamaya giriş yapılamaz.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.graphite(context),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // El çizimi kontrol listesi kutusu
                          SketchCard(
                            borderRadius: 12,
                            borderWidth: 1.6,
                            shadowOffset: const Offset(1.5, 1.5),
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFFEF9C3),
                            borderColor: pencilColor.withValues(alpha: 0.75),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckRow(
                                  context,
                                  'Wi-Fi veya Mobil Veri bağlantınızı açın.',
                                ),
                                const SizedBox(height: 6),
                                _buildCheckRow(
                                  context,
                                  'Uçak modunun kapalı olduğundan emin olun.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Yeniden Bağlan Eskiz Butonu
                          SketchCard(
                            onTap: _isChecking ? null : _retryConnection,
                            borderRadius: 12,
                            borderWidth: 2.2,
                            shadowOffset: const Offset(3.0, 3.0),
                            backgroundColor: AppColors.sunYellow,
                            borderColor: pencilColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isChecking)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.inkBlack),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                      color: AppColors.inkBlack,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isChecking
                                        ? 'Bağlantı Kontrol Ediliyor...'
                                        : 'Bağlantıyı Kontrol Et',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.inkBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.edit_rounded,
            size: 14,
            color: AppColors.pencil(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.pencil(context),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// El çizimi kopuk Wi-Fi / bulut & çarpı işareti çizen eskiz ressamı.
class _SketchOfflineIllustrationPainter extends CustomPainter {
  final Color pencilColor;
  final bool isDark;

  _SketchOfflineIllustrationPainter({
    required this.pencilColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Arka vurgu lekesi (pastel sarı/mercan kurşun kalem gölgesi)
    final blobPaint = Paint()
      ..color = AppColors.sunYellow.withValues(alpha: isDark ? 0.22 : 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.52), width: w * 0.78, height: h * 0.74),
      blobPaint,
    );

    // El çizimi bulut konturu (çift vuruşlu eskiz)
    final cloudPath = Path()
      ..moveTo(w * 0.24, h * 0.68)
      ..cubicTo(w * 0.12, h * 0.68, w * 0.10, h * 0.46, w * 0.24, h * 0.42)
      ..cubicTo(w * 0.26, h * 0.22, w * 0.48, h * 0.16, w * 0.58, h * 0.30)
      ..cubicTo(w * 0.68, h * 0.22, w * 0.84, h * 0.32, w * 0.80, h * 0.46)
      ..cubicTo(w * 0.90, h * 0.50, w * 0.88, h * 0.68, w * 0.74, h * 0.68)
      ..close();

    final fillPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(cloudPath, fillPaint);

    final stroke1 = Paint()
      ..color = pencilColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stroke2 = Paint()
      ..color = pencilColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(cloudPath, stroke1);
    canvas.save();
    canvas.translate(1.4, 1.2);
    canvas.drawPath(cloudPath, stroke2);
    canvas.restore();

    // Bulut içinde kesik Wi-Fi yayları
    final arcPaint = Paint()
      ..color = pencilColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 0.50, h * 0.58);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 18),
      -2.45,
      1.75,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 11),
      -2.35,
      1.55,
      false,
      arcPaint,
    );
    canvas.drawCircle(center, 2.5, Paint()..color = pencilColor);

    // El çizimi kırmızı/mercan çarpı (X) damgası
    final xPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.34, h * 0.32),
      Offset(w * 0.66, h * 0.66),
      xPaint,
    );
    canvas.drawLine(
      Offset(w * 0.66, h * 0.32),
      Offset(w * 0.34, h * 0.66),
      xPaint,
    );

    // Eskiz kalem kıvılcım çizgileri (dışarıda küçük karalamalar)
    final doodlePaint = Paint()
      ..color = pencilColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.14, h * 0.24), Offset(w * 0.20, h * 0.30), doodlePaint);
    canvas.drawLine(Offset(w * 0.85, h * 0.22), Offset(w * 0.79, h * 0.28), doodlePaint);
    canvas.drawLine(Offset(w * 0.42, h * 0.82), Offset(w * 0.58, h * 0.82), doodlePaint);
  }

  @override
  bool shouldRepaint(covariant _SketchOfflineIllustrationPainter oldDelegate) {
    return oldDelegate.pencilColor != pencilColor ||
        oldDelegate.isDark != isDark;
  }
}
