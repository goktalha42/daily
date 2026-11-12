import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daily_games/core/puzzle/puzzle_serializer.dart';
import 'package:daily_games/games/crossclimb/crossclimb_generator.dart';
import 'package:daily_games/games/patches/patches_levels.dart';
import 'package:daily_games/games/pinpoint/pinpoint_generator.dart';
import 'package:daily_games/games/queens/queens_levels.dart';
import 'package:daily_games/games/queens/queens_models.dart';
import 'package:daily_games/games/tango/tango_levels.dart';
import 'package:daily_games/games/zip_path/zip_levels.dart';

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

void main() {
  test('Export 365+ days of puzzles and Turkish word pools for VPS', () {
    final startDate = DateTime.utc(2026, 11, 5); // 7 gün geriden + 366 gün ileri
    const totalDays = 373;

    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < totalDays; i++) {
      final d = startDate.add(Duration(days: i));
      final dateId = _fmtDate(d);

      final queensKolay = QueensLevelRepository.getLevelForDateAndDifficulty(
        dateId,
        QueensDifficulty.kolay,
      );
      final queensZor = QueensLevelRepository.getLevelForDateAndDifficulty(
        dateId,
        QueensDifficulty.zor,
      );
      final queensMaster = QueensLevelRepository.getLevelForDateAndDifficulty(
        dateId,
        QueensDifficulty.master,
      );

      final pinpoint = PinpointGenerator.generate(levelId: dateId);
      final crossclimb = CrossclimbGenerator.generate(levelId: dateId);
      final tango = TangoLevelRepository.getLevelForDate(dateId);
      final zip = ZipLevelRepository.getLevelForDate(dateId);
      final patches = PatchesLevelRepository.getLevelForDate(dateId);

      days.add({
        'date_id': dateId,
        'games': {
          'queens': {
            'kolay': PuzzleSerializer.queensToJson(queensKolay),
            'zor': PuzzleSerializer.queensToJson(queensZor),
            'master': PuzzleSerializer.queensToJson(queensMaster),
          },
          'pinpoint': PuzzleSerializer.pinpointToJson(pinpoint),
          'crossclimb': PuzzleSerializer.crossclimbToJson(crossclimb),
          'tango': PuzzleSerializer.tangoToJson(tango),
          'zip_path': PuzzleSerializer.zipToJson(zip),
          'patches': PuzzleSerializer.patchesToJson(patches),
        },
      });
    }

    final dataDir = Directory('server/database/data');
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }

    final puzzlesFile = File('${dataDir.path}/puzzles_365.json');
    puzzlesFile.writeAsStringSync(jsonEncode({
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'total_days': days.length,
      'days': days,
    }));

    final poolsFile = File('${dataDir.path}/word_pools.json');
    poolsFile.writeAsStringSync(jsonEncode({
      'pinpoint': PinpointGenerator.pool
          .map((e) => PuzzleSerializer.pinpointToJson(e))
          .toList(),
      'crossclimb': CrossclimbGenerator.pool
          .map((e) => PuzzleSerializer.crossclimbToJson(e))
          .toList(),
    }));

    expect(puzzlesFile.existsSync(), isTrue);
    expect(poolsFile.existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

