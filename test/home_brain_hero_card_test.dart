import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/features/home/widgets/home_brain_hero_card.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  testWidgets('HomeBrainHeroCard dinamik verileri gösterir ve dokununca analiz defterini açar',
      (WidgetTester tester) async {
    final activeDate = GameDateUtils.getActiveDate();
    final todayKey = GameDateUtils.getTodayLevelId();
    final yesterday = activeDate.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final statsMap = {
      for (final type in GameType.values)
        type: GamePerformanceData(
          gameType: type,
          percentile: type == GameType.queens || type == GameType.tango ? 8 : null,
          bestScore: type == GameType.queens || type == GameType.tango ? 1750 : 0,
          bestDurationMs: type == GameType.queens || type == GameType.tango ? 24000 : 0,
          totalGamesPlayed: type == GameType.queens || type == GameType.tango ? 2 : 0,
          geniusTitle: 'Keskin Zihin',
          emaZScore: 1.4,
          peakZScore: 1.6,
        ),
    };

    final dailyPlayState = DailyPlayState(
      records: {
        '${GameType.queens.id}|$yesterdayKey': DailyPlayRecord(
          gameType: GameType.queens,
          dateId: yesterdayKey,
          score: 1120,
          durationMs: 28000,
          completedAt: yesterday,
        ),
        '${GameType.tango.id}|$todayKey': DailyPlayRecord(
          gameType: GameType.tango,
          dateId: todayKey,
          score: 1780,
          durationMs: 22000,
          completedAt: activeDate,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeBrainHeroCard(
                userIQ: 112,
                statsMap: statsMap,
                dailyPlayState: dailyPlayState,
                activeDateKey: todayKey,
              ),
            ),
          ),
        ),
      ),
    );

    // Giriş koreografisini tamamla
    await tester.pump(const Duration(milliseconds: 1200));

    // Sabit "5 GÜN" değil, gerçek dinamik 2 günlük seri ve 1/6 tamamlanma görünmeli
    expect(find.text('2 GÜN'), findsOneWidget);
    expect(find.text('AKTİF ✓'), findsOneWidget);
    expect(find.text('IQ 112'), findsOneWidget);
    expect(find.text('GÜNLÜK 1/6'), findsOneWidget);
    expect(find.textContaining('KALİBRASYON: 2/6'), findsOneWidget);

    // Başlangıçta analiz defteri kapalıdır
    expect(find.text('SON 7 GÜN SERİ TAKVİMİ'), findsNothing);

    // Karta dokununca interaktif analiz defteri açılır
    await tester.tap(find.text('Analiz ▾'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SON 7 GÜN SERİ TAKVİMİ'), findsOneWidget);
    expect(find.text('6 BİLİŞSEL ALAN KARNESİ'), findsOneWidget);
    expect(find.textContaining('Einstein Kriteri'), findsOneWidget);
  });
}

