import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/theme/app_colors.dart';
import 'package:daily_games/core/utils/share_card_helper.dart';
import 'package:daily_games/core/widgets/daily_social_share_dialog.dart';
import 'package:daily_games/core/widgets/head_to_head_share_dialog.dart';
import 'package:daily_games/core/widgets/sketch_badge_icons.dart';
import 'package:daily_games/core/widgets/sketch_decorations.dart';
import 'package:daily_games/features/onboarding/onboarding_screen.dart';
import 'package:daily_games/features/profile/profile_screen.dart';
import 'package:daily_games/features/profile/settings_screen.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'zuhtu_user_nickname': 'ZekaTestcisi',
      'zuhtu_user_avatar_id': 'owl',
    });
  });

  group('Onboarding Walkthrough Tests', () {
    testWidgets('OnboardingScreen 1. slaytı doğru başlık ve metinlerle render eder',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZÜHTÜ REHBERİ'), findsOneWidget);
      expect(find.text('Atla'), findsOneWidget);
      expect(find.text('Günde Sadece\n10 Dakika!'), findsOneWidget);
      expect(find.textContaining('☕'), findsNothing);
      expect(find.text('Devam Et'), findsOneWidget);
    });

    testWidgets('OnboardingScreen 5 slayt arasında adım adım ilerler ve son slaytta Başla butonu gösterir',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. slayt -> 2. slayt
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text("Her Gece 00:00'da\n6 Yeni Oyun"), findsOneWidget);
      expect(find.text(GameType.queens.title), findsOneWidget);
      expect(find.text(GameType.pinpoint.title), findsOneWidget);
      expect(find.text(GameType.crossclimb.title), findsOneWidget);
      expect(find.text(GameType.tango.title), findsOneWidget);
      expect(find.text(GameType.zipPath.title), findsOneWidget);
      expect(find.text(GameType.patches.title), findsOneWidget);
      expect(find.text('Nokta Atışı'), findsNothing);

      // 2. slayt -> 3. slayt
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Puanını ve Zeka\nSkorunu Gör'), findsOneWidget);
      expect(find.textContaining('Skorunu Gör 🧠'), findsNothing);
      expect(find.text('ZÜHTÜ SKORU NEDİR?'), findsOneWidget);

      // 3. slayt -> 4. slayt
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Ateşi Söndürme:\nSerini Koru!'), findsOneWidget);

      // 4. slayt -> 5. slayt (Son slayt)
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Liglerde yarış ve\nrozetleri topla'), findsOneWidget);
      expect(find.textContaining('42 kişiyle yarış'), findsOneWidget);
      expect(find.textContaining("ilk 10'a girerek"), findsOneWidget);
      expect(find.byType(SketchBadgeIcon), findsWidgets);
      expect(find.text("Zühtü'ye Başla! 🚀"), findsOneWidget);

      // Başla butonuna basıldığında SharedPreferences'a tamamlandı yazar
      await tester.tap(find.text("Zühtü'ye Başla! 🚀"));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingScreen.completedPrefKey), isTrue);
    });

    testWidgets('OnboardingScreen Atla butonuna basıldığında tamamlandı olarak işaretler',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingScreen.completedPrefKey), isTrue);
    });
  });

  group('DailySocialShareDialog Tests', () {
    testWidgets('DailySocialShareDialog tüm karne alanlarını ve butonları eksiksiz render eder',
        (tester) async {
      final mockDailyPlayState = DailyPlayState(
        records: {
          'queens|2026-11-11': DailyPlayRecord(
            gameType: GameType.queens,
            dateId: '2026-11-11',
            score: 950,
            durationMs: 75000,
            completedAt: DateTime(2026, 11, 11, 10),
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DailySocialShareDialog.show(
                        context,
                        dateId: '2026-11-11',
                        overallIQ: 135,
                        dailyPlayState: mockDailyPlayState,
                      );
                    },
                    child: const Text('Karneni Göster'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Karneni Göster'));
      await tester.pumpAndSettle();

      // Kart bileşenleri
      expect(find.text('ZÜHTÜ GÜNÜN KARNESİ'), findsOneWidget);
      expect(find.text('@ZekaTestcisi'), findsOneWidget);
      expect(find.text('🦉'), findsOneWidget);
      expect(find.text('135'), findsOneWidget);
      expect(find.byType(GameSketchThumbnail), findsNWidgets(6));
      expect(find.byType(SketchDoodleBrain), findsWidgets);
      expect(find.byType(SketchDoodleClipboard), findsOneWidget);
      expect(find.text('Görsel Paylaş'), findsOneWidget);
      expect(find.text('Metin'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
    });

    testWidgets('DailySocialShareDialog seçilen avatarı, özel arka plan rengini ve RepaintBoundary yakalamayı destekler',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'zuhtu_user_nickname': 'RenkliDahi',
        'zuhtu_user_avatar_id': 'crown:cyan',
      });

      final mockDailyPlayState = DailyPlayState(records: {});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailySocialShareDialog(
                dateId: '2026-11-11',
                overallIQ: 120,
                dailyPlayState: mockDailyPlayState,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El çizimi taç avatarı ve seçilen turkuaz arka plan rengi kullanılmalı
      expect(find.byType(SketchDoodleCrown), findsWidgets);
      final avatarBoxes = tester.widgetList<SketchPlaceholderBox>(
        find.byType(SketchPlaceholderBox),
      );
      expect(
        avatarBoxes.any(
          (b) => b.fillColor == AppColors.highlighterCyan.withAlpha(130),
        ),
        isTrue,
      );

      // RepaintBoundary üzerinden gerçek PNG yakalama geçerli PNG baytları üretmeli
      final boundaryFinder = find.descendant(
        of: find.byType(DailySocialShareDialog),
        matching: find.byType(RepaintBoundary),
      );
      expect(boundaryFinder, findsOneWidget);
      final boundaryWidget = tester.widget<RepaintBoundary>(boundaryFinder);
      final pngBytes = await tester.runAsync(
        () => ShareCardHelper.captureWidgetToPngBytes(
          boundaryWidget.key! as GlobalKey,
          pixelRatio: 1.5,
        ),
      );
      expect(pngBytes, isNotNull);
      expect(pngBytes!.length, greaterThan(100));
      expect(pngBytes.sublist(0, 4), equals([137, 80, 78, 71]));
    });

    testWidgets('ShareCardHelper.captureWidgetToFile geçersiz/boş key için güvenle null döner',
        (tester) async {
      final unattachedKey = GlobalKey();
      final result = await ShareCardHelper.captureWidgetToFile(unattachedKey);
      expect(result, isNull);
    });
  });

  group('HeadToHeadShareDialog Tests', () {
    testWidgets('HeadToHeadShareDialog el çizimi kartpostalını ve meydan okuma butonlarını render eder',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      HeadToHeadShareDialog.show(
                        context,
                        gameType: GameType.queens,
                        gameTitle: 'Vezirler',
                        score: 950,
                        durationMs: 45000,
                        moveCount: 8,
                        fallbackIQ: 125,
                      );
                    },
                    child: const Text('Meydan Oku Kartı'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Meydan Oku Kartı'));
      await tester.pumpAndSettle();

      expect(find.text('GÜNLÜK KAFA KAFAYA KART'), findsOneWidget);
      expect(find.text('@ZekaTestcisi'), findsOneWidget);
      expect(find.text('Vezirler'), findsOneWidget);
      expect(find.text('Meydan Oku'), findsOneWidget);
      expect(find.text('Kopyala'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
    });
  });

  group('SettingsScreen Onboarding Link Test', () {
    testWidgets('SettingsScreen Tanıtım Turunu Tekrar İzle seçeneğini gösterir',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tanıtım Turunu Tekrar İzle'), findsOneWidget);
    });
  });
}
