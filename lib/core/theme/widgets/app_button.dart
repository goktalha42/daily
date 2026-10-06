import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary ? AppColors.highlighterYellow : Colors.white;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: AppColors.pencilBlack),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.text,
          style: GoogleFonts.patrickHand(
            color: AppColors.pencilBlack,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: _isPressed ? const Offset(1.5, 1.5) : Offset.zero,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            border: Border.all(color: AppColors.pencilBlack, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.pencilBlack,
                blurRadius: 0,
                offset: _isPressed ? const Offset(1.5, 1.5) : const Offset(3.0, 3.0),
              ),
            ],
          ),
          child: Center(
            widthFactor: widget.isFullWidth ? null : 1.0,
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}
