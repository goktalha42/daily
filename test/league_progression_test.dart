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
      final leaderboard = LeaderboardService();
      final notifier = LeagueNotifier(leaderboard);
      await Future.delayed(const Duration(milliseconds: 100));

      // Başlangıçta Taş ligi
      expect(notifier.state.currentLevel, equals(LeagueLevel.stone));

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

      // Kullanıcı Taş Liginden Bronz Ligine terfi etmeli
      expect(notifier.state.currentLevel, equals(LeagueLevel.bronze));
      expect(notifier.state.pendingPromotion, equals(LeagueLevel.bronze));
    });

    test('Hafta geçişinde kullanıcı son 10 daysa bir alt lige geriler', () async {
      final leaderboard = LeaderboardService();
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

    test('Ekim ayının tamamı için her günde skorbord doludur', () {
      final leaderboard = LeaderboardService();

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
