import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Güvenilir UTC zaman yönetimi ve sunucu saat senkronizasyonu servisi.
///
/// README Bölüm 7 standartları:
/// 1. UTC pivot: Günlük sıfırlama UTC 00:00:00 bazlıdır.
/// 2. Cihaz saatinin kurcalanmasını önlemek için clockDrift kullanılır.
/// 3. Aşama A'da yerel simülasyon ve drift desteği, Aşama B'de sunucu REST API senkronizasyonu.
class TimeSyncService {
  int _clockDriftSeconds = 0;
  int _dayOffset = 0;

  int get clockDriftSeconds => _clockDriftSeconds;
  int get dayOffset => _dayOffset;

  /// Sunucudan alınan epoch saniyesi ile cihaz saati arasındaki farkı (drift) günceller.
  void syncWithServerTime(int serverEpochSeconds) {
    final clientEpochSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    _clockDriftSeconds = serverEpochSeconds - clientEpochSeconds;
  }

  /// Manuel drift atama (test ve simülasyon için)
  void setClockDrift(int driftSeconds) {
    _clockDriftSeconds = driftSeconds;
  }

  /// Gün simülasyonu için günü bir ileri alır
  void advanceDay() {
    _dayOffset++;
  }

  /// Gün ötelemesini sıfırlar
  void resetDayOffset() {
    _dayOffset = 0;
  }

  /// Güvenilir UTC zamanını döndürür.
  DateTime getTrustedTimeUtc() {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc
        .add(Duration(seconds: _clockDriftSeconds))
        .add(Duration(days: _dayOffset));
  }

  /// Gösterim için güvenilir yerel saat
  DateTime getTrustedTimeLocal() {
    return getTrustedTimeUtc().toLocal();
  }

  /// Günlük bulmaca için geçerli gün kimliği (`YYYY-MM-DD`, UTC bazlı)
  String getTodayDateId() {
    final t = getTrustedTimeUtc();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Bir sonraki UTC 00:00:00 sıfırlanmasına kalan süreyi hesaplar.
  Duration getTimeUntilNextReset([DateTime? targetTime]) {
    final now = targetTime ?? getTrustedTimeUtc();
    final nextResetUtc = DateTime.utc(now.year, now.month, now.day + 1);
    final diff = nextResetUtc.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Süreyi "HH:MM:SS" formatına dönüştürür.
  static String formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

final timeSyncServiceProvider = Provider<TimeSyncService>((ref) {
  return TimeSyncService();
});

/// Her saniye güncellenen reaktif kalan süre sağlayıcısı
final nextResetCountdownProvider = StreamProvider.autoDispose<Duration>((ref) {
  final service = ref.watch(timeSyncServiceProvider);
  final controller = StreamController<Duration>();

  void emit() {
    if (!controller.isClosed) {
      controller.add(service.getTimeUntilNextReset());
    }
  }

  emit();
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => emit());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
