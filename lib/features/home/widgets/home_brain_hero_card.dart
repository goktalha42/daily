import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/daily_play_service.dart';
import '../../../core/services/game_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sketch_badge_icons.dart';
import '../../../core/widgets/sketch_countdown_timer.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';
import 'daily_genius_certificate_dialog.dart';
import 'weekly_brain_report_dialog.dart';

/// Zühtü Arenası Ana Sayfa Canlı, Koreografili & %100 El Çizimi Beyin Gücü Hero Kartı.
/// - Sıfır sabit/sahte veri: tüm değerler gerçek oyun kayıtlarından ve psikometrik IQ motorundan akar.
/// - Sıfır düz kutu: tüm rozetler, ilerleme çubukları ve günlük mühürler el çizimi CustomPainter / SketchCard ile çizilir.
/// - Karta dokunulduğunda interaktif "6 Bilişsel Alan & 7 Günlük Seri Karnesi" yumuşakça açılır.
class HomeBrainHeroCard extends StatefulWidget {
  final int userIQ;
  final Map<GameType, GamePerformanceData> statsMap;
  final DailyPlayState dailyPlayState;
  final String activeDateKey;
  final VoidCallback? onStreakTap;
  final ValueChanged<String>? onDateSelected;
  final VoidCallback? onOpenTimeMachine;

  const HomeBrainHeroCard({
    super.key,
    required this.userIQ,
    required this.statsMap,
    required this.dailyPlayState,
    required this.activeDateKey,
    this.onStreakTap,
    this.onDateSelected,
    this.onOpenTimeMachine,
  });

  @override
  State<HomeBrainHeroCard> createState() => _HomeBrainHeroCardState();
}

class _HomeBrainHeroCardState extends State<HomeBrainHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late int _fromIQ;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fromIQ = math.max(88, widget.userIQ - 12);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant HomeBrainHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userIQ != widget.userIQ) {
      _fromIQ = oldWidget.userIQ;
      _entranceController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onStreakTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final subtleTextColor =
        isDark ? AppColors.pencilGrayDark : AppColors.pencilGray;

    // 1. Dinamik Seri ve Rekor Hesaplamaları
    final int currentStreak = widget.dailyPlayState.getCurrentStreak();
    final int maxStreak = widget.dailyPlayState.getMaxStreak();

    // 2. Kategori Çeşitliliği, Toplam Oyun ve Bugün Çözülenler
    int playedCategories = 0;
    int totalGamesPlayed = 0;
    int bestDurationMs = 0;
    for (final perf in widget.statsMap.values) {
      if (perf.hasPlayed) {
        playedCategories++;
        totalGamesPlayed += perf.totalGamesPlayed;
        if (perf.bestDurationMs > 0 &&
            (bestDurationMs == 0 || perf.bestDurationMs < bestDurationMs)) {
          bestDurationMs = perf.bestDurationMs;
        }
      }
    }

    int todayCompleted = 0;
    for (final game in GameType.values) {
      if (widget.dailyPlayState.isCompleted(game, widget.activeDateKey)) {
        todayCompleted++;
      }
    }

    // 3. Psikometrik Seviye, Sonraki Hedef ve Gauss Yüzdelik Dilimi
    final milestone =
        IQMilestone.currentMilestone(widget.userIQ) ?? IQMilestone.all.first;
    final nextMilestone = IQMilestone.nextMilestone(widget.userIQ);
    final double betterThanPercent =
        IQMilestone.gaussianBetterThanPercent(widget.userIQ);

    // Mevcut seviye ile sonraki seviye arasındaki ilerleme oranı (0.0 .. 1.0)
    final double milestoneProgress;
    if (nextMilestone == null) {
      milestoneProgress = 1.0;
    } else {
      final int floorIQ =
          widget.userIQ < 100 ? 90 : milestone.iqThreshold;
      final int span = math.max(1, nextMilestone.iqThreshold - floorIQ);
      milestoneProgress =
          ((widget.userIQ - floorIQ) / span).clamp(0.08, 0.96);
    }

    // 4. Üst Rozet Bilgisi
    final badgeInfo = _resolveTopBadge(
      userIQ: widget.userIQ,
      playedCategories: playedCategories,
    );

