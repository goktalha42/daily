import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/services/league_service.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/features/leaderboard/leaderboard_service.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameDateUtils.resetDayOffset();
  });

  tearDown(() {
    GameDateUtils.resetDayOffset();
  });

  group('Puan Tutarlılığı ve Babayaga 12428 Puan Doğrulama Testleri', () {
    test('Pazartesi günü tüm oyunlar (Vezirler 3 seviye dahil) bittiğinde lig skoru tam 12428 LP olur ve 16.8K kalıntısı bulaşmaz', () async {
      // 1. Pazartesi günü için sabit tarih
      final mondayDate = DateTime(2026, 11, 9, 12, 0, 0); // Pazartesi
      GameDateUtils.setCustomDate(mondayDate);
      final todayId = GameDateUtils.getTodayLevelId();

      // 2. Kullanıcının bugünkü oyun kayıtları (toplam: 12428)
      // Queens Kolay: 800, Zor: 911, Master: 1300 -> Queens Toplam = 3011
      // Pinpoint: 1850, Crossclimb: 1900, Tango: 1850, ZipPath: 1900, Patches: 1917 -> 9417
      // 3011 + 9417 = 12428
      final records = {
        'queens:kolay|$todayId': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: todayId,
          score: 800,
          durationMs: 25000,
          completedAt: mondayDate,
          subKey: 'kolay',
        ),
        'queens:zor|$todayId': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: todayId,
          score: 911,
          durationMs: 45000,
          completedAt: mondayDate,
          subKey: 'zor',
        ),
        'queens:master|$todayId': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: todayId,
          score: 1300,
          durationMs: 90000,
          completedAt: mondayDate,
          subKey: 'master',
        ),
        'pinpoint|$todayId': DailyPlayRecord(
          gameType: GameType.pinpoint,
          dateId: todayId,
          score: 1850,
          durationMs: 15000,
          completedAt: mondayDate,
        ),
        'crossclimb|$todayId': DailyPlayRecord(
          gameType: GameType.crossclimb,
          dateId: todayId,
          score: 1900,
          durationMs: 10000,
          completedAt: mondayDate,
        ),
        'tango|$todayId': DailyPlayRecord(
          gameType: GameType.tango,
          dateId: todayId,
          score: 1850,
          durationMs: 15000,
          completedAt: mondayDate,
        ),
        'zipPath|$todayId': DailyPlayRecord(
          gameType: GameType.zipPath,
          dateId: todayId,
          score: 1900,
          durationMs: 10000,
          completedAt: mondayDate,
        ),
        'patches|$todayId': DailyPlayRecord(
          gameType: GameType.patches,
          dateId: todayId,
          score: 1917,
          durationMs: 9000,
          completedAt: mondayDate,
        ),
      };

      final dailyPlayState = DailyPlayState(records: records);

      // SharedPreferences'ta eski haftadan kalan bozuk önbellek (16754 puanlık) simülasyonu
      SharedPreferences.setMockInitialValues({
        'zuhtu_server_leaderboard_cache_v2': jsonEncode({
          'queens_weekly__': [
            {'rank': 1, 'player_id': 1, 'player_name': 'babayaga', 'total_score': 16754, 'best_time_ms': 50000, 'games_played': 1, 'is_bot': false}
          ]
        }),
        'zuhtu_league_state_v3': jsonEncode({
          'currentLevel': 1, // Bronz
          'weekId': '2026-W46',
          'players': [
            {'userId': 'user_local', 'userName': 'babayaga', 'weeklyScore': 16754, 'rank': 1, 'isUser': true}
          ]
        }),
      });

      final leaderboard = LeaderboardService(userNickname: 'babayaga');
      final leagueNotifier = LeagueNotifier(
        leaderboard,
        null,
        'babayaga',
        dailyPlayState,
        () => 'babayaga',
        () => dailyPlayState,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // 16754 puanlık bozuk önbellek EZİLMELİ ve kullanıcının gerçek haftalık skoru 12428 olmalıdır
      expect(leagueNotifier.state.userWeeklyScore, equals(12428));
      expect(leagueNotifier.state.userPlayer?.weeklyScore, equals(12428));
    });

    test('GameStatsService Vezirler gün toplamını (Kolay + Zor + Master) uzlaştırır ve profile 10717 yerine 12428 puan yansıtır', () async {
      final mondayDate = DateTime(2026, 11, 9, 12, 0, 0);
      GameDateUtils.setCustomDate(mondayDate);
      final todayId = GameDateUtils.getTodayLevelId();

      final dailyPlayPrefMap = {
        'queens:kolay|$todayId': {
          'gameType': 'queens',
          'dateId': todayId,
          'score': 800,
          'durationMs': 25000,
          'completedAt': mondayDate.toIso8601String(),
          'subKey': 'kolay',
        },
        'queens:zor|$todayId': {
          'gameType': 'queens',
          'dateId': todayId,
          'score': 911,
          'durationMs': 45000,
          'completedAt': mondayDate.toIso8601String(),
          'subKey': 'zor',
        },
        'queens:master|$todayId': {
          'gameType': 'queens',
          'dateId': todayId,
          'score': 1300,
          'durationMs': 90000,
          'completedAt': mondayDate.toIso8601String(),
          'subKey': 'master',
        },
      };

      // GameStats'ta eski hatalı durum (Vezirler sadece Master = 1300 olarak kaydedilmişti):
      final statsPrefMap = {
        'queens': {
          'gameType': 'queens',
          'bestScore': 1300, // Eski hatalı skor (800 ve 911 atılmıştı)
          'bestDurationMs': 90000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Vezir Ustası',
          'percentile': 5,
        },
        'pinpoint': {
          'gameType': 'pinpoint',
          'bestScore': 1850,
          'bestDurationMs': 15000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Kelime Avcısı',
          'percentile': 5,
        },
        'crossclimb': {
          'gameType': 'crossclimb',
          'bestScore': 1900,
          'bestDurationMs': 10000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Merdiven Tırmanıcı',
          'percentile': 5,
        },
        'tango': {
          'gameType': 'tango',
          'bestScore': 1850,
          'bestDurationMs': 15000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Güneş & Ay',
          'percentile': 5,
        },
        'zipPath': {
          'gameType': 'zipPath',
          'bestScore': 1900,
          'bestDurationMs': 10000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Yol Bulucu',
          'percentile': 5,
        },
        'patches': {
          'gameType': 'patches',
          'bestScore': 1917,
          'bestDurationMs': 9000,
          'totalGamesPlayed': 1,
          'geniusTitle': 'Alan Bölücü',
          'percentile': 5,
        },
      };

      SharedPreferences.setMockInitialValues({
        'zuhtu_daily_play_records_v1': jsonEncode(dailyPlayPrefMap),
        'daily_genius_game_stats_v3': jsonEncode(statsPrefMap),
      });

      final statsNotifier = GameStatsNotifier();
      await statsNotifier.ensureLoaded();

      // Otomatik uzlaştırma ile Vezirler'in bestScore'u 1300'den 3011'e (800 + 911 + 1300) yükseltilmelidir
      final queensPerf = statsNotifier.state[GameType.queens];
      expect(queensPerf?.bestScore, equals(3011));

      // Tüm 6 oyunun en iyi skorları toplamı: 3011 + 1850 + 1900 + 1850 + 1900 + 1917 = 12428 olmalıdır!
      int totalScore = 0;
      for (var p in statsNotifier.state.values) {
        totalScore += p.bestScore;
      }
      expect(totalScore, equals(12428));
    });
  });
}
