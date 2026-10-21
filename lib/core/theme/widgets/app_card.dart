import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_spacing.dart';
import '../app_colors.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool withGlassEffect;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.withGlassEffect = false,
    this.backgroundColor,
    this.borderColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final isBgLight = cardBg.computeLuminance() > 0.42;
    final textColor = isDark ? (isBgLight ? AppColors.inkBlack : AppColors.inkWhite) : AppColors.pencilBlack;
    final borderColor = widget.borderColor ?? (isDark ? (isBgLight ? AppColors.inkBlack : AppColors.pencilWhite) : AppColors.pencilBlack);
    final shadowColor = isDark ? (isBgLight ? const Color(0xFF000000) : AppColors.cardShadowDark) : AppColors.pencilBlack;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 0,
            offset: const Offset(3.5, 3.5),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding,
        child: IconTheme.merge(
          data: IconThemeData(color: textColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: textColor),
            child: widget.child,
          ),
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
      child: Transform.translate(
        offset: _isPressed ? const Offset(1.5, 1.5) : Offset.zero,
        child: cardContent,
      ),
    );
  }
}
