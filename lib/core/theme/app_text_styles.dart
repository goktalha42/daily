import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // 1. Kara Kalem & Skeç Karakteri (Patrick Hand - Başlıklar, Logolar ve Rozetler)
  static TextStyle displayLarge([Color? color]) => GoogleFonts.patrickHand(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 44,
    letterSpacing: 0.5,
  );

  static TextStyle headlineLarge([Color? color]) => GoogleFonts.patrickHand(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: 0.3,
  );

  static TextStyle headlineMedium([Color? color]) => GoogleFonts.patrickHand(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    letterSpacing: 0.2,
  );

  static TextStyle titleLarge([Color? color]) => GoogleFonts.patrickHand(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: 0.2,
  );

  static TextStyle sketchTitle([Color? color, double size = 20]) => GoogleFonts.patrickHand(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: size,
    letterSpacing: 0.2,
  );

  // 2. Yüksek Okunabilirlikli Temiz Sans-Serif Fontu (Plus Jakarta Sans - Gövde, Açıklamalar, Kurallar, Sayaçlar)
  static TextStyle titleMedium([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 17,
  );

  static TextStyle bodyLarge([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.35,
  );

  static TextStyle bodyMedium([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilGraphite,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.4,
  );

  static TextStyle bodySmall([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilGray,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.35,
  );

  static TextStyle labelLarge([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilBlack,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 0.2,
  );

  static TextStyle labelMedium([Color? color]) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilGraphite,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  static TextStyle cleanSans({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    color: color ?? AppColors.pencilBlack,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
  );
}

