import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/profile/profile_screen.dart' show GameSketchThumbnail;
import '../../games/common/base_game.dart';
import '../models/user_avatar.dart';
import '../services/daily_play_service.dart';
import '../services/game_stats_service.dart';
import '../services/user_avatar_provider.dart';
import '../services/user_nickname_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/share_card_helper.dart';
import 'sketch_badge_icons.dart';
import 'sketch_decorations.dart';

/// WhatsApp & Instagram İçin %100 El Çizimi Eskiz Defteri Paylaşım Kartı Diyaloğu.
/// Sıradan dijital kutular yerine; delikli defter kağıdı dokusu, washi bant, posta damgası,
/// çift vuruşlu kurşun kalem konturları ve el çizimi simgelerle organik bir kartpostal sunar.
class DailySocialShareDialog extends ConsumerStatefulWidget {
  final String dateId;
  final int overallIQ;
  final DailyPlayState dailyPlayState;
  final Map<GameType, GamePerformanceData>? statsMap;

  const DailySocialShareDialog({
    super.key,
    required this.dateId,
    required this.overallIQ,
    required this.dailyPlayState,
    this.statsMap,
  });

  static Future<void> show(
    BuildContext context, {
    required String dateId,
    required int overallIQ,
    required DailyPlayState dailyPlayState,
    Map<GameType, GamePerformanceData>? statsMap,
  }) async {
    HapticFeedback.mediumImpact();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailySocialShareDialog(
        dateId: dateId,
        overallIQ: overallIQ,
        dailyPlayState: dailyPlayState,
        statsMap: statsMap,
      ),
    );
  }

  @override
  ConsumerState<DailySocialShareDialog> createState() =>
      _DailySocialShareDialogState();
}

