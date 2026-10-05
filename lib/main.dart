import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/screen_shake.dart';
import 'core/widgets/online_guard_widget.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DailyGamesApp(),
    ),
  );
}

class DailyGamesApp extends StatelessWidget {
  const DailyGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zühtü',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Kullanıcının istediği açık gri zemin varsayılan
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
