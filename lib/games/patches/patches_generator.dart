import 'dart:math';

import '../../core/puzzle/puzzle_seed.dart';
import 'patches_logic.dart';
import 'patches_models.dart';

/// Patches (Alan Bölme / Shikaku) bulmacalarını tohumdan sıfırdan üretir.
///
/// README Bölüm 4.2 standardı:
/// "Patches: ızgarayı rastgele dikdörtgenlere böl → her dikdörtgene bir sayı yerleştir."
/// Üretilen tahta PatchesLogic.countSolutions çözücüsünden geçerek %100 TEK ÇÖZÜMLÜ
/// olduğu garanti edilir.
class PatchesGenerator {
  static const int maxAttempts = 1000;

  const PatchesGenerator._();

  static PatchesLevel generate({
    required String levelId,
    PatchesDifficulty difficulty = PatchesDifficulty.orta,
  }) {
    final n = difficulty.gridSize;

    final maxArea = switch (difficulty) {
      PatchesDifficulty.kolay => 6,
      PatchesDifficulty.orta => 8,
      PatchesDifficulty.zor => 10,
    };

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = PuzzleSeed.random(
        'patches-${difficulty.name}',
        levelId,
        salt: '$attempt',
      );

      // 1. Izgarayı rastgele geçerli dikdörtgenlerle tamamen kapla (Tiling)
      final rectangles = _generateTiling(n, maxArea, rng);
      if (rectangles == null) continue;

      // 2. Her dikdörtgenin içine rastgele bir hücreye ipucu yerleştir (image.png standardı şekil kısıtı ile)
      final clues = <PatchesClue>[];
      for (final rect in rectangles) {
        final r = rect.topRow + rng.nextInt(rect.height);
        final c = rect.leftCol + rng.nextInt(rect.width);

        PatchShapeType shape;
        if (rect.width == rect.height) {
          shape = PatchShapeType.square;
        } else if (rect.height > rect.width) {
          shape = rng.nextDouble() < 0.7 ? PatchShapeType.tall : PatchShapeType.any;
        } else {
          shape = rng.nextDouble() < 0.7 ? PatchShapeType.wide : PatchShapeType.any;
        }

        clues.add(PatchesClue(
          row: r,
          col: c,
          targetArea: rect.area,
          shapeType: shape,
        ));
      }

      // 3. Tek çözüm garantisi doğrula
      final solCount = PatchesLogic.countSolutions(n, clues, maxCount: 2);
      if (solCount == 1) {
        // Renk indekslerini ata (görsel zenginlik için)
        final coloredRects = <PatchRect>[];
        for (int i = 0; i < rectangles.length; i++) {
          final r = rectangles[i];
          coloredRects.add(PatchRect(
            topRow: r.topRow,
            leftCol: r.leftCol,
            bottomRow: r.bottomRow,
            rightCol: r.rightCol,
            colorIndex: i % 6,
          ));
        }

        return PatchesLevel(
          id: levelId,
          gridSize: n,
          clues: clues,
          solution: coloredRects,
          difficulty: difficulty,
        );
      }
    }

    throw StateError(
      'Patches bulmacası üretilemedi: $levelId (${difficulty.name}) $maxAttempts denemede tek çözüm bulunamadı.',
    );
  }

  /// N x N ızgarayı rastgele dikdörtgenlerle eksiksiz böler.
  static List<PatchRect>? _generateTiling(int n, int maxArea, Random rng) {
    final grid = List<bool>.filled(n * n, false);
    final rectangles = <PatchRect>[];

    bool backtrack() {
      // İlk boş hücreyi bul
      int firstEmpty = -1;
      for (int i = 0; i < n * n; i++) {
        if (!grid[i]) {
          firstEmpty = i;
          break;
        }
      }

      // Tüm tahta kaplandı
      if (firstEmpty == -1) return true;

      final startR = firstEmpty ~/ n;
      final startC = firstEmpty % n;

      // Bu hücreden başlayabilecek tüm geçerli dikdörtgen (w, h) boyutlarını topla
      final options = <_RectDim>[];
      for (int h = 1; h <= n - startR; h++) {
        for (int w = 1; w <= n - startC; w++) {
          final area = w * h;
          if (area > maxArea) continue;
          // Tek hücrelik (1x1) dikdörtgenleri yalnızca nadiren / mecbur kalınca tercih et
          if (area == 1 && options.isNotEmpty) continue;

          // Bu dikdörtgenin kapsadığı tüm hücreler boş mu?
          bool canFit = true;
          for (int r = startR; r < startR + h; r++) {
            for (int c = startC; c < startC + w; c++) {
              if (grid[r * n + c]) {
                canFit = false;
                break;
              }
            }
            if (!canFit) break;
          }

          if (canFit) {
            options.add(_RectDim(w, h));
          }
        }
      }

      if (options.isEmpty) return false;

      // Seçenekleri rastgele karıştır
      options.shuffle(rng);
      options.sort((a, b) {
        // 1x1'leri en sona at
        if (a.area == 1 && b.area > 1) return 1;
        if (b.area == 1 && a.area > 1) return -1;
        return 0;
      });

      for (final opt in options) {
        // Hücreleri işaretle
        for (int r = startR; r < startR + opt.h; r++) {
          for (int c = startC; c < startC + opt.w; c++) {
            grid[r * n + c] = true;
          }
        }

        final rect = PatchRect(
          topRow: startR,
          leftCol: startC,
          bottomRow: startR + opt.h - 1,
          rightCol: startC + opt.w - 1,
        );
        rectangles.add(rect);

        if (backtrack()) return true;

        // Geri al
        rectangles.removeLast();
        for (int r = startR; r < startR + opt.h; r++) {
          for (int c = startC; c < startC + opt.w; c++) {
            grid[r * n + c] = false;
          }
        }
      }

      return false;
    }

    if (backtrack()) {
      return rectangles;
    }
    return null;
  }
}

class _RectDim {
  final int w;
  final int h;

  int get area => w * h;

  const _RectDim(this.w, this.h);
}
