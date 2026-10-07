import 'pinpoint_models.dart';

/// Pinpoint (Kelime İzleri) oyun kuralları, normalizasyon ve puanlama mantığı.
class PinpointLogic {
  const PinpointLogic._();

  /// Türkçe karakter duyarlı büyük harfe dönüştürme.
  static String normalize(String text) {
    return text
        .trim()
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ç', 'Ç')
        .replaceAll('ş', 'Ş')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ö', 'Ö')
        .replaceAll('ü', 'Ü')
        .toUpperCase();
  }

  /// Tahminin doğruluğunu denetler (ana hedef kelime veya kabul edilebilir alternatifler).
  static bool isCorrectGuess(
    String guess,
    String targetWord, {
    List<String> alternativeAnswers = const [],
  }) {
    final normGuess = normalize(guess);
    if (normGuess.isEmpty) return false;

    if (normGuess == normalize(targetWord)) return true;

    for (final alt in alternativeAnswers) {
      if (normGuess == normalize(alt)) return true;
    }

    return false;
  }

  /// Puan hesaplama:
  /// - Başlangıç tabanı: 2000 puan
  /// - Açılan ekstra ipucu cezası: Her ekstra ipucu için 250 puan düşülür
  /// - Yanlış tahmin cezası: Her yanlış tahmin için 100 puan düşülür
  /// - Süre cezası: Her saniye için 5 puan düşülür
  /// - Taban puan: minimum 200
  static int calculateScore({
    required int durationMs,
    required int revealedClues,
    required int wrongGuessesCount,
  }) {
    final cluePenalty = (revealedClues - 1).clamp(0, 4) * 250;
    final wrongPenalty = wrongGuessesCount * 100;
    final timePenalty = (durationMs ~/ 1000) * 5;

    final score = 2000 - cluePenalty - wrongPenalty - timePenalty;
    return score.clamp(200, 2000);
  }

  /// Seviyenin temel kurallara uygunluğunu doğrular:
  /// - Hedef kelime boş olamaz
  /// - Kategori ipucu boş olamaz
  /// - En az 5 adet ipucu olmalıdır ve hiçbiri boş olamaz
  static bool validateLevel(PinpointLevel level) {
    if (level.targetWord.trim().isEmpty) return false;
    if (level.categoryHint.trim().isEmpty) return false;
    if (level.clues.length < 5) return false;
    for (final clue in level.clues) {
      if (clue.trim().isEmpty) return false;
    }
    return true;
  }
}
