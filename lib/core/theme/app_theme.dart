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
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.pencilBlack, width: 2.2),
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
          backgroundColor: AppColors.sunYellow,
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

  /// Zühtü Kara Tahta & Koyu Grafit Skeç Teması
  /// Doğal koyu arduvaz kağıdı, tebeşir/gümüş çizgiler ve canlı fosforlu kalem vurguları.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pencilWhite,
        secondary: AppColors.highlighterCyan,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(AppColors.pencilWhite),
        headlineLarge: AppTextStyles.headlineLarge(AppColors.pencilWhite),
        headlineMedium: AppTextStyles.headlineMedium(AppColors.pencilWhite),
        titleLarge: AppTextStyles.titleLarge(AppColors.pencilWhite),
        titleMedium: AppTextStyles.titleMedium(AppColors.pencilWhite),
        bodyLarge: AppTextStyles.bodyLarge(AppColors.pencilWhite),
        bodyMedium: AppTextStyles.bodyMedium(AppColors.pencilGraphiteDark),
        labelLarge: AppTextStyles.labelLarge(AppColors.pencilWhite),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.pencilWhite, width: 2.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.pencilWhite, width: 2.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.pencilWhite),
        titleTextStyle: AppTextStyles.titleLarge(AppColors.pencilWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunYellow,
          foregroundColor: AppColors.pencilBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.pencilWhite, width: 2.0),
          ),
          textStyle: AppTextStyles.labelLarge(AppColors.pencilBlack),
        ),
      ),
    );
  }
}
