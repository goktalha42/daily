import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHapticState {
  final bool soundEnabled;
  final bool hapticEnabled;

  const SoundHapticState({
    this.soundEnabled = true,
    this.hapticEnabled = true,
  });

  SoundHapticState copyWith({
    bool? soundEnabled,
    bool? hapticEnabled,
  }) {
    return SoundHapticState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}

/// Kara Kalem Eskiz Defteri Ses Efektleri (SFX) ve Dokunsal Geri Bildirim (Haptic) Servisi.
class SoundHapticService {
  SoundHapticService._();
  static final SoundHapticService instance = SoundHapticService._();

  static const _soundPrefKey = 'zuhtu_sfx_enabled_v1';
  static const _hapticPrefKey = 'zuhtu_haptic_enabled_v1';
  static const MethodChannel _channel =
      MethodChannel('com.dailygames.daily_games/retention');

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _loaded = false;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  Future<SoundHapticState> ensureLoaded() async {
    if (_loaded) {
      return SoundHapticState(
        soundEnabled: _soundEnabled,
        hapticEnabled: _hapticEnabled,
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_soundPrefKey) ?? true;
      _hapticEnabled = prefs.getBool(_hapticPrefKey) ?? true;
      _loaded = true;
    } catch (_) {}
    return SoundHapticState(
      soundEnabled: _soundEnabled,
      hapticEnabled: _hapticEnabled,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundPrefKey, enabled);
    } catch (_) {}
    if (enabled) {
      await playPencilTap();
    }
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticPrefKey, enabled);
    } catch (_) {}
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Kalem dokunuşu / hücre seçimi / çarpı işaretleme
  Future<void> playPencilTap() async {
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    if (_soundEnabled) {
      await _triggerSound('pencilTap');
    }
  }

  /// Vezir, Güneş/Ay, Harf veya Alan yerleştirme
  Future<void> playSymbolPlace() async {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_soundEnabled) {
      await _triggerSound('symbolPlace');
    }
  }

  /// Silgi / geri alma (Undo) / temizleme
  Future<void> playErase() async {
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    if (_soundEnabled) {
      await _triggerSound('erase');
    }
  }

  /// Kural hatası / yanlış tahmin
  Future<void> playError() async {
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (_soundEnabled) {
      await _triggerSound('error');
    }
  }

  /// Oyun kazanıldığında kutlama fanfarı
  Future<void> playVictory({bool isMilestoneOrPersonalBest = false}) async {
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (_soundEnabled) {
      await _triggerSound(isMilestoneOrPersonalBest ? 'milestone' : 'victory');
    }
  }

  Future<void> _triggerSound(String type) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('playSound', {'type': type});
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {
      // Test veya desteklenmeyen platformlarda sessizce geç
    }
  }
}

class SoundHapticNotifier extends StateNotifier<SoundHapticState> {
  SoundHapticNotifier() : super(const SoundHapticState()) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await SoundHapticService.instance.ensureLoaded();
    state = loaded;
  }

  Future<void> toggleSound() async {
    final next = !state.soundEnabled;
    await SoundHapticService.instance.setSoundEnabled(next);
    state = state.copyWith(soundEnabled: next);
  }

  Future<void> toggleHaptic() async {
    final next = !state.hapticEnabled;
    await SoundHapticService.instance.setHapticEnabled(next);
    state = state.copyWith(hapticEnabled: next);
  }
}

final soundHapticProvider =
    StateNotifierProvider<SoundHapticNotifier, SoundHapticState>((ref) {
  return SoundHapticNotifier();
});

