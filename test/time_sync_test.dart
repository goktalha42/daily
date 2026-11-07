import 'package:flutter_test/flutter_test.dart';
import 'package:daily_games/core/services/time_sync_service.dart';
import 'package:daily_games/core/utils/date_utils.dart';

void main() {
  group('TimeSyncService Tests', () {
    late TimeSyncService service;

    setUp(() {
      GameDateUtils.resetDayOffset();
      service = TimeSyncService();
    });

    tearDown(() {
      GameDateUtils.resetDayOffset();
    });

    test('varsayılan clockDrift 0 olmalıdır', () {
      expect(service.clockDriftSeconds, 0);
      expect(service.dayOffset, 0);
    });

    test('manual drift ayarlandığında getTrustedTimeUtc drift süresi kadar kaymalıdır', () {
      final nowUtc = DateTime.now().toUtc();
      service.setClockDrift(3600); // +1 saat
      expect(service.clockDriftSeconds, 3600);
      expect(GameDateUtils.clockDriftSeconds, 3600);

      final trusted = service.getTrustedTimeUtc();
      final diffSeconds = trusted.difference(nowUtc).inSeconds;
      expect(diffSeconds, greaterThanOrEqualTo(3595));
      expect(diffSeconds, lessThanOrEqualTo(3605));
    });

    test('advanceDay() dayOffset değerini 1 arttırmalıdır', () {
      expect(service.dayOffset, 0);
      service.advanceDay();
      expect(service.dayOffset, 1);
    });

    test('resetDayOffset() gün ötelemesini sıfırlamalıdır', () {
      service.advanceDay();
      service.advanceDay();
      expect(service.dayOffset, 2);

      service.resetDayOffset();
      expect(service.dayOffset, 0);
    });

    test('getTodayDateId() yerel saat (00:00) bazlı YYYY-MM-DD formatında olmalıdır', () {
      final dateId = service.getTodayDateId();
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(dateId), isTrue);
      expect(dateId, GameDateUtils.getTodayLevelId());
    });

    test('getTimeUntilNextReset() yerel gece yarısı 00:00:00 sıfırlanmasına kalan süreyi doğru hesaplamalıdır', () {
      // Gece 01:30 yerel saatte (gece 12'yi 1.5 saat geçmişken) bir sonraki sıfırlamaya
      // 1.5 saat (03:00) DEĞİL, tam 22 saat 30 dakika (00:00) kalmış olmalıdır!
      final localAfterMidnight = DateTime(2026, 11, 8, 1, 30, 0);
      final remainingAfterMidnight = service.getTimeUntilNextReset(localAfterMidnight);
      expect(remainingAfterMidnight.inHours, 22);
      expect(remainingAfterMidnight.inMinutes % 60, 30);

      // 23:59:50 yerel zamanı için tam 10 saniye kalmış olmalı
      final almostLocalMidnight = DateTime(2026, 10, 7, 23, 59, 50);
      final remaining = service.getTimeUntilNextReset(almostLocalMidnight);
      expect(remaining.inSeconds, 10);

      // 00:00:00 zamanı için tam 24 saat (86400 sn) kalmış olmalı
      final exactlyMidnight = DateTime(2026, 10, 7, 0, 0, 0);
      final remainingFullDay = service.getTimeUntilNextReset(exactlyMidnight);
      expect(remainingFullDay.inHours, 24);
    });

    test('formatCountdown süreyi HH:MM:SS formatında döner', () {
      const dur = Duration(hours: 5, minutes: 23, seconds: 9);
      expect(TimeSyncService.formatCountdown(dur), '05:23:09');
    });
  });
}
