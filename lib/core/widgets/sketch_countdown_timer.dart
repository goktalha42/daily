import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/time_sync_service.dart';
import '../theme/app_colors.dart';

/// Kara Kalem Eskiz Defteri Temalı Kalan Süre Sayacı
class SketchCountdownTimer extends ConsumerWidget {
  final bool showLabel;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SketchCountdownTimer({
    super.key,
    this.showLabel = false,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdownAsync = ref.watch(nextResetCountdownProvider);
    final duration = countdownAsync.value ?? ref.watch(timeSyncServiceProvider).getTimeUntilNextReset();
    final formatted = TimeSyncService.formatCountdown(duration);

    final isDark = AppColors.isDark(context);
    final textColor = isDark ? Colors.white : AppColors.pencilBlack;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white : AppColors.pencilBlack, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.cardShadowDark : AppColors.pencilBlack,
            offset: const Offset(2.0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 5),
          if (showLabel) ...[
            Text(
              'YENİ OYUN: ',
              style: GoogleFonts.patrickHand(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.pencilGraphite,
              ),
            ),
          ],
          Text(
            formatted,
            style: GoogleFonts.patrickHand(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
