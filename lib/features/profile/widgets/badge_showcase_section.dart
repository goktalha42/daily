import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/badge_model.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sketch_decorations.dart';

class BadgeShowcaseSection extends ConsumerWidget {
  const BadgeShowcaseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeState = ref.watch(badgeServiceProvider);
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);

    final championships = DailyBadge.allBadges
        .where((b) => b.category == BadgeCategory.championship)
        .toList();
    final permanentBadges = DailyBadge.allBadges
        .where((b) => b.category != BadgeCategory.championship)
        .toList();

    final activeCount = badgeNotifier.activeBadges.length;
    final totalCount = DailyBadge.allBadges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. BAŞLIK
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.pencilBlack),
                  const SizedBox(width: 6),
                  Text(
                    'ROZETLER & ŞAMPİYONLUK KEMERLERİ',
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pencilGraphite,
                      letterSpacing: 1.0,
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
                  '$activeCount / $totalCount AKTİF',
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

        // 2. ŞAMPİYONLUK KEMERLERİ (SÜRELİ ROZETLER VİTRİNİ)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Text(
            '👑 Şampiyonluk Kemerleri (Süreli - Hak Edilmesi Gerekir)',
            style: GoogleFonts.patrickHand(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.pencilGray,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
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

        // 3. KALICI KOLEKSİYON ROZETLERİ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Text(
            '🎖️ Kalıcı Koleksiyon Rozetleri',
            style: GoogleFonts.patrickHand(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.pencilGray,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: permanentBadges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = permanentBadges[index];
              final userBadge = badgeState[badge.id];
              final isUnlocked = userBadge != null;

              return _buildPermanentBadgeCard(
                context,
                badge: badge,
                userBadge: userBadge,
                isUnlocked: isUnlocked,
              );
            },
          ),
        ),
      ],
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
                      color: isUnlocked ? AppColors.sunYellow : AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.pencilBlack, width: 1.0),
                    ),
                    child: Text(
                      isUnlocked ? '⏳ $remainingDays GÜN' : '🔒 KİLİTLİ',
                      style: GoogleFonts.patrickHand(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? AppColors.pencilBlack : AppColors.pencilGray,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 2),
                  Text(
                    isUnlocked ? 'Aktif Şampiyon' : 'Kazanmak için dokun',
                    style: GoogleFonts.patrickHand(
                      fontSize: 11,
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

  Widget _buildPermanentBadgeCard(
    BuildContext context, {
    required DailyBadge badge,
    required UserBadge? userBadge,
    required bool isUnlocked,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeModal(context, badge, userBadge);
      },
      child: SketchCard(
        backgroundColor: isUnlocked ? Colors.white : AppColors.surfaceSecondaryLight.withValues(alpha: 0.5),
        borderRadius: 12,
        borderWidth: isUnlocked ? 1.8 : 1.2,
        shadowOffset: isUnlocked ? const Offset(2.0, 2.0) : const Offset(1.0, 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SizedBox(
          width: 105,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 26,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? AppColors.pencilBlack : AppColors.pencilGray,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isUnlocked ? '✓ Kazanıldı' : '🔒 Kilitli',
                style: GoogleFonts.patrickHand(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? const Color(0xFF15803D) : AppColors.pencilLight,
                ),
              ),
            ],
          ),
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
                      ? '👑 ŞAMPİYONLUK KEMERİ (${badge.validityDays} GÜN GEÇERLİ)'
                      : '🎖️ KALICI KOLEKSİYON ROZETİ',
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
              const SizedBox(height: 14),

              // Nasıl Kazanılır Kutusu
              SketchCard(
                backgroundColor: AppColors.backgroundLight,
                borderRadius: 12,
                borderWidth: 1.6,
                shadowOffset: const Offset(2, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, size: 16, color: AppColors.pencilBlack),
                        const SizedBox(width: 4),
                        Text(
                          'KAZANMA ŞARTI:',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.requirement,
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                      ),
                    ),
                    if (badge.isTemporary) ...[
                      const Divider(height: 12, color: AppColors.pencilBlack, thickness: 1.0),
                      Text(
                        '⚠️ Bu rozet sürelidir. Bir kez kazandıktan sonra ömür boyu durmaz, süresi dolmadan oyunu tekrar kazanarak kemeri sürekli korumalısın!',
                        style: GoogleFonts.patrickHand(
                          fontSize: 12,
                          color: AppColors.pencilGraphite,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kapat Butonu
              SketchCard(
                backgroundColor: AppColors.sunYellow,
                borderRadius: 12,
                borderWidth: 2.0,
                shadowOffset: const Offset(2.5, 2.5),
                padding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () => Navigator.pop(ctx),
                child: Center(
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.patrickHand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pencilBlack,
                    ),
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
