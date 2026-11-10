import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/daily_play_service.dart';
import '../../../../core/services/game_stats_service.dart';
import '../../../../core/services/user_nickname_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/sketch_badge_icons.dart';
import '../../../../core/widgets/sketch_decorations.dart';
import '../../../../games/common/base_game.dart';

/// Bilişsel alan etiketi ve kullanıcı dostu isim eşleştirmesi
String _getDomainShortName(GameType type) {
  switch (type) {
    case GameType.queens:
      return 'Mantık';
    case GameType.pinpoint:
      return 'Kelime Hafızası';
    case GameType.crossclimb:
      return 'Sözel Akıcılık';
    case GameType.tango:
      return 'İkili Örüntü';
    case GameType.zipPath:
      return 'Uzamsal Planlama';
    case GameType.patches:
      return 'Geometri';
  }
}

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

/// Haftalık Zeka Karnesi Hesaplama Modeli
class WeeklyCognitiveStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<GameType, int> gamePuzzlesSolved;
  final Map<GameType, double> cognitiveFocusPercent;
  final GameType mostFocusedGame;
  final double mostFocusedPercent;
  final GameType weakestGame;
  final double weakestPercent;
  final int totalPuzzlesSolved;
  final int totalScore;
  final int weeklyStreak;
  final bool isSunday;

  const WeeklyCognitiveStats({
    required this.weekStart,
    required this.weekEnd,
    required this.gamePuzzlesSolved,
    required this.cognitiveFocusPercent,
    required this.mostFocusedGame,
    required this.mostFocusedPercent,
    required this.weakestGame,
    required this.weakestPercent,
    required this.totalPuzzlesSolved,
    required this.totalScore,
    required this.weeklyStreak,
    required this.isSunday,
  });

  factory WeeklyCognitiveStats.calculate({
    required DailyPlayState dailyPlayState,
    DateTime? referenceDate,
  }) {
    final active = referenceDate ?? GameDateUtils.getActiveDate();
    final weekStart = GameDateUtils.getStartOfWeek(active);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isSunday = active.weekday == DateTime.sunday;

    final weekDateKeys = <String>{
      for (int i = 0; i < 7; i++) ...[
        () {
          final d = weekStart.add(Duration(days: i));
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }(),
      ],
    };

    final gamePuzzlesSolved = <GameType, int>{
      for (final g in GameType.values) g: 0,
    };
    int totalScore = 0;
    final playedDates = <String>{};

    for (final r in dailyPlayState.records.values) {
      if (weekDateKeys.contains(r.dateId)) {
        gamePuzzlesSolved[r.gameType] = (gamePuzzlesSolved[r.gameType] ?? 0) + 1;
        totalScore += r.score;
        playedDates.add(r.dateId);
      }
    }

    final totalPuzzlesSolved = gamePuzzlesSolved.values.fold<int>(0, (sum, count) => sum + count);
    final cognitiveFocusPercent = <GameType, double>{};

    if (totalPuzzlesSolved > 0) {
      for (final g in GameType.values) {
        final count = gamePuzzlesSolved[g] ?? 0;
        cognitiveFocusPercent[g] = (count / totalPuzzlesSolved) * 100.0;
      }
    } else {
      for (final g in GameType.values) {
        cognitiveFocusPercent[g] = 0.0;
      }
    }

    // En çok ve en zayıf odaklanılan alanları belirle
    GameType mostFocused = GameType.queens;
    double maxPercent = -1.0;
    GameType weakest = GameType.pinpoint;
    double minPercent = 999.0;

    for (final g in GameType.values) {
      final pct = cognitiveFocusPercent[g] ?? 0.0;
      if (pct > maxPercent) {
        maxPercent = pct;
        mostFocused = g;
      }
      if (pct < minPercent) {
        minPercent = pct;
        weakest = g;
      }
    }

    // Eğer hiç oynanmadıysa varsayılanlar
    if (totalPuzzlesSolved == 0) {
      maxPercent = 0.0;
      minPercent = 0.0;
    }

    return WeeklyCognitiveStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      gamePuzzlesSolved: gamePuzzlesSolved,
      cognitiveFocusPercent: cognitiveFocusPercent,
      mostFocusedGame: mostFocused,
      mostFocusedPercent: maxPercent,
      weakestGame: weakest,
      weakestPercent: minPercent,
      totalPuzzlesSolved: totalPuzzlesSolved,
      totalScore: totalScore,
      weeklyStreak: playedDates.length,
      isSunday: isSunday,
    );
  }
}

