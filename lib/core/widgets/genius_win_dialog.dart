import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'screen_shake.dart';
import 'sketch_decorations.dart';

/// Zühtü - Tamamen Organik Kara Kalem Skeç Defteri Zafer Ekranı Diyaloğu.
/// Sert skeç gölgeleri, 2.5px siyah kontur, el çizimi SketchCard yapısı.
class GeniusWinDialog extends StatefulWidget {
  final GameResult result;
  final String gameTitle;
  final VoidCallback onRestart;

  const GeniusWinDialog({
    super.key,
    required this.result,
    required this.gameTitle,
    required this.onRestart,
  });

  static Future<void> show(
    BuildContext context, {
    required GameResult result,
    required String gameTitle,
    required VoidCallback onRestart,
  }) async {
    // Ekranı sars ve konfeti patlat
    ScreenShake.shake(context, intensity: 14.0, duration: const Duration(milliseconds: 600));
    GeniusConfettiOverlay.explode(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GeniusWinDialog(
        result: result,
        gameTitle: gameTitle,
        onRestart: onRestart,
      ),
    );
  }

  @override
  State<GeniusWinDialog> createState() => _GeniusWinDialogState();
}

class _GeniusWinDialogState extends State<GeniusWinDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTopTier = widget.result.durationMs < 60000 || widget.result.score > 800;
    final percentileStr = isTopTier ? "%1'LİK" : "%2'LİK";
    final iqScore = isTopTier ? "152+" : "146+";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SketchCard(
        backgroundColor: Colors.white,
        borderRadius: 22,
        borderWidth: 2.8,
        shadowOffset: const Offset(5.5, 5.5),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // El Çizimi Eskiz Zafer Rozeti
            SketchCard(
              backgroundColor: AppColors.sunYellow,
              borderRadius: 45,
              borderWidth: 2.5,
              shadowOffset: const Offset(3, 3),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.pencilBlack,
                size: 44,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.06, duration: 600.ms, curve: Curves.easeInOut)
                .animate()
                .shake(duration: 400.ms),

            const SizedBox(height: 14),

            // Vurgu Rozeti (El Çizimi SketchCard)
            SketchCard(
              backgroundColor: AppColors.highlighterOrange,
              borderRadius: 10,
              borderWidth: 2.0,
              shadowOffset: const Offset(2, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.pencilBlack, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'HARİKA PERFORMANS!',
                    style: GoogleFonts.patrickHand(
                      color: AppColors.pencilBlack,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 8),

            Text(
              'BÖLÜM TAMAMLANDI! 🎉',
              style: GoogleFonts.patrickHand(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.pencilBlack,
              ),
              textAlign: TextAlign.center,
            ).animate().scale(duration: 300.ms),

            const SizedBox(height: 6),

            // Yüzdelik Dilim Vurgusu
            SketchCard(
              backgroundColor: AppColors.highlighterPink,
              borderRadius: 10,
              borderWidth: 1.8,
              shadowOffset: const Offset(2, 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'EN İYİ $percentileStr DİLİMDESİN 🏆',
                style: GoogleFonts.patrickHand(
                  color: AppColors.pencilBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // İstatistikler Kutusu (Organik SketchCard)
            SketchCard(
              backgroundColor: AppColors.backgroundLight,
              borderRadius: 16,
              borderWidth: 2.0,
              shadowOffset: const Offset(3, 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  _SketchStatRow(
                    icon: Icons.psychology_rounded,
                    label: 'Zeka Endeksi (IQ)',
                    value: '$iqScore ZÜHTÜ',
                    badgeColor: AppColors.highlighterPurple,
                  ),
                  const Divider(height: 14, color: AppColors.pencilBlack, thickness: 1.2),
                  _SketchStatRow(
                    icon: Icons.timer_outlined,
                    label: 'Çözüm Süresi',
                    value: GameDateUtils.formatGameTime(widget.result.durationMs),
                    badgeColor: AppColors.skyBlue,
                  ),
                  const Divider(height: 14, color: AppColors.pencilBlack, thickness: 1.2),
                  _SketchStatRow(
                    icon: Icons.touch_app_rounded,
                    label: 'Hamle Sayısı',
                    value: '${widget.result.moveCount} Hamle',
                    badgeColor: AppColors.highlighterOrange,
                  ),
                  const Divider(height: 14, color: AppColors.pencilBlack, thickness: 1.2),
                  _SketchStatRow(
                    icon: Icons.military_tech_rounded,
                    label: 'Kazanılan Puan',
                    value: '+${widget.result.score} P',
                    badgeColor: const Color(0xFF34D399),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tek Buton: Lobiye Dön (Kullanıcı Talebi: Tekrar Oyna Butonu Kaldırıldı!)
            SketchCard(
              backgroundColor: AppColors.sunYellow,
              borderRadius: 14,
              borderWidth: 2.2,
              shadowOffset: const Offset(3.5, 3.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 20, color: AppColors.pencilBlack),
                    const SizedBox(width: 8),
                    Text(
                      'Lobiye Dön',
                      style: GoogleFonts.patrickHand(
                        color: AppColors.pencilBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color badgeColor;

  const _SketchStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pencilBlack, width: 1.6),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.pencilBlack, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.patrickHand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.pencilBlack,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.patrickHand(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.pencilBlack,
          ),
        ),
      ],
    );
  }
}
