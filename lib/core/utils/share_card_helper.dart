import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Zühtü - Sosyal Medya (WhatsApp, Instagram, X vb.) Görsel Kart Paylaşım Yardımcısı.
/// RepaintBoundary ile sarılmış skeç kartları yüksek çözünürlüklü PNG'ye dönüştürüp
/// doğrudan yerel paylaşım menüsüne aktarır.
class ShareCardHelper {
  ShareCardHelper._();

  static String? lastError;

  static Future<void> _waitForPaintFrame() async {
    final binding = SchedulerBinding.instance;
    if (binding.hasScheduledFrame || binding.schedulerPhase != SchedulerPhase.idle) {
      final completer = Completer<void>();
      binding.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future.timeout(
        const Duration(milliseconds: 120),
        onTimeout: () {},
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 24));
    }
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
      for (int attempt = 0; attempt < 4; attempt++) {
        final context = boundaryKey.currentContext;
        boundary = context?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null &&
            boundary.attached &&
            boundary.hasSize &&
            !boundary.size.isEmpty &&
            !boundary.debugNeedsPaint) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      if (boundary == null ||
          !boundary.attached ||
          !boundary.hasSize ||
          boundary.size.isEmpty) {
        lastError = 'Kart henüz çizilmedi.';
        return null;
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

      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      lastError = '$e';
      debugPrint('[ShareCardHelper] Dosyaya yazma hatası: $e');
      return null;
    }
  }

  /// Görseli yakalayıp yerel paylaşım sayfası üzerinden sadece kart görseli olarak paylaşır.
  static Future<bool> shareCard({
    required GlobalKey boundaryKey,
    String? shareText,
    String? subject,
    String fileName = 'zuhtu_share.png',
  }) async {
    lastError = null;
    try {
      if (kIsWeb) {
        final pngBytes = await captureWidgetToPngBytes(boundaryKey);
        if (pngBytes != null && pngBytes.isNotEmpty) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
            ),
          );
          return true;
        }
        return false;
      }
      final file = await captureWidgetToFile(boundaryKey, fileName: fileName);
      if (file != null && await file.exists() && await file.length() > 0) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      lastError = '$e';
      debugPrint('[ShareCardHelper] Paylaşım hatası: $e');
      return false;
    }
  }
}

