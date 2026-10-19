import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';
import '../../games/common/base_game.dart';
import 'game_stats_service.dart';

final badgeServiceProvider = StateNotifierProvider<BadgeNotifier, Map<String, UserBadge>>((ref) {
  return BadgeNotifier();
});

class BadgeNotifier extends StateNotifier<Map<String, UserBadge>> {
  static const _prefKey = 'daily_user_badges_v2';

  BadgeNotifier() : super({}) {
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final map = <String, UserBadge>{};
        for (final entry in decoded.entries) {
          map[entry.key] = UserBadge.fromJson(entry.value as Map<String, dynamic>);
        }
        state = map;
      }
    } catch (_) {}
  }

  Future<void> _saveBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (var e in state.entries) e.key: e.value.toJson(),
      };
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (_) {}
  }

  /// Belirtilen rozeti kullanıcıya verir veya süreli rozetin geçerliliğini yeniler.
  /// Eğer rozet ilk defa açıldıysa true döner.
  Future<bool> awardBadge(String badgeId) async {
    final badgeDef = DailyBadge.allBadges.firstWhere(
      (b) => b.id == badgeId,
      orElse: () => throw ArgumentError('Bilinmeyen rozet: $badgeId'),
    );

    final now = DateTime.now();
    final DateTime? expires = badgeDef.isTemporary
        ? now.add(Duration(days: badgeDef.validityDays))
        : null;

    final isNew = !state.containsKey(badgeId) || (badgeDef.isTemporary && state[badgeId]!.isExpired);

    final updated = Map<String, UserBadge>.from(state);
    updated[badgeId] = UserBadge(
      badgeId: badgeId,
      unlockedAt: state[badgeId]?.unlockedAt ?? now,
      expiresAt: expires,
    );

    state = updated;
    await _saveBadges();
    return isNew;
  }

  /// Oyun tamamlandığında veya istatistik güncellendiğinde tüm rozet kurallarını değerlendirir.
  /// Yeni kazanılan rozetlerin listesini döner.
  Future<List<DailyBadge>> evaluateBadges({
    required GameType gameType,
    required int score,
    required int durationMs,
    required int overallIQ,
    required Map<GameType, GamePerformanceData> statsMap,
    String? difficulty,
    int? rank,
  }) async {
    final newlyAwarded = <DailyBadge>[];

    // 1. İlk Adım (Herhangi bir oyunu tamamlama)
    if (await _tryAward('badge_first_win')) {
      newlyAwarded.add(_findDef('badge_first_win'));
    }

    // 2. Günün Şimşeği Kemeri (Süreli - 35 sn altı)
    if (durationMs > 0 && durationMs < 35000) {
      if (await _tryAward('belt_lightning')) {
        newlyAwarded.add(_findDef('belt_lightning'));
      }
    }

    // 3. Vezirler Şampiyonluk Kemeri (Süreli - Vezirler Master Tamamlama)
    if (gameType == GameType.queens && difficulty == 'master') {
      if (await _tryAward('belt_queens_master')) {
        newlyAwarded.add(_findDef('belt_queens_master'));
      }
    }

    // 4. Kürsü Lideri Kemeri (Süreli - Sıralamada ilk 3)
    if (rank != null && rank <= 3) {
      if (await _tryAward('belt_weekly_podium')) {
        newlyAwarded.add(_findDef('belt_weekly_podium'));
      }
    }

    // 5. Einstein Zekâ Kemeri (Süreli - 130+ IQ)
    if (overallIQ >= 130) {
      if (await _tryAward('belt_einstein')) {
        newlyAwarded.add(_findDef('belt_einstein'));
      }
    }

    // 6. Dahi Kulübü (Kalıcı - 120+ IQ)
    if (overallIQ >= 120) {
      if (await _tryAward('badge_genius_club')) {
        newlyAwarded.add(_findDef('badge_genius_club'));
      }
    }

    // 7. Oyun Bazlı Ustalık Rozetleri (Her oyunda en az 3 galibiyet)
    final gamePlayed = statsMap[gameType]?.totalGamesPlayed ?? 0;
    if (gamePlayed >= 3) {
      String? masteryBadgeId;
      switch (gameType) {
        case GameType.queens:
          masteryBadgeId = 'badge_queens_mastery';
          break;
        case GameType.pinpoint:
          masteryBadgeId = 'badge_pinpoint_mastery';
          break;
        case GameType.crossclimb:
          masteryBadgeId = 'badge_crossclimb_mastery';
          break;
        case GameType.tango:
          masteryBadgeId = 'badge_tango_mastery';
          break;
        case GameType.zipPath:
          masteryBadgeId = 'badge_zip_mastery';
          break;
        case GameType.patches:
          masteryBadgeId = 'badge_patches_mastery';
          break;
      }
      if (await _tryAward(masteryBadgeId)) {
        newlyAwarded.add(_findDef(masteryBadgeId));
      }
    }

    // 8. Çok Yönlü Deha (6 farklı oyunun hepsinde galibiyet)
    final playedGamesCount = statsMap.values.where((p) => p.hasPlayed).length;
    if (playedGamesCount >= 6) {
      if (await _tryAward('badge_all_rounder')) {
        newlyAwarded.add(_findDef('badge_all_rounder'));
      }
    }

    return newlyAwarded;
  }

  Future<bool> _tryAward(String badgeId) async {
    return await awardBadge(badgeId);
  }

  DailyBadge _findDef(String id) {
    return DailyBadge.allBadges.firstWhere((b) => b.id == id);
  }

  /// Aktif olan (süresi geçmemiş) rozetleri döner.
  List<UserBadge> get activeBadges {
    return state.values.where((b) => !b.isExpired).toList();
  }

  /// Bir rozetin kilidinin açık olup olmadığını kontrol eder.
  bool isUnlocked(String badgeId) {
    final ub = state[badgeId];
    if (ub == null) return false;
    return !ub.isExpired;
  }

  /// Süreli rozetin kalan gün sayısını döner (-1: kalıcı veya kilitli).
  int remainingDays(String badgeId) {
    final ub = state[badgeId];
    if (ub == null || ub.isExpired) return 0;
    return ub.remainingDays;
  }
}
