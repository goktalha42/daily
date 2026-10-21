import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sketch_decorations.dart';
import 'base_game.dart';

/// Zühtü oyun ekranı iskeleti (Kara Kalem Eskiz Defteri dili).
/// Kağıt zemin + kalın konturlu, blur'suz gölgeli üst çubuk.
class NeoGameLayout extends StatelessWidget {
  final GameType gameType;
  final String levelId;
  final Widget child;
  final Widget? statsBar;
  final VoidCallback? onRestart;

  const NeoGameLayout({
    super.key,
    required this.gameType,
    required this.levelId,
    required this.child,
    this.statsBar,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBarBg = isDark ? AppColors.surfaceDark : Colors.white;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final shadowColor = isDark ? AppColors.cardShadowDark : AppColors.pencilBlack;
    final subtitleColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 24, 12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: topBarBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: pencilColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      color: pencilColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: gameType.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.pencilBlack, width: 2),
                          ),
                          child: Text(
                            gameType.title,
                            style: AppTextStyles.titleMedium(AppColors.pencilBlack),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bölüm #$levelId',
                          style: AppTextStyles.bodyMedium(subtitleColor)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                      color: pencilColor,
                      onPressed: onRestart,
                    ),
                  ],
                ),
              ),
              if (statsBar != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: statsBar!,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
