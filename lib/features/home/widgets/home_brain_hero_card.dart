import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/daily_play_service.dart';
import '../../../core/services/game_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sketch_countdown_timer.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';

/// Zühtü Arenası Ana Sayfa Canlı & Animasyonlu Beyin Gücü Hero Kartı
class HomeBrainHeroCard extends StatelessWidget {
  final int userIQ;
  final Map<GameType, GamePerformanceData> statsMap;
  final DailyPlayState dailyPlayState;
  final String activeDateKey;
  final VoidCallback? onStreakTap;

  const HomeBrainHeroCard({
    super.key,
    required this.userIQ,
    required this.statsMap,
    required this.dailyPlayState,
    required this.activeDateKey,
    this.onStreakTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    // 1. Dinamik Seri Hesaplama
    final currentStreak = dailyPlayState.getCurrentStreak();

    // 2. Kategori Çeşitliliği & Bugün Çözülen Oyunlar
    final playedCategories = statsMap.values.where((p) => p.hasPlayed).length;
    int todayCompleted = 0;
    for (final game in GameType.values) {
      if (dailyPlayState.isCompleted(game, activeDateKey)) {
        todayCompleted++;
      }
    }

    // 3. En Hızlı Çözüm Süresi
    int bestDurationMs = 0;
    for (final p in statsMap.values) {
      if (p.bestDurationMs > 0 &&
          (bestDurationMs == 0 || p.bestDurationMs < bestDurationMs)) {
        bestDurationMs = p.bestDurationMs;
      }
    }

    // 4. Dinamik Üst Rozet & İkon Belirleme
    final ({String text, Color bg, Widget icon}) badgeInfo = _getBadgeInfo(
      userIQ: userIQ,
      playedCategories: playedCategories,
      pencilColor: pencilColor,
    );

    // 5. Dinamik Seviye Rozeti (Milestone)
    final milestone = IQMilestone.currentMilestone(userIQ) ?? IQMilestone.all.first;

    // 6. Dinamik Açıklama Metni
    final String subtitleText;
    if (todayCompleted == 6) {
      subtitleText = '🏆 Bugünün 6/6 görevi tamamlandı! Zihnin zirvede.';
    } else if (todayCompleted > 0) {
      subtitleText = 'Bugün $todayCompleted/6 oyun çözüldü • ${6 - todayCompleted} bulmaca bekliyor!';
    } else if (bestDurationMs > 0) {
      subtitleText = 'En hızlı reaksiyonun: ${GameDateUtils.formatGameTime(bestDurationMs)} • Zihnini test et!';
    } else {
      subtitleText = 'Güne zihnini açarak başla • 6 yeni bulmaca seni bekliyor!';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SketchCard(
        enableHatching: true,
        borderWidth: 2.5,
        borderRadius: 18,
        shadowOffset: const Offset(4.0, 4.0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ÜST SATIR: Sol Dinamik Rozet & Sağ Geri Sayım Sayacı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sol: El Çizimi Eskiz Rozet
                SketchCard(
                  backgroundColor: badgeInfo.bg,
                  borderColor: pencilColor,
                  borderWidth: 1.8,
                  borderRadius: 10,
                  shadowOffset: const Offset(1.5, 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      badgeInfo.icon,
                      const SizedBox(width: 5),
                      Text(
                        badgeInfo.text,
                        style: GoogleFonts.patrickHand(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ: Eskiz Sayaç
                const SketchCountdownTimer(fontSize: 13),
              ],
            ),
            const SizedBox(height: 14),

            // ORTA SATIR: Sol IQ Bilgisi & Sağ Ateşli Seri Kutusu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol Bölüm: IQ & Seviye & Açıklama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SketchDoodleBrain(size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'GÜNLÜK BEYİN GÜCÜ ENDEKSİ',
                            style: GoogleFonts.patrickHand(
                              color: graphiteColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            playedCategories == 0 ? 'IQ ~95' : 'IQ $userIQ',
                            style: GoogleFonts.patrickHand(
                              color: pencilColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .scale(
                                begin: const Offset(0.85, 0.85),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutBack,
                                duration: 500.ms,
                              ),
                          const SizedBox(width: 8),
                          // Dinamik El Çizimi Seviye Rozeti
                          SketchCard(
                            backgroundColor: AppColors.skyBlue.withValues(alpha: 0.35),
                            borderColor: pencilColor,
                            borderWidth: 1.6,
                            borderRadius: 8,
                            shadowOffset: const Offset(1.5, 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text(
                              milestone.title.toUpperCase(),
                              style: GoogleFonts.patrickHand(
                                color: pencilColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: GoogleFonts.patrickHand(
                          color: graphiteColor,
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Sağ Bölüm: Canlı Animasyonlu Ateşli Seri Kutusu
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStreakTap,
                    borderRadius: BorderRadius.circular(14),
                    child: SketchCard(
                      backgroundColor: currentStreak > 0
                          ? AppColors.highlighterOrange
                          : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                      borderColor: pencilColor,
                      borderWidth: 2.2,
                      borderRadius: 14,
                      shadowOffset: const Offset(3.0, 3.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Alev Doodle'ı (Seri varsa canlı nefes alma animasyonu)
                            SketchDoodleFlame(
                              size: 26,
                              color: currentStreak > 0 ? AppColors.pencilBlack : graphiteColor,
                            )
                                .animate(
                                  target: currentStreak > 0 ? 1 : 0,
                                  onPlay: currentStreak > 0 ? (controller) => controller.repeat(reverse: true) : null,
                                )
                                .scale(
                                  begin: const Offset(1.0, 1.0),
                                  end: const Offset(1.12, 1.12),
                                  duration: 1200.ms,
                                  curve: Curves.easeInOut,
                                ),
                            const SizedBox(height: 2),
                            Text(
                              currentStreak > 0 ? '$currentStreak GÜN' : '0 GÜN',
                              style: GoogleFonts.patrickHand(
                                color: currentStreak > 0 ? AppColors.pencilBlack : pencilColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              currentStreak > 0 ? 'SERİ 🔥' : 'BAŞLA',
                              style: GoogleFonts.patrickHand(
                                color: currentStreak > 0 ? AppColors.pencilBlack : graphiteColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ALT BÖLÜM: Günlük 6 Oyun Tamamlama İlerleme Çubuğu (Mini Sketch Dots)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F1E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pencilColor.withValues(alpha: 0.3), width: 1.2),
              ),
              child: Row(
                children: [
                  Text(
                    'BUGÜN:',
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: graphiteColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(GameType.values.length, (index) {
                        final game = GameType.values[index];
                        final isDone = dailyPlayState.isCompleted(game, activeDateKey);
                        return _MiniGameDot(
                          game: game,
                          isDone: isDone,
                          isDark: isDark,
                          pencilColor: pencilColor,
                          index: index,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$todayCompleted/6',
                    style: GoogleFonts.patrickHand(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: todayCompleted == 6 ? const Color(0xFF15803D) : pencilColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        // Kartın açılış Wow animasyonu (Hafif yaylı sıçrama ve fade-in)
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutBack, duration: 500.ms);
  }

  /// Dinamik rozet başlığı, arka plan rengi ve ikonu
  static ({String text, Color bg, Widget icon}) _getBadgeInfo({
    required int userIQ,
    required int playedCategories,
    required Color pencilColor,
  }) {
    if (playedCategories < 3) {
      return (
        text: '🌱 KALİBRASYON: $playedCategories/6 KATEGORİ',
        bg: AppColors.sunYellow,
        icon: const SketchDoodleBrain(size: 16),
      );
    }

    if (userIQ >= 148) {
      return (
        text: '👑 EINSTEIN MERTEBESİ • İLK %0.1',
        bg: AppColors.highlighterPurple,
        icon: const SketchDoodleCrown(size: 16, color: AppColors.pencilBlack),
      );
    } else if (userIQ >= 140) {
      return (
        text: '🚀 ZÜHTÜ DAHİSİ • İLK %0.5',
        bg: AppColors.sunYellow,
        icon: const Text('🚀', style: TextStyle(fontSize: 14)),
      );
    } else if (userIQ >= 130) {
      return (
        text: '🌟 MENSA DÜZEYİ • İLK %2',
        bg: AppColors.skyBlue,
        icon: const Text('🌟', style: TextStyle(fontSize: 14)),
      );
    } else if (userIQ >= 120) {
      return (
        text: '💡 BÜYÜK USTA • İLK %10',
        bg: AppColors.sunYellow,
        icon: const Text('💡', style: TextStyle(fontSize: 14)),
      );
    } else if (userIQ >= 110) {
      return (
        text: '⭐ KESKİN ZİHİN • İLK %25',
        bg: AppColors.highlighterOrange,
        icon: const Text('⭐', style: TextStyle(fontSize: 14)),
      );
    } else {
      return (
        text: '🎯 DENGELİ ZİHİN • İLK %50',
        bg: AppColors.sunYellow.withValues(alpha: 0.6),
        icon: const Text('🎯', style: TextStyle(fontSize: 14)),
      );
    }
  }
}

/// Günlük 6 Oyun İlerleme Noktası
class _MiniGameDot extends StatelessWidget {
  final GameType game;
  final bool isDone;
  final bool isDark;
  final Color pencilColor;
  final int index;

  const _MiniGameDot({
    required this.game,
    required this.isDone,
    required this.isDark,
    required this.pencilColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${game.title}: ${isDone ? "Tamamlandı" : "Bekliyor"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isDone ? game.color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDone ? pencilColor : pencilColor.withValues(alpha: 0.4),
            width: isDone ? 1.8 : 1.2,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: pencilColor.withValues(alpha: 0.2),
                    offset: const Offset(1, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isDone
            ? Icon(Icons.check, size: 14, color: AppColors.pencilBlack)
            : Text(
                game.title.substring(0, 1),
                style: GoogleFonts.patrickHand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: pencilColor.withValues(alpha: 0.6),
                ),
              ),
      )
          .animate(delay: (index * 60).ms)
          .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}

