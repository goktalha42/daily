import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/badge_model.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sketch_badge_icons.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../badges_screen.dart';

class BadgeShowcaseSection extends ConsumerWidget {
  const BadgeShowcaseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeState = ref.watch(badgeServiceProvider);

    final allBadges = DailyBadge.allBadges;
    final totalCount = allBadges.length;

    // Kazanılan rozetler
    final unlockedBadges = allBadges.where((b) {
      final ub = badgeState[b.id];
      return ub != null && !ub.isExpired;
    }).toList();

    unlockedBadges.sort((a, b) {
      final dateA = badgeState[a.id]?.unlockedAt ?? DateTime(2000);
      final dateB = badgeState[b.id]?.unlockedAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final unlockedCount = unlockedBadges.length;
    final progressPercent = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SketchDoodleTrophy(
                      size: 17,
                      color: isDark ? AppColors.sunYellow : AppColors.pencilBlack,
                    ),
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
                SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  borderRadius: 6,
                  borderWidth: 1.2,
                  shadowOffset: const Offset(1, 1),
                  backgroundColor: AppColors.sunYellow,
                  child: Text(
                    '$unlockedCount / $totalCount AÇILDI',
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

          // Vitrin Kartı
          SketchCard(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              );
            },
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            borderWidth: 2.0,
            shadowOffset: const Offset(3.0, 3.0),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderColor: isDark ? const Color(0xFF475569) : AppColors.pencilBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SketchCard(
                      padding: EdgeInsets.all(8),
                      borderRadius: 10,
                      borderWidth: 1.5,
                      shadowOffset: Offset(1.5, 1.5),
                      backgroundColor: AppColors.sunYellow,
                      borderColor: AppColors.inkBlack,
                      child: SketchBadgeIcon(
                        type: BadgeArtType.honorMedal,
                        size: 24,
                        strokeColor: AppColors.inkBlack,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rozet Koleksiyonun',
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.pencilBlack,
                            ),
                          ),
                          Text(
                            '%${(progressPercent * 100).toInt()} Tamamlandı • Detaylar için tıkla',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFCBD5E1) : AppColors.pencilGraphite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : AppColors.pencilBlack,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Kazanılan Rozetler Simgeleri
                if (unlockedBadges.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Henüz açılan rozet yok. Günlük bulmacaları çöz ve ilk rozetini kap!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.patrickHand(
                          fontSize: 14,
                          color: AppColors.gray(context),
                        ),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: unlockedBadges.take(6).map((badge) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              SketchBadgeMedallion(
                                type: badge.artType,
                                accentColor: badge.color,
                                isUnlocked: true,
                                size: 46,
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  badge.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencil(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
