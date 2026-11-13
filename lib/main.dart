import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/network_checker.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/screen_shake.dart';
import 'core/widgets/online_guard_widget.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final initialOnline = await NetworkCheckerNotifier.checkInitialConnectivity();
  runApp(
    ProviderScope(
      overrides: [
        networkCheckerProvider.overrideWith(
          (ref) => NetworkCheckerNotifier(initialState: initialOnline),
        ),
      ],
      child: const DailyGamesApp(),
    ),
  );
}

class DailyGamesApp extends ConsumerWidget {
  const DailyGamesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeServiceProvider);

    return MaterialApp(
      title: 'Zühtü',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return OnlineGuardWidget(
          child: ScreenShake(
            child: GeniusConfettiOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const HomeScreen(),
    );
  }
}
