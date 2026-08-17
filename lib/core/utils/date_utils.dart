import 'package:intl/intl.dart';

class GameDateUtils {
  /// Returns today's level ID format, e.g. "2026-08-17"
  static String getTodayLevelId() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Formats date for display in Turkish, e.g. "17 Ağustos 2026"
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
}
