import 'dart:math' as math;
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
/// Oyuncunun tekil oyun zaferini, yüzdelik başarısını ve zeka skorunu
/// WhatsApp, Instagram ve sosyal medyada organik paylaşabileceği el çizimi skeç kartpostalı.
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
    buffer.writeln('🏆 Derece: İlk %$solvePercentile\'lik dilim');
    buffer.writeln('⏱️ Süre: $formattedTime');
    buffer.writeln('🎯 Hamle: ${widget.moveCount}');
    buffer.writeln('🧠 Zeka Skoru: $currentIQ Puan');
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
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. REPAINT BOUNDARY: %100 EL ÇİZİMİ MEYDAN OKUMA KARTPOSTALI
                RepaintBoundary(
                  key: _cardKey,
                  child: CustomPaint(
                    painter: _SketchHeadToHeadPostcardPainter(
                      isDark: isDark,
                      pencilColor: pencilColor,
                      dateString: dateString,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ÜST BAŞLIK VE TARİH ŞERİDİ
                          Row(
                            children: [
                              SketchCard(
                                padding: const EdgeInsets.all(7),
                                borderRadius: 10,
                                borderWidth: 1.8,
                                shadowOffset: const Offset(1.5, 1.5),
                                backgroundColor: AppColors.sunYellow,
                                borderColor: pencilColor,
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  size: 20,
                                  color: AppColors.inkBlack,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GÜNLÜK KAFA KAFAYA KART',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: pencilColor,
                                        letterSpacing: 0.8,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      dateString.toUpperCase(),
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.pencilWhite.withValues(alpha: 0.7)
                                            : AppColors.pencilGraphite,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SketchCard(
                                padding: const EdgeInsets.all(6),
                                borderRadius: 10,
                                borderWidth: 1.8,
                                shadowOffset: const Offset(1.5, 1.5),
                                backgroundColor: AppColors.highlighterPurple,
                                borderColor: pencilColor,
                                child: SketchBadgeIcon(
                                  type: activeMilestone.artType,
                                  size: 22,
                                  strokeColor: pencilColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // OYUNCU VE OYUN BİLGİ ŞERİDİ (SKETCH CARD)
                          SketchCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            borderRadius: 12,
                            borderWidth: 1.8,
                            shadowOffset: const Offset(2, 2),
                            backgroundColor: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderColor: pencilColor,
                            child: Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    final avatarId = ref.watch(userAvatarProvider);
                                    final userAvatar = UserAvatar.getById(avatarId);
                                    return Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: userAvatar.accentColor
                                            .withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: pencilColor, width: 1.6),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        userAvatar.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@$nickname',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: pencilColor,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        '$geniusTitle • $currentIQ Puan',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.pencilLightDark
                                              : AppColors.pencilGraphite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: _getGameColor(widget.gameType),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: pencilColor, width: 1.4),
                                  ),
                                  child: Text(
                                    widget.gameTitle,
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onColor(
                                          _getGameColor(widget.gameType),
                                          context: context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // BÜYÜK VURUCU İSTATİSTİK KARTI (PUNCHLINE)
                          SketchCard(
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFFEF3C7),
                            borderColor: pencilColor,
                            borderRadius: 14,
                            borderWidth: 2.2,
                            shadowOffset: const Offset(3, 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Column(
                              children: [
                                Text(
                                  'BUGÜN ZÜHTÜ\'DEKİ OYUNCULARIN',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.pencilLightDark
                                        : AppColors.pencilGraphite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('⚡ ',
                                          style: TextStyle(fontSize: 20)),
                                      Text(
                                        '%$betterThanPercent\'İNDEN DAHA HIZLI!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.sunYellow
                                              : const Color(0xFFB45309),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SketchCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  borderRadius: 8,
                                  borderWidth: 1.3,
                                  shadowOffset: const Offset(1, 1),
                                  backgroundColor: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  borderColor: pencilColor,
                                  child: Text(
                                    'İlk %$solvePercentile\'lik dilim • $currentIQ Zühtü Skoru 🧠',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: pencilColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                                duration: 350.ms,
                                curve: Curves.easeOutBack,
                              ),

                          const SizedBox(height: 12),

                          // ÜÇLÜ ÇÖZÜM METRİKLERİ (SÜRE, HAMLE, PUAN)
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricPill(
                                  icon: Icons.timer_outlined,
                                  label: 'SÜRE',
                                  value: formattedTime,
                                  bgColor: AppColors.skyBlue,
                                  pencilColor: pencilColor,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildMetricPill(
                                  icon: Icons.touch_app_outlined,
                                  label: 'HAMLE',
                                  value: '${widget.moveCount}',
                                  bgColor: AppColors.highlighterOrange,
                                  pencilColor: pencilColor,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildMetricPill(
                                  icon: Icons.psychology_outlined,
                                  label: 'SKOR',
                                  value: '$currentIQ P',
                                  bgColor: AppColors.highlighterPurple,
                                  pencilColor: pencilColor,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // MEYDAN OKUMA NOTU (CHALLENGE BOX)
                          SketchCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            borderRadius: 10,
                            borderWidth: 1.4,
                            shadowOffset: const Offset(1.5, 1.5),
                            backgroundColor: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            borderColor: pencilColor,
                            child: Row(
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Beni geçebileceğini mi sanıyorsun? 😉 Zühtü\'ye gel kapışalım!',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: pencilColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // WATERMARK
                          Center(
                            child: Text(
                              '👉 zuhtu.app • Her Gece 00:00\'da Yeni Bulmacalar ⚡',
                              style: GoogleFonts.patrickHand(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.pencilWhite.withValues(alpha: 0.7)
                                    : AppColors.pencilGraphite,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. EYLEM BUTONLARI (METİN, GÖRSEL MEYDAN OKU, KAPAT)
                Row(
                  children: [
                    // Metni Kopyala Butonu
                    Expanded(
                      flex: 4,
                      child: SketchCard(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await Clipboard.setData(
                              ClipboardData(text: shareText));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '📋 Meydan okuma metni kopyalandı!',
                                  style: GoogleFonts.patrickHand(fontSize: 15),
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: 12,
                        borderWidth: 1.8,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.skyBlue,
                        borderColor: pencilColor,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy_rounded,
                                  size: 16, color: AppColors.inkBlack),
                              const SizedBox(width: 5),
                              Text(
                                'Kopyala',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inkBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kafa Kafaya Görsel Paylaş Butonu (WhatsApp / Instagram)
                    Expanded(
                      flex: 6,
                      child: SketchCard(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: 12,
                        borderWidth: 2.2,
                        shadowOffset: const Offset(2.5, 2.5),
                        backgroundColor: AppColors.sunYellow,
                        borderColor: pencilColor,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.inkBlack),
                                  ),
                                )
                              else
                                const Icon(Icons.share_rounded,
                                    size: 17, color: AppColors.inkBlack),
                              const SizedBox(width: 6),
                              Text(
                                _isSharing ? 'Hazırlanıyor...' : 'Meydan Oku',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.inkBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kapat Butonu
                    Expanded(
                      flex: 3,
                      child: SketchCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: 12,
                        borderWidth: 1.8,
                        shadowOffset: const Offset(1.5, 1.5),
                        backgroundColor: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                        borderColor: pencilColor,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Kapat',
                            style: GoogleFonts.patrickHand(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: pencilColor,
                            ),
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
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color pencilColor,
    required bool isDark,
  }) {
    return SketchCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      borderRadius: 10,
      borderWidth: 1.4,
      shadowOffset: const Offset(1.5, 1.5),
      backgroundColor: bgColor.withValues(alpha: isDark ? 0.25 : 0.3),
      borderColor: pencilColor,
      child: Column(
        children: [
          Icon(icon, size: 16, color: pencilColor),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.pencilLightDark
                  : AppColors.pencilGraphite,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: pencilColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// %100 El Çizimi Kafa Kafaya Meydan Okuma Kartpostalı Ressamı.
/// Çizgili/kareli defter dokusu, sol kenarda delikli spiral delikleri, kırmızı marjin çizgisi,
/// washi bant ve sağ üstte el çizimi posta damgası çizer.
class _SketchHeadToHeadPostcardPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;
  final String dateString;

  _SketchHeadToHeadPostcardPainter({
    required this.isDark,
    required this.pencilColor,
    required this.dateString,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Zemin Eskiz Kağıdı
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFFAF7EE);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Kareli Defter Izgarası
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.pencilBlack)
          .withValues(alpha: isDark ? 0.04 : 0.032)
      ..strokeWidth = 1.0;
    const double step = 20.0;
    for (double y = 14; y < size.height - 10; y += step) {
      canvas.drawLine(Offset(30, y), Offset(size.width - 10, y), gridPaint);
    }
    for (double x = 30; x < size.width - 10; x += step) {
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), gridPaint);
    }

    // 3. Sol Kenar Kırmızı El Çizimi Marjin Çizgisi
    final marginPaint = Paint()
      ..color = (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444))
          .withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    final marginPath = Path();
    marginPath.moveTo(32, 0);
    for (double y = 0; y <= size.height; y += 30) {
      final wobble = math.sin(y * 0.08) * 0.7;
      marginPath.lineTo(32 + wobble, y);
    }
    canvas.drawPath(marginPath, marginPaint);

    // 4. Sol Kenar Defter Delikleri (Spiral Holes)
    final holePaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final holeBorder = Paint()
      ..color = pencilColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double holeSpacing = 32.0;
    for (double y = 28; y < size.height - 20; y += holeSpacing) {
      canvas.drawCircle(Offset(15, y), 5.0, holePaint);
      canvas.drawCircle(Offset(15, y), 5.0, holeBorder);
    }

    // 5. Organik Çift Vuruşlu El Çizimi Dış Çerçeve
    _drawWobblyDoubleBorder(canvas, size, pencilColor);

    // 6. Üst Ortada Washi Bant
    _drawWashiTape(canvas, size);

    // 7. Sağ Üst El Çizimi Posta Damgası
    _drawPostmarkStamp(canvas, Offset(size.width - 42, 38));
  }

  void _drawWobblyDoubleBorder(Canvas canvas, Size size, Color color) {
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path1 = Path();
    path1.moveTo(10, 10);
    path1.lineTo(size.width - 10, 10 + math.sin(size.width * 0.01) * 0.8);
    path1.lineTo(size.width - 10, size.height - 10);
    path1.lineTo(10, size.height - 10 + math.sin(size.height * 0.01) * 0.8);
    path1.close();
    canvas.drawPath(path1, borderPaint);

    final secondPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    path2.moveTo(11, 11);
    path2.lineTo(size.width - 11, 11);
    path2.lineTo(size.width - 11, size.height - 11);
    path2.lineTo(11, size.height - 11);
    path2.close();
    canvas.drawPath(path2, secondPaint);
  }

  void _drawWashiTape(Canvas canvas, Size size) {
    final tapePaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.85);

    final tapeBorder = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    const tw = 65.0;
    const th = 13.0;

    final tapeRect =
        Rect.fromCenter(center: Offset(cx, 7), width: tw, height: th);
    canvas.drawRect(tapeRect, tapePaint);
    canvas.drawRect(tapeRect, tapeBorder);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    for (double x = cx - tw / 2 + 8; x < cx + tw / 2; x += 10) {
      canvas.drawLine(Offset(x, 2), Offset(x + 4, 13), stripePaint);
    }
  }

  void _drawPostmarkStamp(Canvas canvas, Offset center) {
    final stampPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 20, stampPaint);
    canvas.drawCircle(center, 16, stampPaint..strokeWidth = 0.9);

    final wavePaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = -1; i <= 1; i++) {
      final y = center.dy + i * 4.5;
      final wave = Path();
      wave.moveTo(center.dx - 12, y);
      wave.quadraticBezierTo(
          center.dx - 6, y - 2, center.dx, y);
      wave.quadraticBezierTo(
          center.dx + 6, y + 2, center.dx + 12, y);
      canvas.drawPath(wave, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchHeadToHeadPostcardPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.dateString != dateString;
}
