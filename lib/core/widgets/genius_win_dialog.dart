import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_stats_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'screen_shake.dart';
import 'sketch_badge_icons.dart';
import 'sketch_decorations.dart';
import 'head_to_head_share_dialog.dart';

/// Zühtü - Tamamen Organik Kara Kalem Skeç Defteri Zafer Ekranı Diyaloğu.
/// Sert skeç gölgeleri, 2.5px siyah kontur, el çizimi SketchCard yapısı.
class GeniusWinDialog extends StatefulWidget {
  final GameResult result;
  final String gameTitle;
  final VoidCallback? onRestart;
  final GameStatsUpdateResult? statsResult;
  final bool isPersonalBest;
  final String? personalBestNote;

  const GeniusWinDialog({
    super.key,
    required this.result,
    required this.gameTitle,
    this.onRestart,
    this.statsResult,
    this.isPersonalBest = false,
    this.personalBestNote,
  });

  static Future<void> show(
    BuildContext context, {
    required GameResult result,
    required String gameTitle,
    VoidCallback? onRestart,
    GameStatsUpdateResult? statsResult,
    bool isPersonalBest = false,
    String? personalBestNote,
  }) async {
    ScreenShake.shake(context, intensity: isPersonalBest ? 18.0 : 14.0, duration: const Duration(milliseconds: 600));
    GeniusConfettiOverlay.explode(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GeniusWinDialog(
        result: result,
        gameTitle: gameTitle,
        onRestart: onRestart,
        statsResult: statsResult,
        isPersonalBest: isPersonalBest,
        personalBestNote: personalBestNote,
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
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.pencilBlack;

    final stats = widget.statsResult;
    final int previousIQ = stats?.previousIQ ?? 100;
    final int currentIQ = stats?.currentIQ ?? 102;
    final int iqDelta = currentIQ - previousIQ;

    final double fallbackZ = PsychometricIQCalculator.evaluateSingleSolveZ(
      gameType: widget.result.gameType,
      score: widget.result.score,
      durationMs: widget.result.durationMs,
      difficulty: widget.result.difficulty,
    );
    final int solvePercentile =
        stats?.percentile ?? PsychometricIQCalculator.zScoreToSolvePercentile(fallbackZ);
    final String geniusTitle =
        stats?.geniusTitle ?? PsychometricIQCalculator.titleForIQ(currentIQ, playedCategories: 1);

    final activeMilestone =
        stats?.milestone ?? IQMilestone.currentMilestone(currentIQ) ?? IQMilestone.all.first;
    final nextMilestone = IQMilestone.nextMilestone(currentIQ);
    final isNewMilestone = stats?.milestone != null;

    final BadgeArtType solveBadgeArt = solvePercentile <= 1
        ? BadgeArtType.podiumTrophy
        : (solvePercentile <= 10 ? BadgeArtType.lightning : BadgeArtType.bullseye);
    final String solveBadgeText = solvePercentile <= 1
        ? 'BU OYUN: ZİRVE %1\'LİK ÇÖZÜM'
        : (solvePercentile <= 10
            ? 'BU OYUN: İLK %$solvePercentile\'LİK ÇÖZÜM'
            : 'BU OYUN: İLK %$solvePercentile\'LİK DİLİM');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: SingleChildScrollView(
        child: SketchCard(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          borderColor: isDark ? Colors.white : AppColors.pencilBlack,
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
                borderColor: isDark ? Colors.white : AppColors.pencilBlack,
                borderRadius: 45,
                borderWidth: 2.5,
                shadowOffset: const Offset(3, 3),
                padding: const EdgeInsets.all(14),
                child: const SketchDoodleTrophy(size: 38, color: AppColors.inkBlack),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.75, 0.75),
                    end: const Offset(1.0, 1.0),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  )
                  .shake(duration: 380.ms),

              const SizedBox(height: 12),

              Text(
                'BAŞARIYLA TAMAMLANDI!',
                style: GoogleFonts.patrickHand(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ).animate().scale(duration: 300.ms),

              const SizedBox(height: 6),

              // Tekil Oyun Performansı Yüzdelik Vurgusu veya Yeni Kişisel Zirve Kutlaması
              if (widget.isPersonalBest) ...[
                SketchCard(
                  backgroundColor: isDark ? const Color(0xFFB45309) : AppColors.sunYellow,
                  borderColor: isDark ? Colors.white70 : AppColors.pencilBlack,
                  borderRadius: 12,
                  borderWidth: 2.2,
                  shadowOffset: const Offset(3, 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SketchBadgeIcon(
                        type: BadgeArtType.royalCrown,
                        size: 20,
                        strokeColor: isDark ? Colors.white : AppColors.pencilBlack,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YENİ KİŞİSEL ZİRVE! 🏆',
                              style: GoogleFonts.patrickHand(
                                color: isDark ? Colors.white : AppColors.pencilBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                            if (widget.personalBestNote != null)
                              Text(
                                widget.personalBestNote!,
                                style: GoogleFonts.patrickHand(
                                  color: isDark ? Colors.white70 : AppColors.pencilBlack.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().shimmer(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 8),
              ],

              SketchCard(
                backgroundColor: isDark ? const Color(0xFF9D174D) : AppColors.highlighterPink,
                borderColor: isDark ? Colors.white38 : AppColors.pencilBlack,
                borderRadius: 10,
                borderWidth: 1.8,
                shadowOffset: const Offset(2, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SketchBadgeIcon(
                      type: solveBadgeArt,
                      size: 16,
                      strokeColor: isDark ? Colors.white : AppColors.pencilBlack,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        solveBadgeText,
                        style: GoogleFonts.patrickHand(
                          color: isDark ? Colors.white : AppColors.pencilBlack,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Hareketli Psikometrik IQ ve Sonraki Hedef Motivasyon Kartı
              _buildAnimatedIQMilestoneCard(
                milestone: activeMilestone,
                nextMilestone: nextMilestone,
                previousIQ: previousIQ,
                currentIQ: currentIQ,
                iqDelta: iqDelta,
                isNewMilestone: isNewMilestone,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // İstatistikler Kutusu (Organik SketchCard)
              SketchCard(
                backgroundColor:
                    isDark ? AppColors.surfaceSecondaryDark : AppColors.backgroundLight,
                borderColor: isDark ? Colors.white38 : AppColors.pencilBlack,
                borderRadius: 16,
                borderWidth: 2.0,
                shadowOffset: const Offset(3, 3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    _SketchStatRow(
                      icon: Icons.psychology_rounded,
                      label: 'Genel Zekâ (IQ)',
                      value: '$currentIQ IQ • $geniusTitle',
                      badgeColor: AppColors.highlighterPurple,
                      isDark: isDark,
                    ),
                    Divider(
                        height: 14,
                        color: isDark ? Colors.white24 : AppColors.pencilBlack,
                        thickness: 1.2),
                    _SketchStatRow(
                      icon: Icons.timer_outlined,
                      label: 'Çözüm Süresi',
                      value: GameDateUtils.formatGameTime(widget.result.durationMs),
                      badgeColor: AppColors.skyBlue,
                      isDark: isDark,
                    ),
                    Divider(
                        height: 14,
                        color: isDark ? Colors.white24 : AppColors.pencilBlack,
                        thickness: 1.2),
                    _SketchStatRow(
                      icon: Icons.touch_app_rounded,
                      label: 'Hamle Sayısı',
                      value: '${widget.result.moveCount} Hamle',
                      badgeColor: AppColors.highlighterOrange,
                      isDark: isDark,
                    ),
                    Divider(
                        height: 14,
                        color: isDark ? Colors.white24 : AppColors.pencilBlack,
                        thickness: 1.2),
                    _SketchStatRow(
                      icon: Icons.military_tech_rounded,
                      label: 'Kazanılan Puan',
                      value: '+${widget.result.score} P',
                      badgeColor: AppColors.success,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Kafa Kafaya Meydan Oku & Paylaş Butonu (Viral Büyüme)
              SizedBox(
                width: double.infinity,
                child: SketchCard(
                  backgroundColor: AppColors.sunYellow,
                  borderColor: isDark ? Colors.white : AppColors.pencilBlack,
                  borderRadius: 14,
                  borderWidth: 2.4,
                  shadowOffset: const Offset(3.0, 3.0),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    HeadToHeadShareDialog.show(
                      context,
                      gameType: widget.result.gameType,
                      gameTitle: widget.gameTitle,
                      score: widget.result.score,
                      durationMs: widget.result.durationMs,
                      moveCount: widget.result.moveCount,
                      difficulty: widget.result.difficulty,
                      statsResult: widget.statsResult,
                      fallbackIQ: currentIQ,
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 22, color: AppColors.inkBlack),
                        const SizedBox(width: 8),
                        Text(
                          'Kafa Kafaya Meydan Oku',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.inkBlack,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Aksiyon Butonu (Lobiye Dön)
              SizedBox(
                width: double.infinity,
                child: SketchCard(
                  backgroundColor: isDark ? AppColors.surfaceSecondaryDark : Colors.white,
                  borderColor: isDark ? Colors.white70 : AppColors.pencilBlack,
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(2.5, 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 20,
                          color: isDark ? Colors.white : AppColors.pencilBlack,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lobiye Dön',
                          style: GoogleFonts.patrickHand(
                            color: isDark ? Colors.white : AppColors.pencilBlack,
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
        ),
      ),
    );
  }

  Widget _buildAnimatedIQMilestoneCard({
    required IQMilestone milestone,
    required IQMilestone? nextMilestone,
    required int previousIQ,
    required int currentIQ,
    required int iqDelta,
    required bool isNewMilestone,
    required bool isDark,
  }) {
    final double betterThan = IQMilestone.gaussianBetterThanPercent(currentIQ);
    final double targetPercent = (betterThan / 100.0).clamp(0.06, 1.0);
    final textColor = isDark ? Colors.white : AppColors.pencilBlack;
    final secondaryTextColor = isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite;

    final Color deltaBg = iqDelta > 0
        ? AppColors.success
        : (iqDelta < 0 ? AppColors.highlighterOrange : AppColors.skyBlue);
    final String deltaLabel = iqDelta > 0
        ? '+$iqDelta IQ ARTIŞ!'
        : (iqDelta < 0 ? '$iqDelta IQ' : 'KORUNDU');

    return SketchCard(
      backgroundColor: isNewMilestone
          ? (isDark ? const Color(0xFF451A03).withValues(alpha: 0.6) : const Color(0xFFFFFBEB))
          : (isDark ? AppColors.surfaceSecondaryDark : Colors.white),
      borderColor:
          isDark ? (isNewMilestone ? AppColors.sunYellow : Colors.white38) : AppColors.pencilBlack,
      borderRadius: 14,
      borderWidth: isNewMilestone ? 2.4 : 1.8,
      shadowOffset: const Offset(2.5, 2.5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SketchBadgeMedallion(
                type: milestone.artType,
                accentColor: milestone.artType.defaultAccentColor,
                isUnlocked: true,
                size: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          isNewMilestone ? 'YENİ SEVİYE:' : 'ZEKÂ SEVİYESİ:',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          milestone.title.toUpperCase(),
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isNewMilestone ? AppColors.sunYellow : textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      milestone.message,
                      style: GoogleFonts.patrickHand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Canlı IQ Değişim Etiketi
              SketchCard(
                backgroundColor: deltaBg,
                borderColor: AppColors.pencilBlack,
                borderRadius: 8,
                borderWidth: 1.5,
                shadowOffset: const Offset(1.5, 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: previousIQ.toDouble(), end: currentIQ.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'IQ ${val.round()}',
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkBlack,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          deltaLabel,
                          style: GoogleFonts.patrickHand(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkBlack,
                            height: 1.1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // El Çizimi Taranmış Yükselen Gauss Yüzdelik Çubuğu
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: targetPercent),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return SizedBox(
                      height: 18,
                      child: CustomPaint(
                        painter: _WinSketchProgressPainter(
                          progress: value,
                          strokeColor: isDark ? Colors.white70 : AppColors.pencilBlack,
                          fillColor: AppColors.sunYellow,
                          trackColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%${betterThan.toStringAsFixed(1)} ÜSTÜN',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SketchBadgeIcon(
                type: nextMilestone?.artType ?? BadgeArtType.einsteinBrain,
                size: 15,
                strokeColor: textColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nextMilestone != null
                      ? 'Sonraki Hedef: ${nextMilestone.title} (${nextMilestone.iqThreshold} IQ) • ${nextMilestone.iqThreshold - currentIQ} puan kaldı!'
                      : 'Zirvedesin! 148+ Einstein mertebesini istikrarlı oyunla koru!',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El çizimi çift konturlu ve çapraz taramalı ilerleme çubuğu ressamı
class _WinSketchProgressPainter extends CustomPainter {
  final double progress;
  final Color strokeColor;
  final Color fillColor;
  final Color trackColor;

  _WinSketchProgressPainter({
    required this.progress,
    required this.strokeColor,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(7),
    );

    // Zemin dolgusu
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // İlerleme dolgusu + çapraz kurşun kalem taraması
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0.01) {
      final fillWidth = (size.width - 4) * clamped;
      canvas.save();
      canvas.clipRRect(rrect);

      final fillRect = Rect.fromLTWH(2, 2, fillWidth, size.height - 4);
      canvas.drawRect(fillRect, Paint()..color = fillColor);

      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.18)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;

      for (double x = -size.height; x < fillWidth + size.height; x += 6) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.7, 0),
          hatchPaint,
        );
      }

      // Sağ bitiş kalem çizgisi
      canvas.drawLine(
        Offset(fillWidth + 2, 1),
        Offset(fillWidth + 1.2, size.height - 1),
        Paint()
          ..color = strokeColor
          ..strokeWidth = 1.8,
      );
      canvas.restore();
    }

    // Çift vuruşlu hafif dalgalı el çizimi dış kontur
    final borderPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    final secondStroke = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.8, 1.6, math.max(0, size.width - 3.6), math.max(0, size.height - 3.2)),
      const Radius.circular(6.5),
    );
    canvas.drawRRect(
      secondStroke,
      Paint()
        ..color = strokeColor.withValues(alpha: 0.45)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _WinSketchProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class _SketchStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color badgeColor;
  final bool isDark;

  const _SketchStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.badgeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.pencilBlack;
    final labelColor = isDark ? AppColors.pencilLightDark : AppColors.pencilBlack;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SketchCard(
                padding: const EdgeInsets.all(5),
                borderRadius: 8,
                borderWidth: 1.5,
                shadowOffset: const Offset(1.5, 1.5),
                backgroundColor: badgeColor,
                borderColor: isDark ? Colors.white54 : AppColors.pencilBlack,
                child: Icon(icon, color: AppColors.inkBlack, size: 15),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.patrickHand(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