class _DailySocialShareDialogState extends ConsumerState<DailySocialShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  String _buildShareText({
    required String nickname,
    required String avatarEmoji,
    required String formattedDate,
    required int completedCount,
    required int streak,
    required String milestoneTitle,
    required Map<GameType, DailyPlayRecord> completedMap,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🧠 ZÜHTÜ GÜNÜN ZİHİN KARNESİ $avatarEmoji⚡');
    buffer.writeln('👤 @$nickname • $milestoneTitle (${widget.overallIQ} Puan)');
    buffer.writeln('📅 $formattedDate | 🔥 $streak Gün Seri | 🧩 $completedCount/6 Bulmaca');
    buffer.writeln('');

    for (final type in GameType.values) {
      final res = completedMap[type];
      final label = _getGameShortTitle(type);
      if (res != null) {
        final time = GameDateUtils.formatGameTime(res.durationMs);
        buffer.writeln('$label: 🟩 $time (${res.score} P)');
      } else {
        buffer.writeln('$label: ⬜ Bekliyor');
      }
    }

    buffer.writeln('');
    buffer.writeln('Bugünün zeka antrenmanını tamamladım! Beni geçebilir misin? 😉');
    buffer.writeln('Sen de zihnini sına 👉 https://zuhtuapp.cyboros.com');
    return buffer.toString();
  }

  String _getGameShortTitle(GameType type) {
    switch (type) {
      case GameType.queens:
        return '👑 Vezirler';
      case GameType.pinpoint:
        return '🔍 Kelime İzleri';
      case GameType.crossclimb:
        return '🧗 Kelime Tırmanışı';
      case GameType.tango:
        return '☀️ Güneş & Ay';
      case GameType.zipPath:
        return '🔢 Sayı Yolu';
      case GameType.patches:
        return '🧩 Alan Bölme';
    }
  }

  Color _getGameAccentColor(GameType type) {
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

  Future<void> _shareImageCard(String shareText) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.heavyImpact();

    // Butonun "Hazırlanıyor..." durumuna geçişinin çizilmesini bekle
    try {
      if (WidgetsBinding.instance.hasScheduledFrame) {
        await WidgetsBinding.instance.endOfFrame;
      }
    } catch (_) {}

    try {
      final success = await ShareCardHelper.shareCard(
        boundaryKey: _cardKey,
        shareText: shareText,
        subject: '🧠 Zühtü Günlük Zeka Karnesi: ${widget.overallIQ} Puan',
        fileName: 'zuhtu_gunun_karnesi.png',
      );

      if (!mounted) return;

      if (!success) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görsel paylaşılamadı, karne metni panoya kopyalandı! 📋',
              style: GoogleFonts.patrickHand(fontSize: 15),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DailySocialShareDialog] Paylaşım hatası: $e');
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Karne metni panoya kopyalandı! 📋',
              style: GoogleFonts.patrickHand(fontSize: 15),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;

    final nickname = ref.watch(userNicknameProvider);
    final avatarId = ref.watch(userAvatarProvider);
    final userAvatar = UserAvatar.getById(avatarId);
    final streak = widget.dailyPlayState.getCurrentStreak();
    final completedMap = widget.dailyPlayState.getCompletedGamesForDate(widget.dateId);
    final completedCount = completedMap.length;

    // Seviye: her 5 tamamlanan oyun için 1 seviye
    final totalCompleted = widget.dailyPlayState.records.length;
    final effectiveTotal = totalCompleted > 0 ? totalCompleted : completedCount;
    final userLevel = (effectiveTotal / 5).floor() + 1;

    final activeMilestone =
        IQMilestone.currentMilestone(widget.overallIQ) ?? IQMilestone.all.first;

    final parsedDate = GameDateUtils.parseLevelId(widget.dateId);
    final formattedDate = GameDateUtils.getFormattedDate(parsedDate);
    final stampDateStr =
        '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';

    final shareText = _buildShareText(
      nickname: nickname,
      avatarEmoji: userAvatar.emoji,
      formattedDate: formattedDate,
      completedCount: completedCount,
      streak: streak,
      milestoneTitle: activeMilestone.title,
      completedMap: completedMap,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. SOSYAL MEDYAYA GÖRSEL OLARAK YAKALANACAK %100 EL ÇİZİMİ KARTPOSTAL
                RepaintBoundary(
                  key: _cardKey,
                  child: CustomPaint(
                    painter: _SketchPostcardBackgroundPainter(
                      isDark: isDark,
                      pencilColor: pencilColor,
                      dateString: stampDateStr,
                    ),
                    child: Padding(
                      // Deliklerin ve marjin çizgisinin sağından başlaması için sol dolgu 44px
                      padding: const EdgeInsets.fromLTRB(44, 26, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ÜST DAMGA & BAŞLIK & GÜNÜN TARİHİ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: SketchCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  borderRadius: 8,
                                  borderWidth: 1.6,
                                  shadowOffset: const Offset(1.5, 1.5),
                                  backgroundColor: AppColors.sunYellow,
                                  borderColor: pencilColor,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SketchDoodleBrain(
                                        size: 16,
                                        color: AppColors.inkBlack,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'ZÜHTÜ GÜNÜN KARNESİ',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.inkBlack,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SketchCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                borderRadius: 8,
                                borderWidth: 1.4,
                                shadowOffset: const Offset(1.4, 1.4),
                                backgroundColor: isDark
                                    ? AppColors.surfaceSecondaryDark
                                    : Colors.white,
                                borderColor: pencilColor,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: isDark
                                          ? AppColors.sunYellow
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: pencilColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // OYUNCU BİLGİ KARTI (SKEÇ FORMATINDA)
                          SketchCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            borderRadius: 12,
                            borderWidth: 1.8,
                            shadowOffset: const Offset(2.0, 2.0),
                            backgroundColor: isDark
                                ? AppColors.surfaceSecondaryDark
                                : Colors.white,
                            borderColor: pencilColor,
                            child: Row(
                              children: [
                                SketchPlaceholderBox(
                                  width: 40,
                                  height: 40,
                                  fillColor: userAvatar.accentColor
                                      .withAlpha(isDark ? 95 : 130),
                                  lineColor: pencilColor,
                                  borderRadius: 10,
                                  child: Center(
                                    child: userAvatar.buildWidget(
                                      size: 23,
                                      tintColor: pencilColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@$nickname',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: pencilColor,
                                          height: 1.1,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.sunYellow
                                                  .withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                  color: pencilColor, width: 1.0),
                                            ),
                                            child: Text(
                                              'LVL $userLevel',
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: pencilColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              userAvatar.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.pencilWhite
                                                    : AppColors.pencilGraphite,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SketchCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  borderRadius: 8,
                                  borderWidth: 1.4,
                                  shadowOffset: const Offset(1.2, 1.2),
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  borderColor: pencilColor,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SketchDoodleFlame(
                                          size: 15,
                                          color: Color(0xFFB45309)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$streak Gün',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // BÜYÜK ZEKA SKORU & GÜNÜN DURUMU (SAMİMİ, İDDİASIZ SKEÇ POST-IT)
                          SketchCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            borderRadius: 14,
                            borderWidth: 2.0,
                            shadowOffset: const Offset(2.5, 2.5),
                            backgroundColor: AppColors.sunYellow
                                .withValues(alpha: isDark ? 0.25 : 0.22),
                            borderColor: pencilColor,
                            child: Row(
                              children: [
                                SketchBadgeIcon(
                                  type: activeMilestone.artType,
                                  size: 38,
                                  strokeColor: pencilColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '${widget.overallIQ}',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: pencilColor,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Puan',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: pencilColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '• ${activeMilestone.title}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? AppColors.pencilWhite
                                                    : const Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SketchDoodleBolt(
                                            size: 14,
                                            color: pencilColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Günün zihin jimnastiğini tamamladım, kafam pırıl pırıl!',
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.pencilWhite
                                                    : AppColors.pencilGraphite,
                                                height: 1.15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 6 BULMACA DURUMU (2 SÜTUNLU EL ÇİZİMİ IZGARA)
                          Row(
                            children: [
                              SketchDoodleClipboard(
                                size: 15,
                                color: pencilColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'GÜNÜN 6 BULMACASI ($completedCount/6)',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          SketchCard(
                            padding: const EdgeInsets.all(7),
                            borderRadius: 12,
                            borderWidth: 1.6,
                            shadowOffset: const Offset(2.0, 2.0),
                            backgroundColor: isDark
                                ? AppColors.surfaceSecondaryDark
                                : Colors.white,
                            borderColor: pencilColor,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.queens,
                                        record: completedMap[GameType.queens],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.pinpoint,
                                        record: completedMap[GameType.pinpoint],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.crossclimb,
                                        record:
                                            completedMap[GameType.crossclimb],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.tango,
                                        record: completedMap[GameType.tango],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.zipPath,
                                        record: completedMap[GameType.zipPath],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: _buildMiniGamePill(
                                        type: GameType.patches,
                                        record: completedMap[GameType.patches],
                                        pencilColor: pencilColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // MEYDAN OKUMA VE WATERMARK NOTU
                          SketchCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            borderRadius: 10,
                            borderWidth: 1.4,
                            shadowOffset: const Offset(1.5, 1.5),
                            backgroundColor: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            borderColor: pencilColor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SketchDoodleTarget(
                                  size: 16,
                                  color: pencilColor,
                                  fillColor: const Color(0xFF67E8F9),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Beni geçebilir misin? Zühtü\'ye gel kapışalım!',
                                    textAlign: TextAlign.center,
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

                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final uri = Uri.parse('https://zuhtuapp.cyboros.com');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SketchDoodleBolt(
                                    size: 13,
                                    color: pencilColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'zuhtuapp.cyboros.com',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.sunYellow
                                                  : const Color(0xFF1D4ED8),
                                              decoration: TextDecoration.underline,
                                              decorationColor: isDark
                                                  ? AppColors.sunYellow
                                                  : const Color(0xFF1D4ED8),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " • Her Gece 00:00'da Yeni Bulmacalar",
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.pencilWhite
                                                      .withValues(alpha: 0.7)
                                                  : AppColors.pencilGraphite,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                ),

                const SizedBox(height: 14),

                // 2. EYLEM BUTONLARI (METİN, GÖRSEL PAYLAŞ, KAPAT)
                Row(
                  children: [
                    // Metin Kopyala Butonu
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
                                  '📋 Zeka karnesi panoya kopyalandı!',
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
                                'Metin',
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

                    // Görsel Olarak Paylaş (WhatsApp & Instagram)
                    Expanded(
                      flex: 6,
                      child: SketchCard(
                        onTap: _isSharing
                            ? null
                            : () => _shareImageCard(shareText),
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
                                _isSharing ? 'Hazırlanıyor...' : 'Görsel Paylaş',
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
                        backgroundColor:
                            isDark ? Colors.white10 : const Color(0xFFE2E8F0),
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

  Widget _buildMiniGamePill({
    required GameType type,
    required DailyPlayRecord? record,
    required Color pencilColor,
    required bool isDark,
  }) {
    final isDone = record != null;
    final accent = _getGameAccentColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? accent.withValues(alpha: isDark ? 0.35 : 0.22)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? pencilColor : pencilColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          GameSketchThumbnail(
            game: type,
            size: 18,
            pencilColor: pencilColor,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _getGameName(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.patrickHand(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: pencilColor,
              ),
            ),
          ),
          if (isDone) ...[
            Text(
              GameDateUtils.formatGameTime(record.durationMs),
              style: GoogleFonts.patrickHand(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.sunYellow : const Color(0xFFB45309),
              ),
            ),
          ] else ...[
            Text(
              'Bekliyor',
              style: GoogleFonts.patrickHand(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.pencilWhite.withValues(alpha: 0.5)
                    : AppColors.pencilGraphite,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGameName(GameType type) {
    return type.title;
  }
}

/// %100 El Çizimi Eskiz Defteri Kartpostalı Ressamı.
/// Çizgili/kareli defter dokusu, sol kenarda delikli spiral delikleri, kırmızı marjin çizgisi,
/// washi bant ve sağ üstte el çizimi posta damgası çizer.
class _SketchPostcardBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;
  final String dateString;

  _SketchPostcardBackgroundPainter({
    required this.isDark,
    required this.pencilColor,
    required this.dateString,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Zemin Eskiz Kağıdı (Sıcak krem defter yaprağı veya koyu arduvaz)
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFFAF7EE);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Hafif Kareli Defter Izgarası
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.pencilBlack)
          .withValues(alpha: isDark ? 0.04 : 0.032)
      ..strokeWidth = 1.0;
    const double step = 20.0;
    for (double y = 14; y < size.height - 10; y += step) {
      canvas.drawLine(Offset(32, y), Offset(size.width - 10, y), gridPaint);
    }
    for (double x = 32; x < size.width - 10; x += step) {
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), gridPaint);
    }

    // 3. Sol Kenar Kırmızı El Çizimi Marjin Çizgisi
    final marginPaint = Paint()
      ..color = (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444))
          .withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    final marginPath = Path();
    marginPath.moveTo(34, 0);
    for (double y = 0; y <= size.height; y += 30) {
      final wobble = math.sin(y * 0.08) * 0.7;
      marginPath.lineTo(34 + wobble, y);
    }
    canvas.drawPath(marginPath, marginPaint);

    // 4. Sol Kenar Defter Delikleri (Spiral Binder Holes)
    final holePaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final holeBorder = Paint()
      ..color = pencilColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double holeSpacing = 32.0;
    for (double y = 28; y < size.height - 20; y += holeSpacing) {
      canvas.drawCircle(Offset(16, y), 5.0, holePaint);
      canvas.drawCircle(Offset(16, y), 5.0, holeBorder);
    }

    // 5. Organik Çift Vuruşlu El Çizimi Dış Çerçeve
    _drawWobblyDoubleBorder(canvas, size, pencilColor);

    // 6. Üst Ortada Washi Bant (Taped paper effect)
    _drawWashiTape(canvas, size);

    // 7. Sağ Üst El Çizimi Posta Damgası
    _drawPostmarkStamp(canvas, Offset(size.width - 44, 42));
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

    // İkinci hafif yamuk el vuruşu
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
    const tw = 70.0;
    const th = 14.0;

    final tapeRect = Rect.fromCenter(center: Offset(cx, 8), width: tw, height: th);
    canvas.drawRect(tapeRect, tapePaint);
    canvas.drawRect(tapeRect, tapeBorder);

    // Bant üzerindeki minik doku çizgileri
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    for (double x = cx - tw / 2 + 8; x < cx + tw / 2; x += 10) {
      canvas.drawLine(Offset(x, 2), Offset(x + 4, 14), stripePaint);
    }
  }

  void _drawPostmarkStamp(Canvas canvas, Offset center) {
    final stampPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dış ve iç damga çemberi
    canvas.drawCircle(center, 22, stampPaint);
    canvas.drawCircle(center, 18, stampPaint..strokeWidth = 0.9);

    // Minik dalgalı damga çizgileri
    final wavePaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = -1; i <= 1; i++) {
      final y = center.dy + i * 5.0;
      final wave = Path();
      wave.moveTo(center.dx - 14, y);
      wave.quadraticBezierTo(
          center.dx - 7, y - 2, center.dx, y);
      wave.quadraticBezierTo(
          center.dx + 7, y + 2, center.dx + 14, y);
      canvas.drawPath(wave, wavePaint);
    }

    // Damga içindeki tarih
    final textPainter = TextPainter(
      text: TextSpan(
        text: dateString,
        style: const TextStyle(
          color: Color(0xFFDC2626),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SketchPostcardBackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.dateString != dateString;
}
