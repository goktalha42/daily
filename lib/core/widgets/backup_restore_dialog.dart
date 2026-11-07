import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cloud_backup_service.dart';
import '../services/sound_haptic_service.dart';
import '../theme/app_colors.dart';
import 'sketch_decorations.dart';

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const BackupRestoreDialog(),
    );
  }

  @override
  ConsumerState<BackupRestoreDialog> createState() =>
      _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  final TextEditingController _restoreController = TextEditingController();
  String? _feedbackMessage;
  bool _isErrorFeedback = false;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _handleSyncNow() async {
    await SoundHapticService.instance.playPencilTap();
    final res = await ref.read(cloudBackupProvider.notifier).syncNow();
    if (!mounted) return;
    setState(() {
      _feedbackMessage = res.message;
      _isErrorFeedback = !res.success;
    });
  }

  Future<void> _handleCopyRecoveryCode(String code) async {
    await SoundHapticService.instance.playSymbolPlace();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() {
      _feedbackMessage =
          'Kurtarma Kodu ($code) panoya kopyalandı! Güvenli bir yere kaydedebilirsin.';
      _isErrorFeedback = false;
    });
  }

  Future<void> _handleCopyPortableKey() async {
    await SoundHapticService.instance.playSymbolPlace();
    final key =
        ref.read(cloudBackupProvider.notifier).exportPortableBackupKey();
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    setState(() {
      _feedbackMessage =
          'Taşınabilir Tam Yedek Anahtarı (ZBK1...) panoya kopyalandı! İnternet olmasa bile başka cihaza yapıştırıp geri yükleyebilirsin.';
      _isErrorFeedback = false;
    });
  }

  Future<void> _handleRestore() async {
    final input = _restoreController.text.trim();
    if (input.isEmpty) {
      await SoundHapticService.instance.playError();
      setState(() {
        _feedbackMessage =
            'Lütfen ZHT-XXXX-XXXX kurtarma kodunu veya ZBK1 yedek anahtarını girin.';
        _isErrorFeedback = true;
      });
      return;
    }

    final res =
        await ref.read(cloudBackupProvider.notifier).restoreFromInput(input);
    if (!mounted) return;

    if (res.success) {
      await SoundHapticService.instance.playVictory(
        isMilestoneOrPersonalBest: true,
      );
      _restoreController.clear();
    } else {
      await SoundHapticService.instance.playError();
    }

    setState(() {
      _feedbackMessage = res.message;
      _isErrorFeedback = !res.success;
    });
  }

  String _formatLastSync(DateTime? dt) {
    if (dt == null) return 'Henüz buluta yedeklenmedi';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return 'Son Yedekleme: $day.$month.${dt.year} $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final subColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final backupState = ref.watch(cloudBackupProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        child: SketchCard(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          borderColor: textColor,
          borderRadius: 20,
          borderWidth: 2.6,
          shadowOffset: const Offset(5.0, 5.0),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  SketchCard(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 12,
                    borderWidth: 1.8,
                    shadowOffset: const Offset(2.0, 2.0),
                    backgroundColor: AppColors.highlighterCyan,
                    borderColor: AppColors.pencilBlack,
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: AppColors.pencilBlack,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yedekleme & Cihaz Taşıma',
                          style: GoogleFonts.patrickHand(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _formatLastSync(backupState.lastSyncedAt),
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: textColor, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Kurtarma Kodu Kutusu
              Text(
                'SENİN KURTARMA KODUN',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              SketchCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                borderRadius: 14,
                borderWidth: 2.0,
                shadowOffset: const Offset(2.5, 2.5),
                backgroundColor: isDark
                    ? AppColors.surfaceSecondaryDark
                    : AppColors.surfaceSecondaryLight,
                borderColor: textColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: SelectableText(
                            backupState.recoveryCode,
                            style: GoogleFonts.patrickHand(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        SketchCard(
                          onTap: () =>
                              _handleCopyRecoveryCode(backupState.recoveryCode),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          borderRadius: 8,
                          borderWidth: 1.6,
                          shadowOffset: const Offset(1.5, 1.5),
                          backgroundColor: AppColors.sunYellow,
                          borderColor: AppColors.pencilBlack,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: AppColors.pencilBlack,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Kopyala',
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
                    const SizedBox(height: 8),
                    Text(
                      'Telefon değiştirdiğinde veya uygulamayı yeniden kurduğunda bu kod ile günlük serini, IQ karneni ve rozetlerini geri yükleyebilirsin.',
                      style: GoogleFonts.patrickHand(
                        fontSize: 13,
                        color: subColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Aksiyon Butonları (Şimdi Buluta Yedekle & Tam Yedek Anahtarı)
              Row(
                children: [
                  Expanded(
                    child: SketchCard(
                      onTap: backupState.isSyncing ? null : _handleSyncNow,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      borderRadius: 12,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.5, 2.5),
                      backgroundColor: AppColors.highlighterCyan,
                      borderColor: AppColors.pencilBlack,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (backupState.isSyncing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pencilBlack,
                              ),
                            )
                          else
                            const Icon(
                              Icons.cloud_upload_rounded,
                              size: 18,
                              color: AppColors.pencilBlack,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            'Şimdi Buluta Yedekle',
                            style: GoogleFonts.patrickHand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SketchCard(
                    onTap: _handleCopyPortableKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    borderRadius: 12,
                    borderWidth: 2.0,
                    shadowOffset: const Offset(2.5, 2.5),
                    backgroundColor: AppColors.highlighterPurple,
                    borderColor: AppColors.pencilBlack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 17,
                          color: AppColors.pencilBlack,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tam Anahtar',
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

              const SizedBox(height: 18),
              Divider(color: textColor.withValues(alpha: 0.25), thickness: 1.2),
              const SizedBox(height: 10),

              // 2. Başka Cihazdan Geri Yükle
              Text(
                'BAŞKA CİHAZDAN İLERLEME GERİ YÜKLE',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              SketchCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                borderRadius: 12,
                borderWidth: 1.8,
                shadowOffset: const Offset(2.0, 2.0),
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                borderColor: textColor,
                child: TextField(
                  controller: _restoreController,
                  style: GoogleFonts.patrickHand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Örn: ZHT-4829-K7M2 veya ZBK1...',
                    hintStyle: GoogleFonts.patrickHand(
                      fontSize: 15,
                      color: subColor.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SketchCard(
                  onTap: backupState.isSyncing ? null : _handleRestore,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  borderRadius: 12,
                  borderWidth: 2.2,
                  shadowOffset: const Offset(3.0, 3.0),
                  backgroundColor: AppColors.sunYellow,
                  borderColor: AppColors.pencilBlack,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restore_rounded,
                        size: 20,
                        color: AppColors.pencilBlack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serimi ve İlerlememi Geri Yükle',
                        style: GoogleFonts.patrickHand(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_feedbackMessage != null) ...[
                const SizedBox(height: 12),
                SketchCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 10,
                  borderWidth: 1.6,
                  shadowOffset: const Offset(1.5, 1.5),
                  backgroundColor: _isErrorFeedback
                      ? AppColors.highlighterPink
                      : AppColors.highlighterCyan,
                  borderColor: AppColors.pencilBlack,
                  child: Row(
                    children: [
                      Icon(
                        _isErrorFeedback
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        color: AppColors.pencilBlack,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

