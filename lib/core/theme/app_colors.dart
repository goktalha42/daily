import 'package:flutter/material.dart';

class AppColors {
  // Ultra Modern Neo-Light
  static const Color backgroundLight = Color(0xFFFAFAFC);      
  static const Color surfaceLight = Color(0xFFFFFFFF);         
  static const Color surfaceSecondaryLight = Color(0xFFF0F1F5);

  // OLED Neo-Dark
  static const Color backgroundDark = Color(0xFF000000); // True OLED Black
  static const Color surfaceDark = Color(0xFF0D0D0F); // Very dark gray, almost black
  static const Color surfaceSecondaryDark = Color(0xFF161619);

  // Neon Accents
  static const Color accentPurple = Color(0xFFB983FF); // Neon Purple
  static const Color accentCyan = Color(0xFF00E5FF); // Cyber Cyan
  static const Color accentOrange = Color(0xFFFF5E00); // Neon Orange
  static const Color accentGreen = Color(0xFF00FA9A); // Spring Green

  static const Color primary = Color(0xFF000000); // Dark Charcoal
  
  static const Color warning = Color(0xFFFFB300);
  static const Color success = Color(0xFF00FA9A);
  static const Color error = Color(0xFFFF3366);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0A0A0C); 
  static const Color textSecondaryLight = Color(0xFF71717A); 
  static const Color textMutedLight = Color(0xFFA1A1AA); 

  static const Color textPrimaryDark = Color(0xFFFAFAFA); 
  static const Color textSecondaryDark = Color(0xFFA1A1AA); 
  static const Color textMutedDark = Color(0xFF52525B); 

  static const Color borderLight = Color(0xFFE4E4E7); 
  static const Color borderDark = Color(0xFF27272A); 

  // Game specific signature colors
  static const Color queensGame = Color(0xFFFF3366);
  static const Color pinpointGame = Color(0xFF00E5FF);
  static const Color crossclimbGame = Color(0xFFB983FF);
  static const Color tangoGame = Color(0xFFFF9E00);
  static const Color zipGame = Color(0xFF00FA9A);

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xB3FFFFFF), Color(0x66FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0x26FFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy Aliases for backward compatibility
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color primaryGlow = Color(0xFFE4E4E7);
  static const Color primaryLight = Color(0xFF3F3F46);
  static const Color secondary = Color(0xFF71717A);
  static const Color accentPink = Color(0xFFFF3366);
  static const Color accentAmber = Color(0xFFFF9E00);
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color border = borderLight;

  static const LinearGradient queensGradient = LinearGradient(
    colors: [Color(0xFFFF3366), Color(0xFFFF7096)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient pinpointGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B4D8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient crossclimbGradient = LinearGradient(
    colors: [Color(0xFFB983FF), Color(0xFF90E0EF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient tangoGradient = LinearGradient(
    colors: [Color(0xFFFF9E00), Color(0xFFFFD000)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient zipGradient = LinearGradient(
    colors: [Color(0xFF00FA9A), Color(0xFF00D2D3)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}
