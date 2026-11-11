import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../games/common/base_game.dart';
import '../models/user_avatar.dart';
import '../services/game_stats_service.dart';
import '../services/user_avatar_provider.dart';
import '../services/user_nickname_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/share_card_helper.dart';
import 'sketch_badge_icons.dart';
import 'sketch_decorations.dart';

/// LinkedIn & Instagram Benzeri Günlük "Kafa Kafaya" Karşılaştırma ve Meydan Okuma Kartı.
/// Oyuncunun tekil oyun zaferini, WAIS-IV tabanlı yüzdelik başarısını ve zeka skorunu
/// sosyal medyada (WhatsApp, Instagram, X vb.) organik paylaşabileceği skeç tarzı diyalog.
class HeadToHeadShareDialog extends ConsumerStatefulWidget {
  final GameType gameType;
  final String gameTitle;
  final int score;
  final int durationMs;
  final int moveCount;
  final String? difficulty;
  final GameStatsUpdateResult? statsResult;
  final int? fallbackIQ;
  final String? dateId;

  const HeadToHeadShareDialog({
    super.key,
    required this.gameType,
    required this.gameTitle,
    required this.score,
    required this.durationMs,
    required this.moveCount,
    this.difficulty,
    this.statsResult,
    this.fallbackIQ,
    this.dateId,
  });

  static Future<void> show(
    BuildContext context, {
    required GameType gameType,
    required String gameTitle,
    required int score,
    required int durationMs,
    required int moveCount,
    String? difficulty,
    GameStatsUpdateResult? statsResult,
    int? fallbackIQ,
    String? dateId,
  }) async {
    HapticFeedback.mediumImpact();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => HeadToHeadShareDialog(
        gameType: gameType,
        gameTitle: gameTitle,
        score: score,
        durationMs: durationMs,
        moveCount: moveCount,
        difficulty: difficulty,
        statsResult: statsResult,
        fallbackIQ: fallbackIQ,
        dateId: dateId,
      ),
    );
  }

  @override
  ConsumerState<HeadToHeadShareDialog> createState() =>
      _HeadToHeadShareDialogState();
}

