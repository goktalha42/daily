import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/badge_model.dart';
import '../../../core/services/daily_play_service.dart';
import '../../../core/services/game_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sketch_badge_icons.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';

/// Günlük Zeka Defteri Özeti (Günün 6/6 Tamamlanış Sertifikası)
/// 6 oyunun tamamı bittiğinde oyuncuya özel hazırlanan, paylaşılabilir skeç diploması.
class DailyGeniusCertificateDialog extends StatelessWidget {
  final String dateId;
  final int overallIQ;
  final Map<GameType, GamePerformanceData> statsMap;
  final DailyPlayState dailyPlayState;
  final List<DailyBadge> todayBadges;

  const DailyGeniusCertificateDialog({
    super.key,
    required this.dateId,
    required this.overallIQ,
    required this.statsMap,
    required this.dailyPlayState,
    this.todayBadges = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required String dateId,
    required int overallIQ,
    required Map<GameType, GamePerformanceData> statsMap,
    required DailyPlayState dailyPlayState,
    List<DailyBadge> todayBadges = const [],
  }) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailyGeniusCertificateDialog(
        dateId: dateId,
        overallIQ: overallIQ,
        statsMap: statsMap,
        dailyPlayState: dailyPlayState,
        todayBadges: todayBadges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.cardBgDark : AppColors.surfaceLight;
    final subtitleColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    final completedGames = dailyPlayState.getCompletedGamesForDate(dateId);
    int totalDayScore = 0;
    int totalDayDurationMs = 0;
    for (final r in completedGames.values) {
      totalDayScore += r.score;
      totalDayDurationMs += r.durationMs;
    }

    final activeMilestone =
        IQMilestone.currentMilestone(overallIQ) ?? IQMilestone.all.first;
    final formattedDate =
        GameDateUtils.getFormattedDate(GameDateUtils.parseLevelId(dateId));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SketchCard(
              backgroundColor: cardBg,
              borderColor: pencilColor,
              borderWidth: 2.8,
              borderRadius: 22,
              shadowOffset: const Offset(5, 5),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Sertifika Üst Mührü & Başlık
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
                        child: SketchBadgeIcon(
                          type: BadgeArtType.centuryLaurel,
                          size: 26,
                          strokeColor: pencilColor,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'GÜNÜN DÂHİSİ SERTİFİKASI',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '6 / 6 TAM GÜN DENGESİ',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.8,
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
                          size: 26,
                          strokeColor: pencilColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    color: pencilColor.withValues(alpha: 0.35),
                    thickness: 1.5,
                  ),
                  const SizedBox(height: 8),

                  // 2. Oyuncu Onur Metni & Tarih
                  Text(
                    '$formattedDate tarihindeki tüm zihinsel egzersizleri ve psikometrik bulmacaları başarıyla tamamlayarak zihinsel disiplinini kanıtladın.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      color: subtitleColor,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Genel Performans Rozetleri (IQ, Puan, Toplam Süre)
                  Row(
                    children: [
                      Expanded(
                        child: _CertificateMetricCard(
                          label: 'Beyin Gücü',
                          value: '$overallIQ IQ',
                          subValue: activeMilestone.title,
                          isDark: isDark,
                          pencilColor: pencilColor,
                          darkBgColor: AppColors.highlighterPurple.withValues(alpha: 0.25),
                          lightBgColor: const Color(0xFFF3E8FF),
                          lightLabelColor: const Color(0xFF6D28D9),
                          lightSubColor: const Color(0xFF5B21B6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CertificateMetricCard(
                          label: 'Günün Puanı',
                          value: '$totalDayScore',
                          subValue: '6 Bölüm Toplamı',
                          isDark: isDark,
                          pencilColor: pencilColor,
                          darkBgColor: AppColors.sunYellow.withValues(alpha: 0.25),
                          lightBgColor: const Color(0xFFFEF3C7),
                          lightLabelColor: const Color(0xFFB45309),
                          lightSubColor: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CertificateMetricCard(
                          label: 'Toplam Süre',
                          value: GameDateUtils.formatGameTime(totalDayDurationMs),
                          subValue: 'Odaklanma',
                          isDark: isDark,
                          pencilColor: pencilColor,
                          darkBgColor: AppColors.skyBlue.withValues(alpha: 0.25),
                          lightBgColor: const Color(0xFFE0F2FE),
                          lightLabelColor: const Color(0xFF0369A1),
                          lightSubColor: const Color(0xFF075985),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. 6 Oyunluk Karne Izgarası
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '📋 Günün 6 Bilişsel Alan Karnesi:',
                      style: GoogleFonts.patrickHand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: pencilColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SketchCard(
                    backgroundColor: isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFFBF9F3),
                    borderColor: pencilColor,
                    borderWidth: 1.8,
                    borderRadius: 14,
                    shadowOffset: const Offset(2.5, 2.5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      children: GameType.values.map((game) {
                        final rec = completedGames[game];
                        final score = rec?.score ?? 0;
                        final duration = rec != null
                            ? GameDateUtils.formatGameTime(rec.durationMs)
                            : '--:--';
                        final isDone = rec != null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _HandDrawnCheckBadge(
                                isDone: isDone,
                                pencilColor: pencilColor,
                                isDark: isDark,
                                seed: game.index * 13 + 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.title,
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: pencilColor,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      game.cognitiveDomainLabel,
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 11.5,
                                        color: subtitleColor,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$score P',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                duration,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 5. Günün Açılan Rozetleri (Varsa)
                  if (todayBadges.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '🎖️ Bugün Kazanılan Yeni Rozetler:',
                        style: GoogleFonts.patrickHand(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: pencilColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: todayBadges.map((b) {
                        return SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: b.color.withValues(alpha: 0.25),
                          borderColor: pencilColor,
                          borderWidth: 1.4,
                          borderRadius: 10,
                          shadowOffset: const Offset(1.5, 1.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SketchBadgeIcon(
                                type: b.artType,
                                size: 16,
                                strokeColor: pencilColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b.title,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 6. Eylem Butonları
                  Row(
                    children: [
                      Expanded(
                        child: SketchCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          borderColor: pencilColor,
                          borderWidth: 2.0,
                          borderRadius: 12,
                          shadowOffset: const Offset(2.0, 2.0),
                          child: Center(
                            child: Text(
                              'Kapat',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SketchCard(
                          onTap: () async {
                            HapticFeedback.heavyImpact();
                            final certText = StringBuffer();
                            certText.writeln('🎓 ZÜHTÜ GÜNÜN DÂHİSİ SERTİFİKASI (6/6 TAM DENGESİ) ⚡');
                            certText.writeln('📅 Tarih: $formattedDate');
                            certText.writeln('🧠 Genel Bilişsel Seviye: $overallIQ IQ (${activeMilestone.title})');
                            certText.writeln('🏆 Günlük Toplam Skor: $totalDayScore P');
                            certText.writeln('⏱️ Toplam Çözüm Süresi: ${GameDateUtils.formatGameTime(totalDayDurationMs)}');
                            if (todayBadges.isNotEmpty) {
                              certText.writeln('🎖️ Kazanılan Rozetler: ${todayBadges.map((b) => b.title).join(", ")}');
                            }
                            certText.writeln('');
                            certText.writeln('Bugünün 6 bulmacasını da çözüp zeka karnemi tamamladım! 🧠🔥');
                            certText.writeln('Sen de zihnini sına: 👉 https://zuhtu.app');

                            try {
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: certText.toString(),
                                  subject: '🎓 Zühtü Günün Dâhisi Sertifikası: $overallIQ IQ',
                                ),
                              );
                            } catch (e) {
                              await Clipboard.setData(ClipboardData(text: certText.toString()));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🎉 Sertifika metni panoya kopyalandı!',
                                      style: GoogleFonts.patrickHand(fontSize: 15),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: AppColors.sunYellow,
                          borderColor: pencilColor,
                          borderWidth: 2.2,
                          borderRadius: 12,
                          shadowOffset: const Offset(2.5, 2.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded, size: 18, color: pencilColor),
                              const SizedBox(width: 6),
                              Text(
                                'Paylaş',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _CertificateMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final bool isDark;
  final Color pencilColor;
  final Color darkBgColor;
  final Color lightBgColor;
  final Color lightLabelColor;
  final Color lightSubColor;

  const _CertificateMetricCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.isDark,
    required this.pencilColor,
    required this.darkBgColor,
    required this.lightBgColor,
    required this.lightLabelColor,
    required this.lightSubColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? darkBgColor : lightBgColor;
    final labelColor = isDark ? pencilColor.withValues(alpha: 0.85) : lightLabelColor;
    final valueColor = isDark ? pencilColor : AppColors.inkBlack;
    final subColor = isDark ? pencilColor.withValues(alpha: 0.7) : lightSubColor;

    return SketchCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      backgroundColor: bgColor,
      borderColor: pencilColor,
      borderWidth: 1.8,
      borderRadius: 12,
      shadowOffset: const Offset(2.0, 2.0),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor,
              height: 1.1,
            ),
          ),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.patrickHand(
              fontSize: 10.5,
              fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
              color: subColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandDrawnCheckBadge extends StatelessWidget {
  final bool isDone;
  final Color pencilColor;
  final bool isDark;
  final int seed;

  const _HandDrawnCheckBadge({
    required this.isDone,
    required this.pencilColor,
    required this.isDark,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _HandDrawnCheckBadgePainter(
          isDone: isDone,
          pencilColor: pencilColor,
          isDark: isDark,
          seed: seed,
        ),
      ),
    );
  }
}

class _HandDrawnCheckBadgePainter extends CustomPainter {
  final bool isDone;
  final Color pencilColor;
  final bool isDark;
  final int seed;

  _HandDrawnCheckBadgePainter({
    required this.isDone,
    required this.pencilColor,
    required this.isDark,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = (math.min(size.width, size.height) / 2) - 2.5;

    // 1. Organik Wobbly Daire Yolu
    const pointsCount = 12;
    final path = Path();
    for (int i = 0; i < pointsCount; i++) {
      final angle = (i * 2 * math.pi) / pointsCount;
      final jitter = (rng.nextDouble() - 0.5) * 1.6;
      final r = baseRadius + jitter;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 2. Sert El Çizimi Eskiz Gölgesi
    final shadowPath = path.shift(const Offset(1.5, 1.5));
    final shadowPaint = Paint()
      ..color = pencilColor.withValues(alpha: isDark ? 0.35 : 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, shadowPaint);

    // 3. Arka Plan Dolgusu
    if (isDone) {
      final fillPaint = Paint()
        ..color = isDark ? const Color(0xFF16A34A) : const Color(0xFF22C55E)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Skeç taraması (hatching)
      canvas.save();
      canvas.clipPath(path);
      final hatchPaint = Paint()
        ..color = (isDark ? const Color(0xFF14532D) : const Color(0xFF15803D)).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      for (double x = -10; x < size.width + 10; x += 3.5) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + 8, size.height),
          hatchPaint,
        );
      }
      canvas.restore();
    } else {
      final emptyPaint = Paint()
        ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, emptyPaint);
    }

    // 4. Ana Eskiz Dış Konturu
    final borderPaint = Paint()
      ..color = pencilColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 5. İkinci Serbest El Eskiz Konturu (Taslak Havası)
    final sketchBorderPaint = Paint()
      ..color = pencilColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final secondaryPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8 + 0.3;
      final jitter = (rng.nextDouble() - 0.5) * 1.8;
      final r = baseRadius + jitter;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        secondaryPath.moveTo(x, y);
      } else {
        secondaryPath.lineTo(x, y);
      }
    }
    canvas.drawPath(secondaryPath, sketchBorderPaint);

    // 6. İç İkon: El Çizimi Kaligrafik Tik (Check) ya da Pasif Çizgi
    if (isDone) {
      final tickPath = Path();
      final p1 = Offset(cx - 4.6 + (rng.nextDouble() - 0.5) * 0.4, cy + 0.2);
      final p2 = Offset(cx - 1.2 + (rng.nextDouble() - 0.5) * 0.4, cy + 4.2);
      final p3 = Offset(cx + 4.8 + (rng.nextDouble() - 0.5) * 0.4, cy - 3.8);

      tickPath.moveTo(p1.dx, p1.dy);
      tickPath.lineTo(p2.dx, p2.dy);
      tickPath.lineTo(p3.dx, p3.dy);

      final tickShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(tickPath.shift(const Offset(0.6, 0.6)), tickShadowPaint);

      final tickPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(tickPath, tickPaint);

      final tickSubPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(p2.dx - 0.3, p2.dy - 0.2),
        Offset(p3.dx - 0.8, p3.dy + 0.5),
        tickSubPaint,
      );
    } else {
      final dashPaint = Paint()
        ..color = pencilColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx - 3.5, cy),
        Offset(cx + 3.5, cy),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandDrawnCheckBadgePainter oldDelegate) {
    return oldDelegate.isDone != isDone ||
        oldDelegate.pencilColor != pencilColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.seed != seed;
  }
}