/// Haftalık Zeka Raporu (Pazar Akşamı Özeti) Diyaloğu
class WeeklyBrainReportDialog extends ConsumerWidget {
  final WeeklyCognitiveStats stats;
  final int overallIQ;

  const WeeklyBrainReportDialog({
    super.key,
    required this.stats,
    required this.overallIQ,
  });

  static Future<void> show(
    BuildContext context, {
    required DailyPlayState dailyPlayState,
    required int overallIQ,
    DateTime? referenceDate,
  }) async {
    HapticFeedback.mediumImpact();
    final stats = WeeklyCognitiveStats.calculate(
      dailyPlayState: dailyPlayState,
      referenceDate: referenceDate,
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WeeklyBrainReportDialog(
        stats: stats,
        overallIQ: overallIQ,
      ),
    );
  }

  String _buildShareText({
    required String nickname,
    required String mostFocusedName,
    required String weakestName,
    required IQMilestone activeMilestone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📊 ZÜHTÜ HAFTALIK ZEKA RAPORUM 🧠');
    buffer.writeln('👤 Oyuncu: @$nickname (${activeMilestone.title})');
    buffer.writeln('📅 ${GameDateUtils.getFormattedDate(stats.weekStart)} - ${GameDateUtils.getFormattedDate(stats.weekEnd)}');
    buffer.writeln('');
    if (stats.totalPuzzlesSolved > 0) {
      buffer.writeln('🎯 En Çok Odaklandığım Alan: $mostFocusedName (%${stats.mostFocusedPercent.round()})');
      buffer.writeln('💡 Gelişime Açık Alan: $weakestName (%${stats.weakestPercent.round()})');
    }
    buffer.writeln('🔥 Haftalık Seri: ${stats.weeklyStreak} / 7 Gün');
    buffer.writeln('🧩 Çözülen Bulmaca: ${stats.totalPuzzlesSolved} Adet');
    buffer.writeln('🧠 Psikometrik Zeka: $overallIQ IQ');
    buffer.writeln('');
    buffer.writeln('Sen de haftalık zeka karneni al, zihnini sına!');
    buffer.writeln('👉 https://zuhtu.app');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.backgroundLight;
    final nickname = ref.watch(userNicknameProvider);

    final activeMilestone =
        IQMilestone.currentMilestone(overallIQ) ?? IQMilestone.all.first;

    final mostFocusedName = _getDomainShortName(stats.mostFocusedGame);
    final weakestName = _getDomainShortName(stats.weakestGame);

    final weekRangeText =
        '${stats.weekStart.day} - ${GameDateUtils.getFormattedDate(stats.weekEnd)}';

    final shareText = _buildShareText(
      nickname: nickname,
      mostFocusedName: mostFocusedName,
      weakestName: weakestName,
      activeMilestone: activeMilestone,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                  // 1. Üst Başlık & Pazar Akşamı Mührü
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
                          Icons.insights_rounded,
                          size: 24,
                          color: AppColors.inkBlack,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'HAFTALIK ZEKA RAPORU',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              stats.isSunday
                                  ? 'PAZAR AKŞAMI ÖZETİ • $weekRangeText'.toUpperCase()
                                  : weekRangeText.toUpperCase(),
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: stats.isSunday
                                    ? (isDark ? AppColors.sunYellow : const Color(0xFFB45309))
                                    : (isDark ? AppColors.pencilGrayDark : AppColors.pencilGray),
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

                  // 2. Vurucu Analiz Kartı (Vision Prompt Cümlesi)
                  SketchCard(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                    borderColor: pencilColor,
                    borderRadius: 16,
                    borderWidth: 2.4,
                    shadowOffset: const Offset(3.5, 3.5),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SketchDoodleBrain(
                                size: 24,
                                color: pencilColor,
                                fillColor: AppColors.highlighterPink,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                stats.totalPuzzlesSolved > 0
                                    ? 'Bu hafta en çok odaklandığın alan $mostFocusedName (%${stats.mostFocusedPercent.round()}), en zayıf kaldığın alan $weakestName (%${stats.weakestPercent.round()}).'
                                    : 'Bu hafta henüz bulmaca çözülmedi. İlk oyununu çözerek haftalık bilişsel analizini başlat!',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.pencilWhite : AppColors.pencilBlack,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                          borderColor: pencilColor,
                          borderWidth: 1.5,
                          borderRadius: 8,
                          shadowOffset: const Offset(1.5, 1.5),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SketchDoodleFlame(
                                    size: 15,
                                    color: pencilColor,
                                    fillColor: stats.weeklyStreak >= 7 ? AppColors.sunYellow : AppColors.highlighterOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Haftalık Seri: ${stats.weeklyStreak} Gün!',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: stats.weeklyStreak >= 7 ? AppColors.sunYellow : pencilColor,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$overallIQ IQ • ${activeMilestone.title}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGraphite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 16),

                  // 3. 6 Bilişsel Alan Dağılım Çubukları
                  Text(
                    'BİLİŞSEL ALAN ODAK DAĞILIMI',
                    style: GoogleFonts.patrickHand(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...GameType.values.map((game) {
                    final percent = stats.cognitiveFocusPercent[game] ?? 0.0;
                    final solvedCount = stats.gamePuzzlesSolved[game] ?? 0;
                    final domainName = _getDomainShortName(game);
                    final color = _getGameColor(game);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CognitiveDomainBar(
                        gameTitle: '${game.title} ($domainName)',
                        percent: percent,
                        solvedCount: solvedCount,
                        barColor: color,
                        pencilColor: pencilColor,
                        isDark: isDark,
                        seed: game.index * 7 + 19,
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // 4. Haftalık Özet 3'lü Metrik Kutusu
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          customIcon: SketchDoodleFlame(
                            size: 22,
                            color: pencilColor,
                            fillColor: isDark ? AppColors.highlighterOrange : const Color(0xFFF59E0B),
                          ),
                          label: 'SERİ',
                          value: '${stats.weeklyStreak}/7 Gün',
                          lightBgColor: const Color(0xFFFEF3C7),
                          darkBgColor: AppColors.highlighterOrange.withValues(alpha: 0.22),
                          lightLabelColor: const Color(0xFFB45309),
                          lightIconColor: const Color(0xFFD97706),
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryBox(
                          customIcon: SketchDoodlePuzzle(
                            size: 22,
                            color: pencilColor,
                            fillColor: isDark ? AppColors.skyBlue : const Color(0xFF0284C7),
                          ),
                          label: 'BULMACA',
                          value: '${stats.totalPuzzlesSolved} Adet',
                          lightBgColor: const Color(0xFFE0F2FE),
                          darkBgColor: AppColors.skyBlue.withValues(alpha: 0.22),
                          lightLabelColor: const Color(0xFF0369A1),
                          lightIconColor: const Color(0xFF0284C7),
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryBox(
                          customIcon: SketchDoodleBrain(
                            size: 22,
                            color: pencilColor,
                            fillColor: isDark ? AppColors.highlighterPurple : const Color(0xFF7C3AED),
                          ),
                          label: 'ZEKÂ',
                          value: '$overallIQ IQ',
                          lightBgColor: const Color(0xFFF3E8FF),
                          darkBgColor: AppColors.highlighterPurple.withValues(alpha: 0.22),
                          lightLabelColor: const Color(0xFF6D28D9),
                          lightIconColor: const Color(0xFF7C3AED),
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 5. Zühtü Koç Tavsiyesi Post-it Notu
                  SketchCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderColor: pencilColor.withValues(alpha: 0.6),
                    borderWidth: 1.5,
                    borderRadius: 12,
                    shadowOffset: const Offset(2.0, 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SketchDoodleTarget(
                            size: 20,
                            color: pencilColor,
                            fillColor: AppColors.highlighterPink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stats.totalPuzzlesSolved > 0
                                ? 'Zühtü Tavsiyesi: $mostFocusedName alanındaki odaklanman harika! Yeni haftada $weakestName bulmacalarına ağırlık vererek 6 bilişsel alanda tam denge yakalayabilirsin.'
                                : 'Zühtü Tavsiyesi: Zihinsel gelişim düzenli pratikle başlar. Bugünün 6 bulmacasından başlayarak haftalık serini başlat!',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 6. Eylemler (Kopyala, Paylaş, Kapat)
                  Row(
                    children: [
                      // Metni Kopyala Butonu
                      Expanded(
                        child: SketchCard(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await Clipboard.setData(ClipboardData(text: shareText));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '📋 Haftalık zeka raporu kopyalandı!',
                                    style: GoogleFonts.patrickHand(fontSize: 15),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.skyBlue,
                          borderColor: pencilColor,
                          borderWidth: 2.0,
                          borderRadius: 12,
                          shadowOffset: const Offset(2.2, 2.2),
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
                      const SizedBox(width: 10),
                      // Raporu Paylaş Butonu (WhatsApp / Instagram / Sosyal Medya)
                      Expanded(
                        child: SketchCard(
                          onTap: () async {
                            HapticFeedback.heavyImpact();
                            try {
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: shareText,
                                  subject: '📊 Zühtü Haftalık Zeka Raporum: @$nickname',
                                ),
                              );
                            } catch (e) {
                              debugPrint('[WeeklyBrainReportDialog] Paylaşım hatası: $e');
                              await Clipboard.setData(ClipboardData(text: shareText));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Haftalık rapor metni panoya kopyalandı!',
                                      style: GoogleFonts.patrickHand(fontSize: 15),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.sunYellow,
                          borderColor: pencilColor,
                          borderWidth: 2.2,
                          borderRadius: 12,
                          shadowOffset: const Offset(2.5, 2.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_rounded, size: 18, color: AppColors.inkBlack),
                              const SizedBox(width: 6),
                              Text(
                                'Paylaş',
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
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Kapat Butonu
                  SketchCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    borderColor: pencilColor,
                    borderWidth: 1.8,
                    borderRadius: 12,
                    shadowOffset: const Offset(2.0, 2.0),
                    child: Center(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bilişsel Alan Yatay Skeç Çubuğu
class _CognitiveDomainBar extends StatelessWidget {
  final String gameTitle;
  final double percent;
  final int solvedCount;
  final Color barColor;
  final Color pencilColor;
  final bool isDark;
  final int seed;

  const _CognitiveDomainBar({
    required this.gameTitle,
    required this.percent,
    required this.solvedCount,
    required this.barColor,
    required this.pencilColor,
    required this.isDark,
    this.seed = 23,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = (percent / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                gameTitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.patrickHand(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pencilWhite : AppColors.pencilBlack,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '%${percent.toStringAsFixed(0)} ($solvedCount oyun)',
              style: GoogleFonts.patrickHand(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: percent > 0
                    ? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack)
                    : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 13.5,
          child: CustomPaint(
            painter: _HandDrawnDomainBarPainter(
              ratio: clampedRatio,
              barColor: barColor,
              trackColor: isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFF1EFE9),
              strokeColor: pencilColor,
              seed: seed,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bilişsel Alan Odak Dağılımı Çubuğu (El Çizimi, Çift Hatlı & Taramalı)
class _HandDrawnDomainBarPainter extends CustomPainter {
  final double ratio;
  final Color barColor;
  final Color trackColor;
  final Color strokeColor;
  final int seed;

  _HandDrawnDomainBarPainter({
    required this.ratio,
    required this.barColor,
    required this.trackColor,
    required this.strokeColor,
    this.seed = 23,
  });

  Path _buildWobblyBarPath(Size size, {double inset = 0.8, int s = 0}) {
    final w = size.width - (inset * 2);
    final h = size.height - (inset * 2);
    final r = h / 2;
    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;

    final rnd = math.Random(seed + s);
    final wobbleTop1 = (rnd.nextDouble() - 0.5) * 1.5;
    final wobbleTop2 = (rnd.nextDouble() - 0.5) * 1.5;
    final wobbleBot1 = (rnd.nextDouble() - 0.5) * 1.5;
    final wobbleBot2 = (rnd.nextDouble() - 0.5) * 1.5;

    final path = Path();
    path.moveTo(left + r, top + wobbleTop1);
    path.cubicTo(
      left + w * 0.35, top + wobbleTop1,
      left + w * 0.65, top + wobbleTop2,
      right - r, top + wobbleTop2,
    );
    path.quadraticBezierTo(
      right + (rnd.nextDouble() - 0.5) * 1.1,
      top + h * 0.5,
      right - r,
      bottom + wobbleBot2,
    );
    path.cubicTo(
      left + w * 0.65, bottom + wobbleBot2,
      left + w * 0.35, bottom + wobbleBot1,
      left + r, bottom + wobbleBot1,
    );
    path.quadraticBezierTo(
      left - (rnd.nextDouble() - 0.5) * 1.1,
      top + h * 0.5,
      left + r,
      top + wobbleTop1,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final trackPath = _buildWobblyBarPath(size, inset: 1.0, s: 0);

    // 1. Sert eskiz alt gölgesi
    canvas.save();
    canvas.translate(1.4, 1.4);
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = strokeColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // 2. Track Zemin Dolgusu
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill,
    );

    // 3. İlerleme Dolgusu + Kurşun Kalem Tarama Çizgileri
    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped > 0.005) {
      final fillW = size.width * clamped;
      canvas.save();
      canvas.clipPath(trackPath);

      // Ana renk dolgusu
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillW, size.height),
        Paint()..color = barColor,
      );

      // Çapraz kurşun kalem eskiz taraması (Hatching)
      final hatchPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.22)
        ..strokeWidth = 1.0;
      for (double x = -size.height; x < fillW + size.height; x += 5.5) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.7, 0),
          hatchPaint,
        );
      }

      // İlerleme bitişine el çizimi dik ayırıcı çizgi
      if (clamped < 0.98) {
        final capPaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(fillW, 1),
          Offset(fillW, size.height - 1),
          capPaint,
        );
      }
      canvas.restore();
    }

    // 4. Ana Dış Serbest El Çizgisi (Wobbly Contour)
    final mainStroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, mainStroke);

    // 5. İkinci Serbest El Taslak Çizgisi (Eskiz Defteri Havası)
    final draftPath = _buildWobblyBarPath(size, inset: 1.5, s: 13);
    final draftStroke = Paint()
      ..color = strokeColor.withValues(alpha: 0.32)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(draftPath, draftStroke);
  }

  @override
  bool shouldRepaint(covariant _HandDrawnDomainBarPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.barColor != barColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.seed != seed;
  }
}

class _SummaryBox extends StatelessWidget {
  final Widget customIcon;
  final String label;
  final String value;
  final Color lightBgColor;
  final Color darkBgColor;
  final Color lightLabelColor;
  final Color lightIconColor;
  final Color pencilColor;
  final bool isDark;

  const _SummaryBox({
    required this.customIcon,
    required this.label,
    required this.value,
    required this.lightBgColor,
    required this.darkBgColor,
    required this.lightLabelColor,
    required this.lightIconColor,
    required this.pencilColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SketchCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      backgroundColor: isDark ? darkBgColor : lightBgColor,
      borderColor: pencilColor,
      borderWidth: 1.6,
      borderRadius: 12,
      shadowOffset: const Offset(2.0, 2.0),
      child: Column(
        children: [
          customIcon,
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pencilLightDark : lightLabelColor,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.pencilWhite : AppColors.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
