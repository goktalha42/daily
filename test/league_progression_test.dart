import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/services/league_service.dart';
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

  group('Lig İlerleme ve Hafta Geçişi Testleri', () {
    test('Hafta geçişinde kullanıcı ilk 10 daysa bir üst lige terfi eder', () async {
      final leaderboard = LeaderboardService(enableMockBots: true);
      final notifier = LeagueNotifier(leaderboard);
      await Future.delayed(const Duration(milliseconds: 100));

      // Başlangıçta Demir ligi
      expect(notifier.state.currentLevel, equals(LeagueLevel.iron));

      // Kullanıcının sırasını ilk 5'e sokacak şekilde state simüle et
      notifier.state = notifier.state.copyWith(
        players: notifier.state.players.map((p) => p.isUser ? p.copyWith(rank: 3) : p).toList(),
      );

      expect(notifier.state.userRank, equals(3));

      // Tarihi 7 gün ileri alarak yeni haftaya geç
      for (int i = 0; i < 7; i++) {
        GameDateUtils.advanceToNextDay();
      }

      // Hafta geçişini tetikle
      await notifier.checkWeekTransition();

      // Kullanıcı Demir Liginden Bronz Ligine terfi etmeli
      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingPromotion, equals(LeagueLevel.bronze));
    });

    test('Hafta geçişinde kullanıcı son 10 daysa bir alt lige geriler', () async {
      final leaderboard = LeaderboardService(enableMockBots: true);
      final notifier = LeagueNotifier(leaderboard);
      await Future.delayed(const Duration(milliseconds: 100));

      // Başlangıçta Gümüş liginde olsun ve son 10'da (38. sıra)
      notifier.state = notifier.state.copyWith(
        currentLevel: LeagueLevel.silver,
        players: notifier.state.players.map((p) => p.isUser ? p.copyWith(rank: 38) : p).toList(),
      );

      expect(notifier.state.currentLevel, equals(LeagueLevel.silver));
      expect(notifier.state.userRank, equals(38)); // Son 10'da (33-42)

      // Tarihi 7 gün ileri alarak yeni haftaya geç
      for (int i = 0; i < 7; i++) {
        GameDateUtils.advanceToNextDay();
      }

      // Hafta geçişini tetikle
      await notifier.checkWeekTransition();

      // Kullanıcı Gümüş Liginden Bronz Ligine gerilemeli
      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingRelegation, equals(LeagueLevel.bronze));
    });

    test('SharedPreferences üzerindeki 1. sıra verisi yeni haftada Bronz lige terfi ettirir', () async {
      SharedPreferences.setMockInitialValues({
        'zuhtu_league_state_v3': '{"currentLevel":0,"weekId":"2026-W40","lastRank":1,"players":[{"userId":"user_local","userName":"Sen","weeklyScore":3500,"rank":1,"isUser":true}]}',
      });

      final notifier = LeagueNotifier();
      // _initLeague asenkron çalışır, yüklenmesini bekle
      await Future.delayed(const Duration(milliseconds: 150));

      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingPromotion, equals(LeagueLevel.bronze));
    });

    test('Bozuk lastRank (42) kaydedilmiş olsa bile oyuncu listesindeki 1. sıra kurtarılır ve terfi gerçekleşir', () async {
      SharedPreferences.setMockInitialValues({
        'zuhtu_league_state_v3': '{"currentLevel":0,"weekId":"2026-W40","lastRank":42,"players":[{"userId":"user_local","userName":"Sen","weeklyScore":3500,"rank":1,"isUser":true}]}',
      });

      final notifier = LeagueNotifier();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingPromotion, equals(LeagueLevel.bronze));
    });

    test('refreshAfterGame hafta geçişinde lig terfisini atlamaz ve tetikler', () async {
      final leaderboard = LeaderboardService(enableMockBots: true);
      final notifier = LeagueNotifier(leaderboard);
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.state = notifier.state.copyWith(
        players: notifier.state.players.map((p) => p.isUser ? p.copyWith(rank: 1, weeklyScore: 2000) : p).toList(),
      );

      // Tarihi yeni haftaya al
      for (int i = 0; i < 7; i++) {
        GameDateUtils.advanceToNextDay();
      }

      // Yeni haftada oyun bitişi tetiklenirse doğrudan checkWeekTransition devreye girmeli
      await notifier.refreshAfterGame();

      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingPromotion, equals(LeagueLevel.bronze));
    });

    test('Ekim ayının tamamı için her günde skorbord doludur', () {
      final leaderboard = LeaderboardService(enableMockBots: true);

      // 1 Ekim'den 31 Ekim'e kadar kontrol et
      for (int d = 1; d <= 31; d++) {
        final dayStr = d.toString().padLeft(2, '0');
        final levelId = '2026-10-$dayStr';

        final dailyResults = leaderboard.getLeaderboard(
          gameType: GameType.queens,
          timeframe: LeaderboardTimeframe.daily,
          levelId: levelId,
        );

        expect(
          dailyResults.isNotEmpty,
          isTrue,
          reason: '$levelId günü için skorbord boş olmamalı',
        );
      }
    });
  });
}