    // 5. Dinamik Durum Cümlesi
    final String dynamicHeadline;
    if (todayCompleted == GameType.values.length) {
      dynamicHeadline =
          '6/6 günlük bulmaca fethedildi! Zihin profilin tam güçte.';
    } else if (playedCategories == 0) {
      dynamicHeadline =
          'Kalibrasyonu başlatmak için ilk bulmacanı çöz • 6 alan seni bekliyor!';
    } else if (todayCompleted > 0) {
      dynamicHeadline =
          'Bugün $todayCompleted/6 çözüldü • Nüfusun %${betterThanPercent.toStringAsFixed(1)}\'inden üstünsün!';
    } else if (currentStreak > 0) {
      dynamicHeadline =
          '$currentStreak günlük serini korumak için bugün en az 1 oyun çöz!';
    } else if (bestDurationMs > 0) {
      dynamicHeadline =
          'En hızlı çözümün ${GameDateUtils.formatGameTime(bestDurationMs)} • Nüfusun %${betterThanPercent.toStringAsFixed(1)}\'inden üstünsün!';
    } else {
      dynamicHeadline =
          'Günün 6 yeni zekâ bulmacası hazır • Zihnini test et!';
    }

    // Koreografi eğrileri
    final cardSlideAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    final iqCountAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.88, curve: Curves.easeOutQuart),
    );
    final barFillAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.95, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final double slideOffset = (1.0 - cardSlideAnim.value) * 18.0;
        final double cardScale = 0.95 + (0.05 * cardSlideAnim.value);
        final double opacity = cardSlideAnim.value.clamp(0.0, 1.0);
        final int animatedIQ = (_fromIQ +
                ((widget.userIQ - _fromIQ) * iqCountAnim.value))
            .round();

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: Transform.scale(
              scale: cardScale,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: SketchCard(
                  onTap: _toggleExpanded,
                  enableHatching: true,
                  borderWidth: 2.6,
                  borderRadius: 20,
                  shadowOffset: const Offset(4.5, 4.5),
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. ÜST SATIR: Sol Dinamik Seviye/Kalibrasyon Rozeti & Sağ El Çizimi Sayaç
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: SketchCard(
                              backgroundColor: badgeInfo.bg,
                              borderColor: pencilColor,
                              borderWidth: 1.8,
                              borderRadius: 10,
                              shadowOffset: const Offset(1.8, 1.8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  badgeInfo.icon,
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      badgeInfo.text,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.patrickHand(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkBlack,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SketchCountdownTimer(
                            fontSize: 12.5,
                            padding: EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                          ),
                        ],
                      ),

                      const SizedBox(height: 13),

                      // 2. ORTA BÖLÜM: Yaşayan El Çizimi Beyin Madalyonu + Dinamik IQ + Seri Mührü
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Sol: Canlı Nefes Alan El Çizimi Nöral Madalyon
                          _AnimatedNeuralMedallion(
                            ambientAnimation: _ambientController,
                            isEinstein: widget.userIQ >= 148,
                            isCompleteToday:
                                todayCompleted == GameType.values.length,
                            pencilColor: pencilColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 11),

                          // Orta: Yuvarlanan IQ Sayacı, Rütbe Etiketi ve Durum Metni
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playedCategories == 0
                                      ? 'BAŞLANGIÇ KALİBRASYONU'
                                      : 'PSİKOMETRİK ZEKÂ ENDEKSİ',
                                  style: GoogleFonts.patrickHand(
                                    color: subtleTextColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 7,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      playedCategories == 0
                                          ? 'IQ 100'
                                          : 'IQ $animatedIQ',
                                      style: GoogleFonts.patrickHand(
                                        color: pencilColor,
                                        fontSize: 33,
                                        fontWeight: FontWeight.w700,
                                        height: 1.0,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SketchCard(
                                      backgroundColor: widget.userIQ >= 148
                                          ? AppColors.highlighterPurple
                                          : AppColors.skyBlue
                                              .withValues(alpha: 0.42),
                                      borderColor: pencilColor,
                                      borderWidth: 1.6,
                                      borderRadius: 8,
                                      shadowOffset: const Offset(1.5, 1.5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      child: playedCategories == 0
                                          ? Text(
                                              'TEST BEKLİYOR',
                                              style: GoogleFonts.patrickHand(
                                                color: pencilColor,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SketchBadgeIcon(
                                                  type: milestone.artType,
                                                  size: 14,
                                                  strokeColor:
                                                      widget.userIQ >= 148
                                                          ? AppColors.inkBlack
                                                          : pencilColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  milestone.title.toUpperCase(),
                                                  style:
                                                      GoogleFonts.patrickHand(
                                                    color: widget.userIQ >= 148
                                                        ? AppColors.inkBlack
                                                        : pencilColor,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dynamicHeadline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.patrickHand(
                                    color: graphiteColor,
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 9),

                          // Sağ: %100 Dinamik El Çizimi Ateşli Seri Mührü
                          _DynamicStreakStamp(
                            ambientAnimation: _ambientController,
                            currentStreak: currentStreak,
                            todayCompleted: todayCompleted,
                            pencilColor: pencilColor,
                            graphiteColor: graphiteColor,
                            isDark: isDark,
                            onTap: _toggleExpanded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 3. SONRAKİ IQ MERTEBESİ EL ÇİZİMİ TARAMALI İLERLEME ÇUBUĞU
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SketchBadgeIcon(
                                      type: nextMilestone?.artType ??
                                          BadgeArtType.einsteinBrain,
                                      size: 14,
                                      strokeColor: pencilColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        nextMilestone != null
                                            ? 'SONRAKİ HEDEF: ${nextMilestone.title.toUpperCase()} (${nextMilestone.iqThreshold} IQ)'
                                            : 'ZİRVE MERTEBE: EINSTEIN (148+ IQ AKTİF)',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 11.8,
                                          fontWeight: FontWeight.w700,
                                          color: graphiteColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                nextMilestone != null
                                    ? '${nextMilestone.iqThreshold - widget.userIQ} IQ KALDI'
                                    : 'İLK %0.1',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.sunYellow
                                      : AppColors.pencilBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 13,
                            child: CustomPaint(
                              painter: _HandDrawnMilestoneBarPainter(
                                progress:
                                    milestoneProgress * barFillAnim.value,
                                strokeColor: pencilColor,
                                fillColor: widget.userIQ >= 148
                                    ? AppColors.highlighterPurple
                                    : AppColors.sunYellow,
                                trackColor: isDark
                                    ? AppColors.surfaceSecondaryDark
                                    : AppColors.surfaceSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      // 4. ALT ŞERİT: 6 El Çizimi Günlük Oyun Mührü + Analiz Defteri Aç/Kapat Rozeti
                      SketchCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        borderRadius: 12,
                        borderWidth: 1.5,
                        shadowOffset: const Offset(1.8, 1.8),
                        backgroundColor: isDark
                            ? AppColors.surfaceSecondaryDark
                            : const Color(0xFFF5F1E8),
                        borderColor: pencilColor.withValues(alpha: 0.75),
                        child: Row(
                          children: [
                            Text(
                              'GÜNLÜK $todayCompleted/6',
                              style: GoogleFonts.patrickHand(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: todayCompleted == 6
                                    ? AppColors.success
                                    : graphiteColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                    GameType.values.length, (index) {
                                  final game = GameType.values[index];
                                  final isDone = widget.dailyPlayState
                                      .isCompleted(game, widget.activeDateKey);
                                  final double itemStart =
                                      (0.25 + index * 0.08).clamp(0.0, 0.85);
                                  final double itemEnd =
                                      (itemStart + 0.25).clamp(0.0, 1.0);
                                  final double stampScale = CurvedAnimation(
                                    parent: _entranceController,
                                    curve: Interval(itemStart, itemEnd,
                                        curve: Curves.easeOutBack),
                                  ).value;

                                  return Transform.scale(
                                    scale: stampScale.clamp(0.0, 1.15),
                                    child: _HandDrawnGameStamp(
                                      game: game,
                                      isDone: isDone,
                                      pencilColor: pencilColor,
                                      seed: index + 11,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (todayCompleted == 6) ...[
                              SketchCard(
                                onTap: () {
                                  DailyGeniusCertificateDialog.show(
                                    context,
                                    dateId: widget.activeDateKey,
                                    overallIQ: widget.userIQ,
                                    statsMap: widget.statsMap,
                                    dailyPlayState: widget.dailyPlayState,
                                  );
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                backgroundColor: AppColors.sunYellow,
                                borderColor: pencilColor,
                                borderWidth: 1.4,
                                borderRadius: 8,
                                shadowOffset: const Offset(1.2, 1.2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SketchBadgeIcon(
                                      type: BadgeArtType.centuryLaurel,
                                      size: 13,
                                      strokeColor: AppColors.inkBlack,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Karne',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            SketchCard(
                              backgroundColor: _isExpanded
                                  ? AppColors.sunYellow
                                  : (isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white),
                              borderColor: pencilColor,
                              borderWidth: 1.4,
                              borderRadius: 8,
                              shadowOffset: const Offset(1.2, 1.2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              child: Text(
                                _isExpanded ? 'Kapat ▴' : 'Analiz ▾',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isExpanded
                                      ? AppColors.inkBlack
                                      : pencilColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. İNTERAKTİF AÇILIR PANEL: 7 Günlük Seri Takvimi & 6 Bilişsel Alan Karnesi
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? _ExpandedCognitiveNotebook(
                                statsMap: widget.statsMap,
                                dailyPlayState: widget.dailyPlayState,
                                currentStreak: currentStreak,
                                maxStreak: maxStreak,
                                playedCategories: playedCategories,
                                totalGamesPlayed: totalGamesPlayed,
                                userIQ: widget.userIQ,
                                pencilColor: pencilColor,
                                graphiteColor: graphiteColor,
                                isDark: isDark,
                                activeDateKey: widget.activeDateKey,
                                onDateSelected: widget.onDateSelected,
                                onOpenTimeMachine: widget.onOpenTimeMachine,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static ({String text, Color bg, Widget icon}) _resolveTopBadge({
    required int userIQ,
    required int playedCategories,
  }) {
    if (playedCategories < 6) {
      return (
        text: 'KALİBRASYON: $playedCategories/6 BİLİŞSEL ALAN',
        bg: AppColors.sunYellow,
        icon: const SketchDoodleBrain(size: 15, color: AppColors.inkBlack),
      );
    }

    if (userIQ >= 148) {
      return (
        text: 'EINSTEIN MERTEBESİ • İLK %0.1',
        bg: AppColors.highlighterPurple,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.einsteinBrain,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    } else if (userIQ >= 140) {
      return (
        text: 'ZÜHTÜ DAHİSİ • İLK %0.4',
        bg: AppColors.sunYellow,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.zuhtuGenius,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    } else if (userIQ >= 130) {
      return (
        text: 'MENSA DÜZEYİ • İLK %2.3',
        bg: AppColors.skyBlue,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.mensaCrest,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    } else if (userIQ >= 120) {
      return (
        text: 'BÜYÜK USTA • İLK %9',
        bg: AppColors.sunYellow,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.lightbulb,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    } else if (userIQ >= 110) {
      return (
        text: 'KESKİN ZİHİN • İLK %25',
        bg: AppColors.highlighterOrange,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.sharpStar,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    } else {
      return (
        text: '6/6 ALAN AKTİF • KALİBRE EDİLDİ',
        bg: AppColors.highlighterCyan,
        icon: const SketchBadgeIcon(
          type: BadgeArtType.balanceScale,
          size: 16,
          strokeColor: AppColors.inkBlack,
        ),
      );
    }
  }
}

/// Yaşayan el çizimi nöral beyin / taç madalyonu (nefes alma ve el çizimi kıvılcım çizgileri)
class _AnimatedNeuralMedallion extends StatelessWidget {
  final Animation<double> ambientAnimation;
  final bool isEinstein;
  final bool isCompleteToday;
  final Color pencilColor;
  final bool isDark;

  const _AnimatedNeuralMedallion({
    required this.ambientAnimation,
    required this.isEinstein,
    required this.isCompleteToday,
    required this.pencilColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientAnimation,
      builder: (context, _) {
        final double t = ambientAnimation.value;
        final double floatY = (t - 0.5) * 3.0;
        final Color fill = isEinstein
            ? AppColors.highlighterPurple
            : (isCompleteToday ? AppColors.success : AppColors.sunYellow);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: SizedBox(
            width: 54,
            height: 54,
            child: CustomPaint(
              painter: _WobblyMedallionPainter(
                fillColor: fill,
                strokeColor: pencilColor,
                sparkPhase: t,
              ),
              child: Center(
                child: isEinstein
                    ? const SketchBadgeIcon(
                        type: BadgeArtType.einsteinBrain,
                        size: 27,
                        strokeColor: AppColors.inkBlack,
                      )
                    : const SketchDoodleBrain(
                        size: 26, color: AppColors.inkBlack),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// El çizimi dalgalı madalyon ve nöral kıvılcım çizgileri ressamı
class _WobblyMedallionPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double sparkPhase;

  _WobblyMedallionPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.sparkPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    // Sert kurşun kalem gölgesi
    final shadowPath = _buildWobblyCircle(center + const Offset(2.2, 2.2), radius, 7);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Ana dolgu
    final mainPath = _buildWobblyCircle(center, radius, 7);
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // İç çapraz tarama dokusu
    canvas.save();
    canvas.clipPath(mainPath);
    final hatchPaint = Paint()
      ..color = AppColors.inkBlack.withValues(alpha: 0.14)
      ..strokeWidth = 1.0;
    for (double i = -size.width; i < size.width * 2; i += 6.5) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height * 0.65, 0),
        hatchPaint,
      );
    }
    canvas.restore();

    // Çift vuruşlu el çizimi çember konturu
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    final secondRing = _buildWobblyCircle(center, radius * 0.96, 19);
    canvas.drawPath(
      secondRing,
      Paint()
        ..color = strokeColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Etrafında nefes alan 4 el çizimi kıvılcım çizgisi
    final sparkPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.45 + 0.45 * sparkPhase)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const angles = [-0.75, 0.75, 2.38, -2.38];
    final innerR = radius + 2.5 + (sparkPhase * 1.2);
    final outerR = innerR + 3.0 + (sparkPhase * 1.8);
    for (final a in angles) {
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * innerR,
            center.dy + math.sin(a) * innerR),
        Offset(center.dx + math.cos(a) * outerR,
            center.dy + math.sin(a) * outerR),
        sparkPaint,
      );
    }
  }

  Path _buildWobblyCircle(Offset center, double radius, int seed) {
    final rnd = math.Random(seed);
    final path = Path();
    const steps = 16;
    final pts = List.generate(steps, (i) {
      final angle = (i / steps) * math.pi * 2;
      final jitter = (rnd.nextDouble() - 0.5) * 2.2;
      return Offset(
        center.dx + math.cos(angle) * (radius + jitter),
        center.dy + math.sin(angle) * (radius + jitter),
      );
    });
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < steps; i++) {
      final next = pts[(i + 1) % steps];
      final mid = Offset(
        (pts[i].dx + next.dx) / 2,
        (pts[i].dy + next.dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _WobblyMedallionPainter oldDelegate) {
    return oldDelegate.sparkPhase != sparkPhase ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

/// Sağ taraftaki %100 dinamik el çizimi seri mührü
class _DynamicStreakStamp extends StatelessWidget {
  final Animation<double> ambientAnimation;
  final int currentStreak;
  final int todayCompleted;
  final Color pencilColor;
  final Color graphiteColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DynamicStreakStamp({
    required this.ambientAnimation,
    required this.currentStreak,
    required this.todayCompleted,
    required this.pencilColor,
    required this.graphiteColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStreak = currentStreak > 0;
    final bool securedToday = todayCompleted > 0;

    final Color bg = hasStreak
        ? (securedToday ? AppColors.highlighterOrange : AppColors.sunYellow)
        : (isDark
            ? AppColors.surfaceSecondaryDark
            : AppColors.surfaceSecondaryLight);

    final String statusLabel;
    if (!hasStreak) {
      statusLabel = 'BAŞLAT';
    } else if (securedToday) {
      statusLabel = 'AKTİF ✓';
    } else {
      statusLabel = 'KORU!';
    }

    return SketchCard(
      onTap: onTap,
      backgroundColor: bg,
      borderColor: pencilColor,
      borderWidth: 2.1,
      borderRadius: 14,
      shadowOffset: const Offset(2.8, 2.8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: ambientAnimation,
              builder: (context, child) {
                final scale = hasStreak
                    ? (0.96 + 0.14 * ambientAnimation.value)
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: SketchDoodleFlame(
                size: 24,
                color: hasStreak ? AppColors.inkBlack : graphiteColor,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$currentStreak GÜN',
                style: GoogleFonts.patrickHand(
                  color: hasStreak ? AppColors.inkBlack : pencilColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                statusLabel,
                style: GoogleFonts.patrickHand(
                  color: hasStreak ? AppColors.inkBlack : graphiteColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El çizimi dalgalı ve çapraz taramalı IQ hedef ilerleme çubuğu ressamı
class _HandDrawnMilestoneBarPainter extends CustomPainter {
  final double progress;
  final Color strokeColor;
  final Color fillColor;
  final Color trackColor;

  _HandDrawnMilestoneBarPainter({
    required this.progress,
    required this.strokeColor,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPath = _buildWobblyBarPath(size, seed: 31);

    // Sert alt gölge
    canvas.save();
    canvas.translate(1.5, 1.5);
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // Zemin
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill,
    );

    // İlerleme dolgusu + çapraz kurşun kalem taraması
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0.01) {
      final fillW = size.width * clamped;
      canvas.save();
      canvas.clipPath(trackPath);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillW, size.height),
        Paint()..color = fillColor,
      );

      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.22)
        ..strokeWidth = 1.1;
      for (double x = -size.height; x < fillW + size.height; x += 5.5) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.75, 0),
          hatchPaint,
        );
      }

      // Sağ bitiş el çizimi dikey sınır çizgisi
      if (clamped < 0.99) {
        canvas.drawLine(
          Offset(fillW, 0.5),
          Offset(fillW - 1.0, size.height - 0.5),
          Paint()
            ..color = strokeColor
            ..strokeWidth = 1.8,
        );
      }
      canvas.restore();
    }

    // Çift vuruşlu el çizimi dış kontur
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _buildWobblyBarPath(size, seed: 53, inset: 0.7),
      Paint()
        ..color = strokeColor.withValues(alpha: 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  Path _buildWobblyBarPath(Size size, {required int seed, double inset = 0.8}) {
    final r = (size.height / 2) - inset;
    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;
    final midX = (left + right) / 2;
    final wobble = (seed % 3 == 0) ? 0.6 : -0.6;

    final path = Path();
    path.moveTo(left + r, top);
    path.quadraticBezierTo(midX, top + wobble, right - r, top);
    path.arcToPoint(
      Offset(right - r, bottom),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.quadraticBezierTo(midX, bottom - wobble, left + r, bottom);
    path.arcToPoint(
      Offset(left + r, top),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HandDrawnMilestoneBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

/// Düz Container yerine %100 el çizimi (çift konturlu + taramalı + el çizimi tikli) günlük oyun mührü
class _HandDrawnGameStamp extends StatelessWidget {
  final GameType game;
  final bool isDone;
  final Color pencilColor;
  final int seed;

  const _HandDrawnGameStamp({
    required this.game,
    required this.isDone,
    required this.pencilColor,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${game.title}: ${isDone ? "Tamamlandı" : "Bekliyor"}',
      child: SizedBox(
        width: 25,
        height: 25,
        child: CustomPaint(
          painter: _WobblyGameStampPainter(
            isDone: isDone,
            fillColor: game.color,
            strokeColor: pencilColor,
            seed: seed,
          ),
          child: Center(
            child: isDone
                ? const SizedBox.shrink()
                : Text(
                    game.title.substring(0, 1),
                    style: GoogleFonts.patrickHand(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: pencilColor.withValues(alpha: 0.72),
                      height: 1.0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _WobblyGameStampPainter extends CustomPainter {
  final bool isDone;
  final Color fillColor;
  final Color strokeColor;
  final int seed;

  _WobblyGameStampPainter({
    required this.isDone,
    required this.fillColor,
    required this.strokeColor,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2.2;
    final stampPath = _wobblyStamp(center, radius, seed);

    if (isDone) {
      // Sert mühür gölgesi
      canvas.drawPath(
        _wobblyStamp(center + const Offset(1.3, 1.3), radius, seed),
        Paint()
          ..color = AppColors.inkBlack.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill,
      );

      // Renkli mürekkep dolgusu
      canvas.drawPath(
        stampPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );

      // Çapraz tarama
      canvas.save();
      canvas.clipPath(stampPath);
      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.16)
        ..strokeWidth = 0.9;
      for (double x = -size.height; x < size.width + size.height; x += 4.5) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.7, 0),
          hatchPaint,
        );
      }
      canvas.restore();

      // El çizimi tik işareti (checkmark)
      final checkPath = Path()
        ..moveTo(size.width * 0.28, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.68)
        ..lineTo(size.width * 0.73, size.height * 0.34);
      canvas.drawPath(
        checkPath,
        Paint()
          ..color = AppColors.inkBlack
          ..strokeWidth = 2.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Dış el çizimi çift kontur
    canvas.drawPath(
      stampPath,
      Paint()
        ..color = isDone ? strokeColor : strokeColor.withValues(alpha: 0.5)
        ..strokeWidth = isDone ? 1.7 : 1.25
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _wobblyStamp(center, radius * 0.94, seed + 17),
      Paint()
        ..color = strokeColor.withValues(alpha: isDone ? 0.45 : 0.25)
        ..strokeWidth = 0.75
        ..style = PaintingStyle.stroke,
    );
  }

  Path _wobblyStamp(Offset center, double radius, int s) {
    final rnd = math.Random(s);
    const count = 12;
    final pts = List.generate(count, (i) {
      final a = (i / count) * math.pi * 2;
      final r = radius + (rnd.nextDouble() - 0.5) * 1.5;
      return Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
    });
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < count; i++) {
      final next = pts[(i + 1) % count];
      path.quadraticBezierTo(
        pts[i].dx,
        pts[i].dy,
        (pts[i].dx + next.dx) / 2,
        (pts[i].dy + next.dy) / 2,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _WobblyGameStampPainter oldDelegate) {
    return oldDelegate.isDone != isDone ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

/// Karta dokunulduğunda açılan "Son 7 Gün Seri Takvimi & 6 Bilişsel Alan Karnesi"
class _ExpandedCognitiveNotebook extends StatelessWidget {
  final Map<GameType, GamePerformanceData> statsMap;
  final DailyPlayState dailyPlayState;
  final int currentStreak;
  final int maxStreak;
  final int playedCategories;
  final int totalGamesPlayed;
  final int userIQ;
  final Color pencilColor;
  final Color graphiteColor;
  final bool isDark;
  final String activeDateKey;
  final ValueChanged<String>? onDateSelected;
  final VoidCallback? onOpenTimeMachine;

  const _ExpandedCognitiveNotebook({
    required this.statsMap,
    required this.dailyPlayState,
    required this.currentStreak,
    required this.maxStreak,
    required this.playedCategories,
    required this.totalGamesPlayed,
    required this.userIQ,
    required this.pencilColor,
    required this.graphiteColor,
    required this.isDark,
    required this.activeDateKey,
    this.onDateSelected,
    this.onOpenTimeMachine,
  });

  static const List<String> _weekdayShort = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool _hasAnyPlayOnDate(String dateKey) {
    for (final r in dailyPlayState.records.values) {
      if (r.dateId == dateKey) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final activeDate = GameDateUtils.getActiveDate();
    final todayClean =
        DateTime(activeDate.year, activeDate.month, activeDate.day);

    // Son 7 gün (bugün en sağda)
    final last7Days = List.generate(7, (idx) {
      return todayClean.subtract(Duration(days: 6 - idx));
    });

    // Einstein kriter ilerlemesi
    int minCategoryPlays = playedCategories == 6 ? 999999 : 0;
    if (playedCategories == 6) {
      for (final g in GameType.values) {
        final c = statsMap[g]?.totalGamesPlayed ?? 0;
        if (c < minCategoryPlays) minCategoryPlays = c;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 10,
            thickness: 1.2,
            color: pencilColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 6),

          // BÖLÜM A: Son 7 Günlük Gerçek Seri Takvimi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SON 7 GÜN SERİ TAKVİMİ',
                style: GoogleFonts.patrickHand(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: pencilColor,
                  letterSpacing: 0.4,
                ),
              ),
              if (onOpenTimeMachine != null)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOpenTimeMachine?.call();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SketchDoodleHourglass(size: 13, color: pencilColor),
                        const SizedBox(width: 4),
                        Text(
                          'Tüm Arşiv',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pencilColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Aktif: $currentStreak Gün • Rekor: $maxStreak Gün (Arşiv oyunları seriyi etkilemez)',
            style: GoogleFonts.patrickHand(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: graphiteColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(last7Days.length, (i) {
              final day = last7Days[i];
              final key = _dateKey(day);
              final played = _hasAnyPlayOnDate(key);
              final isToday = i == last7Days.length - 1;
              final isSelected = key == activeDateKey;
              final dayName = _weekdayShort[day.weekday - 1];

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDateSelected?.call(key);
                    },
                    borderRadius: BorderRadius.circular(9),
                    child: SketchCard(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      borderRadius: 9,
                      borderWidth: isSelected ? 2.4 : (isToday ? 2.0 : 1.3),
                      shadowOffset: isSelected
                          ? const Offset(2.2, 2.2)
                          : (played
                              ? const Offset(1.8, 1.8)
                              : const Offset(0.8, 0.8)),
                      backgroundColor: isSelected
                          ? AppColors.skyBlue
                          : (played
                              ? AppColors.sunYellow
                              : (isDark
                                  ? AppColors.surfaceSecondaryDark
                                  : Colors.white)),
                      borderColor: isSelected
                          ? pencilColor
                          : (isToday
                              ? pencilColor
                              : pencilColor.withValues(alpha: 0.6)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.patrickHand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (isSelected || played)
                                  ? AppColors.inkBlack
                                  : graphiteColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          isSelected
                              ? const SizedBox(
                                  height: 16,
                                  child: Center(
                                    child: SketchDoodleTarget(
                                      size: 14,
                                      color: AppColors.pencilBlack,
                                      fillColor: AppColors.highlighterPink,
                                    ),
                                  ),
                                )
                              : Text(
                                  played ? '✓' : '${day.day}',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: (isSelected || played)
                                        ? AppColors.inkBlack
                                        : pencilColor.withValues(alpha: 0.55),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // BÖLÜM B: 6 Bilişsel Alan Yetenek Haritası
          Text(
            '6 BİLİŞSEL ALAN KARNESİ',
            style: GoogleFonts.patrickHand(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: pencilColor,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          ...GameType.values.map((game) {
            final perf = statsMap[game];
            final hasPlayed = perf != null && perf.hasPlayed;
            final domainIQ = perf?.domainIQ ?? 100;
            final double normBar = hasPlayed
                ? ((domainIQ - 85.0) / (152.0 - 85.0)).clamp(0.10, 1.0)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      '${game.shortDomainLabel} (${game.title})',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.patrickHand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: graphiteColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 10,
                      child: CustomPaint(
                        painter: _HandDrawnMilestoneBarPainter(
                          progress: normBar,
                          strokeColor: pencilColor.withValues(alpha: 0.8),
                          fillColor: game.color,
                          trackColor: isDark
                              ? AppColors.surfaceSecondaryDark
                              : AppColors.surfaceSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      hasPlayed ? '$domainIQ IQ' : '—',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.patrickHand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: hasPlayed ? pencilColor : graphiteColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // BÖLÜM C: Einstein Mertebesi Kriter Notu
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            borderRadius: 10,
            borderWidth: 1.4,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: isDark
                ? AppColors.surfaceSecondaryDark
                : const Color(0xFFFFFBEB),
            borderColor: pencilColor.withValues(alpha: 0.7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SketchBadgeIcon(
                    type: BadgeArtType.einsteinBrain,
                    size: 16,
                    strokeColor: pencilColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    userIQ >= 148
                        ? 'Einstein Mertebesi Aktif! Tüm 6 bilişsel alanda %99.9\'luk efsanevi istikrarı koruyorsun.'
                        : 'Einstein Kriteri (148+ IQ): $playedCategories/6 alan • En az ${math.min(5, minCategoryPlays)}/5 kategori derinliği • ${math.min(35, totalGamesPlayed)}/35 toplam çözüm ve elit hız istikrarı.',
                    style: GoogleFonts.patrickHand(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w700,
                      color: pencilColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Haftalık Zeka Raporu Açma Butonu (Pazar Akşamı Özeti)
          SketchCard(
            onTap: () {
              HapticFeedback.mediumImpact();
              WeeklyBrainReportDialog.show(
                context,
                dailyPlayState: dailyPlayState,
                overallIQ: userIQ,
              );
            },
            backgroundColor: AppColors.sunYellow,
            borderColor: pencilColor,
            borderWidth: 2.0,
            borderRadius: 12,
            shadowOffset: const Offset(2.0, 2.0),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights_rounded, size: 18, color: AppColors.inkBlack),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Haftalık Zeka Raporu (Pazar Özeti) ➔',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
