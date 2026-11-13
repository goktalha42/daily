import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/cloud_backup_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/services/league_service.dart';
import '../../core/services/player_stats_service.dart';
import '../../core/services/retention_notification_service.dart';
import '../../core/puzzle/remote_puzzle_store.dart';
import '../../core/services/sound_haptic_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/update_service.dart';
import '../../core/services/user_avatar_provider.dart';
import '../../core/services/user_nickname_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/backup_restore_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/widgets/update_prompt_dialog.dart';
import '../home/home_screen.dart';
import '../leaderboard/leaderboard_service.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeServiceProvider);
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    final currentStreak =
        ref.watch(dailyPlayServiceProvider).getCurrentStreak();
    final soundHaptic = ref.watch(soundHapticProvider);
    final notifySettings = ref.watch(retentionNotificationProvider);
    final backupState = ref.watch(cloudBackupProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. ÜST BAŞLIK & GERİ BUTONU
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, top: 18, bottom: 12),
                child: Row(
                  children: [
                    SketchCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      padding: const EdgeInsets.all(8),
                      borderRadius: 10,
                      borderWidth: 1.8,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: cardBg,
                      borderColor: pencilColor,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: pencilColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sunYellow,
                                border: Border.all(color: pencilColor, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'YAPILANDIRMA & TERCİHLER',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: graphiteColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ayarlar',
                          style: GoogleFonts.patrickHand(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: pencilColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. TEMA VE GÖRÜNÜM
            _buildSectionHeader(
              title: 'GÖRÜNÜM VE TEMA',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.highlighterPurple,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      _ThemeModeChip(
                        title: 'Sistem',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: currentThemeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeServiceProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                      const SizedBox(width: 6),
                      _ThemeModeChip(
                        title: 'Açık',
                        icon: Icons.light_mode_rounded,
                        isSelected: currentThemeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeServiceProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 6),
                      _ThemeModeChip(
                        title: 'Koyu',
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentThemeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeServiceProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. SES VE DOKUNSAL HİSSİYAT (HAPTIC)
            _buildSectionHeader(
              title: 'SES VE DOKUNSAL HİSSİYAT',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.highlighterCyan,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  borderColor: pencilColor,
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.volume_up_rounded,
                        accentColor: AppColors.highlighterCyan,
                        title: 'Kalem & Oyun Ses Efektleri (SFX)',
                        subtitle: 'Hamle, vezir koyma ve zafer fanfarı sesleri',
                        value: soundHaptic.soundEnabled,
                        onToggle: () =>
                            ref.read(soundHapticProvider.notifier).toggleSound(),
                      ),
                      Divider(
                        height: 16,
                        color: pencilColor.withAlpha(40),
                        thickness: 1.1,
                      ),
                      _SettingsToggleRow(
                        icon: Icons.vibration_rounded,
                        accentColor: AppColors.highlighterPurple,
                        title: 'Dokunsal Geri Bildirim (Haptic)',
                        subtitle: 'Hücre seçimi, hata ve zafer titreşimleri',
                        value: soundHaptic.hapticEnabled,
                        onToggle: () =>
                            ref.read(soundHapticProvider.notifier).toggleHaptic(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. BİLDİRİMLER VE HATIRLATICILAR
            _buildSectionHeader(
              title: 'BİLDİRİMLER VE GÜNLÜK SERİ',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.highlighterOrange,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  borderColor: pencilColor,
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.local_fire_department_rounded,
                        accentColor: AppColors.highlighterOrange,
                        title: 'Günlük Seri Koruma Bildirimi (18:00)',
                        subtitle:
                            'O gün oyun çözülmediyse akşam 18:00\'de seriyi korumanız için uyarır',
                        value: notifySettings.streakReminderEnabled,
                        onToggle: () => ref
                            .read(retentionNotificationProvider.notifier)
                            .toggleStreakReminder(),
                      ),
                      Divider(
                        height: 16,
                        color: pencilColor.withAlpha(40),
                        thickness: 1.1,
                      ),
                      _SettingsToggleRow(
                        icon: Icons.insights_rounded,
                        accentColor: AppColors.sunYellow,
                        title: 'Pazar Akşamı Zeka Raporu (18:00)',
                        subtitle:
                            'Haftalık 6 bilişsel alan karnesi hazır olduğunda bildirir',
                        value: notifySettings.sundayReportEnabled,
                        onToggle: () => ref
                            .read(retentionNotificationProvider.notifier)
                            .toggleSundayReport(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SketchCard(
                          onTap: () async {
                            await SoundHapticService.instance.playSymbolPlace();
                            await RetentionNotificationService.instance
                                .sendTestNotification(
                                    currentStreak: currentStreak);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.pencilBlack,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.sunYellow,
                                      width: 1.5,
                                    ),
                                  ),
                                  content: Text(
                                    '🔔 Test bildirimi gönderildi! Bildirim çubuğunu kontrol et.',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          borderRadius: 10,
                          borderWidth: 1.8,
                          shadowOffset: const Offset(2.0, 2.0),
                          backgroundColor: isDark
                              ? AppColors.surfaceSecondaryDark
                              : AppColors.surfaceSecondaryLight,
                          borderColor: pencilColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 17,
                                color: pencilColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Seri Bildirimini Test Et',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: pencilColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. BULUT YEDEKLEME VE CİHAZ TAŞIMA
            _buildSectionHeader(
              title: 'İLERLEME YEDEKLEME VE CİHAZ TAŞIMA',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.highlighterCyan,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  borderColor: pencilColor,
                  child: Row(
                    children: [
                      SketchCard(
                        padding: const EdgeInsets.all(9),
                        borderRadius: 10,
                        borderWidth: 1.6,
                        shadowOffset: const Offset(1.5, 1.5),
                        backgroundColor: AppColors.highlighterCyan,
                        borderColor: AppColors.pencilBlack,
                        child: const Icon(
                          Icons.cloud_done_rounded,
                          color: AppColors.pencilBlack,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurtarma Kodu: ${backupState.recoveryCode}',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pencilColor,
                              ),
                            ),
                            Text(
                              'İlerlemeni buluta yedekle veya yeni cihazına aktar.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: graphiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SketchCard(
                        onTap: () {
                          SoundHapticService.instance.playPencilTap();
                          BackupRestoreDialog.show(context);
                        },
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: 10,
                        borderWidth: 1.8,
                        shadowOffset: const Offset(2.0, 2.0),
                        backgroundColor: AppColors.sunYellow,
                        borderColor: pencilColor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sync_lock_rounded,
                                size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'Yedekle / Taşı',
                              style: GoogleFonts.patrickHand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 6. UYGULAMA SÜRÜMÜ & GÜNCELLEME KONTROLÜ
            _buildSectionHeader(
              title: 'UYGULAMA SÜRÜMÜ VE BİLGİLERİ',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.highlighterPink,
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _SettingsAppVersionCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const OnboardingScreen(isRevisit: true),
                      ),
                    );
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  borderColor: pencilColor,
                  child: Row(
                    children: [
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 10,
                        borderWidth: 1.5,
                        shadowOffset: const Offset(1.5, 1.5),
                        backgroundColor: AppColors.highlighterPurple
                            .withAlpha(isDark ? 60 : 40),
                        borderColor: pencilColor,
                        child: const Text('📖', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanıtım Turunu Tekrar İzle',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pencilColor,
                              ),
                            ),
                            Text(
                              'Zühtü\'nün 6 oyununu, IQ sistemini ve ligleri incele',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: graphiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: pencilColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 8. TEHLİKELİ BÖLGE / VERİ SIFIRLAMA (GOOGLE PLAY DATA DELETION)
            _buildSectionHeader(
              title: 'VERİ YÖNETİMİ VE HESAP SIFIRLAMA',
              pencilColor: pencilColor,
              graphiteColor: graphiteColor,
              accentColor: AppColors.error,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SketchCard(
                  onTap: () => _showResetConfirmationDialog(context, ref),
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: cardBg,
                  borderColor: AppColors.error.withAlpha(180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error, width: 1.5),
                            ),
                            child: const Icon(Icons.delete_forever_rounded,
                                color: AppColors.error, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hesap ve Tüm Verileri Kalıcı Sil',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  'Tüm oyun skorlarınızı, IQ karnenizi ve rozetlerinizi kalıcı olarak siler.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: graphiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error, width: 1.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _showResetConfirmationDialog(context, ref),
                          child: Text(
                            'Tüm Verileri ve Hesabı Sıfırla',
                            style: GoogleFonts.patrickHand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 50),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionHeader({
    required String title,
    required Color pencilColor,
    required Color graphiteColor,
    required Color accentColor,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 6),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                border: Border.all(color: pencilColor, width: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.patrickHand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: graphiteColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final cardBg = isDark ? AppColors.cardBgDark : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: SketchCard(
                borderRadius: 18,
                borderWidth: 2.5,
                shadowOffset: const Offset(4.0, 4.0),
                backgroundColor: cardBg,
                borderColor: AppColors.error,
                padding: const EdgeInsets.all(20),
                child: isDeleting
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.error),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hesap ve Veriler Siliniyor...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: pencilColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lütfen bekleyin, sunucu ve cihazınızdaki tüm kayıtlar sıfırlanıyor.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: graphiteColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(30),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.error, width: 2.0),
                            ),
                            child: const Center(
                              child: Icon(Icons.warning_amber_rounded,
                                  color: AppColors.error, size: 30),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tüm Verilerini Silmek İstiyor musun?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.patrickHand(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: pencilColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Bu işlem geri alınamaz!\n\nCihazınızdaki tüm günlük seriler, WAIS-IV IQ karnesi, rozetler ve sunucudaki lig puanlarınız tamamen silinecektir.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: graphiteColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: pencilColor, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(),
                                  child: Text(
                                    'Vazgeç',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: pencilColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    setDialogState(() => isDeleting = true);
                                    HapticFeedback.vibrate();

                                    try {
                                      // 1. Sunucudan sil
                                      await ref
                                          .read(apiClientProvider)
                                          .deleteAccount();
                                    } catch (e) {
                                      debugPrint('[Settings] Sunucu silme hatası: $e');
                                    }

                                    // 2. Tema tercihini koruyarak yerel hafızayı temizle
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final currentTheme =
                                        prefs.getString('zuhtu_theme_mode');
                                    await prefs.clear();
                                    if (currentTheme != null) {
                                      await prefs.setString(
                                          'zuhtu_theme_mode', currentTheme);
                                    }

                                    // 3. Bellek içi bulmaca önbelleğini temizle
                                    RemotePuzzleStore.clearMemory();

                                    // 4. Provider'ları sıfırla
                                    ref.invalidate(dailyPlayServiceProvider);
                                    ref.invalidate(gameStatsServiceProvider);
                                    ref.invalidate(badgeServiceProvider);
                                    ref.invalidate(playerStatsServiceProvider);
                                    ref.invalidate(leagueServiceProvider);
                                    ref.invalidate(userNicknameProvider);
                                    ref.invalidate(userAvatarProvider);
                                    ref.invalidate(cloudBackupProvider);
                                    ref.invalidate(leaderboardServiceProvider);
                                    ref.invalidate(apiClientProvider);

                                    // 5. Ana menü lobisine yönlendir
                                    ref
                                        .read(homeBottomNavIndexProvider.notifier)
                                        .state = 0;

                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.pencilBlack,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: const BorderSide(
                                                color: AppColors.error,
                                                width: 1.5),
                                          ),
                                          content: Row(
                                            children: [
                                              const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: AppColors.sunYellow,
                                                  size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Tüm hesap ve oyun verileriniz başarıyla sıfırlandı.',
                                                  style: GoogleFonts.patrickHand(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Text(
                                    'Evet, Sıfırla',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuad,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.sunYellow
                : (isDark ? AppColors.cardBgDark : AppColors.cardBgLight),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.pencilBlack : pencilColor.withAlpha(60),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.pencilBlack,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.pencilBlack : pencilColor,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.patrickHand(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.pencilBlack : pencilColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  const _SettingsToggleRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggle();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SketchCard(
              padding: const EdgeInsets.all(8),
              borderRadius: 10,
              borderWidth: 1.5,
              shadowOffset: const Offset(1.5, 1.5),
              backgroundColor: accentColor.withAlpha(isDark ? 60 : 40),
              borderColor: pencilColor,
              child: Icon(icon, color: pencilColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.patrickHand(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: pencilColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: graphiteColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: value ? AppColors.sunYellow : Colors.grey.withAlpha(80),
                  border: Border.all(color: pencilColor, width: 1.8),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pencilColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsAppVersionCard extends StatefulWidget {
  const _SettingsAppVersionCard();

  @override
  State<_SettingsAppVersionCard> createState() =>
      _SettingsAppVersionCardState();
}

class _SettingsAppVersionCardState extends State<_SettingsAppVersionCard> {
  bool _isChecking = false;
  String _versionText = 'v1.2.22 (Build 40)';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await UpdateService.instance.getInstalledVersion();
    if (mounted) {
      setState(() {
        _versionText = 'v${v.version} (Build ${v.buildNumber})';
      });
    }
  }

  Future<void> _checkUpdate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    HapticFeedback.lightImpact();

    try {
      final info = await UpdateService.instance.checkForUpdate();
      if (!mounted) return;

      if (info != null && info.isUpdateAvailable) {
        await UpdatePromptDialog.show(context, info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.pencilBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.sunYellow, width: 1.5),
            ),
            content: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zühtü en güncel sürümde! ($_versionText)',
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Güncelleme kontrolü başarısız: $e',
              style: GoogleFonts.patrickHand(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    return SketchCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.0, 3.0),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      borderColor: pencilColor,
      child: Row(
        children: [
          SketchCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 10,
            borderWidth: 1.5,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: AppColors.sunYellow.withAlpha(isDark ? 60 : 40),
            borderColor: pencilColor,
            child: const Text('📱', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zühtü $_versionText',
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: pencilColor,
                  ),
                ),
                Text(
                  'Canlı Sunucu & Google Play Sürümü',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: graphiteColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SketchCard(
            onTap: _isChecking ? null : _checkUpdate,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            borderRadius: 8,
            borderWidth: 1.6,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: AppColors.sunYellow,
            borderColor: AppColors.pencilBlack,
            child: _isChecking
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.pencilBlack),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          size: 15, color: AppColors.pencilBlack),
                      const SizedBox(width: 4),
                      Text(
                        'Denetle',
                        style: GoogleFonts.patrickHand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

