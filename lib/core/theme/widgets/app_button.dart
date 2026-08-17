import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isPrimary
        ? (isDark ? AppColors.accentCyan : AppColors.primary)
        : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight);

    final textColor = isPrimary
        ? (isDark ? AppColors.primary : AppColors.surfaceLight)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        child: Ink(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: bgColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            widthFactor: isFullWidth ? null : 1.0,
            child: buttonChild,
          ),
        ),
      ),
    ).animate().scale(
      duration: 150.ms,
      curve: Curves.easeOut,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }
}
