import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/features/league/league_screen.dart';
import 'package:daily_games/core/services/league_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LeagueScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LeagueScreen(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LeagueScreen), findsOneWidget);
    expect(find.text('Lig Tablosu'), findsOneWidget);
  });

  testWidgets('LeagueProfileCard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LeagueProfileCard(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LeagueProfileCard), findsOneWidget);
  });

  test('LeagueLevel enum has 10 tiers with proper emoji and names', () {
    expect(LeagueLevel.values.length, 10);
    expect(LeagueLevel.iron.displayName, 'Demir');
    expect(LeagueLevel.champion.displayName, 'Şampiyonluk');
    expect(LeagueLevel.iron.isMin, true);
    expect(LeagueLevel.champion.isMax, true);
    expect(LeagueLevel.iron.next, LeagueLevel.bronze);
    expect(LeagueLevel.champion.previous, LeagueLevel.grandmaster);
  });
}
