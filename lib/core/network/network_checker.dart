import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkCheckerProvider =
    StateNotifierProvider<NetworkCheckerNotifier, bool>((ref) {
  return NetworkCheckerNotifier();
});

class NetworkCheckerNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkCheckerNotifier({bool initialState = true}) : super(initialState) {
    _init();
  }

  static bool _hasActiveInterface(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn ||
        (kIsWeb && result == ConnectivityResult.other));
  }

  /// Gerçek internet erişimini doğrular (Wi-Fi açık ama internet yoksa yakalar).
  static Future<bool> _verifyInternetAccess(
      List<ConnectivityResult> results) async {
    if (!_hasActiveInterface(results)) {
      return false;
    }
    if (kIsWeb) {
      return true;
    }
    try {
      final socket = await Socket.connect(
        '2.56.109.165',
        80,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } on SocketException {
      // Sunucu erişilemezse genel DNS kontrolü ile gerçek internet varlığını doğrula
      try {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return true;
    }
  }

  /// Uygulama açılışında (runApp öncesi) internet durumunu senkronize kontrol eder.
  static Future<bool> checkInitialConnectivity() async {
    try {
      final results = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      return await _verifyInternetAccess(results);
    } catch (_) {
      return true;
    }
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateState(results);
    } catch (_) {
      // Test ortamı veya eklenti erişim hatasında mevcut durumu koru
    }

    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  Future<void> _updateState(List<ConnectivityResult> results) async {
    if (!_hasActiveInterface(results)) {
      if (mounted) state = false;
      return;
    }
    final reachable = await _verifyInternetAccess(results);
    if (mounted) {
      state = reachable;
    }
  }

  /// Kullanıcı "Bağlantıyı Kontrol Et" butonuna bastığında anlık doğrulama yapar.
  Future<bool> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final reachable = await _verifyInternetAccess(results);
      if (mounted) {
        state = reachable;
      }
      return reachable;
    } catch (_) {
      return state;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
