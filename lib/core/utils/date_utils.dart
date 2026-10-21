import 'package:intl/intl.dart';

class GameDateUtils {
  static int _dayOffset = 0;

  /// Gün simülatörü için gün ötelemesini döndürür
  static int get dayOffset => _dayOffset;

  /// Gün ötelemesini bir gün ileri alır
  static void advanceToNextDay() {
    _dayOffset++;
  }

  /// Gün ötelemesini sıfırlar
  static void resetDayOffset() {
    _dayOffset = 0;
  }

  /// Mevcut aktif tarihi (gün ötelemesi uygulanmış) döner
  static DateTime getActiveDate() {
    return DateTime.now().add(Duration(days: _dayOffset));
  }

  /// Returns today's level ID format, e.g. "2026-08-20"
  static String getTodayLevelId() {
    final active = getActiveDate();
    return DateFormat('yyyy-MM-dd').format(active);
  }

  /// Formats date for display in Turkish, e.g. "20 Ağustos 2026"
  static String getFormattedDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Calculates duration remaining until next midnight (UTC / Local)
  static Duration getTimeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Formats duration to "HH:MM:SS" countdown format
  static String formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Formats elapsed milliseconds to "mm:ss.s" for game stopwatch
  static String formatGameTime(int totalMilliseconds) {
    final minutes = (totalMilliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((totalMilliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final tenths = ((totalMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  /// Aktif tarihin ait olduğu takvim haftasının başlangıcı (Pazartesi 00:00:00)
  static DateTime getStartOfWeek([DateTime? date]) {
    final target = date ?? getActiveDate();
    final monday = target.subtract(Duration(days: target.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
  }

  /// Aktif tarihin ait olduğu takvim ayının başlangıcı (Ayın 1'i 00:00:00)
  static DateTime getStartOfMonth([DateTime? date]) {
    final target = date ?? getActiveDate();
    return DateTime(target.year, target.month, 1, 0, 0, 0);
  }
}
