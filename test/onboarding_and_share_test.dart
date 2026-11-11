import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/services/daily_play_service.dart';
import 'package:daily_games/core/widgets/daily_social_share_dialog.dart';
import 'package:daily_games/features/onboarding/onboarding_screen.dart';
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
    testWidgets('OnboardingScreen 1. slaytı doğru başlık ve oyunlarla render eder',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZÜHTÜ REHBERİ'), findsOneWidget);
      expect(find.text('Atla'), findsOneWidget);
      expect(find.textContaining("Her Gece 00:00'da"), findsOneWidget);
      expect(find.text('Vezirler'), findsOneWidget);
      expect(find.text('Nokta Atışı'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
    });

    testWidgets('OnboardingScreen slaytlar arası geçiş yapar ve son slaytta Başla butonu gösterir',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. slayttan 2. slayta geç
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bilimsel WAIS-IV'), findsOneWidget);

      // 2. slayttan 3. slayta geç
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Haftalık Canlı Ligler'), findsOneWidget);
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
      expect(find.text('ZÜHTÜ GÜNLÜK ZEKA'), findsOneWidget);
      expect(find.text('@ZekaTestcisi'), findsOneWidget);
      expect(find.text('🦉'), findsOneWidget);
      expect(find.text('135'), findsOneWidget);
      expect(find.text('Görsel Paylaş'), findsOneWidget);
      expect(find.text('Metin'), findsOneWidget);
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
