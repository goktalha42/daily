import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_stats_service.dart';
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
  final GameStatsUpdateResult? statsResult;

  const GeniusWinDialog({
    super.key,
    required this.result,
    required this.gameTitle,
    required this.onRestart,
    this.statsResult,
  });

  static Future<void> show(
    BuildContext context, {
    required GameResult result,
    required String gameTitle,
    required VoidCallback onRestart,
    GameStatsUpdateResult? statsResult,
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
        statsResult: statsResult,
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
    final stats = widget.statsResult;
    final int currentIQ = stats?.currentIQ ?? 115;
    final int percentile = stats?.percentile ??
        (widget.result.score >= 1000 ? 1 : (widget.result.score >= 800 ? 5 : 20));
    final String geniusTitle = stats?.geniusTitle ?? (percentile <= 5 ? 'Üstün Zekâ' : 'Ortalama Üstü');

    final activeMilestone = stats?.milestone ?? IQMilestone.currentMilestone(currentIQ) ?? IQMilestone.all.first;
    final isNewMilestone = stats?.milestone != null;

    final String percentileBadgeText = percentile <= 1
        ? '🏆 ZİRVE %1\'LİK DİLİM'
        : '🎯 İLK %$percentile\'LİK DİLİM';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: SingleChildScrollView(
        child: SketchCard(
          backgroundColor: Colors.white,
          borderRadius: 22,
          borderWidth: 2.8,
          shadowOffset: const Offset(5.5, 5.5),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El Çizimi Eskiz Zafer Rozeti
              SketchCard(
                backgroundColor: AppColors.sunYellow,
                borderRadius: 45,
                borderWidth: 2.5,
                shadowOffset: const Offset(3, 3),
                padding: const EdgeInsets.all(14),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.pencilBlack,
                  size: 40,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.06, duration: 600.ms, curve: Curves.easeInOut)
                  .animate()
                  .shake(duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                'BÖLÜM TAMAMLANDI! 🎉',
                style: GoogleFonts.patrickHand(
                  fontSize: 26,
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
                  '$percentileBadgeText 🏆',
                  style: GoogleFonts.patrickHand(
                    color: AppColors.pencilBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 🚀 HAREKETLİ IQ VE OYUNCU KARŞILAŞTIRMA GRAFİĞİ (KULLANICI TALEBİ!)
              _buildAnimatedIQMilestoneCard(
                milestone: activeMilestone,
                currentIQ: currentIQ,
                isNewMilestone: isNewMilestone,
              ),

              const SizedBox(height: 14),

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
                      value: '$currentIQ IQ • $geniusTitle',
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

              const SizedBox(height: 18),

              // Lobiye Dön Butonu
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
      ),
    );
  }

  Widget _buildAnimatedIQMilestoneCard({
    required IQMilestone milestone,
    required int currentIQ,
    required bool isNewMilestone,
  }) {
    final double targetPercent = (milestone.betterThanPercent / 100.0).clamp(0.05, 1.0);

    return SketchCard(
      backgroundColor: isNewMilestone ? const Color(0xFFFFFBEB) : Colors.white,
      borderRadius: 14,
      borderWidth: isNewMilestone ? 2.4 : 1.8,
      shadowOffset: const Offset(2.5, 2.5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                milestone.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isNewMilestone ? 'YENİ SEVİYE: ' : 'ZEKÂ GRAFİĞİ: ',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          milestone.title.toUpperCase(),
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isNewMilestone ? AppColors.sunYellow : AppColors.pencilBlack,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      milestone.message,
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hareketli Yükselen Karşılaştırma Çubuğu
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: targetPercent),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.sunYellow,
                              border: Border(
                                right: BorderSide(color: AppColors.pencilBlack, width: 1.8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%${milestone.betterThanPercent.toStringAsFixed(milestone.betterThanPercent % 1 == 0 ? 0 : 1)} ÜSTÜN',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilBlack,
                ),
              ),
            ],
          ),
        ],
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
