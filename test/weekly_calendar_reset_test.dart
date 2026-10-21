import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
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

  test('Çarşamba günü oynanan oyunun puanı Pazartesi günü sıfırlanır (Çarşamba gününü beklemez)', () async {
    final leaderboard = LeaderboardService();
    final leagueNotifier = LeagueNotifier(leaderboard);
    await Future.delayed(const Duration(milliseconds: 100));

    // 1. Simülasyon: Kullanıcı 21 Ekim 2026 Çarşamba gününde (veya mevcut günde) oyun oynar
    final wednesdayDate = GameDateUtils.getActiveDate(); // Çarşamba
    final wednesdayId = GameDateUtils.getTodayLevelId();

    final dailyPlay = DailyPlayState(records: {
      'tango|$wednesdayId': DailyPlayRecord(
        gameType: GameType.tango,
        dateId: wednesdayId,
        score: 1850,
        durationMs: 25000,
        completedAt: wednesdayDate,
      ),
    });

    // Liderlik tablosuyla eşitle
    leaderboard.syncWithDailyPlay(dailyPlay);
    await leagueNotifier.refreshAfterGame();

    // Çarşamba günü kullanıcının haftalık puanı 1850 olmalı
    expect(leagueNotifier.state.userWeeklyScore, equals(1850));

    // 2. Günleri Pazar gününe kadar ilerlet (Çarşamba -> Perşembe -> Cuma -> Cumartesi -> Pazar = 4 gün)
    final daysUntilSunday = 7 - wednesdayDate.weekday;
    for (int i = 0; i < daysUntilSunday; i++) {
      GameDateUtils.advanceToNextDay();
    }

    // Pazar günü puan hala korunmalı (haftanın son günü)
    await leagueNotifier.checkWeekTransition();
    expect(leagueNotifier.state.userWeeklyScore, equals(1850));

    // 3. Pazar'dan Pazartesi'ye geç (1 gün daha ilerlet) -> YENİ HAFTA!
    GameDateUtils.advanceToNextDay();
    await leagueNotifier.checkWeekTransition();

    // PAZARTESİ GÜNÜ PUAN SIFIRLANMALIDIR! ÇARŞAMBAYI BEKLEMEMELİDİR!
    expect(
      leagueNotifier.state.userWeeklyScore,
      equals(0),
      reason: 'Pazartesi yeni hafta başladığı için önceki haftanın puanı sıfırlanmalıdır!',
    );

    // 4. Pazartesi günü yeni bir oyun oynandığında sadece yeni haftanın puanı birikir
    final mondayId = GameDateUtils.getTodayLevelId();
    final mondayDate = GameDateUtils.getActiveDate();
    final newDailyPlay = DailyPlayState(records: {
      ...dailyPlay.records,
      'tango|$mondayId': DailyPlayRecord(
        gameType: GameType.tango,
        dateId: mondayId,
        score: 1200,
        durationMs: 30000,
        completedAt: mondayDate,
      ),
    });

    leaderboard.syncWithDailyPlay(newDailyPlay);
    await leagueNotifier.refreshAfterGame();

    // Yeni haftadaki puan sadece Pazartesi oynanan 1200 olmalı (1850 + 1200 = 3050 OLMAMALI!)
    expect(leagueNotifier.state.userWeeklyScore, equals(1200));
  });
}
