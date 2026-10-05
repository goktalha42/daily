import 'package:flutter/material.dart';

class AppColors {
  // Kara Kalem & Skeç Kağıt Zeminleri
  static const Color backgroundLight = Color(0xFFFBF9F4); // Doğal eskiz kağıdı dokusu
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Çizim kağıdı beyazı
  static const Color surfaceSecondaryLight = Color(0xFFF3EFE6);
  static const Color cardBgLight = Color(0xFFFFFFFF);

  // Koyu mod için kara tahta / grafit zemin
  static const Color backgroundDark = Color(0xFF18181B);
  static const Color surfaceDark = Color(0xFF27272A);
  static const Color surfaceSecondaryDark = Color(0xFF3F3F46);

  // Kurşun Kalem & Çini Mürekkebi Çizgileri
  static const Color pencilBlack = Color(0xFF1C1917); // Net kurşun kalem / keçe uçlu siyah
  static const Color pencilGraphite = Color(0xFF44403C); // 2B Grafit tonu
  static const Color pencilGray = Color(0xFF78716C); // Açık karalama tonu
  static const Color pencilLight = Color(0xFFA8A29E); // Taslak çizgisi
  static const Color sketchBorder = Color(0xFF1C1917); // 2px standart skeç kenarlığı

  // Fotoğraftaki İkonik Fosforlu Kalem (Highlighter) Vurguları
  static const Color highlighterYellow = Color(0xFFFFDE59); // Fotoğraftaki sarı fosfor
  static const Color highlighterCyan = Color(0xFF70E0D8);   // Fotoğraftaki turkuaz fosfor
  static const Color highlighterOrange = Color(0xFFFF9F68); // Skeç mercan/turuncu
  static const Color highlighterPink = Color(0xFFFF85A1);   // Skeç neon pembe
  static const Color highlighterGreen = Color(0xFF86EFAC);  // Skeç yeşil
  static const Color highlighterPurple = Color(0xFFC4B5FD); // Skeç lavanta moru

  // Dopamin & ADHD Eskiz Eşleşmeleri
  static const Color geniusGold = highlighterYellow;
  static const Color electricAmber = highlighterOrange;
  static const Color dopaminePurple = highlighterPurple;
  static const Color hyperCyan = highlighterCyan;
  static const Color supremeEmerald = highlighterGreen;

  static const Color primary = pencilBlack;
  static const Color warning = highlighterYellow;
  static const Color success = highlighterGreen;
  static const Color error = Color(0xFFEF4444);

  // Metin Renkleri
  static const Color textPrimaryLight = pencilBlack;
  static const Color textSecondaryLight = pencilGraphite;
  static const Color textMutedLight = pencilGray;

  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);

  static const Color borderLight = pencilBlack;
  static const Color borderDark = Color(0xFF52525B);

  // Oyun Özel Skeç Renkleri
  static const Color queensGame = highlighterPink;
  static const Color pinpointGame = highlighterCyan;
  static const Color crossclimbGame = highlighterPurple;
  static const Color tangoGame = highlighterOrange;
  static const Color zipGame = highlighterGreen;

  // Legacy Uyumluluğu
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color primaryLight = pencilGraphite;
  static const Color secondary = pencilGray;
  static const Color accentPurple = highlighterPurple;
  static const Color accentPink = highlighterPink;
  static const Color accentAmber = highlighterYellow;
  static const Color accentCyan = highlighterCyan;
  static const Color accentOrange = highlighterOrange;
  static const Color accentGreen = highlighterGreen;
  static const Color primaryGlow = pencilLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color border = borderLight;

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

  static const LinearGradient queensGradient = LinearGradient(
    colors: [highlighterPink, Color(0xFFFFB3C6)],
  );
  static const LinearGradient pinpointGradient = LinearGradient(
    colors: [highlighterCyan, Color(0xFFA5F3FC)],
  );
  static const LinearGradient crossclimbGradient = LinearGradient(
    colors: [highlighterPurple, Color(0xFFDDD6FE)],
  );
  static const LinearGradient tangoGradient = LinearGradient(
    colors: [highlighterOrange, Color(0xFFFED7AA)],
  );
  static const LinearGradient zipGradient = LinearGradient(
    colors: [highlighterGreen, Color(0xFFBBF7D0)],
  );
}

