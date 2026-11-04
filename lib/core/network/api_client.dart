import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/time_sync_service.dart';
import '../../games/common/base_game.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final timeSync = ref.watch(timeSyncServiceProvider);
  return ApiClient(timeSync: timeSync);
});

class ApiClient {
  final TimeSyncService timeSync;
  final http.Client _client = http.Client();

  // Canlı VPS Sunucu Adresi (Ubuntu 24.04 - Nginx Port 80)
  static const String _defaultLiveUrl = 'http://2.56.109.165/api/v1';

  static const String _serverUrlKey = 'zuhtu_custom_server_url';
  static const String _deviceIdKey = 'zuhtu_device_uuid';
  static const String _authTokenKey = 'zuhtu_auth_token';
  static const String _nicknameKey = 'zuhtu_user_nickname';

  String? _cachedBaseUrl;
  String? _deviceId;
  String? _authToken;
  String? _cachedNickname;
  bool _isOnlineServerReachable = false;

  bool get isServerOnline => _isOnlineServerReachable;

  ApiClient({required this.timeSync});

  /// Kayıtlı takma adı döner
  Future<String?> getNickname() async {
    if (_cachedNickname != null) return _cachedNickname;
    final prefs = await SharedPreferences.getInstance();
    _cachedNickname = prefs.getString(_nicknameKey);
    return _cachedNickname;
  }

  /// Takma adın daha önce seçilip seçilmediğini kontrol eder
  Future<bool> hasNickname() async {
    final nick = await getNickname();
    return nick != null && nick.trim().isNotEmpty;
  }

