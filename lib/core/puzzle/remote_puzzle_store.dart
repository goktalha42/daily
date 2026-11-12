import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../games/crossclimb/crossclimb_models.dart';
import '../../games/patches/patches_models.dart';
import '../../games/pinpoint/pinpoint_models.dart';
import '../../games/queens/queens_models.dart';
import '../../games/tango/tango_models.dart';
import '../../games/zip_path/zip_models.dart';
import '../network/api_client.dart';
import 'puzzle_serializer.dart';

class DaySpecialMeta {
  final bool isSpecial;
  final String? specialNote;

  const DaySpecialMeta({required this.isSpecial, this.specialNote});
}

/// Sunucudan (365 günlük takvim & Admin paneli) indirilen günlük bulmacaları
/// bellekte ve SharedPreferences'da tutar.
/// Senkron getter'ları sayesinde tüm oyun ekranları ve `*LevelRepository`'ler
/// anında sunucu bulmacasını alır; ağ yoksa lokal deterministik jeneratöre düşer.
class RemotePuzzleStore {
  RemotePuzzleStore._();

  static const String _prefPrefix = 'zuhtu_remote_day_v1_';
  static const String _prefIndexKey = 'zuhtu_remote_day_index_v1';
  static const int _maxStoredDays = 21;

  static final Map<String, Map<String, dynamic>> _rawByDate = {};
  static final Map<String, Future<bool>> _inFlightSyncs = {};
  static final Set<String> _syncedThisSession = {};

  // Ayrıştırılmış model önbellekleri
  static final Map<String, QueensLevel> _queensCache = {};
  static final Map<String, PinpointLevel> _pinpointCache = {};
  static final Map<String, CrossclimbLevel> _crossclimbCache = {};
  static final Map<String, TangoLevel> _tangoCache = {};
  static final Map<String, ZipLevel> _zipCache = {};
  static final Map<String, PatchesLevel> _patchesCache = {};

  static void _invalidateParsedForDate(String dateId) {
    _queensCache.removeWhere((k, _) => k.startsWith('$dateId|'));
    _pinpointCache.remove(dateId);
    _crossclimbCache.remove(dateId);
    _tangoCache.remove(dateId);
    _zipCache.remove(dateId);
    _patchesCache.remove(dateId);
  }

  /// Testler veya manuel sıfırlama için bellek içi durumu temizler.
  @visibleForTesting
  static void clearMemory() {
    _rawByDate.clear();
    _inFlightSyncs.clear();
    _syncedThisSession.clear();
    _queensCache.clear();
    _pinpointCache.clear();
    _crossclimbCache.clear();
    _tangoCache.clear();
    _zipCache.clear();
    _patchesCache.clear();
  }

  /// Doğrudan bir günün ham JSON yükünü belleğe enjekte eder (test veya ön yükleme için).
  static void ingestDayPayload(String dateId, Map<String, dynamic> data) {
    _rawByDate[dateId] = Map<String, dynamic>.from(data);
    _invalidateParsedForDate(dateId);
  }

