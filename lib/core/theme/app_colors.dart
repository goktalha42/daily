import 'package:flutter/material.dart';
import '../services/theme_service.dart';


class AppColors {
  // Kara Kalem & Skeç Kağıt Zeminleri (Açık Tema Sabitleri - ASLA DİNAMİK DEĞİL, SAF AÇIK RENKLER!)
  static const Color backgroundLight = Color(0xFFFBF9F4); // Doğal eskiz kağıdı dokusu
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Çizim kağıdı beyazı
  static const Color surfaceSecondaryLight = Color(0xFFF3EFE6);
  static const Color cardBgLight = Color(0xFFFFFFFF);

  // Kara Tahta & Koyu Grafit Zeminleri (Koyu Tema Sabitleri)
  static const Color backgroundDark = Color(0xFF131417); // Koyu grafit eskiz defteri zemini
  static const Color surfaceDark = Color(0xFF1E2025);    // Koyu çizim kartı / arduvaz taşı
  static const Color surfaceSecondaryDark = Color(0xFF282A32); // İkincil elevated yüzey
  static const Color cardBgDark = Color(0xFF1E2025);
  static const Color cardShadowDark = Color(0xFF000000); // 3D sert siyah gölge

  // Kurşun Kalem & Çini Mürekkebi Çizgileri (Açık Tema Temel Sabitleri)
  static const Color pencilBlack = Color(0xFF1C1917);
  static const Color pencilGraphite = Color(0xFF44403C);
  static const Color pencilGray = Color(0xFF78716C);
  static const Color pencilLight = Color(0xFFA8A29E);
  static const Color sketchBorder = Color(0xFF1C1917);

  // Tebeşir & Gümüş Grafit Çizgileri (Koyu Tema Sabitleri)
  static const Color pencilWhite = Color(0xFFFFFFFF); // Kar beyazı tebeşir / net yazı
  static const Color pencilGraphiteDark = Color(0xFFFFFFFF); // Koyu temada okunabilirlik için tam beyaz
  static const Color pencilGrayDark = Color(0xFFE2E8F0); // Çok açık ve net gümüş beyaz
  static const Color pencilLightDark = Color(0xFF94A3B8); // İnce taslak çizgisi
  static const Color sketchBorderDark = Color(0xFFFFFFFF);

  // Sabit Çini Siyahı & Tebeşir Beyazı (Parlak renkli zeminlerde asla beyaz olmaması gereken yerler için)
  static const Color inkBlack = Color(0xFF1C1917);
  static const Color inkWhite = Color(0xFFFFFFFF);

  /// Dinamik zemin kontrast kontrolü:
  /// YALNIZCA KOYU TEMA AKTİFKEN parlak zeminleri siyaha çevirir.
  /// Açık temada: Daima standart kurşun kalem siyahı (inkBlack).
  /// Koyu temada: Arka plan aydınlığına (luminance) göre parlak renklerde (sarı, turkuaz vb.) SİYAH, koyu zeminlerde BEYAZ.
  static Color onColor(Color background, {BuildContext? context}) {
    final bool isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : ThemeNotifier.isDarkActive;
    if (!isDark) {
      return inkBlack;
    }
    return background.computeLuminance() > 0.35 ? inkBlack : inkWhite;
  }

  /// Arka plan rengine göre okunabilir ikincil metin/açıklama kontrast rengi.
  static Color onColorSubtitle(Color background, {BuildContext? context}) {
    final bool isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : ThemeNotifier.isDarkActive;
    if (!isDark) {
      return const Color(0xFF44403C);
    }
    return background.computeLuminance() > 0.35
        ? const Color(0xFF44403C)
        : const Color(0xFFE2E8F0);
  }

  // İkonik Kalem & Sanatçı Eskiz Vurguları (Altın Kural gereği çiğ neon sarı ve çiğ neon yeşil tamamen yasaklandı)
  static const Color sunYellow = Color(0xFFF59E0B);        // Güzel, sıcak altın sarısı
  static const Color skyBlue = Color(0xFF38BDF8);          // Temiz gök mavisi (Ay için)
  static const Color highlighterYellow = sunYellow;        // Altın Kural: Sıcak altın sarısına bağlandı
  static const Color highlighterCyan = Color(0xFF70E0D8);   // Turkuaz
  static const Color highlighterOrange = Color(0xFFFF9F68); // Mercan/turuncu
  static const Color highlighterPink = Color(0xFFFF85A1);   // Pembe
  static const Color highlighterGreen = success;           // Altın Kural: Doğal yeşile bağlandı
  static const Color highlighterPurple = Color(0xFFC4B5FD); // Lavanta moru

  // Zühtü Renk Eşleşmeleri
  static const Color primary = pencilBlack;
  static const Color warning = sunYellow;
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBgLight = Color(0xFFFEE2E2);
  static const Color errorBgDark = Color(0xFF450A0A);

  // Metin Renkleri
  static const Color textPrimaryLight = Color(0xFF1C1917);
  static const Color textSecondaryLight = Color(0xFF44403C);
  static const Color textMutedLight = Color(0xFF78716C);

  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Beyaz
  static const Color textSecondaryDark = Color(0xFFFFFFFF); // Beyaz
  static const Color textMutedDark = Color(0xFFE2E8F0); // Açık gümüş

  static const Color borderLight = Color(0xFF1C1917);
  static const Color borderDark = Color(0xFFFFFFFF);

  // Oyun Özel Skeç Renkleri
  static const Color queensGame = highlighterPink;
  static const Color pinpointGame = highlighterCyan;
  static const Color crossclimbGame = highlighterPurple;
  static const Color tangoGame = highlighterOrange;
  static const Color zipGame = skyBlue;                  // Sayı yolu artık ferah gök mavisi
  static const Color patchesGame = Color(0xFFA78BFA);     // Alan bölme şık mor/lavanta

  // Temel Uyumluluk (Varsayılan Açık Tema)
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color primaryLight = Color(0xFF44403C);
  static const Color secondary = Color(0xFF78716C);
  static const Color accentPurple = highlighterPurple;
  static const Color accentPink = highlighterPink;
  static const Color accentAmber = sunYellow;
  static const Color accentCyan = highlighterCyan;
  static const Color accentOrange = highlighterOrange;
  static const Color accentGreen = Color(0xFF34D399);
  static const Color primaryGlow = Color(0xFFA8A29E);
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color border = borderLight;

  // Dinamik / Temaya Duyarlı Yardımcı Metotlar
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pencil(BuildContext context) =>
      isDark(context) ? pencilWhite : pencilBlack;

  static Color graphite(BuildContext context) =>
      isDark(context) ? pencilGraphiteDark : pencilGraphite;

  static Color gray(BuildContext context) =>
      isDark(context) ? pencilGrayDark : pencilGray;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceSecondaryOf(BuildContext context) =>
      isDark(context) ? surfaceSecondaryDark : surfaceSecondaryLight;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color shadowOf(BuildContext context) =>
      isDark(context) ? cardShadowDark : pencilBlack;

  static Color adaptive(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) => isDark(context) ? dark : light;

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
