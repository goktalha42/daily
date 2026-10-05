import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'screen_shake.dart';

/// Zühtü - Kara Kalem Skeç Defteri Zafer Ekranı Diyaloğu.
/// Sert skeç gölgeleri, 2.5px siyah kontur ve Patrick Hand tipografisi.
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.pencilBlack,
            width: 2.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pencilBlack,
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fosforlu Skeç Zafer Kupası
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.highlighterYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pencilBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pencilBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.pencilBlack,
                    size: 46,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.06, duration: 600.ms, curve: Curves.easeInOut)
                  .animate()
                  .shake(duration: 400.ms),

              const SizedBox(height: 14),

              // Vurgu Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.highlighterOrange,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                ),
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

              const SizedBox(height: 6),

              Text(
                'BÖLÜM TAMAMLANDI! 🎉',
                style: GoogleFonts.patrickHand(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilBlack,
                ),
                textAlign: TextAlign.center,
              ).animate().scale(duration: 300.ms),

              const SizedBox(height: 4),

              // Yüzdelik Dilim Vurgusu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.highlighterPink,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                ),
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

              // İstatistikler Kutusu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                ),
                child: Column(
                  children: [
                    _SketchStatRow(
                      icon: Icons.psychology_rounded,
                      label: 'Zeka Endeksi (IQ)',
                      value: '$iqScore DAHİ',
                      badgeColor: AppColors.highlighterPurple,
                    ),
                    const Divider(height: 14, color: AppColors.pencilBlack, thickness: 1.2),
                    _SketchStatRow(
                      icon: Icons.timer_outlined,
                      label: 'Çözüm Süresi',
                      value: GameDateUtils.formatGameTime(widget.result.durationMs),
                      badgeColor: AppColors.highlighterCyan,
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
                      badgeColor: AppColors.highlighterGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Aksiyon Butonları (Skeç Butonlar)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.pencilBlack, width: 2.2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pencilBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Lobiye Dön',
                            style: GoogleFonts.patrickHand(
                              color: AppColors.pencilBlack,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onRestart();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.highlighterYellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.pencilBlack, width: 2.2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pencilBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded, size: 20, color: AppColors.pencilBlack),
                            const SizedBox(width: 6),
                            Text(
                              'Tekrar Oyna',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilBlack,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pencilBlack, width: 1.5),
          ),
          child: Icon(icon, size: 16, color: AppColors.pencilBlack),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 16,
              color: AppColors.pencilGraphite,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.patrickHand(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.pencilBlack,
          ),
        ),
      ],
    );
  }
}
