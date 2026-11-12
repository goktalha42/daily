import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkCheckerProvider = StateNotifierProvider<NetworkCheckerNotifier, bool>((ref) {
  return NetworkCheckerNotifier();
});

class NetworkCheckerNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkCheckerNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateState(results);
    } catch (_) {
      state = true; // Fallback to online in case of permission issues
    }

    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    // Tarayıcılarda (Web) masaüstü/VPN ağları genellikle ConnectivityResult.other döner.
    final isOnline = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn ||
        (kIsWeb && result == ConnectivityResult.other));

    state = isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
