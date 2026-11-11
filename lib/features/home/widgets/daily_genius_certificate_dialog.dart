import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/badge_model.dart';
import '../../../core/services/daily_play_service.dart';
import '../../../core/services/game_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/share_card_helper.dart';
import '../../../core/widgets/sketch_badge_icons.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';

/// Günlük Zeka Defteri Özeti (Günün 6/6 Tamamlanış Sertifikası)
/// 6 oyunun tamamı bittiğinde oyuncuya özel hazırlanan, paylaşılabilir skeç diploması.
class DailyGeniusCertificateDialog extends StatefulWidget {
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
  State<DailyGeniusCertificateDialog> createState() =>
      _DailyGeniusCertificateDialogState();
}

class _DailyGeniusCertificateDialogState
    extends State<DailyGeniusCertificateDialog> {
  final GlobalKey _certKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.cardBgDark : AppColors.surfaceLight;
    final subtitleColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    final completedGames = widget.dailyPlayState.getCompletedGamesForDate(widget.dateId);
    int totalDayScore = 0;
    int totalDayDurationMs = 0;
    for (final r in completedGames.values) {
      totalDayScore += r.score;
      totalDayDurationMs += r.durationMs;
    }

    final overallIQ = widget.overallIQ;
    final todayBadges = widget.todayBadges;
    final activeMilestone =
        IQMilestone.currentMilestone(widget.overallIQ) ?? IQMilestone.all.first;
    final formattedDate =
        GameDateUtils.getFormattedDate(GameDateUtils.parseLevelId(widget.dateId));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: RepaintBoundary(
              key: _certKey,
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
                    '$formattedDate tarihindeki 6 zeka bulmacasını da başarıyla bitirip günün antrenmanını tamamladın! Harika bir zihin performansı sergiledin.',
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
                              HandDrawnCheckBadge(
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
                          onTap: _isSharing
                              ? null
                              : () async {
                                  setState(() => _isSharing = true);
                                  HapticFeedback.heavyImpact();
                                  final certText = StringBuffer();
                                  certText.writeln(
                                      '🎓 ZÜHTÜ GÜNÜN DÂHİSİ SERTİFİKASI (6/6 TAM DENGESİ) ⚡');
                                  certText.writeln('📅 Tarih: $formattedDate');
                                  certText.writeln(
                                      '🧠 Genel Bilişsel Seviye: $overallIQ IQ (${activeMilestone.title})');
                                  certText.writeln(
                                      '🏆 Günlük Toplam Skor: $totalDayScore P');
                                  certText.writeln(
                                      '⏱️ Toplam Çözüm Süresi: ${GameDateUtils.formatGameTime(totalDayDurationMs)}');
                                  if (todayBadges.isNotEmpty) {
                                    certText.writeln(
                                        '🎖️ Kazanılan Rozetler: ${todayBadges.map((b) => b.title).join(", ")}');
                                  }
                                  certText.writeln('');
                                  certText.writeln(
                                      'Bugünün 6 bulmacasını da çözüp zeka karnemi tamamladım! 🧠🔥');
                                  certText.writeln(
                                      'Sen de zihnini sına: 👉 https://zuhtu.app');

                                  try {
                                    final success =
                                        await ShareCardHelper.shareCard(
                                      boundaryKey: _certKey,
                                      shareText: certText.toString(),
                                      subject:
                                          '🎓 Zühtü Günün Dâhisi Sertifikası: $overallIQ IQ',
                                      fileName:
                                          'zuhtu_gunun_dahisi_sertifikasi.png',
                                    );
                                    if (!success && mounted) {
                                      await Clipboard.setData(
                                          ClipboardData(text: certText.toString()));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Görsel paylaşılamadı, sertifika metni panoya kopyalandı! 📋',
                                            style: GoogleFonts.patrickHand(
                                                fontSize: 15),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    await Clipboard.setData(
                                        ClipboardData(text: certText.toString()));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '🎉 Sertifika metni panoya kopyalandı!',
                                            style: GoogleFonts.patrickHand(
                                                fontSize: 15),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSharing = false);
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
                                Icon(Icons.share_rounded,
                                    size: 18, color: pencilColor),
                              const SizedBox(width: 6),
                              Text(
                                _isSharing ? 'Hazırlanıyor...' : 'Paylaş',
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
