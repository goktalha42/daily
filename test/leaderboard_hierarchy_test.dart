import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/features/leaderboard/leaderboard_screen.dart';

void main() {
  testWidgets('LeaderboardScreen hiyerarşik filtreleri (Dönem, Oyun, Seviye) doğru render eder',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LeaderboardScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Düzey: Dönem Seçici (Zaman aralıkları ikonlu etiketlerle görünmeli)
    expect(find.text('☀️ Bugün'), findsOneWidget);
    expect(find.text('📅 Haftalık'), findsOneWidget);
    expect(find.text('🌙 Aylık'), findsOneWidget);
    expect(find.text('🏆 Genel'), findsOneWidget);

    // 2. Düzey: Oyun Seçici
    expect(find.text('Vezirler'), findsOneWidget);

    // 3. Düzey: Vezirler alt seviye göstergesi ve seviye hapları
    expect(find.text('Seviye:'), findsOneWidget);
    expect(find.text('Toplam'), findsOneWidget);
    expect(find.text('Kolay'), findsOneWidget);
    expect(find.text('Zor'), findsOneWidget);
    expect(find.text('Master'), findsOneWidget);

    // Kelime İzleri oyununa tıklandığında alt seviye paneli gizlenmeli
    await tester.tap(find.text('Kelime İzleri'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Seviye:'), findsNothing);
    expect(find.text('Master'), findsNothing);

    // Tekrar Vezirler seçildiğinde alt seviye paneli tekrar görünmeli
    await tester.tap(find.text('Vezirler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Seviye:'), findsOneWidget);
    expect(find.text('Master'), findsOneWidget);
  });
}