  /// İsim kullanılabilirlik kontrolü (Büyük/küçük harf duyarsız kontrol)
  Future<Map<String, dynamic>> checkNicknameAvailability(String nickname) async {
    try {
      final baseUrl = await getBaseUrl();
      final deviceId = await getDeviceId();
      final uri = Uri.parse('$baseUrl/auth/check-nickname').replace(
        queryParameters: {
          'nickname': nickname.trim(),
          'device_id': deviceId,
        },
      );

      final res = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          'available': data['available'] == true,
          'message': data['message'] ?? '',
        };
      } else {
        return {
          'available': false,
          'message': data['message'] ?? 'Bu isim kullanılamaz.',
        };
      }
    } catch (e) {
      debugPrint('[ApiClient] checkNickname hatası: $e');
      return {
        'available': false,
        'message': 'Sunucuyla bağlantı kurulamadı. İnternet bağlantını kontrol et.',
      };
    }
  }

  /// Sunucuya zorunlu ve benzersiz takma adı kaydeder
  Future<Map<String, dynamic>> registerNickname(String nickname) async {
    try {
      final baseUrl = await getBaseUrl();
      final deviceId = await getDeviceId();
      final url = Uri.parse('$baseUrl/auth/set-nickname');

      final res = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'nickname': nickname.trim(),
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        final token = data['token'] as String?;
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          _authToken = token;
          await prefs.setString(_authTokenKey, token);
        }
        _cachedNickname = nickname.trim();
        await prefs.setString(_nicknameKey, _cachedNickname!);

        return {
          'success': true,
          'message': data['message'] ?? 'Kullanıcı adı başarıyla kaydedildi.',
        };
      } else {
        final message = data['message'] ?? 'Bu isim alınamadı.';
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('[ApiClient] registerNickname hatası: $e');
      return {
        'success': false,
        'message': 'Sunucuya ulaşılamadı. Lütfen internet bağlantını kontrol et.',
      };
    }
  }

  /// Akıllı varsayılan sunucu URL'i belirler
  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_serverUrlKey);
    if (customUrl != null && customUrl.isNotEmpty) {
      _cachedBaseUrl = customUrl;
      return _cachedBaseUrl!;
    }

    // Canlı VPS Sunucusu devrede: Tüm istemciler (Android, iOS, Windows, Web)
    // varsayılan olarak canlı sunucuya bağlanır.
    _cachedBaseUrl = _defaultLiveUrl;
    return _cachedBaseUrl!;
  }

  /// Sunucu URL'ini özel olarak ayarlar (VPS veya başka IP için)
  Future<void> setCustomServerUrl(String url) async {
    _cachedBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, _cachedBaseUrl!);
  }

  /// Cihaz UUID'sini alır veya ilk açılışta üretip saklar
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _deviceId = id;
    return _deviceId!;
  }

  /// Sunucuyla bağlantıyı test eder ve saat senkronizasyonu yapar
  Future<bool> checkConnectionAndTimeSync() async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/time');
      final res = await _client.get(url).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['timestamp'] != null) {
          final serverEpoch = data['timestamp'] as int;
          timeSync.syncWithServerTime(serverEpoch);
        }
        _isOnlineServerReachable = true;
        return true;
      }
    } catch (e) {
      debugPrint('[ApiClient] Sunucuya ulaşılamadı (Local fallback devrede): $e');
    }

    _isOnlineServerReachable = false;
    return false;
  }

  /// Cihaz oturumu açar veya mevcut tokenı döner
  Future<String?> ensureAuthenticated({String? nickname}) async {
    final prefs = await SharedPreferences.getInstance();
    _authToken ??= prefs.getString(_authTokenKey);
    if (_authToken != null) return _authToken;

    try {
      final baseUrl = await getBaseUrl();
      final deviceId = await getDeviceId();
      final nick = nickname ?? await getNickname();
      final url = Uri.parse('$baseUrl/auth/guest');

      final res = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'nickname': ?nick,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String?;
        if (token != null) {
          _authToken = token;
          await prefs.setString(_authTokenKey, token);
          return token;
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] Oturum açma hatası: $e');
    }
    return null;
  }

  String _mapGameType(GameType type) {
    if (type == GameType.zipPath) return 'zip_path';
    return type.id;
  }

  /// Oyuncu oyun bitirdiğinde skoru sunucuya asenkron iletir
  Future<bool> submitGameScore({
    required GameType gameType,
    required String dateId,
    required int score,
    required int durationMs,
    int moveCount = 0,
    String? difficulty,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final deviceId = await getDeviceId();
      final token = await ensureAuthenticated();

      final url = Uri.parse('$baseUrl/games/submit');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-Id': deviceId,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final payload = {
        'game_type': _mapGameType(gameType),
        'date_id': dateId,
        'difficulty': difficulty ?? 'default',
        'score': score,
        'duration_ms': durationMs,
        'move_count': moveCount,
        'device_id': deviceId,
      };

      final res = await _client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Skor gönderme hatası: $e');
      return false;
    }
  }

  /// Sunucudan canlı liderlik tablosunu çeker
  Future<List<LeaderboardEntry>?> fetchLeaderboard({
    required GameType gameType,
    required LeaderboardTimeframe timeframe,
    String? difficulty,
    String? dateId,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final deviceId = await getDeviceId();

      String tfParam;
      switch (timeframe) {
        case LeaderboardTimeframe.daily:
          tfParam = 'daily';
          break;
        case LeaderboardTimeframe.weekly:
          tfParam = 'weekly';
          break;
        case LeaderboardTimeframe.monthly:
          tfParam = 'monthly';
          break;
        case LeaderboardTimeframe.allTime:
          tfParam = 'all_time';
          break;
      }

      final queryParams = {
        'game_type': _mapGameType(gameType),
        'timeframe': tfParam,
        'difficulty': ?difficulty,
        'date_id': ?dateId,
      };

      final uri = Uri.parse('$baseUrl/leaderboard').replace(queryParameters: queryParams);
      final res = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-Id': deviceId,
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['leaderboard'] as List<dynamic>?;
        if (list != null) {
          return list.map((item) {
            return LeaderboardEntry(
              rank: item['rank'] as int,
              userId: 'server_player_${item['player_id']}',
              userName: item['player_name'] as String,
              totalScore: item['total_score'] as int,
              bestTimeMs: item['best_time_ms'] as int,
              gamesPlayed: item['games_played'] as int? ?? 1,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] Liderlik tablosu çekme hatası (Local fallback): $e');
    }
    return null;
  }
}
