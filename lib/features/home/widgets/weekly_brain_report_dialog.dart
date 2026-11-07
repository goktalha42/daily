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
                            const Text('🧠 ', style: TextStyle(fontSize: 20)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: pencilColor, width: 1.5),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '🔥 Haftalık Seri: ${stats.weeklyStreak} Gün!',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: stats.weeklyStreak >= 7 ? AppColors.sunYellow : pencilColor,
                                ),
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
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _CognitiveDomainBar(
                        gameTitle: '${game.title} ($domainName)',
                        percent: percent,
                        solvedCount: solvedCount,
                        barColor: color,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // 4. Haftalık Özet 3'lü Metrik Kutusu
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          icon: Icons.local_fire_department_rounded,
                          label: 'SERİ',
                          value: '${stats.weeklyStreak}/7 Gün',
                          bgColor: AppColors.highlighterOrange,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryBox(
                          icon: Icons.extension_rounded,
                          label: 'BULMACA',
                          value: '${stats.totalPuzzlesSolved} Adet',
                          bgColor: AppColors.skyBlue,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryBox(
                          icon: Icons.psychology_rounded,
                          label: 'ZEKÂ',
                          value: '$overallIQ IQ',
                          bgColor: AppColors.highlighterPurple,
                          pencilColor: pencilColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 5. Zühtü Koç Tavsiyesi Post-it Notu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pencilColor.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 18)),
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
                                      '📋 Haftalık zeka raporu kopyalandı!',
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
                      // Raporu Paylaş Butonu (WhatsApp / Instagram / Sosyal Medya)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
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
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Kapat Butonu
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

  const _CognitiveDomainBar({
    required this.gameTitle,
    required this.percent,
    required this.solvedCount,
    required this.barColor,
    required this.pencilColor,
    required this.isDark,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pencilWhite : AppColors.pencilBlack,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '%${percent.toStringAsFixed(0)} ($solvedCount oyun)',
              style: GoogleFonts.patrickHand(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: percent > 0
                    ? (isDark ? AppColors.pencilWhite : AppColors.pencilBlack)
                    : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: pencilColor, width: 1.4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillW = constraints.maxWidth * clampedRatio;
              if (fillW <= 0) return const SizedBox.shrink();

              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4.5),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color pencilColor;
  final bool isDark;

  const _SummaryBox({
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
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: pencilColor,
            ),
          ),
        ],
      ),
    );
  }
}
