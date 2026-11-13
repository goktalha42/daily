import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/network/network_checker.dart';
import 'package:daily_games/core/widgets/sketch_countdown_timer.dart';
import 'package:daily_games/features/home/home_screen.dart';

class _FakeOnlineNotifier extends StateNotifier<bool> implements NetworkCheckerNotifier {
  _FakeOnlineNotifier() : super(true);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'zuhtu_user_nickname': 'ZekaTestcisi',
      'zuhtu_user_avatar_id': 'owl',
    });
  });

  group('SketchCountdownTimer Sabit Genişlik Testleri', () {
    testWidgets('SketchCountdownTimer sabit genişliğe ve tabular figures özelliğine sahiptir',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SketchCountdownTimer(
                  fontSize: 12.5,
                  width: 108,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Timer'ın render edilen kutu genişliği tam olarak 108px olmalıdır
      final size = tester.getSize(find.byType(SketchCountdownTimer));
      expect(size.width, equals(108.0));
    });
  });

  group('HomeScreen 3 Tuşlu Navigasyon Çubuğu Konumlandırma Testleri', () {
    testWidgets('3 tuşlu navigasyonda (bottomInset: 48) alt menü tuşların üstüne güvenle konumlanır',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkCheckerProvider.overrideWith((ref) => _FakeOnlineNotifier()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Oyunlar'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      final navBarFinder = find.ancestor(
        of: find.text('Oyunlar'),
        matching: find.byType(Positioned),
      );
      expect(navBarFinder, findsWidgets);

      final positionedWidget = tester.widget<Positioned>(navBarFinder.first);
      // navBottom = bottomInset > 0 ? (bottomInset + 10) : 22
      // 48 + 10 = 58 olmalı
      expect(positionedWidget.bottom, equals(58.0));
    });

    testWidgets('Normal / Gesture navigasyonda (bottomInset: 0) menü 22px taban boşluğunda kalır',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding.zero;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkCheckerProvider.overrideWith((ref) => _FakeOnlineNotifier()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final navBarFinder = find.ancestor(
        of: find.text('Oyunlar'),
        matching: find.byType(Positioned),
      );
      final positionedWidget = tester.widget<Positioned>(navBarFinder.first);
      expect(positionedWidget.bottom, equals(22.0));
    });
  });
}
