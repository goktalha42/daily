import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_utils.dart';
import 'daily_play_service.dart';

class RetentionNotificationSettings {
  final bool streakReminderEnabled;
  final bool sundayReportEnabled;

  const RetentionNotificationSettings({
    this.streakReminderEnabled = true,
    this.sundayReportEnabled = true,
  });

  RetentionNotificationSettings copyWith({
    bool? streakReminderEnabled,
    bool? sundayReportEnabled,
  }) {
    return RetentionNotificationSettings(
      streakReminderEnabled:
          streakReminderEnabled ?? this.streakReminderEnabled,
      sundayReportEnabled: sundayReportEnabled ?? this.sundayReportEnabled,
    );
  }
}

/// Akşam 20:00 Günlük Seri Koruma ve Pazar 20:00 Haftalık Zeka Raporu Bildirim Servisi.
class RetentionNotificationService {
  RetentionNotificationService._();
  static final RetentionNotificationService instance =
      RetentionNotificationService._();

  static const _streakPrefKey = 'zuhtu_notify_streak_20h_v1';
  static const _sundayPrefKey = 'zuhtu_notify_sunday_20h_v1';

  static const int idStreakReminder = 1001;
  static const int idSundayReport = 1002;

  static const MethodChannel _channel =
      MethodChannel('com.dailygames.daily_games/retention');

  bool _streakReminderEnabled = true;
  bool _sundayReportEnabled = true;
  bool _loaded = false;

  Future<RetentionNotificationSettings> ensureLoaded() async {
    if (_loaded) {
      return RetentionNotificationSettings(
        streakReminderEnabled: _streakReminderEnabled,
        sundayReportEnabled: _sundayReportEnabled,
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakReminderEnabled = prefs.getBool(_streakPrefKey) ?? true;
      _sundayReportEnabled = prefs.getBool(_sundayPrefKey) ?? true;
      _loaded = true;
    } catch (_) {}
    return RetentionNotificationSettings(
      streakReminderEnabled: _streakReminderEnabled,
      sundayReportEnabled: _sundayReportEnabled,
    );
  }

  /// Akşam 20:00 bildirim zamanını hesaplar.
  /// Eğer bugün zaten en az 1 oyun çözülmüşse veya saat 20:00'yi geçmişse
  /// bildirimi otomatik olarak YARIN 20:00'ye kurar.
  static DateTime computeNextStreakTriggerTime({
    required DateTime now,
    required bool hasCompletedGameToday,
  }) {
    final todayAt20 = DateTime(now.year, now.month, now.day, 20, 0);
    if (!hasCompletedGameToday && now.isBefore(todayAt20)) {
      return todayAt20;
    }
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 0);
  }

  /// Pazar akşamı 20:00 Haftalık Zeka Raporu bildirim zamanını hesaplar.
  static DateTime computeNextSundayReportTriggerTime(DateTime now) {
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final candidateDate = now.add(Duration(days: daysUntilSunday));
    final candidateAt20 = DateTime(
      candidateDate.year,
      candidateDate.month,
      candidateDate.day,
      20,
      0,
    );
    if (candidateAt20.isAfter(now)) {
      return candidateAt20;
    }
    final nextSunday = candidateDate.add(const Duration(days: 7));
    return DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
  }

  /// Aktif seri sayısına göre kişiselleştirilmiş bildirim başlığı ve metni üretir.
  static ({String title, String body}) buildStreakNotificationContent(
    int currentStreak,
  ) {
    if (currentStreak > 0) {
      return (
        title: '🔥 $currentStreak Günlük Serin Yanmak Üzere!',
        body:
            'Gece 00:00 olmadan günün bulmacalarından en az 1 tanesini çöz, $currentStreak günlük kesintisiz zeka serini koru!',
      );
    }
    return (
      title: '✏️ Günün 6 Zeka Bulmacası Seni Bekliyor!',
      body:
          'Zühtü Eskiz Defteri yenilendi! Yeni bir günlük seri başlatmak ve IQ karneni yükseltmek için hemen oyna.',
    );
  }

