import 'crossclimb_models.dart';

/// Crossclimb (Kelime Tırmanışı) zincir kuralları, normalizasyon ve skor mantığı.
class CrossclimbLogic {
  const CrossclimbLogic._();

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

  /// İki kelime arasındaki farklı harf sayısını (Hamming Distance) döner.
  /// Kelime uzunlukları eşit değilse -1 döner.
  static int hammingDistance(String wordA, String wordB) {
    final a = normalize(wordA);
    final b = normalize(wordB);
    if (a.length != b.length) return -1;

    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) diff++;
    }
    return diff;
  }

  /// İki kelime arasında değişen tek harfin indeksini döner (0 tabanlı).
  /// Eğer tam olarak 1 harf farklı değilse -1 döner.
  static int findChangedIndex(String wordA, String wordB) {
    final a = normalize(wordA);
    final b = normalize(wordB);
    if (a.length != b.length) return -1;

    int changedIdx = -1;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        if (changedIdx != -1) return -1; // Birden fazla farklılık var
        changedIdx = i;
      }
    }
    return changedIdx;
  }

  /// Verilen tahminin adım hedef kelimesiyle eşleşip eşleşmediğini kontrol eder.
  static bool isStepValid(String guess, String targetWord) {
    return normalize(guess) == normalize(targetWord);
  }

  /// Puan hesaplama:
  /// - Taban puan: 2000
  /// - Süre cezası: Her saniye için 6 puan düşülür
  /// - Hatalı deneme cezası: Her hata için 50 puan düşülür
  /// - Taban puan: minimum 200
  static int calculateScore({
    required int durationMs,
    required int stepCount,
    int wrongAttempts = 0,
  }) {
    final timePenalty = (durationMs ~/ 1000) * 6;
    final wrongPenalty = wrongAttempts * 50;
    final score = 2000 - timePenalty - wrongPenalty;
    return score.clamp(200, 2000);
  }

  /// Bir seviyenin zincir kurallarına uygunluğunu doğrular:
  /// 1. Adımlar listesi boş olamaz.
  /// 2. Tüm kelimelerin uzunlukları eşit olmalıdır.
  /// 3. startWord ile ilk adım arasında tam olarak 1 harf değişmelidir.
  /// 4. Her ardışık adım arasında tam olarak 1 harf değişmelidir.
  /// 5. step.changedIndex değeri gerçek değişen harf indeksi ile uyuşmalıdır.
  /// 6. Son adımın kelimesi endWord ile aynı olmalıdır.
  static bool validateLevel(CrossclimbLevel level) {
    if (level.steps.isEmpty) return false;
    final wordLen = level.startWord.length;
    if (level.endWord.length != wordLen) return false;

    String prev = level.startWord;
    for (int i = 0; i < level.steps.length; i++) {
      final step = level.steps[i];
      final curr = step.targetWord;

      if (curr.length != wordLen) return false;

      final diff = hammingDistance(prev, curr);
      if (diff != 1) return false;

      final expectedChangedIdx = findChangedIndex(prev, curr);
      if (step.changedIndex != expectedChangedIdx) return false;

      prev = curr;
    }

    if (normalize(level.steps.last.targetWord) != normalize(level.endWord)) {
      return false;
    }

    return true;
  }
}
