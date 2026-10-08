import 'package:flutter/material.dart';

class AppColors {
  // Kara Kalem & Skeç Kağıt Zeminleri
  static const Color backgroundLight = Color(0xFFFBF9F4); // Doğal eskiz kağıdı dokusu
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Çizim kağıdı beyazı
  static const Color surfaceSecondaryLight = Color(0xFFF3EFE6);
  static const Color cardBgLight = Color(0xFFFFFFFF);

  // Kurşun Kalem & Çini Mürekkebi Çizgileri
  static const Color pencilBlack = Color(0xFF1C1917); // Net kurşun kalem / keçe uçlu siyah
  static const Color pencilGraphite = Color(0xFF44403C); // 2B Grafit tonu
  static const Color pencilGray = Color(0xFF78716C); // Açık karalama tonu
  static const Color pencilLight = Color(0xFFA8A29E); // Taslak çizgisi
  static const Color sketchBorder = Color(0xFF1C1917); // 2px standart skeç kenarlığı

  // İkonik Kalem & Sanatçı Eskiz Vurguları (Altın Kural gereği çiğ neon sarı ve çiğ neon yeşil tamamen yasaklandı)
  static const Color sunYellow = Color(0xFFF59E0B);        // Güzel, sıcak altın sarısı
  static const Color skyBlue = Color(0xFF38BDF8);          // Temiz gök mavisi (Ay için)
  static const Color highlighterYellow = Color(0xFFF59E0B); // Çiğ sarı yerine sıcak altın kehribar
  static const Color highlighterCyan = Color(0xFF70E0D8);   // Turkuaz
  static const Color highlighterOrange = Color(0xFFFF9F68); // Mercan/turuncu
  static const Color highlighterPink = Color(0xFFFF85A1);   // Pembe
  static const Color highlighterGreen = Color(0xFF34D399);  // Çiğ neon yeşil yerine ferah pastel nane
  static const Color highlighterPurple = Color(0xFFC4B5FD); // Lavanta moru

  // Zühtü Renk Eşleşmeleri
  static const Color primary = pencilBlack;
  static const Color warning = sunYellow;
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBgLight = Color(0xFFFEE2E2);

  // Metin Renkleri
  static const Color textPrimaryLight = pencilBlack;
  static const Color textSecondaryLight = pencilGraphite;
  static const Color textMutedLight = pencilGray;

  static const Color borderLight = pencilBlack;

  // Oyun Özel Skeç Renkleri
  static const Color queensGame = highlighterPink;
  static const Color pinpointGame = highlighterCyan;
  static const Color crossclimbGame = highlighterPurple;
  static const Color tangoGame = highlighterOrange;
  static const Color zipGame = skyBlue;                  // Sayı yolu artık ferah gök mavisi
  static const Color patchesGame = Color(0xFFA78BFA);     // Alan bölme şık mor/lavanta

  // Temel Uyumluluk
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color primaryLight = pencilGraphite;
  static const Color secondary = pencilGray;
  static const Color accentPurple = highlighterPurple;
  static const Color accentPink = highlighterPink;
  static const Color accentAmber = sunYellow;
  static const Color accentCyan = highlighterCyan;
  static const Color accentOrange = highlighterOrange;
  static const Color accentGreen = Color(0xFF34D399);
  static const Color primaryGlow = pencilLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color border = borderLight;

  // Oyun Kartları Gradyanları (Küçük rozetler için)
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
    colors: [skyBlue, Color(0xFFBAE6FD)],
  );
  static const LinearGradient patchesGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFFDDD6FE)],
  );
}
