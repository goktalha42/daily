import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Zühtü - Sosyal Medya (WhatsApp, Instagram, X vb.) Görsel Kart Paylaşım Yardımcısı.
/// RepaintBoundary ile sarılmış skeç kartları yüksek çözünürlüklü (3x) PNG'ye dönüştürüp
/// doğrudan yerel paylaşım menüsüne aktarır.
class ShareCardHelper {
  ShareCardHelper._();

  /// Belirtilen [boundaryKey]'e sahip widget'ı PNG olarak yakalar ve geçici dizine kaydeder.
  static Future<File?> captureWidgetToFile(
    GlobalKey boundaryKey, {
    String fileName = 'zuhtu_share.png',
    double pixelRatio = 3.0,
  }) async {
    try {
      final context = boundaryKey.currentContext;
      if (context == null) return null;

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Eğer widget henüz tam çizilmediyse bir frame bekle
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('[ShareCardHelper] Görsel yakalama hatası: $e');
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
    try {
      final file = await captureWidgetToFile(boundaryKey, fileName: fileName);
      if (file != null && await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ShareCardHelper] Paylaşım hatası: $e');
      return false;
    }
  }
}

