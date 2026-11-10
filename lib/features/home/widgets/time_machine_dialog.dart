import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/daily_play_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/sketch_decorations.dart';

/// Zühtü - Zaman Makinesi & Arşiv Seviyeleri Takvim Seçici Diyaloğu.
/// Oyuncunun geçmiş günleri kaçırdığında o günlerin bulmacalarını çözebilmesini sağlar.
/// Kural: Günlük seri kazanımı sadece gününde çözülünce verilir.
class TimeMachineDialog extends StatefulWidget {
  final DailyPlayState dailyPlayState;
  final String activeLevelId;

  const TimeMachineDialog({
    super.key,
    required this.dailyPlayState,
    required this.activeLevelId,
  });

  static Future<String?> show(
    BuildContext context, {
    required DailyPlayState dailyPlayState,
    required String activeLevelId,
  }) async {
    HapticFeedback.mediumImpact();
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TimeMachineDialog(
        dailyPlayState: dailyPlayState,
        activeLevelId: activeLevelId,
      ),
    );
  }

  @override
  State<TimeMachineDialog> createState() => _TimeMachineDialogState();
}

class _TimeMachineDialogState extends State<TimeMachineDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    final active = GameDateUtils.getActiveDate();
    _today = DateTime(active.year, active.month, active.day);

    final selected = GameDateUtils.parseLevelId(widget.activeLevelId);
    _selectedDate = DateTime(selected.year, selected.month, selected.day);
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    if (next.isAfter(DateTime(_today.year, _today.month, 1))) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = next;
    });
  }

  String _formatLevelId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.backgroundLight;

    final canGoNextMonth = _currentMonth.isBefore(DateTime(_today.year, _today.month, 1));
    final monthTitle = '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}';

    final selectedKey = _formatLevelId(_selectedDate);
    final completedCount = widget.dailyPlayState.getCompletedCountForDate(selectedKey);
    final isSelectedToday = _selectedDate.isAtSameMomentAs(_today);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SketchCard(
              backgroundColor: cardBg,
              borderColor: pencilColor,
              borderWidth: 2.8,
              borderRadius: 22,
              shadowOffset: const Offset(5.0, 5.0),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Üst Başlık & Zaman Makinesi İkonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.sunYellow,
                        borderColor: pencilColor,
                        child: const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 24,
                          color: AppColors.inkBlack,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'ZAMAN MAKİNESİ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'GEÇMİŞ BULMACA ARŞİVİ',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGray,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2, 2),
                        backgroundColor: AppColors.skyBlue,
                        borderColor: pencilColor,
                        child: const SketchDoodleHourglass(
                          size: 24,
                          color: AppColors.inkBlack,
                          fillColor: AppColors.sunYellow,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Kural Bilgilendirme Notu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pencilColor.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SketchDoodleHourglass(
                            size: 18,
                            color: pencilColor,
                            fillColor: AppColors.sunYellow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Geçmiş günlerin bulmacalarını çözebilirsin. Not: Günlük seri kazanımı sadece gününde çözülen oyunlar için geçerlidir.',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Ay Seçici Başlık Çubuğu (< Ay Yıl >)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _prevMonth,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: pencilColor, width: 1.6),
                          ),
                          child: Icon(Icons.chevron_left_rounded, size: 20, color: pencilColor),
                        ),
                      ),
                      Text(
                        monthTitle.toUpperCase(),
                        style: GoogleFonts.patrickHand(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: pencilColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: canGoNextMonth ? _nextMonth : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: canGoNextMonth ? pencilColor : pencilColor.withValues(alpha: 0.25),
                              width: 1.6,
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: canGoNextMonth ? pencilColor : pencilColor.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Haftanın Günleri Başlığı
                  Row(
                    children: const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.pencilGray,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 6),

                  // 5. Takvim Izgarası
                  _buildMonthCalendar(isDark, pencilColor),

                  const SizedBox(height: 14),

                  // 6. Seçilen Gün Durum Özeti
                  SketchCard(
                    backgroundColor: isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFFEF3C7),
                    borderColor: pencilColor,
                    borderRadius: 12,
                    borderWidth: 1.8,
                    shadowOffset: const Offset(2.0, 2.0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSelectedToday
                                  ? 'Bugün (${GameDateUtils.getFormattedDate(_selectedDate)})'
                                  : GameDateUtils.getFormattedDate(_selectedDate),
                              style: GoogleFonts.patrickHand(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                              ),
                            ),
                            Text(
                              completedCount == 6
                                  ? 'Tüm 6 Bulmaca Çözüldü ✓'
                                  : (completedCount > 0
                                      ? '$completedCount / 6 Bulmaca Çözüldü'
                                      : 'Henüz Çözülmedi'),
                              style: GoogleFonts.patrickHand(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: completedCount == 6
                                    ? AppColors.success
                                    : (isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite),
                              ),
                            ),
                          ],
                        ),
                        if (completedCount == 6)
                          const Text('🏆', style: TextStyle(fontSize: 20))
                        else if (completedCount > 0)
                          const Text('⚡', style: TextStyle(fontSize: 18))
                        else
                          const Text('📖', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 7. Aksiyon Butonları
                  Row(
                    children: [
                      // Kapat Butonu
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pencilColor, width: 2.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Kapat',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: pencilColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Işınlan Butonu
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              Navigator.pop(context, selectedKey);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.sunYellow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pencilColor, width: 2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: pencilColor.withValues(alpha: 0.25),
                                    offset: const Offset(2.5, 2.5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.history_toggle_off_rounded, size: 18, color: AppColors.inkBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSelectedToday ? 'Bugüne Dön' : 'Bu Tarihe Işınlan ➔',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(bool isDark, Color pencilColor) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1: Pzt, 7: Paz

    final List<Widget> dayWidgets = [];

    // Önceki aydan boş hücreler
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Ayın günleri
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final isFuture = date.isAfter(_today);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isCurrentToday = date.year == _today.year &&
          date.month == _today.month &&
          date.day == _today.day;

      final key = _formatLevelId(date);
      final completed = widget.dailyPlayState.getCompletedCountForDate(key);

      Color bgColor;
      if (isSelected) {
        bgColor = AppColors.sunYellow;
      } else if (isCurrentToday) {
        bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7);
      } else if (completed == 6) {
        bgColor = isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5);
      } else if (completed > 0) {
        bgColor = isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFE2E8F0);
      } else {
        bgColor = isDark ? AppColors.surfaceDark : Colors.white;
      }

      dayWidgets.add(
        InkWell(
          onTap: isFuture
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDate = date;
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isFuture ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)) : bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? pencilColor
                    : (isCurrentToday
                        ? AppColors.sunYellow
                        : (isFuture ? Colors.transparent : pencilColor.withValues(alpha: 0.35))),
                width: isSelected ? 2.2 : (isCurrentToday ? 1.8 : 1.2),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: pencilColor.withValues(alpha: 0.25),
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: isSelected || isCurrentToday ? FontWeight.bold : FontWeight.w600,
                    color: isFuture
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isSelected ? AppColors.inkBlack : pencilColor),
                  ),
                ),
                if (!isFuture)
                  Text(
                    completed == 6 ? '✓ 6/6' : (completed > 0 ? '$completed/6' : '·'),
                    style: GoogleFonts.patrickHand(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.inkBlack
                          : (completed == 6
                              ? AppColors.success
                              : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray)),
                    ),
                  )
                else
                  const Icon(Icons.lock_outline_rounded, size: 10, color: Colors.black26),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1.05,
      children: dayWidgets,
    );
  }

  static String _getMonthName(int month) {
    const names = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

