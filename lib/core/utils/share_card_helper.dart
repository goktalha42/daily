import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Zühtü - Sosyal Medya (WhatsApp, Instagram, X vb.) Görsel Kart Paylaşım Yardımcısı.
/// RepaintBoundary ile sarılmış skeç kartları yüksek çözünürlüklü PNG'ye dönüştürüp
/// doğrudan yerel paylaşım menüsüne aktarır.
class ShareCardHelper {
  ShareCardHelper._();

  static String? lastError;

  static Future<void> _waitForPaintFrame() async {
    final binding = SchedulerBinding.instance;
    if (binding.hasScheduledFrame ||
        binding.schedulerPhase != SchedulerPhase.idle) {
      final completer = Completer<void>();
      binding.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future.timeout(
        const Duration(milliseconds: 250),
        onTimeout: () {},
      );
    }
    if (binding.hasScheduledFrame) {
      try {
        await binding.endOfFrame;
      } catch (_) {}
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 24));
    }
  }

  static bool _needsPaint(RenderRepaintBoundary boundary) {
    var needsPaint = false;
    assert(() {
      needsPaint = boundary.debugNeedsPaint;
      return true;
    }());
    return needsPaint;
  }

  /// Belirtilen [boundaryKey]'e sahip widget'ı PNG baytları olarak yakalar.
  static Future<Uint8List?> captureWidgetToPngBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    lastError = null;
    try {
      if (boundaryKey.currentContext == null) {
        lastError = 'Kart henüz ekrana bağlanmadı.';
        return null;
      }

      await _waitForPaintFrame();

      RenderRepaintBoundary? boundary;
      for (int attempt = 0; attempt < 8; attempt++) {
        final context = boundaryKey.currentContext;
        final ro = context?.findRenderObject();
        if (ro is RenderRepaintBoundary) {
          boundary = ro;
          if (boundary.attached &&
              boundary.hasSize &&
              !boundary.size.isEmpty &&
              !_needsPaint(boundary)) {
            break;
          }
        }
        if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          SchedulerBinding.instance.scheduleFrame();
        }
        await Future<void>.delayed(const Duration(milliseconds: 35));
        if (SchedulerBinding.instance.hasScheduledFrame) {
          try {
            await SchedulerBinding.instance.endOfFrame;
          } catch (_) {}
        }
      }

      if (boundary == null ||
          !boundary.attached ||
          !boundary.hasSize ||
          boundary.size.isEmpty) {
        lastError = 'Kart henüz çizilmedi.';
        return null;
      }

      if (_needsPaint(boundary)) {
        SchedulerBinding.instance.scheduleFrame();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        try {
          await SchedulerBinding.instance.endOfFrame;
        } catch (_) {}
      }

      final ratios = <double>{
        pixelRatio,
        2.0,
        1.5,
        1.0,
      }.where((r) => r <= pixelRatio).toList();

      for (final ratio in ratios) {
        ui.Image? image;
        try {
          image = await boundary.toImage(pixelRatio: ratio);
          final ByteData? byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null && byteData.lengthInBytes > 0) {
            return byteData.buffer.asUint8List();
          }
        } catch (e) {
          debugPrint('[ShareCardHelper] toImage ($ratio x) hatası: $e');
          lastError = '$e';
        } finally {
          image?.dispose();
        }
      }

      lastError ??= 'PNG baytları oluşturulamadı.';
      return null;
    } catch (e) {
      lastError = '$e';
      debugPrint('[ShareCardHelper] Görsel yakalama hatası: $e');
      return null;
    }
  }

  /// Belirtilen [boundaryKey]'e sahip widget'ı PNG olarak yakalar ve geçici dizine kaydeder.
  static Future<File?> captureWidgetToFile(
    GlobalKey boundaryKey, {
    String fileName = 'zuhtu_share.png',
    double pixelRatio = 3.0,
  }) async {
    try {
      final pngBytes = await captureWidgetToPngBytes(
        boundaryKey,
        pixelRatio: pixelRatio,
      );
      if (pngBytes == null || pngBytes.isEmpty) return null;

      Directory? targetDir;
      try {
        targetDir = await getTemporaryDirectory();
      } catch (_) {
        targetDir = await getApplicationCacheDirectory();
      }
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      lastError = '$e';
      debugPrint('[ShareCardHelper] Dosyaya yazma hatası: $e');
      return null;
    }
  }

  /// Görseli yakalayıp yerel paylaşım sayfası üzerinden kart görseli ve açıklama metni ile paylaşır.
  static Future<bool> shareCard({
    required GlobalKey boundaryKey,
    String? shareText,
    String? subject,
    String fileName = 'zuhtu_share.png',
  }) async {
    lastError = null;
    final effectiveSubject = subject ?? '🧠 Zühtü Günlük Zeka Karnesi';
    final effectiveText = (shareText != null && shareText.trim().isNotEmpty)
        ? shareText
        : 'Sen de zihnini sına 👉 https://zuhtuapp.cyboros.com';

    try {
      if (kIsWeb) {
        final pngBytes = await captureWidgetToPngBytes(boundaryKey);
        if (pngBytes != null && pngBytes.isNotEmpty) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
              text: effectiveText,
              subject: effectiveSubject,
              title: effectiveSubject,
            ),
          );
          return true;
        }
        return false;
      }

      final file = await captureWidgetToFile(boundaryKey, fileName: fileName);
      if (file != null && await file.exists() && await file.length() > 0) {
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
              text: effectiveText,
              subject: effectiveSubject,
              title: effectiveSubject,
            ),
          );
          return true;
        } catch (sharePlatformError) {
          debugPrint(
              '[ShareCardHelper] SharePlus platform hatası: $sharePlatformError');
          // Bazı Android cihazlarda/ROM'larda subject/title/mimeType ile chooser açılmazsa yalın parametrelerle tekrar dene
          try {
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                text: effectiveText,
              ),
            );
            return true;
          } catch (retryError) {
            debugPrint('[ShareCardHelper] SharePlus yalın tekrar hatası: $retryError');
          }
          // Masaüstü platformlarında (Windows/Linux/macOS) share sheet açılamazsa dosyayı görüntüleyicide aç
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            try {
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
                return true;
              }
            } catch (launchError) {
              debugPrint('[ShareCardHelper] launchUrl hatası: $launchError');
            }
          }
          lastError = '$sharePlatformError';
          return false;
        }
      }
      lastError ??= 'Kart görseli dosyaya yazılamadı.';
      return false;
    } catch (e) {
      lastError = '$e';
      debugPrint('[ShareCardHelper] Paylaşım hatası: $e');
      return false;
    }
  }
}

