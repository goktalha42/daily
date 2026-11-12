import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/network/api_client.dart';
import 'package:daily_games/core/puzzle/puzzle_serializer.dart';
import 'package:daily_games/core/puzzle/remote_puzzle_store.dart';
import 'package:daily_games/core/services/time_sync_service.dart';
import 'package:daily_games/games/crossclimb/crossclimb_generator.dart';
import 'package:daily_games/games/patches/patches_levels.dart';
import 'package:daily_games/games/pinpoint/pinpoint_generator.dart';
import 'package:daily_games/games/pinpoint/pinpoint_levels.dart';
import 'package:daily_games/games/queens/queens_levels.dart';
import 'package:daily_games/games/queens/queens_models.dart';
import 'package:daily_games/games/tango/tango_levels.dart';
import 'package:daily_games/games/zip_path/zip_levels.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RemotePuzzleStore.clearMemory();
  });

  test('PuzzleSerializer tüm 6 oyun modelini kayıpsız JSON gidiş-dönüş çevirir', () {
    const dateId = '2026-11-12';

    final q = QueensLevelRepository.getLevelForDateAndDifficulty(dateId, QueensDifficulty.kolay);
    final q2 = PuzzleSerializer.queensFromJson(PuzzleSerializer.queensToJson(q));
    expect(q2.gridSize, q.gridSize);
    expect(q2.regionMap, q.regionMap);
    expect(q2.solution, q.solution);

    final p = PinpointGenerator.generate(levelId: dateId);
    final p2 = PuzzleSerializer.pinpointFromJson(PuzzleSerializer.pinpointToJson(p));
    expect(p2.targetWord, p.targetWord);
    expect(p2.clues, p.clues);

    final c = CrossclimbGenerator.generate(levelId: dateId);
    final c2 = PuzzleSerializer.crossclimbFromJson(PuzzleSerializer.crossclimbToJson(c));
    expect(c2.startWord, c.startWord);
    expect(c2.endWord, c.endWord);
    expect(c2.steps.length, c.steps.length);

    final t = TangoLevelRepository.getLevelForDate(dateId);
    final t2 = PuzzleSerializer.tangoFromJson(PuzzleSerializer.tangoToJson(t));
    expect(t2.gridSize, t.gridSize);
    expect(t2.constraints.length, t.constraints.length);

    final z = ZipLevelRepository.getLevelForDate(dateId);
    final z2 = PuzzleSerializer.zipFromJson(PuzzleSerializer.zipToJson(z));
    expect(z2.gridSize, z.gridSize);
    expect(z2.numberPoints.length, z.numberPoints.length);

    final pa = PatchesLevelRepository.getLevelForDate(dateId);
    final pa2 = PuzzleSerializer.patchesFromJson(PuzzleSerializer.patchesToJson(pa));
    expect(pa2.gridSize, pa.gridSize);
    expect(pa2.clues.length, pa.clues.length);
  });

  test('RemotePuzzleStore sunucudan gelen özel gün bulmacasını repositorylere aktarır', () async {
    const specialDate = '2026-04-23';
    final mockResponse = {
      'status': 'success',
      'date_id': specialDate,
      'is_special': true,
      'special_note': '23 Nisan Özel',
      'games': {
        'queens': {
          'kolay': PuzzleSerializer.queensToJson(
            QueensLevelRepository.getLevelForDateAndDifficulty(specialDate, QueensDifficulty.kolay),
          ),
          'zor': PuzzleSerializer.queensToJson(
            QueensLevelRepository.getLevelForDateAndDifficulty(specialDate, QueensDifficulty.zor),
          ),
          'master': PuzzleSerializer.queensToJson(
            QueensLevelRepository.getLevelForDateAndDifficulty(specialDate, QueensDifficulty.master),
          ),
        },
        'pinpoint': {
          'id': specialDate,
          'categoryHint': 'Özel Gün',
          'targetWord': 'BAYRAM',
          'clues': ['23 Nisan', 'Çocuk', 'Şenlik', 'Atatürk', 'Kutlama'],
          'alternativeAnswers': [],
        },
        'crossclimb': PuzzleSerializer.crossclimbToJson(
          CrossclimbGenerator.generate(levelId: specialDate),
        ),
        'tango': PuzzleSerializer.tangoToJson(
          TangoLevelRepository.getLevelForDate(specialDate),
        ),
        'zip_path': PuzzleSerializer.zipToJson(
          ZipLevelRepository.getLevelForDate(specialDate),
        ),
        'patches': PuzzleSerializer.patchesToJson(
          PatchesLevelRepository.getLevelForDate(specialDate),
        ),
      },
    };

    final mockClient = MockClient((request) async {
      expect(request.url.path, endsWith('/puzzles/daily'));
      expect(request.url.queryParameters['date'], specialDate);
      return http.Response.bytes(
        utf8.encode(jsonEncode(mockResponse)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ApiClient(timeSync: TimeSyncService());
    final ok = await RemotePuzzleStore.syncDay(
      api,
      specialDate,
      httpClient: mockClient,
    );
    expect(ok, isTrue);

    final loadedPinpoint = PinpointLevelRepository.getLevelForDate(specialDate);
    expect(loadedPinpoint.targetWord, 'BAYRAM');
    expect(RemotePuzzleStore.getSpecialMeta(specialDate)?.isSpecial, isTrue);
    expect(RemotePuzzleStore.getSpecialMeta(specialDate)?.specialNote, '23 Nisan Özel');
  });
}

