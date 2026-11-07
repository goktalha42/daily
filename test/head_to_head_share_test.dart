import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_games/core/widgets/head_to_head_share_dialog.dart';
import 'package:daily_games/games/common/base_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'zuhtu_user_nickname': 'TestDahi',
    });
  });

  group('Kafa Kafaya Karşılaştırma & Paylaşım Kartı Testleri', () {
    test('Percentile ve BetterThan oranı matematiksel olarak tutarlıdır', () {
      // 1. dilim (%1): oyuncuların %99'undan daha hızlı
      const percentile1 = 1;
      final better1 = (100 - percentile1).clamp(1, 99);
      expect(better1, 99);

      // 6. dilim (%6): oyuncuların %94'ünden daha hızlı
      const percentile6 = 6;
      final better6 = (100 - percentile6).clamp(1, 99);
      expect(better6, 94);

      // 50. dilim (%50): oyuncuların %50'sinden daha hızlı
      const percentile50 = 50;
      final better50 = (100 - percentile50).clamp(1, 99);
      expect(better50, 50);
    });

    testWidgets('HeadToHeadShareDialog ekranda eksiksiz render edilir', (tester) async {
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
                        gameTitle: 'Vezirler 👑',
                        score: 1850,
                        durationMs: 45000,
                        moveCount: 8,
                        fallbackIQ: 132,
                      );
                    },
                    child: const Text('Aç'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Aç butonuna bas
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      // Kart başlığı ve bileşenleri bulunmalı
      expect(find.text('GÜNLÜK KAFA KAFAYA KART'), findsOneWidget);
      expect(find.text('Vezirler 👑'), findsOneWidget);
      expect(find.textContaining('BUGÜN ZÜHTÜ\'DEKİ OYUNCULARIN'), findsOneWidget);
      expect(find.textContaining('DAHA HIZLI!'), findsOneWidget);
      expect(find.text('Meydan Oku'), findsOneWidget);
      expect(find.text('Kopyala'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
    });
  });
}

