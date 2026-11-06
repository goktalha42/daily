import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/badge_model.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/widgets/app_button.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sketch_badge_icons.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  final BadgeCategory? initialCategory;

  const BadgesScreen({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  BadgeCategory? _selectedCategory;
  bool _onlyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeState = ref.watch(badgeServiceProvider);
    final dailyPlay = ref.watch(dailyPlayServiceProvider);
    final statsMap = ref.watch(gameStatsServiceProvider);

    final allBadges = DailyBadge.allBadges;
    final unlockedCount = allBadges.where((b) {
      final ub = badgeState[b.id];
      return ub != null && !ub.isExpired;
    }).length;

    final progressRatio =
        allBadges.isNotEmpty ? (unlockedCount / allBadges.length) : 0.0;
    final activeStreak = dailyPlay.getCurrentStreak(null);

    // Filtreleme
    List<DailyBadge> filtered = allBadges;
    if (_selectedCategory != null) {
      filtered =
          filtered.where((b) => b.category == _selectedCategory).toList();
    }
    if (_onlyUnlocked) {
      filtered = filtered.where((b) {
        final ub = badgeState[b.id];
        return ub != null && !ub.isExpired;
      }).toList();
    }

    final pencilColor = AppColors.pencil(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SketchPaperBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. ÜST BAR & BAŞLIK ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      SketchCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        padding: const EdgeInsets.all(8),
                        borderRadius: 10,
                        borderWidth: 1.6,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.surfaceOf(context),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: pencilColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.sunYellow,
                                    border: Border.fromBorderSide(
                                      BorderSide(color: pencilColor, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'KİŞİSEL GELİŞİM • BAŞARILAR',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.graphite(context),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rozetler & Başarılar',
                              style: GoogleFonts.patrickHand(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: pencilColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 2. SKEÇ ÖZET KARTI (İLERLEME VE SERİ) ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: SketchCard(
                    enableHatching: true,
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    borderWidth: 2.2,
                    shadowOffset: const Offset(3.5, 3.5),
                    backgroundColor: AppColors.surfaceOf(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SketchCard(
                              padding: EdgeInsets.all(10),
                              borderRadius: 12,
                              borderWidth: 1.6,
                              shadowOffset: Offset(2, 2),
                              backgroundColor: AppColors.sunYellow,
                              child: SketchDoodleTrophy(
                                size: 26,
                                color: AppColors.inkBlack,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Zekâ Prestiji & Koleksiyon',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: pencilColor,
                                    ),
                                  ),
                                  Text(
                                    '$unlockedCount / ${allBadges.length} Rozet Tamamlandı',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 14,
                                      color: AppColors.gray(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SketchCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              borderRadius: 8,
                              borderWidth: 1.4,
                              shadowOffset: const Offset(1.5, 1.5),
                              backgroundColor: AppColors.sunYellow,
                              child: Text(
                                '%${(progressRatio * 100).toInt()}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // %100 El Çizimi Çapraz Taramalı İlerleme Çubuğu
                        SizedBox(
                          height: 14,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BadgesSketchProgressBarPainter(
                              progress: progressRatio,
                              strokeColor: pencilColor,
                              fillColor: AppColors.sunYellow,
                              trackColor: isDark
                                  ? AppColors.surfaceSecondaryDark
                                  : AppColors.surfaceSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SketchDoodleFlame(
                                  size: 15,
                                  color: activeStreak > 0
                                      ? AppColors.highlighterOrange
                                      : AppColors.gray(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Aktif Seri: $activeStreak Gün',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: pencilColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${allBadges.length - unlockedCount} Rozet Kaldı',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 3. KATEGORİ SEÇİCİ SEKMELER (EL ÇİZİMİ CHIPS) ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'Tümü (${allBadges.length})',
                          isSelected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Başarılar',
                          leadingIcon: SketchBadgeIcon(
                            type: BadgeArtType.hexagramStar,
                            size: 16,
                            strokeColor:
                                _selectedCategory == BadgeCategory.mastery
                                    ? AppColors.inkBlack
                                    : pencilColor,
                          ),
                          isSelected:
                              _selectedCategory == BadgeCategory.mastery,
                          onTap: () => setState(
                              () => _selectedCategory = BadgeCategory.mastery),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Seriler',
                          leadingIcon: SketchBadgeIcon(
                            type: BadgeArtType.sparkFlame,
                            size: 16,
                            strokeColor:
                                _selectedCategory == BadgeCategory.streak
                                    ? AppColors.inkBlack
                                    : pencilColor,
                          ),
                          isSelected: _selectedCategory == BadgeCategory.streak,
                          onTap: () => setState(
                              () => _selectedCategory = BadgeCategory.streak),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Şampiyonluk',
                          leadingIcon: SketchBadgeIcon(
                            type: BadgeArtType.royalCrown,
                            size: 16,
                            strokeColor:
                                _selectedCategory == BadgeCategory.championship
                                    ? AppColors.inkBlack
                                    : pencilColor,
                          ),
                          isSelected:
                              _selectedCategory == BadgeCategory.championship,
                          onTap: () => setState(() =>
                              _selectedCategory = BadgeCategory.championship),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 4. SADECE KAZANILANLAR FİLTRESİ ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _onlyUnlocked = !_onlyUnlocked),
                        child: Row(
                          children: [
                            SketchCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 5,
                              borderWidth: 1.4,
                              shadowOffset: const Offset(1, 1),
                              backgroundColor: _onlyUnlocked
                                  ? AppColors.sunYellow
                                  : AppColors.surfaceOf(context),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: _onlyUnlocked
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: AppColors.inkBlack)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sadece Kazanılanları Göster',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pencilColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${filtered.length} Rozet Listeleniyor',
                        style: GoogleFonts.patrickHand(
                          fontSize: 12,
                          color: AppColors.gray(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 5. ROZET LİSTESİ (SKEÇ KARTLAR) ───────────────────────────
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Bu kategoride henüz açılan rozet bulunmuyor.',
                        style: GoogleFonts.patrickHand(
                          fontSize: 16,
                          color: AppColors.gray(context),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final badge = filtered[index];
                        final ub = badgeState[badge.id];
                        final isUnlocked = ub != null && !ub.isExpired;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildBadgeCard(
                            context,
                            badge: badge,
                            isUnlocked: isUnlocked,
                            dailyPlay: dailyPlay,
                            statsMap: statsMap,
                            unlockedAt: ub?.unlockedAt,
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    Widget? leadingIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      borderRadius: 10,
      borderWidth: isSelected ? 2.0 : 1.4,
      shadowOffset:
          isSelected ? const Offset(2.0, 2.0) : const Offset(1.5, 1.5),
      backgroundColor:
          isSelected ? AppColors.sunYellow : AppColors.surfaceOf(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.inkBlack : AppColors.pencil(context),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveBadgeProgressText({
    required DailyBadge badge,
    required DailyPlayState dailyPlay,
    required Map<GameType, GamePerformanceData> statsMap,
  }) {
    if (badge.category == BadgeCategory.streak && badge.streakDays > 0) {
      final cur = dailyPlay.getCurrentStreak(badge.relatedGame);
      return '$cur / ${badge.streakDays} Gün';
    }
    if (badge.relatedGame != null && badge.id.endsWith('_mastery')) {
      final wins =
          (statsMap[badge.relatedGame!]?.totalGamesPlayed ?? 0).clamp(0, 3);
      return '$wins / 3 Oyun';
    }
    if (badge.id == 'badge_all_rounder') {
      final playedTypes = statsMap.values.where((p) => p.hasPlayed).length;
      return '$playedTypes / ${GameType.values.length} Oyun Türü';
    }
    if (badge.id == 'badge_century_club') {
      final totalPlayed = statsMap.values
          .fold<int>(0, (sum, p) => sum + p.totalGamesPlayed)
          .clamp(0, 100);
      return '$totalPlayed / 100 Oyun';
    }
    if (badge.id == 'belt_clean_sweep') {
      final todayCount =
          dailyPlay.getCompletedCountForDate(GameDateUtils.getTodayLevelId());
      return 'Bugün $todayCount / 6 Oyun';
    }
    return null;
  }

  Widget _buildBadgeCard(
    BuildContext context, {
    required DailyBadge badge,
    required bool isUnlocked,
    required DailyPlayState dailyPlay,
    required Map<GameType, GamePerformanceData> statsMap,
    DateTime? unlockedAt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressText = isUnlocked
        ? null
        : _resolveBadgeProgressText(
            badge: badge,
            dailyPlay: dailyPlay,
            statsMap: statsMap,
          );

    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeDetailsDialog(
          context,
          badge: badge,
          isUnlocked: isUnlocked,
          progressText: progressText,
          unlockedAt: unlockedAt,
        );
      },
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      borderWidth: isUnlocked ? 2.2 : 1.5,
      shadowOffset:
          isUnlocked ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
      backgroundColor: isUnlocked
          ? badge.color.withValues(alpha: isDark ? 0.16 : 0.18)
          : AppColors.surfaceOf(context),
      child: Row(
        children: [
          // %100 El Çizimi Dalgalı Madalyon Rozet Simgesi
          SketchBadgeMedallion(
            type: badge.artType,
            accentColor: badge.color,
            isUnlocked: isUnlocked,
            size: 50,
          ),
          const SizedBox(width: 12),

          // Metinler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: GoogleFonts.patrickHand(
                    fontSize: 17,
                    fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w700,
                    color: AppColors.pencil(context),
                  ),
                ),
                Text(
                  badge.requirement,
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray(context),
                  ),
                ),
                if (progressText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'İlerleme: $progressText',
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pencil(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // El Çizimi Durum Rozeti
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: 7,
            borderWidth: 1.2,
            shadowOffset: const Offset(1, 1),
            backgroundColor: isUnlocked
                ? AppColors.sunYellow
                : (isDark ? Colors.white10 : const Color(0xFFF1EDE4)),
            borderColor: AppColors.pencil(context),
            child: isUnlocked
                ? Text(
                    '✓ AÇILDI',
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkBlack,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SketchDoodleLock(
                        size: 12,
                        color: AppColors.gray(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'KİLİTLİ',
                        style: GoogleFonts.patrickHand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray(context),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetailsDialog(
    BuildContext context, {
    required DailyBadge badge,
    required bool isUnlocked,
    String? progressText,
    DateTime? unlockedAt,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SketchCard(
            enableHatching: true,
            backgroundColor: AppColors.surfaceOf(context),
            borderRadius: 18,
            borderWidth: 2.4,
            shadowOffset: const Offset(4, 4),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SketchBadgeMedallion(
                  type: badge.artType,
                  accentColor: badge.color,
                  isUnlocked: isUnlocked,
                  size: 88,
                ),
                const SizedBox(height: 14),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pencil(context),
                  ),
                ),
                const SizedBox(height: 6),
                SketchCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  borderRadius: 7,
                  borderWidth: 1.3,
                  shadowOffset: const Offset(1.2, 1.2),
                  backgroundColor: isUnlocked
                      ? AppColors.sunYellow
                      : AppColors.surfaceSecondaryOf(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUnlocked) ...[
                        SketchDoodleLock(
                          size: 12,
                          color: AppColors.gray(context),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isUnlocked
                            ? '✓ KOLEKSİYONUNDA AÇIK'
                            : (progressText != null
                                ? 'KİLİTLİ • $progressText'
                                : 'HENÜZ KİLİTLİ'),
                        style: GoogleFonts.patrickHand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.inkBlack
                              : AppColors.gray(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 14.5,
                    color: AppColors.gray(context),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                SketchCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 10,
                  borderWidth: 1.4,
                  shadowOffset: const Offset(1.5, 1.5),
                  backgroundColor: AppColors.surfaceSecondaryOf(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: AppColors.pencil(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Kazanma Koşulu: ${badge.requirement}',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencil(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  text: isUnlocked ? 'Harika!' : 'Hedefe Devam Et',
                  onPressed: () => Navigator.of(ctx).pop(),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El çizimi dalgalı ve çapraz taramalı rozet koleksiyon ilerleme çubuğu ressamı
class _BadgesSketchProgressBarPainter extends CustomPainter {
  final double progress;
  final Color strokeColor;
  final Color fillColor;
  final Color trackColor;

  _BadgesSketchProgressBarPainter({
    required this.progress,
    required this.strokeColor,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPath = _wobblyBar(size, inset: 0.9, wobble: -0.5);

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

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0.01) {
      final fillW = math.max(size.height * 0.75, size.width * clamped);
      canvas.save();
      canvas.clipPath(trackPath);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillW, size.height),
        Paint()..color = fillColor,
      );

      final hatchPaint = Paint()
        ..color = AppColors.inkBlack.withValues(alpha: 0.20)
        ..strokeWidth = 1.05;
      for (double x = -size.height; x < fillW + size.height; x += 5.5) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height * 0.72, 0),
          hatchPaint,
        );
      }

      if (clamped < 0.99) {
        canvas.drawLine(
          Offset(fillW, 0.8),
          Offset(fillW - 0.9, size.height - 0.8),
          Paint()
            ..color = strokeColor
            ..strokeWidth = 1.7,
        );
      }
      canvas.restore();
    }

    // Çift vuruşlu el çizimi kontur
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _wobblyBar(size, inset: 1.5, wobble: 0.5),
      Paint()
        ..color = strokeColor.withValues(alpha: 0.38)
        ..strokeWidth = 0.85
        ..style = PaintingStyle.stroke,
    );
  }

  Path _wobblyBar(Size size, {required double inset, required double wobble}) {
    final r = math.max(2.0, (size.height / 2) - inset);
    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;
    final midX = (left + right) / 2;

    return Path()
      ..moveTo(left + r, top)
      ..quadraticBezierTo(midX, top + wobble, right - r, top)
      ..arcToPoint(
        Offset(right - r, bottom),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(midX, bottom - wobble, left + r, bottom)
      ..arcToPoint(
        Offset(left + r, top),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _BadgesSketchProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor;
  }
}