  /// Android 13+ bildirim iznini ister.
  Future<bool> requestPermissionIfNeeded() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _channel.invokeMethod<bool>(
          'requestNotificationPermission',
        );
        return granted ?? true;
      }
    } catch (_) {}
    return true;
  }

  /// Günlük seri durumuna göre akşam 20:00 ve Pazar 20:00 bildirimlerini senkronize eder.
  Future<void> syncSchedules(DailyPlayState playState) async {
    await ensureLoaded();
    final now = DateTime.now();
    final todayId = GameDateUtils.getTodayLevelId();
    final completedToday = playState.getCompletedCountForDate(todayId) > 0;
    final currentStreak = playState.getCurrentStreak();

    // 1. Günlük Seri Koruma Bildirimi (20:00)
    if (_streakReminderEnabled) {
      final nextTrigger = computeNextStreakTriggerTime(
        now: now,
        hasCompletedGameToday: completedToday,
      );
      final content = buildStreakNotificationContent(currentStreak);
      await _scheduleNative(
        id: idStreakReminder,
        triggerAtMs: nextTrigger.millisecondsSinceEpoch,
        repeatIntervalMs: const Duration(hours: 24).inMilliseconds,
        title: content.title,
        body: content.body,
      );
    } else {
      await _cancelNative(idStreakReminder);
    }

    // 2. Pazar Akşamı 20:00 Haftalık Zeka Raporu Bildirimi
    if (_sundayReportEnabled) {
      final nextSunday = computeNextSundayReportTriggerTime(now);
      await _scheduleNative(
        id: idSundayReport,
        triggerAtMs: nextSunday.millisecondsSinceEpoch,
        repeatIntervalMs: const Duration(days: 7).inMilliseconds,
        title: '📊 Haftalık Zeka Raporun Hazır!',
        body:
            'Pazar akşamı özeti çıktı! 6 bilişsel alandaki odak dağılımını ve haftalık seri karneni incelemek için dokun.',
      );
    } else {
      await _cancelNative(idSundayReport);
    }
  }

  Future<void> setStreakReminderEnabled(
    bool enabled,
    DailyPlayState playState,
  ) async {
    _streakReminderEnabled = enabled;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_streakPrefKey, enabled);
    } catch (_) {}
    if (enabled) {
      await requestPermissionIfNeeded();
    }
    await syncSchedules(playState);
  }

  Future<void> setSundayReportEnabled(
    bool enabled,
    DailyPlayState playState,
  ) async {
    _sundayReportEnabled = enabled;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sundayPrefKey, enabled);
    } catch (_) {}
    if (enabled) {
      await requestPermissionIfNeeded();
    }
    await syncSchedules(playState);
  }

  /// Kullanıcının Profil ekranından bildirimlerin çalıştığını anında doğrulaması için test bildirimi.
  Future<void> sendTestNotification({required int currentStreak}) async {
    await requestPermissionIfNeeded();
    final content = buildStreakNotificationContent(currentStreak);
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('showTestNotification', {
          'title': content.title,
          'body': content.body,
        });
      }
    } catch (_) {}
  }

  Future<void> _scheduleNative({
    required int id,
    required int triggerAtMs,
    required int repeatIntervalMs,
    required String title,
    required String body,
  }) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('scheduleNotification', {
          'id': id,
          'triggerAtMs': triggerAtMs,
          'repeatIntervalMs': repeatIntervalMs,
          'title': title,
          'body': body,
        });
      }
    } catch (_) {}
  }

  Future<void> _cancelNative(int id) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('cancelNotification', {'id': id});
      }
    } catch (_) {}
  }
}

class RetentionNotificationNotifier
    extends StateNotifier<RetentionNotificationSettings> {
  final Ref ref;

  RetentionNotificationNotifier(this.ref)
      : super(const RetentionNotificationSettings()) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await RetentionNotificationService.instance.ensureLoaded();
    state = loaded;
    final playState = ref.read(dailyPlayServiceProvider);
    await RetentionNotificationService.instance.syncSchedules(playState);
  }

  Future<void> toggleStreakReminder() async {
    final next = !state.streakReminderEnabled;
    final playState = ref.read(dailyPlayServiceProvider);
    await RetentionNotificationService.instance.setStreakReminderEnabled(
      next,
      playState,
    );
    state = state.copyWith(streakReminderEnabled: next);
  }

  Future<void> toggleSundayReport() async {
    final next = !state.sundayReportEnabled;
    final playState = ref.read(dailyPlayServiceProvider);
    await RetentionNotificationService.instance.setSundayReportEnabled(
      next,
      playState,
    );
    state = state.copyWith(sundayReportEnabled: next);
  }
}

final retentionNotificationProvider = StateNotifierProvider<
    RetentionNotificationNotifier, RetentionNotificationSettings>((ref) {
  final notifier = RetentionNotificationNotifier(ref);
  ref.listen<DailyPlayState>(dailyPlayServiceProvider, (prev, next) {
    RetentionNotificationService.instance.syncSchedules(next);
  });
  return notifier;
});

