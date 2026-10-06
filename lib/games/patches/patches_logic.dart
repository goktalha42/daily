import 'patches_models.dart';

class PatchesLogic {
  /// Tek bir dikdörtgenin kurallara uygunluğunu kontrol eder:
  /// - İçinde tam olarak 1 adet sayı ipucu bulunmalı.
  /// - Dikdörtgenin alanı o sayıya eşit olmalıdır.
  static bool isValidRect(PatchRect rect, List<PatchesClue> clues) {
    int clueCount = 0;
    int targetArea = 0;

    for (final clue in clues) {
      if (rect.contains(clue.row, clue.col)) {
        clueCount++;
        targetArea = clue.targetArea;
      }
    }

    return clueCount == 1 && rect.area == targetArea;
  }

  /// Dikdörtgenin içindeki ipucu sayısını döner.
  static int getClueCountInRect(PatchRect rect, List<PatchesClue> clues) {
    int count = 0;
    for (final clue in clues) {
      if (rect.contains(clue.row, clue.col)) {
        count++;
      }
    }
    return count;
  }

  /// Verilen dikdörtgenin başka dikdörtgenlerle çakışıp çakışmadığını denetler.
  static bool hasOverlap(PatchRect rect, List<PatchRect> otherRects) {
    for (final other in otherRects) {
      if (rect != other && rect.overlaps(other)) {
        return true;
      }
    }
    return false;
  }

  /// Tüm tahtanın tam ve hatasız çözülüp çözülmediğini doğrular.
  static bool validateBoard(
    List<PatchRect> userRects,
    List<PatchesClue> clues,
    int gridSize,
  ) {
    if (userRects.isEmpty) return false;

    // 1. Çakışma kontrolü
    for (int i = 0; i < userRects.length; i++) {
      for (int j = i + 1; j < userRects.length; j++) {
        if (userRects[i].overlaps(userRects[j])) {
          return false;
        }
      }
    }

    // 2. Her dikdörtgenin kendi geçerliliği
    final visitedClues = <PatchesClue>{};
    for (final rect in userRects) {
      PatchesClue? containedClue;
      for (final clue in clues) {
        if (rect.contains(clue.row, clue.col)) {
          if (containedClue != null) {
            // Birden fazla ipucu içeriyor
            return false;
          }
          containedClue = clue;
        }
      }

      if (containedClue == null || rect.area != containedClue.targetArea) {
        // İpucu içermiyor veya alanı uyuşmuyor
        return false;
      }

      visitedClues.add(containedClue);
    }

    // 3. Tüm ipuçları kullanılmış olmalı
    if (visitedClues.length != clues.length) {
      return false;
    }

    // 4. Izgaradaki toplam kaplanan alan gridSize * gridSize olmalı
    int totalArea = 0;
    for (final rect in userRects) {
      totalArea += rect.area;
    }

    return totalArea == gridSize * gridSize;
  }
}
