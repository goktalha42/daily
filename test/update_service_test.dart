import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:daily_games/core/services/update_service.dart';

void main() {
  group('UpdateService Unit Tests', () {
    test('compareSemver doğru sonuçlar verir', () {
      expect(UpdateService.compareSemver('1.0.3', '1.0.2'), 1);
      expect(UpdateService.compareSemver('1.0.2', '1.0.3'), -1);
      expect(UpdateService.compareSemver('1.0.2', '1.0.2'), 0);
      expect(UpdateService.compareSemver('v1.1.0', '1.0.9'), 1);
      expect(UpdateService.compareSemver('2.0.0', '1.99.99'), 1);
      expect(UpdateService.compareSemver('1.0.0', '1.0.0.0'), 0);
    });

    test('isRemoteNewer build numaralarını öncelikli değerlendirir', () {
      // Build numarası büyükse versiyon stringi ne olursa olsun yenidir
      expect(
        UpdateService.isRemoteNewer(
          localBuildNumber: 3,
          localVersion: '1.0.2',
          remoteBuildNumber: 4,
          remoteVersion: '1.0.3',
        ),
        isTrue,
      );

      // Build numarası küçükse eskidir
      expect(
        UpdateService.isRemoteNewer(
          localBuildNumber: 4,
          localVersion: '1.0.3',
          remoteBuildNumber: 3,
          remoteVersion: '1.0.2',
        ),
        isFalse,
      );

      // Build numaraları eşitse ve versiyon da eşitse yenisi yoktur
      expect(
        UpdateService.isRemoteNewer(
          localBuildNumber: 4,
          localVersion: '1.0.3',
          remoteBuildNumber: 4,
          remoteVersion: '1.0.3',
        ),
        isFalse,
      );

      // Build numaraları eşit ama semver büyükse
      expect(
        UpdateService.isRemoteNewer(
          localBuildNumber: 4,
          localVersion: '1.0.2',
          remoteBuildNumber: 4,
          remoteVersion: '1.0.3',
        ),
        isTrue,
      );
    });

    test('AppUpdateInfo.fromJson JSON verisini eksiksiz çözümler', () {
      final json = {
        'version': '1.0.3',
        'build_number': 4,
        'title': 'Yeni Sürüm!',
        'changelog': '• Hata düzeltmeleri',
        'apk_url': 'https://github.com/goktalha42/daily/releases/download/v1.0.3/Zuhtu_v1.0.3.apk',
        'release_url': 'https://github.com/goktalha42/daily/releases/tag/v1.0.3',
        'force_update': false,
      };

      final info = AppUpdateInfo.fromJson(
        json: json,
        currentVersion: '1.0.2',
        currentBuildNumber: 3,
      );

      expect(info.currentVersion, '1.0.2');
      expect(info.currentBuildNumber, 3);
      expect(info.remoteVersion, '1.0.3');
      expect(info.remoteBuildNumber, 4);
      expect(info.title, 'Yeni Sürüm!');
      expect(info.changelog, '• Hata düzeltmeleri');
      expect(info.isUpdateAvailable, isTrue);
      expect(info.forceUpdate, isFalse);
    });

    test('UpdateService mock HTTP istemcisiyle güncelleme yanıtını alır', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final mockData = {
        'version': '1.2.0',
        'build_number': 99,
        'title': 'Test Güncellemesi',
        'changelog': 'Test içeriği',
        'apk_url': 'https://example.com/Zuhtu.apk',
        'release_url': 'https://example.com/release',
        'force_update': false,
      };

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final info = await UpdateService.instance.checkForUpdate(httpClient: client);
      expect(info, isNotNull);
      expect(info!.remoteVersion, '1.2.0');
      expect(info.remoteBuildNumber, 99);
      expect(info.isUpdateAvailable, isTrue);
    });

    test('Oturum içi erteleme (dismissThisSession) doğru çalışır', () {
      expect(UpdateService.hasDismissedThisSession(42), isFalse);
      UpdateService.dismissThisSession(42);
      expect(UpdateService.hasDismissedThisSession(42), isTrue);
      expect(UpdateService.hasDismissedThisSession(43), isFalse);
    });
  });
}

