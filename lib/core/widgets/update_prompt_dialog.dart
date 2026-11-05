import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_colors.dart';
import 'sketch_decorations.dart';

/// Zühtü El Çizimi Eskiz Güncelleme Penceresi
class UpdatePromptDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdatePromptDialog({
    super.key,
    required this.updateInfo,
  });

  /// Güncelleme varsa kullanıcıya dialog gösterir
  static Future<void> show(BuildContext context, AppUpdateInfo info) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => UpdatePromptDialog(updateInfo: info),
    );
  }

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

enum _UpdateStatus {
  idle,
  downloading,
  installing,
  error,
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  _UpdateStatus _status = _UpdateStatus.idle;
  int _downloadProgress = 0;
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _status = _UpdateStatus.downloading;
      _downloadProgress = 0;
      _errorMessage = null;
    });

    try {
      _otaSubscription?.cancel();
      _otaSubscription = UpdateService.instance
          .startOtaUpdate(widget.updateInfo.apkUrl)
          .listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final percent = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _status = _UpdateStatus.downloading;
                _downloadProgress = percent.clamp(0, 100);
              });
              break;

            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              setState(() {
                _status = _UpdateStatus.installing;
              });
              break;

            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _status = _UpdateStatus.error;
                _errorMessage =
                    'Uygulama yükleme izni verilmedi. Lütfen ayarlardan izin verin veya tarayıcıdan indirin.';
              });
              break;

            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.INSTALLATION_ERROR:
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _status = _UpdateStatus.error;
                _errorMessage =
                    'İndirme sırasında bir sorun oluştu. Tarayıcı üzerinden doğrudan indirebilirsiniz.';
              });
              break;

            case OtaStatus.CANCELED:
              setState(() {
                _status = _UpdateStatus.idle;
              });
              break;
          }
        },
        onError: (dynamic error) {
          if (!mounted) return;
          setState(() {
            _status = _UpdateStatus.error;
            _errorMessage = 'Bağlantı hatası: $error';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _UpdateStatus.error;
        _errorMessage = 'Güncelleme başlatılamadı: $e';
      });
    }
  }

  Future<void> _openBrowserDownload() async {
    final urlStr = widget.updateInfo.apkUrl.isNotEmpty
        ? widget.updateInfo.apkUrl
        : widget.updateInfo.releaseUrl;
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[UpdatePromptDialog] Tarayıcı açılamadı: $e');
    }
  }

  void _dismiss() {
    UpdateService.dismissThisSession(widget.updateInfo.remoteBuildNumber);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final subtitleColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && _status != _UpdateStatus.downloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SketchCard(
          backgroundColor: cardBg,
          borderColor: pencilColor,
          borderWidth: 2.5,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Üst Başlık & İkon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sunYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: pencilColor, width: 2.0),
                        ),
                        child: const Text('🚀', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.updateInfo.title.isNotEmpty
                                  ? widget.updateInfo.title
                                  : 'Yeni Güncelleme Mevcut!',
                              style: GoogleFonts.patrickHand(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: pencilColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Sürüm Geçiş Rozeti
                            Row(
                              children: [
                                _VersionBadge(
                                  label: 'v${widget.updateInfo.currentVersion}',
                                  isDark: isDark,
                                  isOld: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: subtitleColor,
                                  ),
                                ),
                                _VersionBadge(
                                  label: 'v${widget.updateInfo.remoteVersion}',
                                  isDark: isDark,
                                  isOld: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Yenilikler (Changelog) Kutusu
                  if (widget.updateInfo.changelog.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '📝 Yenilikler ve İyileştirmeler:',
                        style: GoogleFonts.patrickHand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: pencilColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceSecondaryDark
                            : const Color(0xFFF9F7F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pencilColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.updateInfo.changelog,
                          style: GoogleFonts.patrickHand(
                            fontSize: 15,
                            color: pencilColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Durum Alanı (İndirme İlerlemesi / Yükleme / Hata)
                  if (_status == _UpdateStatus.downloading) ...[
                    _buildDownloadingView(pencilColor, isDark),
                  ] else if (_status == _UpdateStatus.installing) ...[
                    _buildInstallingView(pencilColor),
                  ] else if (_status == _UpdateStatus.error) ...[
                    _buildErrorView(pencilColor),
                  ] else ...[
                    // 4. Normal Başlangıç Butonları
                    _buildActionButtons(pencilColor, isDark),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// İndirme İlerleme Görünümü
  Widget _buildDownloadingView(Color pencilColor, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Güncelleme indiriliyor...',
              style: GoogleFonts.patrickHand(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pencilColor,
              ),
            ),
            Text(
              '%$_downloadProgress',
              style: GoogleFonts.patrickHand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.skyBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Çizgili Eskiz Progress Bar
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pencilColor, width: 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth =
                  constraints.maxWidth * (_downloadProgress / 100.0);
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: fillWidth,
                    decoration: BoxDecoration(
                      color: AppColors.sunYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lütfen bekleyin, tamamlandığında yükleme başlayacaktır.',
          style: GoogleFonts.patrickHand(
            fontSize: 13,
            color: pencilColor.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Yükleme Başlatılıyor Görünümü
  Widget _buildInstallingView(Color pencilColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.sunYellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pencilColor, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yükleme başlatılıyor... Lütfen açılan Android penceresinde "Güncelle"ye basınız.',
              style: GoogleFonts.patrickHand(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: pencilColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hata ve Tarayıcı Fallback Görünümü
  Widget _buildErrorView(Color pencilColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error, width: 1.8),
          ),
          child: Text(
            _errorMessage ?? 'Güncelleme sırasında bir sorun oluştu.',
            style: GoogleFonts.patrickHand(
              fontSize: 14,
              color: pencilColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SketchActionBtn(
                text: 'Tekrar Dene',
                onPressed: _startUpdate,
                bgColor: AppColors.sunYellow,
                pencilColor: pencilColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SketchActionBtn(
                text: '🌐 Tarayıcıdan İndir',
                onPressed: _openBrowserDownload,
                bgColor: AppColors.skyBlue.withValues(alpha: 0.3),
                pencilColor: pencilColor,
              ),
            ),
          ],
        ),
        if (!widget.updateInfo.forceUpdate) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _dismiss,
            child: Text(
              'Kapat',
              style: GoogleFonts.patrickHand(
                fontSize: 16,
                color: pencilColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Normal Başlangıç Butonları
  Widget _buildActionButtons(Color pencilColor, bool isDark) {
    return Column(
      children: [
        // Ana Güncelleme Butonu
        _SketchActionBtn(
          text: '⚡ Şimdi Güncelle',
          onPressed: () {
            HapticFeedback.mediumImpact();
            _startUpdate();
          },
          bgColor: AppColors.sunYellow,
          pencilColor: pencilColor,
          isBold: true,
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Doğrudan Tarayıcıdan İndir Linki
            InkWell(
              onTap: _openBrowserDownload,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_browser_rounded, size: 16, color: pencilColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'veya Tarayıcıdan İndir',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        color: pencilColor.withValues(alpha: 0.8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!widget.updateInfo.forceUpdate) ...[
              const SizedBox(width: 14),
              Text(
                '•',
                style: TextStyle(color: pencilColor.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 14),
              // Daha Sonra
              InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Daha Sonra',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14,
                      color: pencilColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Sürüm Rozeti
class _VersionBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isOld;

  const _VersionBadge({
    required this.label,
    required this.isDark,
    required this.isOld,
  });

  @override
  Widget build(BuildContext context) {
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final bg = isOld
        ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
        : AppColors.sunYellow.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pencilColor.withValues(alpha: isOld ? 0.3 : 0.8),
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.patrickHand(
          fontSize: 13,
          fontWeight: isOld ? FontWeight.normal : FontWeight.bold,
          color: pencilColor,
        ),
      ),
    );
  }
}

/// El Çizimi Buton Bileşeni
class _SketchActionBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color pencilColor;
  final bool isBold;

  const _SketchActionBtn({
    required this.text,
    required this.onPressed,
    required this.bgColor,
    required this.pencilColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pencilColor, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: pencilColor.withValues(alpha: 0.18),
                offset: const Offset(2.5, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.patrickHand(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: pencilColor,
            ),
          ),
        ),
      ),
    );
  }
}
