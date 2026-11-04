import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/badge_model.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/widgets/app_button.dart';
import '../../core/widgets/sketch_decorations.dart';

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

    final allBadges = DailyBadge.allBadges;
    final unlockedCount = allBadges.where((b) {
      final ub = badgeState[b.id];
      return ub != null && !ub.isExpired;
    }).length;

    final progressRatio = allBadges.isNotEmpty ? (unlockedCount / allBadges.length) : 0.0;
    final activeStreak = dailyPlay.getCurrentStreak(null);

    // Filtreleme
    List<DailyBadge> filtered = allBadges;
    if (_selectedCategory != null) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }
    if (_onlyUnlocked) {
      filtered = filtered.where((b) {
        final ub = badgeState[b.id];
        return ub != null && !ub.isExpired;
      }).toList();
    }

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
                          color: AppColors.pencil(context),
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
                                      BorderSide(color: AppColors.pencil(context), width: 1.5),
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
                                color: AppColors.pencil(context),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: SketchCard(
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
                            SketchCard(
                              padding: const EdgeInsets.all(10),
                              borderRadius: 12,
                              borderWidth: 1.6,
                              shadowOffset: const Offset(2, 2),
                              backgroundColor: AppColors.sunYellow,
                              child: const Text('🏆', style: TextStyle(fontSize: 26)),
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
                                      color: AppColors.pencil(context),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                        // El Çizimi İlerleme Çubuğu
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.pencil(context), width: 1.4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressRatio.clamp(0.04, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.sunYellow,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🔥 Aktif Seri: $activeStreak Gün',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencil(context),
                              ),
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

              // ─── 3. KATEGORİ SEÇİCİ SEKMELER (SKEÇ CHIPS) ───────────────────
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
                          label: '🌟 Başarılar',
                          isSelected: _selectedCategory == BadgeCategory.mastery,
                          onTap: () => setState(() => _selectedCategory = BadgeCategory.mastery),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: '🔥 Seriler',
                          isSelected: _selectedCategory == BadgeCategory.streak,
                          onTap: () => setState(() => _selectedCategory = BadgeCategory.streak),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: '👑 Şampiyonluk',
                          isSelected: _selectedCategory == BadgeCategory.championship,
                          onTap: () => setState(() => _selectedCategory = BadgeCategory.championship),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 4. SADECE KAZANILANLAR FİLTRESİ ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _onlyUnlocked = !_onlyUnlocked),
                        child: Row(
                          children: [
                            SketchCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 5,
                              borderWidth: 1.4,
                              shadowOffset: const Offset(1, 1),
                              backgroundColor: _onlyUnlocked ? AppColors.sunYellow : AppColors.surfaceOf(context),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: _onlyUnlocked
                                    ? const Icon(Icons.check, size: 14, color: AppColors.inkBlack)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sadece Kazanılanları Göster',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencil(context),
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
                        'Bu kategoride henüz rozet bulunmuyor.',
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      borderRadius: 10,
      borderWidth: isSelected ? 2.0 : 1.4,
      shadowOffset: isSelected ? const Offset(2.0, 2.0) : const Offset(1.5, 1.5),
      backgroundColor: isSelected ? AppColors.sunYellow : AppColors.surfaceOf(context),
      child: Text(
        label,
        style: GoogleFonts.patrickHand(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.inkBlack : AppColors.pencil(context),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context, {
    required DailyBadge badge,
    required bool isUnlocked,
    required DailyPlayState dailyPlay,
    DateTime? unlockedAt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Seri ilerlemesi
    String? progressText;
    if (badge.category == BadgeCategory.streak && badge.streakDays > 0) {
      final cur = dailyPlay.getCurrentStreak(badge.relatedGame);
      progressText = '$cur / ${badge.streakDays} Gün';
    }

    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeDetailsDialog(context, badge: badge, isUnlocked: isUnlocked, unlockedAt: unlockedAt);
      },
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      borderWidth: isUnlocked ? 2.2 : 1.5,
      shadowOffset: isUnlocked ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
      backgroundColor: isUnlocked
          ? (isDark ? AppColors.sunYellow.withValues(alpha: 0.16) : AppColors.sunYellow.withValues(alpha: 0.22))
          : AppColors.surfaceOf(context),
      child: Row(
        children: [
          // Rozet Simgesi
          SketchCard(
            padding: EdgeInsets.zero,
            borderRadius: 10,
            borderWidth: 1.5,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: isUnlocked
                ? AppColors.sunYellow
                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
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
                if (progressText != null && !isUnlocked) ...[
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

          // Durum Rozeti
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: 7,
            borderWidth: 1.2,
            shadowOffset: const Offset(1, 1),
            backgroundColor: isUnlocked
                ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
            borderColor: isUnlocked
                ? const Color(0xFF16A34A)
                : AppColors.pencil(context).withValues(alpha: 0.3),
            child: Text(
              isUnlocked ? '✓ AÇILDI' : '🔒 KİLİTLİ',
              style: GoogleFonts.patrickHand(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUnlocked
                    ? const Color(0xFF16A34A)
                    : AppColors.gray(context),
              ),
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
            backgroundColor: AppColors.surfaceOf(context),
            borderRadius: 18,
            borderWidth: 2.4,
            shadowOffset: const Offset(4, 4),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SketchCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(2.5, 2.5),
                  backgroundColor: isUnlocked ? AppColors.sunYellow : AppColors.surfaceSecondaryOf(context),
                  child: Text(badge.emoji, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 14),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pencil(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    color: AppColors.gray(context),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 10,
                  borderWidth: 1.4,
                  shadowOffset: const Offset(1.5, 1.5),
                  backgroundColor: AppColors.surfaceSecondaryOf(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded, size: 16),
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
