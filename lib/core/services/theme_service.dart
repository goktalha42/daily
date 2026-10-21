import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema Modu Yönetici Servisi
/// - Sistem teması, Açık tema ve Koyu tema seçeneklerini destekler.
/// - Seçimi SharedPreferences'ta kalıcı olarak saklar.
final themeServiceProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _prefKey = 'zuhtu_theme_mode';
  static ThemeMode currentMode = ThemeMode.dark;

  static bool get isDarkActive {
    if (currentMode == ThemeMode.dark) return true;
    if (currentMode == ThemeMode.light) return false;
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  ThemeNotifier() : super(ThemeMode.dark) {
    currentMode = ThemeMode.dark;
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        currentMode = ThemeMode.light;
        state = ThemeMode.light;
      } else if (savedMode == 'system') {
        currentMode = ThemeMode.system;
        state = ThemeMode.system;
      } else {
        currentMode = ThemeMode.dark;
        state = ThemeMode.dark;
      }
    } catch (_) {
      currentMode = ThemeMode.dark;
      state = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    currentMode = mode;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.dark) {
        await prefs.setString(_prefKey, 'dark');
      } else if (mode == ThemeMode.light) {
        await prefs.setString(_prefKey, 'light');
      } else {
        await prefs.setString(_prefKey, 'system');
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (currentBrightness == Brightness.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
