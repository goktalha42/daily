import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_games/core/network/network_checker.dart';
import 'package:daily_games/core/widgets/online_guard_widget.dart';

class _FixedNetworkNotifier extends NetworkCheckerNotifier {
  _FixedNetworkNotifier(bool initial) : super(initialState: initial);

  @override
  Future<bool> checkNow() async => state;
}

void main() {
  testWidgets('İnternet yokken OnlineGuardWidget el çizimi uyarı ekranını gösterir ve içeriği gizler',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkCheckerProvider.overrideWith((ref) => _FixedNetworkNotifier(false)),
        ],
        child: const MaterialApp(
          home: OnlineGuardWidget(
            child: Scaffold(body: Text('ANA_ICERIK')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NoInternetSketchScreen), findsOneWidget);
    expect(find.text('İnternetsiz Giriş Yapılamaz!'), findsOneWidget);
    expect(find.text('ÇEVRİMDIŞI GİRİŞ KAPALI'), findsOneWidget);
    expect(find.text('Bağlantıyı Kontrol Et'), findsOneWidget);
    expect(find.text('ANA_ICERIK'), findsNothing);
  });

  testWidgets('İnternet varken OnlineGuardWidget normal uygulama içeriğini gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkCheckerProvider.overrideWith((ref) => _FixedNetworkNotifier(true)),
        ],
        child: const MaterialApp(
          home: OnlineGuardWidget(
            child: Scaffold(body: Text('ANA_ICERIK')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NoInternetSketchScreen), findsNothing);
    expect(find.text('ANA_ICERIK'), findsOneWidget);
  });
}
