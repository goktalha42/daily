import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/features/league/league_screen.dart';

void main() {
  testWidgets('LeagueScreen üst şeridi kaldırır ve ? butonuna basınca Lig Basamakları diyaloğunu açar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LeagueScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Üst şeritteki eski yatay basamaklar artık ana ekranda doğrudan görünmemeli
    expect(find.text('BURADASIN'), findsNothing);
    expect(find.text('KİLİTLİ'), findsNothing);

    // Ana lig kartı içindeki ? butonu görünmeli
    final helpButton = find.text('?');
    expect(helpButton, findsOneWidget);

    // ? butonuna tıklandığında Lig Basamakları & Kurallar diyaloğu açılmalı
    await tester.tap(helpButton);
    await tester.pumpAndSettle();

    expect(find.text('Lig Basamakları & Kurallar'), findsOneWidget);
    expect(find.text('1. Demir'), findsOneWidget);
    expect(find.text('10. Şampiyonluk'), findsOneWidget);
    expect(find.text('BURADASIN'), findsOneWidget);
    expect(find.text('Haftalık Lig Kuralları (Pazar 23:59 Kapanış)'), findsOneWidget);

    // Anladım butonuna basınca diyalog kapanmalı
    await tester.tap(find.text('Anladım'));
    await tester.pumpAndSettle();
    expect(find.text('Lig Basamakları & Kurallar'), findsNothing);
  });
}

