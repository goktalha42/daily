import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';

class LeaderboardEntryCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final String? customDetailText;
  final bool showThreeOfThree;

  const LeaderboardEntryCard({
    super.key,
    required this.entry,
    required this.isMe,
    this.customDetailText,
    this.showThreeOfThree = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isTop3 = entry.rank <= 3;
    final detailText = customDetailText ?? 'Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SketchCard(
        borderRadius: 12,
        borderWidth: isMe ? 2.4 : 1.8,
        shadowOffset: isMe ? const Offset(3.5, 3.5) : const Offset(2.0, 2.0),
        backgroundColor: isMe
            ? (isDark ? AppColors.sunYellow.withValues(alpha: 0.22) : AppColors.sunYellow.withValues(alpha: 0.35))
            : AppColors.surfaceOf(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            // Derece Rozeti
            SketchCard(
              borderRadius: 7,
              borderWidth: 1.4,
              shadowOffset: const Offset(1.5, 1.5),
              padding: EdgeInsets.zero,
              backgroundColor: isTop3
                  ? AppColors.sunYellow
                  : (isMe ? AppColors.sunYellow : AppColors.surfaceSecondaryOf(context)),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: (isTop3 || isMe) ? AppColors.pencilBlack : AppColors.pencil(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Kullanıcı Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.userName + (isMe ? ' (Sen)' : ''),
                          style: GoogleFonts.patrickHand(
                            fontSize: 17,
                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.pencil(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.rank == 1) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.sunYellow),
                      ],
                      if (showThreeOfThree) ...[
                        const SizedBox(width: 6),
                        SketchCard(
                          borderRadius: 5,
                          borderWidth: 1.0,
                          shadowOffset: const Offset(1, 1),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          backgroundColor: AppColors.sunYellow.withValues(alpha: 0.25),
                          child: Text(
                            '3/3',
                            style: GoogleFonts.patrickHand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencil(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    detailText,
                    style: GoogleFonts.patrickHand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray(context),
                    ),
                  ),
                ],
              ),
            ),

            // Puan Rozeti
            SketchCard(
              borderRadius: 8,
              borderWidth: 1.4,
              shadowOffset: const Offset(1.5, 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              backgroundColor: isTop3
                  ? AppColors.sunYellow
                  : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
              child: Text(
                '${entry.totalScore} P',
                style: GoogleFonts.patrickHand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isTop3 ? AppColors.pencilBlack : AppColors.pencil(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