class _HeadToHeadShareDialogState extends ConsumerState<HeadToHeadShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Color _getGameColor(GameType type) {
    switch (type) {
      case GameType.queens:
        return AppColors.queensGame;
      case GameType.pinpoint:
        return AppColors.pinpointGame;
      case GameType.crossclimb:
        return AppColors.crossclimbGame;
      case GameType.tango:
        return AppColors.tangoGame;
      case GameType.zipPath:
        return AppColors.zipGame;
      case GameType.patches:
        return AppColors.patchesGame;
    }
  }

  String _buildShareText({
    required String nickname,
    required int betterThanPercent,
    required int solvePercentile,
    required int currentIQ,
    required String geniusTitle,
    required String formattedTime,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🧠 ZÜHTÜ GÜNLÜK ZEKA MEYDAN OKUMASI ⚡');
    buffer.writeln('👤 Oyuncu: @$nickname ($geniusTitle)');
    buffer.writeln('🎮 Oyun: ${widget.gameTitle}');
    buffer.writeln('');
    buffer.writeln('📊 "Bugün Zühtü\'deki oyuncuların %$betterThanPercent\'inden daha hızlı çözdüm!"');
    buffer.writeln('🏆 Derece: İlk %$solvePercentile\'lik elit dilim');
    buffer.writeln('⏱️ Süre: $formattedTime');
    buffer.writeln('🎯 Hamle: ${widget.moveCount}');
    buffer.writeln('🧠 Bilişsel Seviye: $currentIQ IQ');
    buffer.writeln('');
    buffer.writeln('Beni geçebileceğini mi sanıyorsun? 😉');
    buffer.writeln('Hemen Zühtü\'ye gel, günün bulmacasını çöz ve meydan oku!');
    buffer.writeln('👉 https://zuhtu.app');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.backgroundLight;
    final nickname = ref.watch(userNicknameProvider);

    final int currentIQ = widget.statsResult?.currentIQ ?? widget.fallbackIQ ?? 105;
    final double fallbackZ = PsychometricIQCalculator.evaluateSingleSolveZ(
      gameType: widget.gameType,
      score: widget.score,
      durationMs: widget.durationMs,
      difficulty: widget.difficulty,
    );
    final int solvePercentile =
        widget.statsResult?.percentile ?? PsychometricIQCalculator.zScoreToSolvePercentile(fallbackZ);
    final int betterThanPercent = (100 - solvePercentile).clamp(1, 99);
    final String geniusTitle =
        widget.statsResult?.geniusTitle ?? PsychometricIQCalculator.titleForIQ(currentIQ, playedCategories: 1);

    final activeMilestone =
        widget.statsResult?.milestone ?? IQMilestone.currentMilestone(currentIQ) ?? IQMilestone.all.first;

    final formattedTime = GameDateUtils.formatGameTime(widget.durationMs);
    final String dateString = widget.dateId != null
        ? GameDateUtils.getFormattedDate(GameDateUtils.parseLevelId(widget.dateId!))
        : GameDateUtils.getFormattedDate(DateTime.now());

    final shareText = _buildShareText(
      nickname: nickname,
      betterThanPercent: betterThanPercent,
      solvePercentile: solvePercentile,
      currentIQ: currentIQ,
      geniusTitle: geniusTitle,
      formattedTime: formattedTime,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: RepaintBoundary(
              key: _cardKey,
              child: SketchCard(
              backgroundColor: cardBg,
              borderColor: pencilColor,
              borderWidth: 2.8,
              borderRadius: 22,
              shadowOffset: const Offset(5.0, 5.0),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Üst Başlık & Gazete Tarihi Mührü
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.sunYellow,
                        borderColor: pencilColor,
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 24,
                          color: AppColors.inkBlack,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'GÜNLÜK KAFA KAFAYA KART',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              dateString.toUpperCase(),
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGray,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.highlighterPurple,
                        borderColor: pencilColor,
                        child: SketchBadgeIcon(
                          type: activeMilestone.artType,
                          size: 24,
                          strokeColor: pencilColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Oyuncu & Oyun Bilgi Şeridi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: pencilColor, width: 2.0),
                    ),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final avatarId = ref.watch(userAvatarProvider);
                            final userAvatar = UserAvatar.getById(avatarId);
                            return Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: userAvatar.accentColor.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: pencilColor, width: 1.8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                userAvatar.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$nickname',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                '$geniusTitle • $currentIQ IQ',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getGameColor(widget.gameType),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: pencilColor, width: 1.6),
                          ),
                          child: Text(
                            widget.gameTitle,
                            style: GoogleFonts.patrickHand(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onColor(_getGameColor(widget.gameType), context: context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Büyük Vurucu İstatistik (LinkedIn Style Viral Punchline)
                  SketchCard(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                    borderColor: pencilColor,
                    borderRadius: 16,
                    borderWidth: 2.4,
                    shadowOffset: const Offset(3.5, 3.5),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'BUGÜN ZÜHTÜ\'DEKİ OYUNCULARIN',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⚡ ', style: TextStyle(fontSize: 22)),
                              Text(
                                '%$betterThanPercent\'İNDEN DAHA HIZLI!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.sunYellow : const Color(0xFFB45309),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: pencilColor, width: 1.5),
                          ),
                          child: Text(
                            'İlk %$solvePercentile\'lik elit çözüm dilimi • $currentIQ IQ 🧠',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: pencilColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 14),

                  // 4. Üçlü Çözüm Metrikleri (Süre, Hamle, Puan)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricSketchBox(
                          icon: Icons.timer_outlined,
                          label: 'SÜRE',
                          value: formattedTime,
                          bgColor: AppColors.skyBlue,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricSketchBox(
                          icon: Icons.touch_app_outlined,
                          label: 'HAMLE',
                          value: '${widget.moveCount}',
                          bgColor: AppColors.highlighterOrange,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricSketchBox(
                          icon: Icons.psychology_outlined,
                          label: 'ZEKÂ',
                          value: '$currentIQ IQ',
                          bgColor: AppColors.highlighterPurple,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 5. Meydan Okuma Çağrısı (Challenge Box)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pencilColor.withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Beni geçebileceğini mi sanıyorsun? 😉 Zühtü\'ye gel, günün bulmacasını çöz ve meydan oku!',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 6. Eylemler (Paylaş, Kopyala, Kapat)
                  Row(
                    children: [
                      // Metni Kopyala Butonu
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              await Clipboard.setData(ClipboardData(text: shareText));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '📋 Meydan okuma metni kopyalandı! Arkadaşlarına meydan oku 🎯',
                                      style: GoogleFonts.patrickHand(fontSize: 15),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pencilColor, width: 2.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: pencilColor.withValues(alpha: 0.2),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 17, color: AppColors.inkBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Kopyala',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Kafa Kafaya Paylaş Butonu (WhatsApp / Instagram / Sosyal Medya)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSharing
                                ? null
                                : () async {
                                    setState(() => _isSharing = true);
                                    HapticFeedback.heavyImpact();
                                    try {
                                      final success =
                                          await ShareCardHelper.shareCard(
                                        boundaryKey: _cardKey,
                                        shareText: shareText,
                                        subject:
                                            '🧠 Zühtü Zeka Meydan Okuması: @$nickname',
                                        fileName: 'zuhtu_meydan_okuma.png',
                                      );
                                      if (!success && mounted) {
                                        await Clipboard.setData(
                                            ClipboardData(text: shareText));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Görsel paylaşılamadı, metin panoya kopyalandı! 📋',
                                              style: GoogleFonts.patrickHand(
                                                  fontSize: 15),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          '[HeadToHeadShareDialog] Paylaşım hatası: $e');
                                      await Clipboard.setData(
                                          ClipboardData(text: shareText));
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Meydan okuma metni panoya kopyalandı!',
                                              style: GoogleFonts.patrickHand(
                                                  fontSize: 15),
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isSharing = false);
                                      }
                                    }
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.sunYellow,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: pencilColor, width: 2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: pencilColor.withValues(alpha: 0.25),
                                    offset: const Offset(2.5, 2.5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isSharing)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.inkBlack),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.share_rounded,
                                          size: 18, color: AppColors.inkBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSharing
                                          ? 'Hazırlanıyor...'
                                          : 'Meydan Oku',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Kapat Butonu (Tam Genişlik)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: pencilColor, width: 1.8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Kapat',
                          style: GoogleFonts.patrickHand(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: pencilColor,
                          ),
                        ),
                      ),
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
}

class _MetricSketchBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color pencilColor;
  final bool isDark;

  const _MetricSketchBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.pencilColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isDark ? 0.22 : 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pencilColor, width: 1.6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: pencilColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: pencilColor,
            ),
          ),
        ],
      ),
    );
  }
}
