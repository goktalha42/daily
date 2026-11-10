import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/games/zip_path/zip_generator.dart';
import 'package:daily_games/games/zip_path/zip_levels.dart';
import 'package:daily_games/games/zip_path/zip_logic.dart';
import 'package:daily_games/games/zip_path/zip_models.dart';

void main() {
  group('ZipGenerator (Sayı Yolu Jeneratörü) Testleri', () {
    test('Aynı gün ve zorluk için deterministik bulmaca üretir', () {
      final l1 = ZipGenerator.generate(
        levelId: '2026-10-06',
        difficulty: ZipDifficulty.kolay,
      );
      final l2 = ZipGenerator.generate(
        levelId: '2026-10-06',
        difficulty: ZipDifficulty.kolay,
      );

      expect(l1.gridSize, equals(l2.gridSize));
      expect(l1.numberPoints.length, equals(l2.numberPoints.length));

      for (final entry in l1.numberPoints.entries) {
        expect(l2.numberPoints[entry.key], equals(entry.value));
      }
    });

    test('Üretilen her seviyenin TEK bir geçerli çözümü vardır', () {
      for (final diff in ZipDifficulty.values) {
        final level = ZipGenerator.generate(
          levelId: '2026-10-06',
          difficulty: diff,
        );

        final solCount = ZipLogic.countSolutions(
          level.gridSize,
          level.numberPoints,
          walls: level.walls,
          edgeWalls: level.edgeWalls,
          maxCount: 2,
        );

        expect(solCount, equals(1),
            reason: '${diff.name} seviyesinde tam 1 çözüm olmalı.');
      }
    });

    test('Üretilen çözüm yolu kurallara tam uyar', () {
      final level = ZipGenerator.generate(
        levelId: '2026-10-07',
        difficulty: ZipDifficulty.orta,
      );

      expect(level.solutionPath, isNotNull);
      final isValid = ZipLogic.validatePath(
        level.solutionPath!,
        level.numberPoints,
        level.gridSize,
        walls: level.walls,
        edgeWalls: level.edgeWalls,
      );

      expect(isValid, isTrue, reason: 'Üretilen yol Zip kurallarına tam uymalı.');
    });

    test('Farklı günler farklı bulmacalar üretir', () {
      final l1 = ZipGenerator.generate(
        levelId: '2026-10-06',
        difficulty: ZipDifficulty.orta,
      );
      final l2 = ZipGenerator.generate(
        levelId: '2026-10-07',
        difficulty: ZipDifficulty.orta,
      );

      expect(l1.numberPoints == l2.numberPoints, isFalse,
          reason: 'Farklı günler aynı kontrol noktalarını üretmemeli.');
    });

    test('ZipDifficultyScheduler 365 gün boyunca art arda 3 aynı zorluk getirmez', () {
      final history = <ZipDifficulty>[];
      for (var day = 0; day < 365; day++) {
        final d = ZipDifficultyScheduler.getDifficultyForDays(day);
        history.add(d);
        if (history.length >= 3) {
          final last3 = history.sublist(history.length - 3);
          expect(
            last3[0] == last3[1] && last3[1] == last3[2],
            isFalse,
            reason: '$day. günde art arda 3 kez ${d.name} geldi',
          );
        }
      }
    });

    test('LocalZipPuzzleRepository günlük seviyeyi döner', () async {
      const repo = LocalZipPuzzleRepository();
      final level = await repo.getDaily('2026-10-08');

      expect(level, isNotNull);
      expect(level.numberPoints.isNotEmpty, isTrue);
    });

    test('10 Kasım (2026-11-10) dahil hiçbir seviyede son noktadan erken geçilen yanıltıcı yol yoktur', () {
      for (final dateId in ['2026-11-08', '2026-11-09', '2026-11-10', '2026-11-11']) {
        final level = ZipLevelRepository.getLevelForDate(dateId);
        final solCount = ZipLogic.countSolutions(
          level.gridSize,
          level.numberPoints,
          walls: level.walls,
          edgeWalls: level.edgeWalls,
          maxCount: 2,
          allowPassThroughMax: true,
        );
        expect(solCount, equals(1), reason: '$dateId seviyesinde son noktadan devam eden ikincil yol olmamalı.');
      }
    });

    test('validatePath son numaranın (maxNumber) son karede olmamasını reddeder', () {
      final numberPoints = <Point, int>{
        const Point(0, 0): 1,
        const Point(1, 0): 2,
      };
      // 2x2 tahtada 2 numaradan (1,0) erken geçip (1,1) -> (0,1) ile biten yol geçersiz olmalı
      final invalidPath = const [
        Point(0, 0),
        Point(1, 0),
        Point(1, 1),
        Point(0, 1),
      ];
      expect(ZipLogic.validatePath(invalidPath, numberPoints, 2), isFalse);

      // 2 numaranın en sonda olduğu yol geçerli olmalı
      final validPath = const [
        Point(0, 0),
        Point(0, 1),
        Point(1, 1),
        Point(1, 0),
      ];
      expect(ZipLogic.validatePath(validPath, numberPoints, 2), isTrue);
    });
  });
}
