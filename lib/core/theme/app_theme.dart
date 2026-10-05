import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

export 'app_colors.dart';
export 'app_text_styles.dart';
export 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pencilBlack,
        secondary: AppColors.highlighterCyan,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(AppColors.pencilBlack),
        headlineLarge: AppTextStyles.headlineLarge(AppColors.pencilBlack),
        headlineMedium: AppTextStyles.headlineMedium(AppColors.pencilBlack),
        titleLarge: AppTextStyles.titleLarge(AppColors.pencilBlack),
        titleMedium: AppTextStyles.titleMedium(AppColors.pencilBlack),
        bodyLarge: AppTextStyles.bodyLarge(AppColors.pencilBlack),
        bodyMedium: AppTextStyles.bodyMedium(AppColors.pencilGraphite),
        labelLarge: AppTextStyles.labelLarge(AppColors.pencilBlack),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.pencilBlack, width: 2.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.pencilBlack),
        titleTextStyle: AppTextStyles.titleLarge(AppColors.pencilBlack),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlighterYellow,
          foregroundColor: AppColors.pencilBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.pencilBlack, width: 2.0),
          ),
          textStyle: AppTextStyles.labelLarge(AppColors.pencilBlack),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.surfaceLight,
        secondary: AppColors.accentCyan,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(AppColors.textPrimaryDark),
        headlineLarge: AppTextStyles.headlineLarge(AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headlineMedium(AppColors.textPrimaryDark),
        titleLarge: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        titleMedium: AppTextStyles.titleMedium(AppColors.textPrimaryDark),
        bodyLarge: AppTextStyles.bodyLarge(AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
        labelLarge: AppTextStyles.labelLarge(AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.labelLarge(AppColors.primary),
        ),
      ),
    );
  }
}
