import 'patches_models.dart';

class PatchesLogic {
  /// Tek bir dikdörtgenin kurallara uygunluğunu kontrol eder:
  /// - İçinde tam olarak 1 adet sayı ipucu bulunmalı.
  /// - Dikdörtgenin alanı o sayıya eşit olmalıdır.
  /// - image.png standardı: Şekil türü (kare, uzun, geniş, herhangi biri) kuralına uymalıdır.
  static bool isValidRect(PatchRect rect, List<PatchesClue> clues) {
    PatchesClue? containedClue;
    int clueCount = 0;

    for (final clue in clues) {
      if (rect.contains(clue.row, clue.col)) {
        clueCount++;
        containedClue = clue;
      }
    }

    if (clueCount != 1 || containedClue == null) return false;
    if (rect.area != containedClue.targetArea) return false;

    // Şekil Türü Kısıtı (image.png standardı)
    switch (containedClue.shapeType) {
      case PatchShapeType.square:
        return rect.width == rect.height;
      case PatchShapeType.tall:
        return rect.height > rect.width;
      case PatchShapeType.wide:
        return rect.width > rect.height;
      case PatchShapeType.any:
        return true;
    }
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

    // 2. Her dikdörtgenin kendi geçerliliği ve şekil kısıtı
    final visitedClues = <PatchesClue>{};
    for (final rect in userRects) {
      if (!isValidRect(rect, clues)) {
        return false;
      }

      for (final clue in clues) {
        if (rect.contains(clue.row, clue.col)) {
          visitedClues.add(clue);
          break;
        }
      }
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

  /// Verilen ipuçları ve ızgara boyutu için çözüm sayısını hesaplar.
  /// [maxCount] sayısına ulaşıldığında aramayı erken sonlandırır (tek çözüm testi için maxCount=2 idealdir).
  static int countSolutions(
    int gridSize,
    List<PatchesClue> clues, {
    int maxCount = 2,
  }) {
    final solutions = <List<PatchRect>>[];
    _searchSolutions(gridSize, clues, maxCount: maxCount, solutions: solutions);
    return solutions.length;
  }

  /// Verilen ipuçları için ilk geçerli çözümü döner (yoksa null).
  static List<PatchRect>? solve(int gridSize, List<PatchesClue> clues) {
    final solutions = <List<PatchRect>>[];
    _searchSolutions(gridSize, clues, maxCount: 1, solutions: solutions);
    return solutions.isEmpty ? null : solutions.first;
  }

  /// Shikaku tahtası için adayları bulur ve geri izleme (backtracking with MRV) ile çözer.
  static void _searchSolutions(
    int gridSize,
    List<PatchesClue> clues, {
    required int maxCount,
    required List<List<PatchRect>> solutions,
  }) {
    if (clues.isEmpty || maxCount <= 0) return;

    final totalArea = clues.fold<int>(0, (sum, c) => sum + c.targetArea);
    if (totalArea != gridSize * gridSize) return;

    // Her ipucu için geçerli olabilecek aday dikdörtgenleri oluştur
    final candidatesList = <_ClueCandidates>[];

    for (final clue in clues) {
      final validRects = _findCandidatesForClue(clue, clues, gridSize);
      if (validRects.isEmpty) {
        // En az bir ipucunun hiçbir adayı yoksa çözüm imkansızdır
        return;
      }

      final masks = validRects.map((r) => _rectToMask(r, gridSize)).toList();
      candidatesList.add(_ClueCandidates(
        clue: clue,
        rects: validRects,
        masks: masks,
      ));
    }

    // MRV (Minimum Remaining Values) sezgiseli: En az adayı olan ipucunu önce dene
    candidatesList.sort((a, b) => a.rects.length.compareTo(b.rects.length));

    final current = <PatchRect>[];
    _backtrack(0, 0, candidatesList, maxCount, current, solutions);
  }

  static void _backtrack(
    int clueIdx,
    int occupiedMask,
    List<_ClueCandidates> sortedClues,
    int maxCount,
    List<PatchRect> current,
    List<List<PatchRect>> solutions,
  ) {
    if (solutions.length >= maxCount) return;

    if (clueIdx == sortedClues.length) {
      solutions.add(List<PatchRect>.from(current));
      return;
    }

    final clueData = sortedClues[clueIdx];
    for (int i = 0; i < clueData.rects.length; i++) {
      final mask = clueData.masks[i];
      if ((occupiedMask & mask) == 0) {
        current.add(clueData.rects[i]);
        _backtrack(
          clueIdx + 1,
          occupiedMask | mask,
          sortedClues,
          maxCount,
          current,
          solutions,
        );
        current.removeLast();

        if (solutions.length >= maxCount) return;
      }
    }
  }

  /// Bir ipucu için diğer ipuçlarını içermeyen ve alanı uyuşan tüm dikdörtgen adayları
  static List<PatchRect> _findCandidatesForClue(
    PatchesClue clue,
    List<PatchesClue> allClues,
    int gridSize,
  ) {
    final result = <PatchRect>[];
    final area = clue.targetArea;

    for (int h = 1; h <= gridSize; h++) {
      if (area % h != 0) continue;
      final w = area ~/ h;
      if (w > gridSize) continue;

      // Şekil türü kısıtı filtresi (image.png standardı)
      if (clue.shapeType == PatchShapeType.square && w != h) continue;
      if (clue.shapeType == PatchShapeType.tall && h <= w) continue;
      if (clue.shapeType == PatchShapeType.wide && w <= h) continue;

      final minTop = (clue.row - h + 1).clamp(0, gridSize - 1);
      final maxTop = clue.row.clamp(0, gridSize - h);
      final minLeft = (clue.col - w + 1).clamp(0, gridSize - 1);
      final maxLeft = clue.col.clamp(0, gridSize - w);

      for (int top = minTop; top <= maxTop; top++) {
        final bottom = top + h - 1;
        for (int left = minLeft; left <= maxLeft; left++) {
          final right = left + w - 1;

          // Bu dikdörtgenin içinde başka ipucu var mı?
          bool containsOther = false;
          for (final other in allClues) {
            if (identical(other, clue)) continue;
            if (other.row >= top &&
                other.row <= bottom &&
                other.col >= left &&
                other.col <= right) {
              containsOther = true;
              break;
            }
          }

          if (!containsOther) {
            result.add(PatchRect(
              topRow: top,
              leftCol: left,
              bottomRow: bottom,
              rightCol: right,
            ));
          }
        }
      }
    }

    return result;
  }

  static int _rectToMask(PatchRect r, int gridSize) {
    int mask = 0;
    for (int row = r.topRow; row <= r.bottomRow; row++) {
      final rowOffset = row * gridSize;
      for (int col = r.leftCol; col <= r.rightCol; col++) {
        mask |= (1 << (rowOffset + col));
      }
    }
    return mask;
  }
}

class _ClueCandidates {
  final PatchesClue clue;
  final List<PatchRect> rects;
  final List<int> masks;

  _ClueCandidates({
    required this.clue,
    required this.rects,
    required this.masks,
  });
}
