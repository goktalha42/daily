import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_avatar.dart';
import '../network/api_client.dart';

final userAvatarProvider = StateNotifierProvider<UserAvatarNotifier, String>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserAvatarNotifier(apiClient);
});

/// Aktif avatar modelini doğrudan sağlayan yardımcı provider
final currentAvatarModelProvider = Provider<UserAvatar>((ref) {
  final id = ref.watch(userAvatarProvider);
  return UserAvatar.getById(id);
});

class UserAvatarNotifier extends StateNotifier<String> {
  final ApiClient apiClient;
  static const String _avatarKey = 'zuhtu_user_avatar_id';

  UserAvatarNotifier(this.apiClient) : super(UserAvatar.defaultAvatarId) {
    _loadInitialAvatar();
  }

  Future<void> _loadInitialAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_avatarKey);
    if (saved != null && saved.trim().isNotEmpty) {
      state = saved.trim();
    }
  }

  Future<void> setAvatar(String newAvatarId) async {
    final trimmed = newAvatarId.trim();
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, trimmed);

    // Asenkron olarak arka planda sunucuya bildir
    apiClient.updateAvatar(trimmed);
  }
}

