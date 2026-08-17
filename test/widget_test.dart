import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_games/main.dart';

void main() {
  testWidgets('App renders home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DailyGamesApp(),
      ),
    );

    // Initial pump without letting timer fail test
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bento Lobi'), findsWidgets);
    expect(find.text('Vezirler'), findsWidgets);
  });
}
