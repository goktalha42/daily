import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'badge_service.dart';
import 'daily_play_service.dart';
import 'game_stats_service.dart';
import 'league_service.dart';
import 'user_nickname_provider.dart';

class CloudBackupState {
  final String recoveryCode;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final String? lastMessage;

  const CloudBackupState({
    this.recoveryCode = 'ZHT-....-....',
    this.lastSyncedAt,
    this.isSyncing = false,
    this.lastMessage,
  });

  CloudBackupState copyWith({
    String? recoveryCode,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    String? lastMessage,
  }) {
    return CloudBackupState(
      recoveryCode: recoveryCode ?? this.recoveryCode,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      lastMessage: lastMessage,
    );
  }
}

/// İlerleme, Günlük Seri, WAIS-IV IQ Karnesi ve Rozetleri Buluta Yedekleme / Cihaz Taşıma Servisi.
class CloudBackupNotifier extends StateNotifier<CloudBackupState> {
  static const _lastSyncedPrefKey = 'zuhtu_backup_last_synced_v1';
  static const _backupSignatureSalt = 'zuhtu_sketch_backup_2026_v1';

  final Ref ref;

  CloudBackupNotifier(this.ref) : super(const CloudBackupState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final prefs = await SharedPreferences.getInstance();
      final savedSyncStr = prefs.getString(_lastSyncedPrefKey);
      final savedSync =
          savedSyncStr != null ? DateTime.tryParse(savedSyncStr) : null;

      String? code = await apiClient.getRecoveryCode();
      if (code == null || code.isEmpty) {
        final deviceId = await apiClient.getDeviceId();
        code = deriveDeterministicCodeFromDeviceId(deviceId);
      }

      state = state.copyWith(
        recoveryCode: code,
        lastSyncedAt: savedSync,
      );
    } catch (_) {}
  }

  /// Cihaz UUID'sinden okunaklı ZHT-XXXX-XXXX formatında deterministik kod türetir.
  static String deriveDeterministicCodeFromDeviceId(String deviceId) {
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final digest = sha256.convert(utf8.encode('zuhtu_rec_$deviceId')).bytes;
    final p1 = StringBuffer();
    final p2 = StringBuffer();
    for (int i = 0; i < 4; i++) {
      p1.write(alphabet[digest[i] % alphabet.length]);
      p2.write(alphabet[digest[i + 4] % alphabet.length]);
    }
    return 'ZHT-${p1.toString()}-${p2.toString()}';
  }

  /// Tüm yerel ilerleme verilerini tek bir JSON paketinde toplar.
  Map<String, dynamic> buildProgressPayload() {
    final dailyNotifier = ref.read(dailyPlayServiceProvider.notifier);
    final statsNotifier = ref.read(gameStatsServiceProvider.notifier);
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);
    final leagueNotifier = ref.read(leagueServiceProvider.notifier);
    final nickname = ref.read(userNicknameProvider);

    return {
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'nickname': nickname,
      'daily_play': dailyNotifier.exportBackupMap(),
      'game_stats': statsNotifier.exportBackupMap(),
      'badges': badgeNotifier.exportBackupMap(),
      'league': leagueNotifier.exportBackupMap(),
    };
  }

  /// İmzalı, çevrimdışı da taşınabilen tam yedek anahtarı (`ZBK1.<base64>.<imza>`) üretir.
  String exportPortableBackupKey() {
    final payload = buildProgressPayload();
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final b64 = base64UrlEncode(jsonBytes);
    final sig = sha256
        .convert(utf8.encode('$b64:$_backupSignatureSalt'))
        .toString()
        .substring(0, 10)
        .toUpperCase();
    return 'ZBK1.$b64.$sig';
  }

  /// Taşınabilir yedek anahtarını doğrular ve içindeki JSON paketini çözer.
  static Map<String, dynamic>? decodePortableBackupKey(String rawKey) {
    final trimmed = rawKey.trim();
    if (!trimmed.startsWith('ZBK1.')) return null;
    final parts = trimmed.split('.');
    if (parts.length != 3) return null;

    final b64 = parts[1];
    final sig = parts[2].toUpperCase();
    final expectedSig = sha256
        .convert(utf8.encode('$b64:$_backupSignatureSalt'))
        .toString()
        .substring(0, 10)
        .toUpperCase();

    if (sig != expectedSig) return null;

    try {
      final decodedStr = utf8.decode(base64Url.decode(b64));
      final map = jsonDecode(decodedStr);
      if (map is Map<String, dynamic>) {
        return map;
      }
    } catch (_) {}
    return null;
  }

  /// Mevcut ilerlemeyi canlı sunucuya yedekler.
  Future<({bool success, String message})> syncNow() async {
    if (state.isSyncing) {
      return (success: false, message: 'Yedekleme işlemi devam ediyor...');
    }

    state = state.copyWith(isSyncing: true);
    try {
      final payload = buildProgressPayload();
      final leagueLevelName =
          ref.read(leagueServiceProvider).currentLevel.name;
      final apiClient = ref.read(apiClientProvider);

      final result = await apiClient.syncProgressToServer(
        progressPayload: payload,
        leagueTier: leagueLevelName,
      );

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncedPrefKey, now.toIso8601String());

      final serverCode = result['recovery_code'] as String?;
      final resolvedCode = (serverCode != null && serverCode.isNotEmpty)
          ? serverCode
          : state.recoveryCode;

      state = state.copyWith(
        recoveryCode: resolvedCode,
        lastSyncedAt: now,
        isSyncing: false,
        lastMessage: result['message'] as String?,
      );

      if (result['success'] == true) {
        return (
          success: true,
          message:
              'Bulut yedeği güncellendi! Kurtarma Kodun: $resolvedCode',
        );
      } else {
        return (
          success: true,
          message:
              'Yerel yedek hazır ($resolvedCode). Sunucu çevrimdışı olduğunda Yedek Anahtarı ile cihaz taşıyabilirsin.',
        );
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      return (
        success: false,
        message: 'Yedekleme sırasında hata oluştu: $e',
      );
    }
  }

  /// Kullanıcının girdiği Kurtarma Kodu (`ZHT-XXXX-XXXX`) veya Taşınabilir Yedek Anahtarı (`ZBK1....`)
  /// üzerinden tüm seriyi, IQ karnesini ve rozetleri geri yükler.
  Future<({bool success, String message})> restoreFromInput(
    String rawInput,
  ) async {
    final cleaned = rawInput.trim();
    if (cleaned.isEmpty) {
      return (
        success: false,
        message: 'Lütfen geçerli bir Kurtarma Kodu veya Yedek Anahtarı girin.',
      );
    }

    state = state.copyWith(isSyncing: true);

    try {
      // 1. Çevrimdışı Taşınabilir Yedek Anahtarı (`ZBK1.`) kontrolü
      if (cleaned.startsWith('ZBK1.')) {
        final decoded = decodePortableBackupKey(cleaned);
        if (decoded == null) {
          state = state.copyWith(isSyncing: false);
          return (
            success: false,
            message: 'Yedek anahtarı geçersiz veya bozulmuş.',
          );
        }
        await applyProgressPayload(decoded);
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncedPrefKey, now.toIso8601String());
        state = state.copyWith(isSyncing: false, lastSyncedAt: now);
        return (
          success: true,
          message:
              'Yedek anahtarındaki tüm günlük seri, IQ karnesi ve rozetler başarıyla geri yüklendi!',
        );
      }

      // 2. Canlı Sunucu Kurtarma Kodu (`ZHT-XXXX-XXXX`) ile geri yükleme
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.restoreProgressFromServer(cleaned);

      if (res['success'] == true) {
        final payload = res['progress_payload'];
        if (payload is Map<String, dynamic>) {
          await applyProgressPayload(payload);
        }
        final restoredNick = res['nickname'] as String?;
        if (restoredNick != null && restoredNick.isNotEmpty) {
          await ref
              .read(userNicknameProvider.notifier)
              .setNickname(restoredNick);
        }
        final recCode = res['recovery_code'] as String? ?? cleaned.toUpperCase();
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncedPrefKey, now.toIso8601String());

        state = state.copyWith(
          recoveryCode: recCode,
          lastSyncedAt: now,
          isSyncing: false,
        );
        return (
          success: true,
          message:
              res['message'] as String? ??
              'Hesabınız ve tüm seriniz başarıyla geri yüklendi!',
        );
      }

      state = state.copyWith(isSyncing: false);
      return (
        success: false,
        message:
            res['message'] as String? ??
            'Bu kurtarma kodu ile eşleşen bir sunucu yedeği bulunamadı.',
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      return (
        success: false,
        message: 'Geri yükleme işlemi başarısız: $e',
      );
    }
  }

  /// Çözümlenen ilerleme paketini tüm yerel servislere uygular.
  Future<void> applyProgressPayload(Map<String, dynamic> payload) async {
    final dailyMap = payload['daily_play'];
    if (dailyMap is Map<String, dynamic>) {
      await ref
          .read(dailyPlayServiceProvider.notifier)
          .restoreFromBackupMap(dailyMap, merge: true);
    }

    final statsMap = payload['game_stats'];
    if (statsMap is Map<String, dynamic>) {
      await ref
          .read(gameStatsServiceProvider.notifier)
          .restoreFromBackupMap(statsMap, merge: true);
    }

    final badgesMap = payload['badges'];
    if (badgesMap is Map<String, dynamic>) {
      await ref
          .read(badgeServiceProvider.notifier)
          .restoreFromBackupMap(badgesMap, merge: true);
    }

    final leagueMap = payload['league'];
    if (leagueMap is Map<String, dynamic>) {
      await ref
          .read(leagueServiceProvider.notifier)
          .restoreFromBackupMap(leagueMap);
    }

    final nick = payload['nickname'];
    if (nick is String && nick.trim().isNotEmpty && nick != 'Oyuncu') {
      await ref.read(userNicknameProvider.notifier).setNickname(nick.trim());
    }
  }
}

final cloudBackupProvider =
    StateNotifierProvider<CloudBackupNotifier, CloudBackupState>((ref) {
  final notifier = CloudBackupNotifier(ref);

  // Kullanıcı yeni bir oyun tamamladığında arka planda otomatik buluta yedekle
  ref.listen<DailyPlayState>(dailyPlayServiceProvider, (prev, next) {
    if (prev != null && next.records.length > prev.records.length) {
      notifier.syncNow();
    }
  });

  return notifier;
});