  static Future<void> _loadFromPrefsIfNeeded(String dateId) async {
    if (_rawByDate.containsKey(dateId)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefPrefix$dateId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _rawByDate[dateId] = decoded;
          _invalidateParsedForDate(dateId);
        }
      }
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Prefs okuma hatası ($dateId): $e');
    }
  }

  static Future<void> _persistToPrefs(String dateId, String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$dateId', rawJson);

      final index = List<String>.from(prefs.getStringList(_prefIndexKey) ?? const []);
      index.remove(dateId);
      index.add(dateId);
      while (index.length > _maxStoredDays) {
        final oldest = index.removeAt(0);
        await prefs.remove('$_prefPrefix$oldest');
      }
      await prefs.setStringList(_prefIndexKey, index);
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Prefs yazma hatası ($dateId): $e');
    }
  }

  /// Verilen [dateId] için sunucudan günlük tüm bulmacaları indirir.
  static Future<bool> syncDay(
    ApiClient apiClient,
    String dateId, {
    bool forceRefresh = false,
    http.Client? httpClient,
  }) async {
    await _loadFromPrefsIfNeeded(dateId);

    if (!forceRefresh && _syncedThisSession.contains(dateId) && _rawByDate.containsKey(dateId)) {
      return true;
    }

    if (!forceRefresh && _inFlightSyncs.containsKey(dateId)) {
      return _inFlightSyncs[dateId]!;
    }

    final future = _performSync(
      apiClient,
      dateId,
      httpClient: httpClient,
    );
    _inFlightSyncs[dateId] = future;
    try {
      return await future;
    } finally {
      _inFlightSyncs.remove(dateId);
    }
  }

  static Future<bool> _performSync(
    ApiClient apiClient,
    String dateId, {
    http.Client? httpClient,
  }) async {
    final ownsClient = httpClient == null;
    final client = httpClient ?? http.Client();
    try {
      final baseUrl = await apiClient.getBaseUrl();
      final uri = Uri.parse('$baseUrl/puzzles/daily').replace(
        queryParameters: {'date': dateId},
      );
      final res = await client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final bodyStr = utf8.decode(res.bodyBytes);
        final decoded = jsonDecode(bodyStr);
        if (decoded is Map<String, dynamic> && decoded['games'] is Map<String, dynamic>) {
          _rawByDate[dateId] = decoded;
          _syncedThisSession.add(dateId);
          _invalidateParsedForDate(dateId);
          await _persistToPrefs(dateId, bodyStr);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Sunucu bulmaca çekme hatası ($dateId): $e');
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
    return false;
  }

  static DaySpecialMeta? getSpecialMeta(String dateId) {
    final day = _rawByDate[dateId];
    if (day == null) return null;
    return DaySpecialMeta(
      isSpecial: day['is_special'] == true,
      specialNote: day['special_note']?.toString(),
    );
  }

  static Map<String, dynamic>? _gamePayload(String dateId, String gameKey, {String? subKey}) {
    final day = _rawByDate[dateId];
    if (day == null) return null;
    final games = day['games'];
    if (games is! Map<String, dynamic>) return null;
    final entry = games[gameKey];
    if (entry is! Map<String, dynamic>) return null;
    if (subKey != null) {
      final sub = entry[subKey];
      return sub is Map<String, dynamic> ? sub : null;
    }
    return entry;
  }

  static QueensLevel? getQueens(String dateId, QueensDifficulty difficulty) {
    final cacheKey = '$dateId|${difficulty.name}';
    if (_queensCache.containsKey(cacheKey)) return _queensCache[cacheKey];

    final payload = _gamePayload(dateId, 'queens', subKey: difficulty.name);
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.queensFromJson(payload, fallbackId: dateId);
      _queensCache[cacheKey] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Queens ayrıştırma hatası ($cacheKey): $e');
      return null;
    }
  }

  static PinpointLevel? getPinpoint(String dateId) {
    if (_pinpointCache.containsKey(dateId)) return _pinpointCache[dateId];
    final payload = _gamePayload(dateId, 'pinpoint');
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.pinpointFromJson(payload, fallbackId: dateId);
      _pinpointCache[dateId] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Pinpoint ayrıştırma hatası ($dateId): $e');
      return null;
    }
  }

  static CrossclimbLevel? getCrossclimb(String dateId) {
    if (_crossclimbCache.containsKey(dateId)) return _crossclimbCache[dateId];
    final payload = _gamePayload(dateId, 'crossclimb');
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.crossclimbFromJson(payload, fallbackId: dateId);
      _crossclimbCache[dateId] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Crossclimb ayrıştırma hatası ($dateId): $e');
      return null;
    }
  }

  static TangoLevel? getTango(String dateId) {
    if (_tangoCache.containsKey(dateId)) return _tangoCache[dateId];
    final payload = _gamePayload(dateId, 'tango');
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.tangoFromJson(payload, fallbackId: dateId);
      _tangoCache[dateId] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Tango ayrıştırma hatası ($dateId): $e');
      return null;
    }
  }

  static ZipLevel? getZip(String dateId) {
    if (_zipCache.containsKey(dateId)) return _zipCache[dateId];
    final payload = _gamePayload(dateId, 'zip_path');
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.zipFromJson(payload, fallbackId: dateId);
      _zipCache[dateId] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Zip ayrıştırma hatası ($dateId): $e');
      return null;
    }
  }

  static PatchesLevel? getPatches(String dateId) {
    if (_patchesCache.containsKey(dateId)) return _patchesCache[dateId];
    final payload = _gamePayload(dateId, 'patches');
    if (payload == null) return null;
    try {
      final parsed = PuzzleSerializer.patchesFromJson(payload, fallbackId: dateId);
      _patchesCache[dateId] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[RemotePuzzleStore] Patches ayrıştırma hatası ($dateId): $e');
      return null;
    }
  }
}

