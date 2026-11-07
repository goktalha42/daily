import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/features/home/widgets/weekly_brain_report_dialog.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'zuhtu_user_nickname': 'ZekaUstasi',
    });
  });

  group('Haftalık Zeka Raporu (Pazar Akşamı Özeti) Testleri', () {
    test('Haftalık bilişsel odak dağılımı ve en güçlü/zayıf alanları doğru hesaplar', () {
      // 2026-11-08 Pazar referans tarihi
      final sundayRef = DateTime(2026, 11, 8);

      // Pazartesi (2026-11-02) ile Pazar (2026-11-08) arasındaki oyun kayıtları
      // 9 Vezirler (Mantık), 5 Tango (Örüntü), 3 Zip Path (Uzamsal), 3 Pinpoint (Kelime Hafızası) = 20 toplam oyun
      // Mantık oranı: 9/20 = %45
      // Kelime Hafızası oranı: 3/20 = %15
      final records = <String, DailyPlayRecord>{};

      // 7 gün boyunca her gün en az 1 oyun oynansın (Seri = 7 gün)
      for (int day = 2; day <= 8; day++) {
        final dStr = '2026-11-${day.toString().padLeft(2, '0')}';
        records['queens|$dStr'] = DailyPlayRecord(
          gameType: GameType.queens,
          dateId: dStr,
          score: 1800,
          durationMs: 40000,
          completedAt: DateTime(2026, 11, day, 10, 0),
        );
      }
      // Ek Vezirler kayıtları (toplam 9)
      records['queens:zor|2026-11-02'] = DailyPlayRecord(
        gameType: GameType.queens,
        dateId: '2026-11-02',
        score: 1750,
        durationMs: 45000,
        completedAt: DateTime(2026, 11, 2, 11, 0),
        subKey: 'zor',
      );
      records['queens:master|2026-11-03'] = DailyPlayRecord(
        gameType: GameType.queens,
        dateId: '2026-11-03',
        score: 1900,
        durationMs: 50000,
        completedAt: DateTime(2026, 11, 3, 11, 0),
        subKey: 'master',
      );

      // Tango kayıtları (toplam 5)
      for (int day = 2; day <= 6; day++) {
        final dStr = '2026-11-${day.toString().padLeft(2, '0')}';
        records['tango|$dStr'] = DailyPlayRecord(
          gameType: GameType.tango,
          dateId: dStr,
          score: 1820,
          durationMs: 30000,
          completedAt: DateTime(2026, 11, day, 12, 0),
        );
      }

      // Zip Path kayıtları (toplam 3)
      for (int day = 2; day <= 4; day++) {
        final dStr = '2026-11-${day.toString().padLeft(2, '0')}';
        records['zipPath|$dStr'] = DailyPlayRecord(
          gameType: GameType.zipPath,
          dateId: dStr,
          score: 1790,
          durationMs: 28000,
          completedAt: DateTime(2026, 11, day, 13, 0),
        );
      }

      // Pinpoint kayıtları (toplam 3)
      for (int day = 5; day <= 7; day++) {
        final dStr = '2026-11-${day.toString().padLeft(2, '0')}';
        records['pinpoint|$dStr'] = DailyPlayRecord(
          gameType: GameType.pinpoint,
          dateId: dStr,
          score: 1650,
          durationMs: 35000,
          completedAt: DateTime(2026, 11, day, 14, 0),
        );
      }

      final dailyState = DailyPlayState(records: records);
      final stats = WeeklyCognitiveStats.calculate(
        dailyPlayState: dailyState,
        referenceDate: sundayRef,
      );

      expect(stats.isSunday, isTrue);
      expect(stats.weeklyStreak, 7); // 7 gün kesintisiz oynandı
      expect(stats.totalPuzzlesSolved, 20); // 9 + 5 + 3 + 3 = 20

      // En çok odaklanılan alan: Mantık (%45)
      expect(stats.mostFocusedGame, GameType.queens);
      expect(stats.mostFocusedPercent, closeTo(45.0, 0.1));

      // Pinpoint oranı: 3/20 = %15
      expect(stats.cognitiveFocusPercent[GameType.pinpoint], closeTo(15.0, 0.1));
    });

    testWidgets('WeeklyBrainReportDialog ekranda eksiksiz render edilir', (tester) async {
      final sundayRef = DateTime(2026, 11, 8);
      final records = <String, DailyPlayRecord>{
        'queens|2026-11-08': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: '2026-11-08',
          score: 1850,
          durationMs: 40000,
          completedAt: DateTime(2026, 11, 8, 12, 0),
        ),
      };
      final dailyState = DailyPlayState(records: records);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      WeeklyBrainReportDialog.show(
                        context,
                        dailyPlayState: dailyState,
                        overallIQ: 134,
                        referenceDate: sundayRef,
                      );
                    },
                    child: const Text('Raporu Aç'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Raporu Aç'));
      await tester.pumpAndSettle();

      expect(find.text('HAFTALIK ZEKA RAPORU'), findsOneWidget);
      expect(find.textContaining('PAZAR AKŞAMI ÖZETİ'), findsOneWidget);
      expect(find.text('BİLİŞSEL ALAN ODAK DAĞILIMI'), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
      expect(find.text('Kopyala'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
    });
  });
}

