import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Kara Kalem & Skeç El Yazısı Fontu (Patrick Hand)
  static TextStyle displayLarge(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 44,
    letterSpacing: 0.5,
  );

  static TextStyle headlineLarge(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: 0.3,
  );

  static TextStyle headlineMedium(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    letterSpacing: 0.2,
  );

  static TextStyle titleLarge(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: 0.2,
  );

  static TextStyle titleMedium(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  static TextStyle bodyLarge(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 17,
  );

  static TextStyle bodyMedium(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );

  static TextStyle labelLarge(Color color) => GoogleFonts.patrickHand(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: 0.3,
  );
}

