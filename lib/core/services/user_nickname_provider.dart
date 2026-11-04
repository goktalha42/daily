import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

final userNicknameProvider = StateNotifierProvider<UserNicknameNotifier, String>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserNicknameNotifier(apiClient);
});

class UserNicknameNotifier extends StateNotifier<String> {
  final ApiClient apiClient;
  static const String _nicknameKey = 'zuhtu_user_nickname';

  UserNicknameNotifier(this.apiClient) : super('Oyuncu') {
    _loadInitialNickname();
  }

  Future<void> _loadInitialNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_nicknameKey);
    if (saved != null && saved.trim().isNotEmpty) {
      state = saved.trim();
    }
  }

  Future<void> setNickname(String newNickname) async {
    final trimmed = newNickname.trim();
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, trimmed);
  }
}

