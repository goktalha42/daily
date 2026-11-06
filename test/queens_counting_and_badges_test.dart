import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/models/badge_model.dart';
import 'package:daily_games/core/services/badge_service.dart';
import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/services/game_stats_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';
import 'package:daily_games/core/widgets/sketch_badge_icons.dart';
import 'package:daily_games/features/profile/badges_screen.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameDateUtils.resetDayOffset();
  });

  tearDown(() {
    GameDateUtils.resetDayOffset();
  });

  group('Vezirler (Queens) Günlük Tek Oyun Sayımı Testleri', () {
    test('Vezirler oyununda 1 bölüm de 3 bölüm de tamamlansa günlük 1 oyun sayılır; tüm oyunlarla toplam 6 olur',
        () async {
      final todayId = GameDateUtils.getTodayLevelId();
      final dailyNotifier = DailyPlayNotifier();
      final statsNotifier = GameStatsNotifier();
      final badgeNotifier = BadgeNotifier();

      // 1. Önce Vezirler Kolay tamamlanır -> 1 oyun
      await statsNotifier.recordGameResult(
        gameType: GameType.queens,
        score: 850,
        durationMs: 32000,
        moveCount: 10,
        difficulty: 'kolay',
        dateId: todayId,
      );
      await dailyNotifier.recordCompletion(
        game: GameType.queens,
        dateId: todayId,
        score: 850,
        durationMs: 32000,
        subKey: 'kolay',
      );

      expect(dailyNotifier.state.getCompletedCountForDate(todayId), 1);
      expect(statsNotifier.state[GameType.queens]!.totalGamesPlayed, 1);

      // 2. Aynı gün Vezirler Zor ve Master da tamamlanır -> Hâlâ 1 oyun!
      await statsNotifier.recordGameResult(
        gameType: GameType.queens,
        score: 1050,
        durationMs: 38000,
        moveCount: 14,
        difficulty: 'zor',
        dateId: todayId,
      );
      await dailyNotifier.recordCompletion(
        game: GameType.queens,
        dateId: todayId,
        score: 1050,
        durationMs: 38000,
        subKey: 'zor',
      );

      await statsNotifier.recordGameResult(
        gameType: GameType.queens,
        score: 1320,
        durationMs: 41000,
        moveCount: 16,
        difficulty: 'master',
        dateId: todayId,
      );
      await dailyNotifier.recordCompletion(
        game: GameType.queens,
        dateId: todayId,
        score: 1320,
        durationMs: 41000,
        subKey: 'master',
      );

      expect(dailyNotifier.state.getCompletedCountForDate(todayId), 1);
      expect(statsNotifier.state[GameType.queens]!.totalGamesPlayed, 1);

      // Toplam Vezirler skoru ise 3 seviyenin toplamıdır (850 + 1050 + 1320 = 3220)
      final aggQueensRecord = dailyNotifier.state.getRecord(GameType.queens, todayId);
      expect(aggQueensRecord, isNotNull);
      expect(aggQueensRecord!.score, 850 + 1050 + 1320);

      // 3. Diğer 5 oyun da aynı gün tamamlanır -> Toplam çözülen oyun 8 değil tam 6 olur!
      final otherGames = GameType.values.where((g) => g != GameType.queens);
      for (final game in otherGames) {
        await statsNotifier.recordGameResult(
          gameType: game,
          score: 1650,
          durationMs: 25000,
          moveCount: 15,
          dateId: todayId,
        );
        await dailyNotifier.recordCompletion(
          game: game,
          dateId: todayId,
          score: 1650,
          durationMs: 25000,
        );
      }

      final totalPlayedAcrossAll = statsNotifier.state.values
          .fold<int>(0, (sum, perf) => sum + perf.totalGamesPlayed);
      expect(totalPlayedAcrossAll, 6);
      expect(dailyNotifier.state.getCompletedCountForDate(todayId), 6);

      // Mükemmel Gün (6/6) rozeti başarıyla açılmalıdır
      await badgeNotifier.evaluateBadges(
        gameType: GameType.patches,
        score: 1650,
        durationMs: 25000,
        overallIQ: statsNotifier.getOverallIQ(),
        statsMap: statsNotifier.state,
        dailyPlayState: dailyNotifier.state,
      );
      expect(badgeNotifier.isUnlocked('belt_clean_sweep'), isTrue);
    });

    test('Eski 8 oyunluk Vezirler kaydı açılışta otomatik olarak 6 oyuna (günlük 1 Vezirler) düzeltilir',
        () async {
      const dateId = '2026-11-06';
      final legacyDailyRecords = {
        'queens|$dateId': {
          'gameType': 'queens',
          'dateId': dateId,
          'score': 800,
          'durationMs': 30000,
          'completedAt': '2026-11-06T10:00:00.000Z',
          'subKey': 'kolay',
        },
        'queens:kolay|$dateId': {
          'gameType': 'queens',
          'dateId': dateId,
          'score': 800,
          'durationMs': 30000,
          'completedAt': '2026-11-06T10:00:00.000Z',
          'subKey': 'kolay',
        },
        'queens:zor|$dateId': {
          'gameType': 'queens',
          'dateId': dateId,
          'score': 1000,
          'durationMs': 35000,
          'completedAt': '2026-11-06T10:05:00.000Z',
          'subKey': 'zor',
        },
        'queens:master|$dateId': {
          'gameType': 'queens',
          'dateId': dateId,
          'score': 1250,
          'durationMs': 40000,
          'completedAt': '2026-11-06T10:10:00.000Z',
          'subKey': 'master',
        },
      };

      final legacyStats = {
        for (final g in GameType.values)
          g.id: {
            'percentile': 10,
            'bestScore': 1500,
            'bestDurationMs': 25000,
            'totalGamesPlayed': g == GameType.queens ? 3 : 1, // Eskiden 5 + 3 = 8 idi
            'geniusTitle': 'Keskin Zihin',
            'emaZScore': 1.2,
            'peakZScore': 1.3,
          },
      };

      SharedPreferences.setMockInitialValues({
        'zuhtu_daily_play_records_v1': jsonEncode(legacyDailyRecords),
        'daily_genius_game_stats_v3': jsonEncode(legacyStats),
      });

      final dailyNotifier = DailyPlayNotifier();
      await dailyNotifier.loadFromPrefs();

      // Kopya 'queens|date' anahtarı temizlenmiş ve toplam puan 3050 olmalı
      expect(dailyNotifier.state.records.containsKey('queens|$dateId'), isFalse);
      expect(dailyNotifier.state.getRecord(GameType.queens, dateId)?.score, 3050);

      final statsNotifier = GameStatsNotifier();
      await statsNotifier.ensureLoaded();

      expect(statsNotifier.state[GameType.queens]!.totalGamesPlayed, 1);
      final totalAfterMigration = statsNotifier.state.values
          .fold<int>(0, (sum, p) => sum + p.totalGamesPlayed);
      expect(totalAfterMigration, 6);
    });
  });

  group('El Çizimi Rozet & Başarı Tasarımları Tutarlılık Testleri', () {
    test('27 rozetin tamamı benzersiz el çizimi sanat tipine sahiptir ve IQ mertebeleriyle tutarlıdır', () {
      final allBadges = DailyBadge.allBadges;
      expect(allBadges.length, 27);

      final badgeArtTypes = allBadges.map((b) => b.artType).toSet();
      expect(
        badgeArtTypes.length,
        allBadges.length,
        reason: 'Her rozetin kendine özgü tekil bir BadgeArtType tasarımı olmalıdır',
      );

      final milestoneArtTypes = IQMilestone.all.map((m) => m.artType).toSet();
      expect(milestoneArtTypes.length, IQMilestone.all.length);

      // Ortak başarı/mertebeler birebir aynı el çizimi sembolü kullanmalıdır
      final einsteinBadge = allBadges.firstWhere((b) => b.id == 'belt_einstein');
      final einsteinMilestone = IQMilestone.all.firstWhere((m) => m.iqThreshold == 148);
      expect(einsteinBadge.artType, BadgeArtType.einsteinBrain);
      expect(einsteinMilestone.artType, BadgeArtType.einsteinBrain);

      final grandmasterBadge = allBadges.firstWhere((b) => b.id == 'belt_grandmaster');
      final grandmasterMilestone = IQMilestone.all.firstWhere((m) => m.iqThreshold == 120);
      expect(grandmasterBadge.artType, BadgeArtType.lightbulb);
      expect(grandmasterMilestone.artType, BadgeArtType.lightbulb);
    });

    testWidgets('Tüm 31 BadgeArtType el çizimi madalyonu açık ve kilitli modda hatasız çizilir',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final art in BadgeArtType.values) ...[
                    SketchBadgeMedallion(
                      type: art,
                      accentColor: art.defaultAccentColor,
                      isUnlocked: true,
                      size: 48,
                    ),
                    SketchBadgeMedallion(
                      type: art,
                      accentColor: art.defaultAccentColor,
                      isUnlocked: false,
                      size: 48,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SketchBadgeMedallion), findsNWidgets(BadgeArtType.values.length * 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('BadgesScreen el çizimi rozetleri ve kategori sekmelerini hatasız gösterir',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BadgesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rozetler & Başarılar'), findsOneWidget);
      expect(find.text('Başarılar'), findsOneWidget);
      expect(find.text('Seriler'), findsOneWidget);
      expect(find.text('Şampiyonluk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
