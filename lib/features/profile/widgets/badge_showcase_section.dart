import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/badge_model.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/theme/app_colors.dart';
import '../badges_screen.dart';

class BadgeShowcaseSection extends ConsumerWidget {
  const BadgeShowcaseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeState = ref.watch(badgeServiceProvider);
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);

    // Kemerler ve Rozetler ayrıştırması
    final championships = DailyBadge.allBadges
        .where((b) => b.category == BadgeCategory.championship)
        .toList();

    final permanentBadges = DailyBadge.allBadges
        .where((b) => b.category != BadgeCategory.championship)
        .toList();

    final totalCount = DailyBadge.allBadges.length;
    final activeTotalCount = badgeNotifier.activeBadges.length;

    // Aktif kemerler
    final activeBelts = championships.where((b) {
      final ub = badgeState[b.id];
      return ub != null && !ub.isExpired;
    }).toList();

    // Kazanılan kalıcı rozetler (en son kazanılanlar önde)
    final unlockedPermanent = permanentBadges.where((b) {
      final ub = badgeState[b.id];
      return ub != null && !ub.isExpired;
    }).toList();

    // Kazanılma tarihine göre sırala (en son açılanlar en başta)
    unlockedPermanent.sort((a, b) {
      final dateA = badgeState[a.id]?.unlockedAt ?? DateTime(2000);
      final dateB = badgeState[b.id]?.unlockedAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final permanentUnlockedCount = unlockedPermanent.length;
    final permanentTotalCount = permanentBadges.length;
    final permanentPercent = permanentTotalCount > 0
        ? (permanentUnlockedCount / permanentTotalCount)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BÖLÜM BAŞLIĞI VE ÖZET
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'BAŞARI & PRESTİJ VİTRİNİ',
                      style: GoogleFonts.patrickHand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sunYellow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                  ),
                  child: Text(
                    '$activeTotalCount / $totalCount KAZANILDI',
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 2. KART 1: ŞAMPİYONLUK KEMERLERİ (AYRI GEÇİŞ)
          _buildBeltsShowcaseCard(
            context,
            isDark: isDark,
            activeBelts: activeBelts,
            totalBeltsCount: championships.length,
            badgeState: badgeState,
          ),

          const SizedBox(height: 12),

          // 3. KART 2: STEAM TARZI ROZET KOLEKSİYONU (AYRI GEÇİŞ)
          _buildBadgesShowcaseCard(
            context,
            isDark: isDark,
            unlockedBadges: unlockedPermanent,
            unlockedCount: permanentUnlockedCount,
            totalCount: permanentTotalCount,
            completionPercent: permanentPercent,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KART 1: ŞAMPİYONLUK KEMERLERİ GEÇİŞ KARTI
  // ===========================================================================
  Widget _buildBeltsShowcaseCard(
    BuildContext context, {
    required bool isDark,
    required List<DailyBadge> activeBelts,
    required int totalBeltsCount,
    required Map<String, UserBadge> badgeState,
  }) {
    final hasActive = activeBelts.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BadgesScreen(initialTab: BadgeScreenTab.belts),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? (hasActive ? const Color(0xFF241E11) : AppColors.surfaceDark)
              : (hasActive ? const Color(0xFFFFFBEB) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActive ? AppColors.sunYellow : (isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack),
            width: hasActive ? 2.2 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: hasActive
                  ? AppColors.sunYellow.withValues(alpha: 0.35)
                  : (isDark ? Colors.black : AppColors.pencilBlack),
              offset: const Offset(2.5, 2.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Satır: Başlık & Rozet Durumu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sunYellow.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.sunYellow, width: 1.2),
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ŞAMPİYONLUK KEMERLERİ',
                          style: GoogleFonts.patrickHand(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.pencilBlack,
                          ),
                        ),
                        Text(
                          hasActive
                              ? '${activeBelts.length} Aktif Şampiyonluk Taşınıyor'
                              : 'Süreli Dinamik Unvanlar & Zirve Kemerleri',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            color: hasActive
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Sağ Buton
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sunYellow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.pencilBlack, offset: Offset(1, 1)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Kemerler (${activeBelts.length}/$totalBeltsCount)',
                        style: GoogleFonts.patrickHand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.inkBlack),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Orta Alan: Aktif Kemer Yuvaları VEYA Boş Durum Bilgisi
            if (hasActive) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: activeBelts.map((belt) {
                  final ub = badgeState[belt.id];
                  final remaining = ub?.remainingDays ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceSecondaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sunYellow, width: 1.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(belt.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          belt.title,
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.pencilBlack,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: belt.validityDays == 0 ? AppColors.highlighterPurple : AppColors.sunYellow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            belt.validityDays == 0 ? '🧠 130+ IQ' : '⏳ $remaining Gün',
                            style: GoogleFonts.patrickHand(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.sketchBorderDark.withValues(alpha: 0.3) : AppColors.pencilLight,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Şu an taşınan aktif kemer yok. Günlük liderlik ve hız rekorları ile kemer kazan!',
                        style: GoogleFonts.patrickHand(
                          fontSize: 12,
                          color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KART 2: STEAM TARZI ROZET KOLEKSİYONU GEÇİŞ KARTI
  // ===========================================================================
  Widget _buildBadgesShowcaseCard(
    BuildContext context, {
    required bool isDark,
    required List<DailyBadge> unlockedBadges,
    required int unlockedCount,
    required int totalCount,
    required double completionPercent,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BadgesScreen(initialTab: BadgeScreenTab.badges),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black : AppColors.pencilBlack,
              offset: const Offset(2.5, 2.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Satır: Başlık & Tamamlanma
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.highlighterCyan.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentCyan, width: 1.2),
                      ),
                      child: const Text('🎖️', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROZET KOLEKSİYONU',
                          style: GoogleFonts.patrickHand(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.pencilBlack,
                          ),
                        ),
                        Text(
                          '$unlockedCount / $totalCount Açıldı • %${(completionPercent * 100).toStringAsFixed(0)} Tamamlandı',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Sağ Buton
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.highlighterCyan,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.pencilBlack, offset: Offset(1, 1)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Tüm Rozetler ($totalCount)',
                        style: GoogleFonts.patrickHand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.inkBlack),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Steam Tarzı İlerleme Çubuğu
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColors.sketchBorderDark.withValues(alpha: 0.3) : AppColors.pencilLight,
                      width: 1.0,
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: completionPercent.clamp(0.02, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Son Kazanılan Rozetlerin Steam Slotları (4 Slot)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                if (index < unlockedBadges.length) {
                  final badge = unlockedBadges[index];
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badge.color, width: 1.4),
                      ),
                      child: Column(
                        children: [
                          Text(badge.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 2),
                          Text(
                            badge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.patrickHand(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Boş Kilit Yuvası
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.sketchBorderDark.withValues(alpha: 0.3) : AppColors.pencilLight,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'Kilitli',
                            style: GoogleFonts.patrickHand(
                              fontSize: 10,
                              color: isDark ? AppColors.pencilLightDark : AppColors.pencilLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
