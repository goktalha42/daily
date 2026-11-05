import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Güncelleme Bilgisi Modeli
class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String remoteVersion;
  final int remoteBuildNumber;
  final String title;
  final String changelog;
  final String apkUrl;
  final String releaseUrl;
  final bool forceUpdate;
  final bool isUpdateAvailable;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.remoteVersion,
    required this.remoteBuildNumber,
    required this.title,
    required this.changelog,
    required this.apkUrl,
    required this.releaseUrl,
    this.forceUpdate = false,
    required this.isUpdateAvailable,
  });

  factory AppUpdateInfo.fromJson({
    required Map<String, dynamic> json,
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    final remoteVersion = (json['version'] ?? '1.0.0').toString().trim();
    final remoteBuildNumber = int.tryParse((json['build_number'] ?? '0').toString()) ?? 0;
    final title = (json['title'] ?? 'Yeni Güncelleme Mevcut!').toString();
    final changelog = (json['changelog'] ?? '').toString();
    final apkUrl = (json['apk_url'] ?? '').toString();
    final releaseUrl = (json['release_url'] ?? apkUrl).toString();
    final forceUpdate = json['force_update'] == true;

    final isNewer = UpdateService.isRemoteNewer(
      localBuildNumber: currentBuildNumber,
      localVersion: currentVersion,
      remoteBuildNumber: remoteBuildNumber,
      remoteVersion: remoteVersion,
    );

    return AppUpdateInfo(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      remoteVersion: remoteVersion,
      remoteBuildNumber: remoteBuildNumber,
      title: title,
      changelog: changelog,
      apkUrl: apkUrl,
      releaseUrl: releaseUrl,
      forceUpdate: forceUpdate,
      isUpdateAvailable: isNewer,
    );
  }
}

/// Otomatik Güncelleme Servisi (GitHub & VPS Destekli)
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Yedek sürüm sabitleri (PackageInfo çağrılamazsa fallback)
  static const String fallbackVersion = '1.0.3';
  static const int fallbackBuildNumber = 4;

  /// GitHub raw güncelleme URL'i (Genel açık repo)
  static const String githubVersionUrl =
      'https://raw.githubusercontent.com/goktalha42/daily/main/version.json';

  /// VPS yedek kontrol URL'i
  static const String vpsVersionUrl =
      'http://2.56.109.165/api/v1/app-version';

  /// Bu oturumda kullanıcının "Daha Sonra" dediği build numarası
  static int? _dismissedBuildNumberInSession;

  /// Bu oturumda kullanıcı bu güncellemeyi kapattı mı?
  static bool hasDismissedThisSession(int buildNumber) {
    return _dismissedBuildNumberInSession == buildNumber;
  }

  /// Güncellemeyi bu oturum için ertele
  static void dismissThisSession(int buildNumber) {
    _dismissedBuildNumberInSession = buildNumber;
  }

  /// Semver veya Build Number karşılaştırması
  static bool isRemoteNewer({
    required int localBuildNumber,
    required String localVersion,
    required int remoteBuildNumber,
    required String remoteVersion,
  }) {
    // 1. Öncelik: Build numarası
    if (remoteBuildNumber > 0 && localBuildNumber > 0) {
      if (remoteBuildNumber > localBuildNumber) return true;
      if (remoteBuildNumber < localBuildNumber) return false;
    }

    // 2. Build numaraları eşitse veya yoksa Semver karşılaştır
    return compareSemver(remoteVersion, localVersion) > 0;
  }

  /// İki semver sürümünü karşılaştırır (1: a > b, -1: a < b, 0: a == b)
  static int compareSemver(String a, String b) {
    // Varsa 'v' harfini temizle
    final cleanA = a.replaceAll(RegExp(r'^[vV]'), '').trim();
    final cleanB = b.replaceAll(RegExp(r'^[vV]'), '').trim();

    final partsA = cleanA.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final partsB = cleanB.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (int i = 0; i < maxLen; i++) {
      final partA = i < partsA.length ? partsA[i] : 0;
      final partB = i < partsB.length ? partsB[i] : 0;
      if (partA > partB) return 1;
      if (partA < partB) return -1;
    }
    return 0;
  }

  /// Mevcut uygulama sürüm bilgilerini alır
  Future<({String version, int buildNumber})> getInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? fallbackBuildNumber;
      return (version: info.version.isNotEmpty ? info.version : fallbackVersion, buildNumber: build);
    } catch (e) {
      debugPrint('[UpdateService] PackageInfo alınamadı, fallback kullanılıyor: $e');
      return (version: fallbackVersion, buildNumber: fallbackBuildNumber);
    }
  }

  /// Güncelleme olup olmadığını kontrol eder
  Future<AppUpdateInfo?> checkForUpdate({
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final installed = await getInstalledVersion();

    // 1. Önce GitHub raw version.json üzerinden dene (önbellek engellemek için timestamp parametresi)
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final githubUri = Uri.parse('$githubVersionUrl?t=$cacheBuster');

    try {
      final response = await client
          .get(githubUri)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(
          json: data,
          currentVersion: installed.version,
          currentBuildNumber: installed.buildNumber,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] GitHub üzerinden güncelleme sorgulanamadı: $e');
    }

    // 2. GitHub ulaşılamazsa VPS yedek endpointini dene
    try {
      final vpsUri = Uri.parse('$vpsVersionUrl?t=$cacheBuster');
      final response = await client
          .get(vpsUri)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(
          json: data,
          currentVersion: installed.version,
          currentBuildNumber: installed.buildNumber,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] VPS yedek güncelleme kontrolü de başarısız: $e');
    }

    return null;
  }

  /// OTA Güncelleme indirme ve yükleme akışını başlatır
  Stream<OtaEvent> startOtaUpdate(String apkUrl) {
    return OtaUpdate().execute(
      apkUrl,
      destinationFilename: 'Zuhtu.apk',
    );
  }
}

