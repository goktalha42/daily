import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/time_sync_service.dart';
import '../theme/app_colors.dart';
import 'sketch_decorations.dart';

/// Kara Kalem Eskiz Defteri Temalı El Çizimi Kalan Süre Sayacı
class SketchCountdownTimer extends ConsumerWidget {
  final bool showLabel;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double? width;

  const SketchCountdownTimer({
    super.key,
    this.showLabel = false,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdownAsync = ref.watch(nextResetCountdownProvider);
    final duration =
        countdownAsync.value ?? ref.watch(timeSyncServiceProvider).getTimeUntilNextReset();
    final formatted = TimeSyncService.formatCountdown(duration);

    final isDark = AppColors.isDark(context);
    final textColor = isDark ? Colors.white : AppColors.pencilBlack;

    // Sabit metin kutusu genişliği: "00:00:00" metninin karakter değişikliklerinde
    // (özellikle '1' ile diğer rakamların genişlik farkından kaynaklı) boyutunun
    // saniye bazında oynamasını/titremesini tamamen önler.
    final timerTextWidth = (fontSize * 5.2).ceilToDouble();

    final card = SketchCard(
      padding: padding,
      backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
      borderColor: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
      borderWidth: 1.8,
      borderRadius: 10,
      shadowOffset: const Offset(2.0, 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 15,
            color: textColor,
          ),
          const SizedBox(width: 5),
          if (showLabel) ...[
            Text(
              'YENİ OYUN: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.pencilGraphite,
              ),
            ),
          ],
          SizedBox(
            width: timerTextWidth,
            child: Text(
              formatted,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                color: textColor,
                letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: card,
      );
    }
    return card;
  }
}
