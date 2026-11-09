import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_server_stats.dart';
import '../network/api_client.dart';
import 'user_nickname_provider.dart';

final playerStatsServiceProvider =
    StateNotifierProvider<PlayerStatsNotifier, PlayerServerStats>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final userNickname = ref.watch(userNicknameProvider);
  final notifier = PlayerStatsNotifier(apiClient: apiClient, userNickname: userNickname);
  notifier.initialize();
  return notifier;
});

class PlayerStatsNotifier extends StateNotifier<PlayerServerStats> {
  final ApiClient apiClient;
  final String userNickname;
  static const String _prefKey = 'zuhtu_player_server_stats_v1';
  bool _isRefreshing = false;

  PlayerStatsNotifier({
    required this.apiClient,
    required this.userNickname,
  }) : super(const PlayerServerStats());

  Future<void> initialize() async {
    await _loadFromLocal();
    await refreshStats();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = PlayerServerStats.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[PlayerStatsService] Yerel istatistik yükleme hatası: $e');
    }
  }

  /// Canlı sunucudan kullanıcının en güncel doğrulanmış istatistiklerini çeker
  Future<void> refreshStats() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final stats = await apiClient.fetchPlayerStats(nickname: userNickname);
      if (stats != null && stats.totalCareerScore >= state.totalCareerScore) {
        state = stats;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, jsonEncode(stats.toJson()));
      }
    } catch (e) {
      debugPrint('[PlayerStatsService] refreshStats hatası: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}
