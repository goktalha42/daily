import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/badge_model.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/daily_play_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';

class BadgeShowcaseSection extends ConsumerStatefulWidget {
  const BadgeShowcaseSection({super.key});

  @override
  ConsumerState<BadgeShowcaseSection> createState() => _BadgeShowcaseSectionState();
}

class _BadgeShowcaseSectionState extends ConsumerState<BadgeShowcaseSection> {
  BadgeCategory? _selectedCategory;
  GameType? _selectedStreakGame;

  @override
  Widget build(BuildContext context) {
    final badgeState = ref.watch(badgeServiceProvider);
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);
    final dailyPlayState = ref.watch(dailyPlayServiceProvider);

    final championships = DailyBadge.allBadges
        .where((b) => b.category == BadgeCategory.championship)
        .toList();

    // Filtrelenmiş liste
    List<DailyBadge> filteredBadges = DailyBadge.allBadges;
    if (_selectedCategory != null) {
      filteredBadges = filteredBadges.where((b) => b.category == _selectedCategory).toList();
      if (_selectedCategory == BadgeCategory.streak && _selectedStreakGame != null) {
        filteredBadges = filteredBadges.where((b) => b.relatedGame == _selectedStreakGame).toList();
      }
    }

    final activeCount = badgeNotifier.activeBadges.length;
    final totalCount = DailyBadge.allBadges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. BAŞLIK & İSTATİSTİK
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.sunYellow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ROZETLER & ŞAMPİYONLUK KEMERLERİ',
                        style: GoogleFonts.patrickHand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilGraphite,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sunYellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                ),
                child: Text(
                  '$activeCount / $totalCount KAZANILDI',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. SÜRELİ ŞAMPİYONLUK KEMERLERİ VİTRİNİ (YATAY KAYAN KARUSEL)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                'Süreli Rozetler & Şampiyonluk Kemerleri',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: championships.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = championships[index];
              final userBadge = badgeState[badge.id];
              final isUnlocked = userBadge != null && !userBadge.isExpired;
              final remainingDays = userBadge?.remainingDays ?? 0;

              return _buildChampionshipBeltCard(
                context,
                badge: badge,
                userBadge: userBadge,
                isUnlocked: isUnlocked,
                remainingDays: remainingDays,
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // 3. KATEGORİ FİLTRELEME ÇUBUĞU
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryFilterChip(
                  label: 'Tümü ($totalCount)',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() {
                    _selectedCategory = null;
                    _selectedStreakGame = null;
                  }),
                ),
                const SizedBox(width: 6),
                _buildCategoryFilterChip(
                  label: '🔥 Seriler (91)',
                  isSelected: _selectedCategory == BadgeCategory.streak,
                  onTap: () => setState(() => _selectedCategory = BadgeCategory.streak),
                ),
                const SizedBox(width: 6),
                _buildCategoryFilterChip(
                  label: '👑 Süreli Kemerler (10)',
                  isSelected: _selectedCategory == BadgeCategory.championship,
                  onTap: () => setState(() {
                    _selectedCategory = BadgeCategory.championship;
                    _selectedStreakGame = null;
                  }),
                ),
                const SizedBox(width: 6),
                _buildCategoryFilterChip(
                  label: '🎮 Oyun Ustalığı (6)',
                  isSelected: _selectedCategory == BadgeCategory.gameMastery,
                  onTap: () => setState(() {
                    _selectedCategory = BadgeCategory.gameMastery;
                    _selectedStreakGame = null;
                  }),
                ),
                const SizedBox(width: 6),
                _buildCategoryFilterChip(
                  label: '🧠 Zekâ & Başarı (6)',
                  isSelected: _selectedCategory == BadgeCategory.brainPower,
                  onTap: () => setState(() {
                    _selectedCategory = BadgeCategory.brainPower;
                    _selectedStreakGame = null;
                  }),
                ),
              ],
            ),
          ),
        ),

        // 4. EĞER SERİLER SEÇİLİYSE: OYUN BAZLI ALT FİLTRE
        if (_selectedCategory == BadgeCategory.streak) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildSubGameChip(
                    label: 'Tüm Oyunlar',
                    isSelected: _selectedStreakGame == null,
                    onTap: () => setState(() => _selectedStreakGame = null),
                  ),
                  for (final g in GameType.values) ...[
                    const SizedBox(width: 5),
                    _buildSubGameChip(
                      label: g.title,
                      isSelected: _selectedStreakGame == g,
                      currentStreak: dailyPlayState.getCurrentStreak(g),
                      onTap: () => setState(() => _selectedStreakGame = g),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),

        // 5. ROZET LİSTESİ / IZGARASI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: filteredBadges.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Bu kategoride rozet bulunamadı.',
                      style: GoogleFonts.patrickHand(fontSize: 16, color: AppColors.pencilLight),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBadges.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final badge = filteredBadges[index];
                    final userBadge = badgeState[badge.id];
                    final isUnlocked = userBadge != null && !userBadge.isExpired;

                    return _buildBadgeListItem(
                      context,
                      badge: badge,
                      userBadge: userBadge,
                      isUnlocked: isUnlocked,
                      dailyPlayState: dailyPlayState,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isSelected
        ? AppColors.sunYellow
        : (isDark ? AppColors.surfaceDark : Colors.white);
    final chipTextColor = isSelected ? AppColors.inkBlack : AppColors.pencil(context);
    final borderColor = isSelected ? AppColors.inkBlack : AppColors.pencil(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.2),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.inkBlack, offset: Offset(1.5, 1.5))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.patrickHand(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: chipTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSubGameChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? currentStreak,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isSelected
        ? AppColors.accentCyan
        : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight);
    final chipTextColor = isSelected ? AppColors.inkBlack : AppColors.pencil(context);
    final borderColor = isSelected ? AppColors.inkBlack : AppColors.pencil(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          currentStreak != null && currentStreak > 0 ? '$label (🔥$currentStreak)' : label,
          style: GoogleFonts.patrickHand(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: chipTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildChampionshipBeltCard(
    BuildContext context, {
    required DailyBadge badge,
    required UserBadge? userBadge,
    required bool isUnlocked,
    required int remainingDays,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeModal(context, badge, userBadge);
      },
      child: SketchCard(
        backgroundColor: isUnlocked ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: 14,
        borderWidth: isUnlocked ? 2.2 : 1.4,
        shadowOffset: isUnlocked ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(badge.emoji, style: const TextStyle(fontSize: 26)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (badge.validityDays == 0 ? AppColors.highlighterPurple : AppColors.sunYellow)
                          : AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                    ),
                    child: Text(
                      isUnlocked
                          ? (badge.validityDays == 0 ? '🧠 130+ IQ' : '⏳ $remainingDays GÜN')
                          : '🔒 KİLİTLİ',
                      style: GoogleFonts.patrickHand(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                badge.title,
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? AppColors.pencilBlack : AppColors.pencilGray,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                    size: 13,
                    color: isUnlocked ? const Color(0xFF15803D) : AppColors.pencilLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUnlocked ? 'Taşınıyor' : 'Kazanılmadı',
                    style: GoogleFonts.patrickHand(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? const Color(0xFF15803D) : AppColors.pencilLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeListItem(
    BuildContext context, {
    required DailyBadge badge,
    required UserBadge? userBadge,
    required bool isUnlocked,
    required DailyPlayState dailyPlayState,
  }) {
    int currentStreak = 0;
    if (badge.category == BadgeCategory.streak) {
      currentStreak = dailyPlayState.getCurrentStreak(badge.relatedGame);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeModal(context, badge, userBadge);
      },
      child: SketchCard(
        backgroundColor: isUnlocked ? const Color(0xFFFAFAF5) : Colors.white,
        borderRadius: 12,
        borderWidth: isUnlocked ? 2.0 : 1.4,
        shadowOffset: isUnlocked ? const Offset(2.0, 2.0) : const Offset(1.0, 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Simge Kutusu
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnlocked ? badge.color.withValues(alpha: 0.35) : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.pencilBlack, width: 1.5),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Metin Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? AppColors.pencilBlack : AppColors.pencilGray,
                    ),
                  ),
                  Text(
                    badge.requirement,
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.pencilLight,
                    ),
                  ),
                  if (badge.category == BadgeCategory.streak && !isUnlocked) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Mevcut Seri: $currentStreak / ${badge.streakDays} Gün',
                          style: GoogleFonts.patrickHand(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Durum Rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isUnlocked ? const Color(0xFFD1FAE5) : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isUnlocked ? const Color(0xFF059669) : AppColors.pencilLight,
                  width: 1.2,
                ),
              ),
              child: Text(
                isUnlocked ? '✓ Kazanıldı' : '🔒 Kilitli',
                style: GoogleFonts.patrickHand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? const Color(0xFF047857) : AppColors.pencilLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeModal(BuildContext context, DailyBadge badge, UserBadge? userBadge) {
    final isUnlocked = userBadge != null && !userBadge.isExpired;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SketchCard(
          backgroundColor: Colors.white,
          borderRadius: 20,
          borderWidth: 2.5,
          shadowOffset: const Offset(4, 4),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rozet İkonu
              SketchCard(
                backgroundColor: isUnlocked ? badge.color : AppColors.surfaceSecondaryLight,
                borderRadius: 40,
                borderWidth: 2.2,
                shadowOffset: const Offset(2.5, 2.5),
                padding: const EdgeInsets.all(16),
                child: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 12),

              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilBlack,
                ),
              ),
              const SizedBox(height: 4),

              // Tür Etiketi
              SketchCard(
                backgroundColor: badge.isTemporary ? AppColors.sunYellow : AppColors.skyBlue,
                borderRadius: 8,
                borderWidth: 1.4,
                shadowOffset: const Offset(1.2, 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Text(
                  badge.isTemporary
                      ? (badge.validityDays == 0
                          ? '👑 KOŞULLU DİNAMİK ROZET'
                          : '👑 ŞAMPİYONLUK KEMERİ (${badge.validityDays} GÜN GEÇERLİ)')
                      : (badge.category == BadgeCategory.streak
                          ? '🔥 KALICI SERİ ROZETİ'
                          : '🎖️ KALICI KOLEKSİYON ROZETİ'),
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(
                  fontSize: 15,
                  color: AppColors.pencilBlack,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.pencilBlack, width: 1.4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.pencilGraphite),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kazanma Koşulu: ${badge.requirement}',
                        style: GoogleFonts.patrickHand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Kapat Butonu
              SketchCard(
                backgroundColor: AppColors.sunYellow,
                borderRadius: 12,
                borderWidth: 2.0,
                shadowOffset: const Offset(2.0, 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onTap: () => Navigator.pop(ctx),
                child: Text(
                  'Kapat',
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
