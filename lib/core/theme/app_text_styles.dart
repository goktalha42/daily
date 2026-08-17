import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Heading Styles (Plus Jakarta Sans)
  static TextStyle displayLarge(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    fontSize: 48,
  );

  static TextStyle headlineLarge(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    fontSize: 32,
  );

  static TextStyle headlineMedium(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontSize: 24,
  );

  static TextStyle titleLarge(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: -0.5,
  );

  static TextStyle titleMedium(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Body Styles
  static TextStyle bodyLarge(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static TextStyle bodyMedium(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static TextStyle labelLarge(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 0.5,
  );
}
