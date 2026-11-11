import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// WhatsApp & Instagram Paylaşım Kartı Diyaloğu (Günün Zeka Karnesi).
/// Oyuncunun günlük 6 oyunluk ilerlemesini, serisini (streak), WAIS-IV IQ puanını
/// ve seçtiği avatarı şık bir el çizimi eskiz kartpostalı olarak PNG formatında paylaşır.
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
    buffer.writeln('🧠 ZÜHTÜ GÜNLÜK ZEKA KARNESİ $avatarEmoji⚡');
    buffer.writeln('👤 @$nickname • $milestoneTitle (${widget.overallIQ} IQ)');
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
    buffer.writeln('Bugünün zeka antrenmanını tamamladım! Sen beni geçebilir misin? 😉');
    buffer.writeln('👉 https://zuhtu.app');
    return buffer.toString();
  }

  String _getGameShortTitle(GameType type) {
    switch (type) {
      case GameType.queens:
        return '👑 Vezirler';
      case GameType.pinpoint:
        return '🎯 Nokta Atışı';
      case GameType.crossclimb:
        return '🧗 Kelime Tırmanışı';
      case GameType.tango:
        return '⚪ Tango';
      case GameType.zipPath:
        return '🔢 Sayı Yolu';
      case GameType.patches:
        return '🧩 Yamalar';
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

    try {
      final success = await ShareCardHelper.shareCard(
        boundaryKey: _cardKey,
        shareText: shareText,
        subject: '🧠 Zühtü Günlük Zeka Karnesi: ${widget.overallIQ} IQ',
        fileName: 'zuhtu_gunun_karnesi.png',
      );

      if (!success && mounted) {
        await Clipboard.setData(ClipboardData(text: shareText));
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
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFAF7EE);
    final innerBg = isDark ? AppColors.surfaceSecondaryDark : Colors.white;

    final nickname = ref.watch(userNicknameProvider);
    final avatarId = ref.watch(userAvatarProvider);
    final userAvatar = UserAvatar.getById(avatarId);
    final streak = widget.dailyPlayState.getCurrentStreak();
    final completedMap = widget.dailyPlayState.getCompletedGamesForDate(widget.dateId);
    final completedCount = completedMap.length;

    // Seviye formülü: (toplam tamamlanan / 5).floor() + 1
    final totalCompleted = widget.dailyPlayState.records.length;
    final effectiveTotal = totalCompleted > 0 ? totalCompleted : completedCount;
    final userLevel = (effectiveTotal / 5).floor() + 1;

    final activeMilestone =
        IQMilestone.currentMilestone(widget.overallIQ) ?? IQMilestone.all.first;
    final betterThanPercent =
        IQMilestone.gaussianBetterThanPercent(widget.overallIQ).round();

    final formattedDate =
        GameDateUtils.getFormattedDate(GameDateUtils.parseLevelId(widget.dateId));

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. SOSYAL MEDYAYA GÖRSEL OLARAK AKTARILACAK ESKİZ KARTPOSTALI
                RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: pencilColor, width: 2.8),
                      boxShadow: [
                        BoxShadow(
                          color: pencilColor.withValues(alpha: isDark ? 0.4 : 0.25),
                          offset: const Offset(5, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Üst Damga ve Tarih
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sunYellow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: pencilColor, width: 1.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🧠', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ZÜHTÜ GÜNLÜK ZEKA',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.inkBlack,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: innerBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: pencilColor, width: 1.4),
                                ),
                                child: Text(
                                  formattedDate.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.pencilWhite
                                        : AppColors.pencilGraphite,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Oyuncu Profil Şeridi (Avatar, Nickname, Level, Streak)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: pencilColor, width: 1.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: userAvatar.accentColor.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: pencilColor, width: 2.0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  userAvatar.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '@$nickname',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: pencilColor,
                                        height: 1.1,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.sunYellow
                                                .withValues(alpha: 0.4),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            userAvatar.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 13,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: pencilColor, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥',
                                        style: TextStyle(fontSize: 15)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$streak Gün',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 14,
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

                        const SizedBox(height: 12),

                        // Büyük IQ ve Bilişsel Seviye Vitrini
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.highlighterPurple
                                .withValues(alpha: isDark ? 0.35 : 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: pencilColor, width: 2.2),
                          ),
                          child: Row(
                            children: [
                              SketchBadgeIcon(
                                type: activeMilestone.artType,
                                size: 36,
                                strokeColor: pencilColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          'IQ',
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: pencilColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '• ${activeMilestone.title}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.pencilWhite
                                                  : const Color(0xFF5B21B6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '⚡ Türkiye geneli oyuncuların %$betterThanPercent\'inden daha yüksek bilişsel performans!',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.pencilWhite
                                            : AppColors.pencilGraphite,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 6 Oyunluk Durum Tablosu (2 Sütun x 3 Satır)
                        Text(
                          '📋 GÜNÜN 6 BULMACA DURUMU ($completedCount/6)',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: pencilColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: pencilColor, width: 1.8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.queens,
                                      completedResult:
                                          completedMap[GameType.queens],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.pinpoint,
                                      completedResult:
                                          completedMap[GameType.pinpoint],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.crossclimb,
                                      completedResult:
                                          completedMap[GameType.crossclimb],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.tango,
                                      completedResult:
                                          completedMap[GameType.tango],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.zipPath,
                                      completedResult:
                                          completedMap[GameType.zipPath],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMiniGameStatus(
                                      type: GameType.patches,
                                      completedResult:
                                          completedMap[GameType.patches],
                                      pencilColor: pencilColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Meydan Okuma Kutusu & Footer Damgası
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: pencilColor.withValues(alpha: 0.5),
                                width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Günün zeka karnesini tamamladım! Sen beni geçebilir misin? 😉',
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

                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'zuhtu.app • Her Gece 00:00\'da Yeni Bulmacalar ⚡',
                            style: GoogleFonts.patrickHand(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.pencilWhite.withValues(alpha: 0.7)
                                  : AppColors.pencilGraphite,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. EYLEM BUTONLARI
                Row(
                  children: [
                    // Metin Kopyala Butonu
                    Expanded(
                      flex: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
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
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Görsel Olarak Paylaş (WhatsApp & Instagram)
                    Expanded(
                      flex: 6,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSharing
                              ? null
                              : () => _shareImageCard(shareText),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.sunYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pencilColor, width: 2.2),
                              boxShadow: [
                                BoxShadow(
                                  color: pencilColor.withValues(alpha: 0.25),
                                  offset: const Offset(2.5, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
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
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kapat Butonu
                    Expanded(
                      flex: 3,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pencilColor, width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: pencilColor.withValues(alpha: 0.15),
                                  offset: const Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
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

  Widget _buildMiniGameStatus({
    required GameType type,
    required DailyPlayRecord? completedResult,
    required Color pencilColor,
    required bool isDark,
  }) {
    final isDone = completedResult != null;
    final accent = _getGameAccentColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDone
            ? accent.withValues(alpha: isDark ? 0.35 : 0.22)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? pencilColor : pencilColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Text(_getGameEmoji(type), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _getGameName(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.patrickHand(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: pencilColor,
              ),
            ),
          ),
          if (isDone) ...[
            Text(
              GameDateUtils.formatGameTime(completedResult.durationMs),
              style: GoogleFonts.patrickHand(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.sunYellow : const Color(0xFFB45309),
              ),
            ),
          ] else ...[
            Text(
              'Bekliyor',
              style: GoogleFonts.patrickHand(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.pencilWhite.withValues(alpha: 0.5) : AppColors.pencilGraphite,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGameEmoji(GameType type) {
    switch (type) {
      case GameType.queens:
        return '👑';
      case GameType.pinpoint:
        return '🎯';
      case GameType.crossclimb:
        return '🧗';
      case GameType.tango:
        return '⚪';
      case GameType.zipPath:
        return '🔢';
      case GameType.patches:
        return '🧩';
    }
  }

  String _getGameName(GameType type) {
    switch (type) {
      case GameType.queens:
        return 'Vezirler';
      case GameType.pinpoint:
        return 'Nokta Atışı';
      case GameType.crossclimb:
        return 'Kelime T.';
      case GameType.tango:
        return 'Tango';
      case GameType.zipPath:
        return 'Sayı Yolu';
      case GameType.patches:
        return 'Yamalar';
    }
  }
}
