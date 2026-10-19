import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/features/leaderboard/leaderboard_service.dart';
import 'package:daily_games/games/common/base_game.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';

void main() {
  group('LeaderboardService 150 Oyuncu & Kurallar Testi', () {
    test('150 Farklı kullanıcı başarıyla seed edilir ve günlük liderlikte yer alır', () {
      final service = LeaderboardService();
      final dailyTango = service.getLeaderboard(
        gameType: GameType.tango,
        timeframe: LeaderboardTimeframe.daily,
      );

      expect(dailyTango.length, equals(150));
      // İlk sıradaki oyuncu en yüksek puana sahip
      expect(dailyTango.first.totalScore, greaterThan(dailyTango.last.totalScore));
      // Rütbeler 1'den 150'ye kadar ardışıktır
      expect(dailyTango.first.rank, equals(1));
      expect(dailyTango.last.rank, equals(150));
    });

    test('Vezirler oyununda toplam puan: Kolay + Zor + Master toplamıdır, oynanmayan 0 sayılır', () {
      final service = LeaderboardService();

      // Zorluk belirtilmeden çağrıldığında toplam puan sıralaması döner
      final queensOverall = service.getLeaderboard(
        gameType: GameType.queens,
        timeframe: LeaderboardTimeframe.daily,
      );

      expect(queensOverall.length, equals(150));

      // En üstteki oyuncular 3 seviyeyi de oynamış olmalı (Kolay + Zor + Master)
      final topEntry = queensOverall.first;
      expect(topEntry.gamesPlayed, equals(3));
      expect(topEntry.totalScore, greaterThan(3000)); // 3 seviyenin toplamı 3000'den büyük

      // Sadece Kolay oynayan oyuncular listenin alt kısımlarındadır
      final bottomEntry = queensOverall.last;
      expect(bottomEntry.gamesPlayed, equals(1)); // Sadece kolay
      expect(bottomEntry.totalScore, lessThan(1100)); // Sadece kolay puanı (~700-1000)
    });

    test('Vezirler belirli bir zorluk için tekil liderlik tablosu verir', () {
      final service = LeaderboardService();

      final kolayEntries = service.getLeaderboard(
        gameType: GameType.queens,
        timeframe: LeaderboardTimeframe.daily,
        difficulty: 'kolay',
      );
      final masterEntries = service.getLeaderboard(
        gameType: GameType.queens,
        timeframe: LeaderboardTimeframe.daily,
        difficulty: 'master',
      );

      expect(kolayEntries.length, equals(150));
      expect(masterEntries.length, equals(50)); // Master'ı sadece 50 kişi tamamlamış
      expect(kolayEntries.first.totalScore, lessThan(1200));
      expect(masterEntries.first.totalScore, greaterThan(1300));
    });

    test('Kullanıcı DailyPlayState kaydı ile liderlik tablosuna dinamik olarak eklenir ve sıralamaya girer', () {
      final service = LeaderboardService();
      final todayId = GameDateUtils.getTodayLevelId();

      final dailyState = DailyPlayState(records: {
        'tango|$todayId': DailyPlayRecord(
          gameType: GameType.tango,
          dateId: todayId,
          score: 1980, // Çok yüksek bir skor -> 1. sıraya yerleşmeli
          durationMs: 15000,
          completedAt: DateTime.now(),
        ),
      });

      service.syncWithDailyPlay(dailyState);

      final tangoLeaderboard = service.getLeaderboard(
        gameType: GameType.tango,
        timeframe: LeaderboardTimeframe.daily,
        levelId: todayId,
      );

      final myEntry = tangoLeaderboard.firstWhere((e) => e.userId == 'user_local');
      expect(myEntry.rank, equals(1));
      expect(myEntry.totalScore, equals(1980));
      expect(tangoLeaderboard.length, equals(151)); // 150 bot + 1 yerel kullanıcı
    });

    test('Kullanıcı sadece kolay vezirler oynadığında toplam puan sadece kolay puanı olur', () {
      final service = LeaderboardService();
      final todayId = GameDateUtils.getTodayLevelId();

      final dailyState = DailyPlayState(records: {
        'queens:kolay|$todayId': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: todayId,
          score: 850,
          durationMs: 35000,
          completedAt: DateTime.now(),
          subKey: 'kolay',
        ),
      });

      service.syncWithDailyPlay(dailyState);

      final queensOverall = service.getLeaderboard(
        gameType: GameType.queens,
        timeframe: LeaderboardTimeframe.daily,
        levelId: todayId,
      );

      final myEntry = queensOverall.firstWhere((e) => e.userId == 'user_local');
      expect(myEntry.totalScore, equals(850)); // Diğerleri oynanmadığı için 0 sayıldı
      expect(myEntry.gamesPlayed, equals(1));
    });

    test('Kullanıcı henüz oyun oynamadıysa skorborda dahil edilmez ve Sena_M kullanıcı sayılmaz', () {
      final service = LeaderboardService();

      for (final game in GameType.values) {
        final entries = service.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.daily,
        );

        // Kullanıcı henüz oynamadığı için skorbordda yer almamalı
        final userEntries = entries.where((e) => e.userId == 'user_local');
        expect(userEntries.isEmpty, isTrue);

        // Sena_M kullanıcısı kendi id'sine sahip olmalı ve kullanıcı gibi gösterilmemeli
        final sena = entries.firstWhere((e) => e.userName == 'Sena_M');
        expect(sena.userId, startsWith('mock_user_'));
        expect(sena.userId, isNot(equals('user_local')));
      }
    });

    test('Bütün oyunlar için Haftalık, Aylık ve Genel sıralamalarda puanlar zamanla birikir ve artar', () {
      final service = LeaderboardService();

      for (final game in GameType.values) {
        final dailyEntries = service.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.daily,
        );
        final weeklyEntries = service.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.weekly,
        );
        final monthlyEntries = service.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.monthly,
        );
        final allTimeEntries = service.getLeaderboard(
          gameType: game,
          timeframe: LeaderboardTimeframe.allTime,
        );

        expect(dailyEntries.isNotEmpty, isTrue, reason: '${game.id} günlük verisi boş olmamalı');
        expect(weeklyEntries.isNotEmpty, isTrue, reason: '${game.id} haftalık verisi boş olmamalı');
        expect(monthlyEntries.isNotEmpty, isTrue, reason: '${game.id} aylık verisi boş olmamalı');
        expect(allTimeEntries.isNotEmpty, isTrue, reason: '${game.id} genel verisi boş olmamalı');

        // Haftalık lider skoru günlükten belirgin şekilde yüksektir (oyunlar birikir)
        expect(weeklyEntries.first.totalScore, greaterThan(dailyEntries.first.totalScore));

        // Aylık lider skoru haftalıktan belirgin şekilde yüksektir
        expect(monthlyEntries.first.totalScore, greaterThan(weeklyEntries.first.totalScore));

        // Genel (tüm zamanlar) lider skoru aylıktan daha da yüksektir
        expect(allTimeEntries.first.totalScore, greaterThan(monthlyEntries.first.totalScore));
      }
    });
  });
}
