import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_spacing.dart';
import '../app_colors.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool withGlassEffect;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.withGlassEffect = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: widget.withGlassEffect ? null : defaultBg,
        gradient: widget.withGlassEffect
            ? (isDark ? AppColors.glassGradientDark : AppColors.glassGradientLight)
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.025),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: cardContent,
      ),
    );
  }
}
