import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../games/common/base_game.dart';

/// Tüm zeka oyunları için oturum ve sayaç takip servisi.
/// Oyun oynanırken süre ve hamleler anlık olarak saklanır.
/// Kullanıcı menüye çıksa, ekranı kapatsa veya uygulama kapansa bile
/// sayaç ve oyun durumu sıfırlanmaz, kaldığı yerden devam eder.
class GameSessionService {
  static const String _prefix = 'zuhtu_session_';

  static String _makeKey(GameType game, String levelId, [String? subKey]) {
    if (subKey != null && subKey.isNotEmpty) {
      return '$_prefix${game.id}_${levelId}_$subKey';
    }
    return '$_prefix${game.id}_$levelId';
  }

  /// Aktif oyun oturumunu kaydeder.
  static Future<void> saveSession({
    required GameType game,
    required String levelId,
    String? subKey,
    required int elapsedMs,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(game, levelId, subKey);
      final payload = {
        'elapsedMs': elapsedMs,
        'savedAt': DateTime.now().toIso8601String(),
        'data': data,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  /// Yalnızca süreyi hızlıca günceller.
  static Future<void> updateElapsedMs({
    required GameType game,
    required String levelId,
    String? subKey,
    required int elapsedMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(game, levelId, subKey);
      final raw = prefs.getString(key);
      Map<String, dynamic> payload = {};
      if (raw != null) {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      }
      payload['elapsedMs'] = elapsedMs;
      payload['savedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  /// Kayıtlı oturumu yükler (varsa döner, yoksa null).
  static Future<Map<String, dynamic>?> loadSession({
    required GameType game,
    required String levelId,
    String? subKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(game, levelId, subKey);
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Oyun bittiğinde veya kullanıcı 'Sıfırla' dediğinde oturumu siler.
  static Future<void> clearSession({
    required GameType game,
    required String levelId,
    String? subKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(game, levelId, subKey);
      await prefs.remove(key);
    } catch (_) {}
  }
}

final gameSessionServiceProvider = Provider<GameSessionService>((ref) {
  return GameSessionService();
});
