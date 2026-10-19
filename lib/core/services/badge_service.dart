import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';
import '../utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'game_stats_service.dart';
import 'daily_play_service.dart';

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
    final DateTime? expires = (badgeDef.isTemporary && badgeDef.validityDays > 0)
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

  /// Rozeti kullanıcıdan geri alır (özellikle IQ 130 altına düştüğünde Einstein rozeti için).
  Future<void> revokeBadge(String badgeId) async {
    if (!state.containsKey(badgeId)) return;
    final updated = Map<String, UserBadge>.from(state);
    updated.remove(badgeId);
    state = updated;
    await _saveBadges();
  }

  /// Oyun tamamlandığında veya istatistik güncellendiğinde tüm rozet kurallarını değerlendirir.
  /// Yeni kazanılan rozetlerin listesini döner.
  Future<List<DailyBadge>> evaluateBadges({
    required GameType gameType,
    required int score,
    required int durationMs,
    required int overallIQ,
    required Map<GameType, GamePerformanceData> statsMap,
    DailyPlayState? dailyPlayState,
    String? difficulty,
    int? rank,
  }) async {
    final newlyAwarded = <DailyBadge>[];

    // 1. Einstein Zekâ Rozeti (130+ IQ korunduğu sürece aktif, 130 altına inildiğinde otomatik düşer)
    if (overallIQ >= 130) {
      if (await _tryAward('belt_einstein')) {
        newlyAwarded.add(_findDef('belt_einstein'));
      }
    } else {
      if (state.containsKey('belt_einstein')) {
        await revokeBadge('belt_einstein');
      }
    }

    // 2. Büyük Usta Rozeti (120+ IQ korunduğu sürece aktif, 120 altına inildiğinde otomatik düşer)
    if (overallIQ >= 120) {
      if (await _tryAward('belt_grandmaster')) {
        newlyAwarded.add(_findDef('belt_grandmaster'));
      }
    } else {
      if (state.containsKey('belt_grandmaster')) {
        await revokeBadge('belt_grandmaster');
      }
    }

    // 3. Zirve Hükümdarı Kemeri (#1 Sıra)
    if (rank != null && rank == 1) {
      if (await _tryAward('belt_daily_champion')) {
        newlyAwarded.add(_findDef('belt_daily_champion'));
      }
    }

    // 4. Kürsü Lideri Kemeri (Sıralamada ilk 3)
    if (rank != null && rank <= 3) {
      if (await _tryAward('belt_weekly_podium')) {
        newlyAwarded.add(_findDef('belt_weekly_podium'));
      }
    }

    // 5. Günün Şimşeği Kemeri (35 sn altı)
    if (durationMs > 0 && durationMs < 35000) {
      if (await _tryAward('belt_lightning')) {
        newlyAwarded.add(_findDef('belt_lightning'));
      }
    }

    // 6. Işık Hızı Efendisi (Kalıcı - 20 sn altı)
    if (durationMs > 0 && durationMs < 20000) {
      if (await _tryAward('badge_speed_demon')) {
        newlyAwarded.add(_findDef('badge_speed_demon'));
      }
    }

    // 7. Vezirler Şampiyonluk Kemeri (Vezirler Master Tamamlama)
    if (gameType == GameType.queens && difficulty == 'master') {
      if (await _tryAward('belt_queens_master')) {
        newlyAwarded.add(_findDef('belt_queens_master'));
      }
    }

    // 8. Gece Baykuşu Rozeti (00:00 - 04:00 saatleri arası)
    final nowHour = DateTime.now().hour;
    if (nowHour >= 0 && nowHour < 4) {
      if (await _tryAward('belt_night_owl')) {
        newlyAwarded.add(_findDef('belt_night_owl'));
      }
    }

    // 9. Erken Kalkan Deha (05:00 - 08:30 saatleri arası)
    if (nowHour >= 5 && nowHour < 9) {
      if (await _tryAward('belt_early_bird')) {
        newlyAwarded.add(_findDef('belt_early_bird'));
      }
    }

    // 10. Günün 6'da 6 Fatihi Kemeri
    if (dailyPlayState != null) {
      final todayCount = dailyPlayState.getCompletedCountForDate(GameDateUtils.getTodayLevelId());
      if (todayCount >= 6) {
        if (await _tryAward('belt_clean_sweep')) {
          newlyAwarded.add(_findDef('belt_clean_sweep'));
        }
      }
    }

    // 11. SERİ ROZETLERİ (Her oyun için ayrı ve genel seri)
    if (dailyPlayState != null) {
      final gameStreak = dailyPlayState.getMaxStreak(gameType);
      final allStreak = dailyPlayState.getMaxStreak(null);

      for (final tier in DailyBadge.streakTiers) {
        // İlgili oyun serisi
        if (gameStreak >= tier) {
          final badgeId = 'streak_${gameType.id}_$tier';
          if (await _tryAward(badgeId)) {
            newlyAwarded.add(_findDef(badgeId));
          }
        }

        // Genel zihin serisi
        if (allStreak >= tier) {
          final badgeId = 'streak_all_$tier';
          if (await _tryAward(badgeId)) {
            newlyAwarded.add(_findDef(badgeId));
          }
        }
      }
    }

    // 12. İlk Adım (Herhangi bir oyunu tamamlama)
    if (await _tryAward('badge_first_win')) {
      newlyAwarded.add(_findDef('badge_first_win'));
    }

    // 13. Dahi Kulübü (Kalıcı - 120+ IQ)
    if (overallIQ >= 120) {
      if (await _tryAward('badge_genius_club')) {
        newlyAwarded.add(_findDef('badge_genius_club'));
      }
    }

    // 14. Oyun Bazlı Ustalık Rozetleri (Her oyunda en az 3 galibiyet)
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

    // 15. Çok Yönlü Deha (6 farklı oyunun hepsinde galibiyet)
    final playedGamesCount = statsMap.values.where((p) => p.hasPlayed).length;
    if (playedGamesCount >= 6) {
      if (await _tryAward('badge_all_rounder')) {
        newlyAwarded.add(_findDef('badge_all_rounder'));
      }
    }

    // 16. 100'ler Kulübü (Toplam 100 oyun tamamlama)
    int totalAllPlayed = 0;
    for (final p in statsMap.values) {
      totalAllPlayed += p.totalGamesPlayed;
    }
    if (totalAllPlayed >= 100) {
      if (await _tryAward('badge_century_club')) {
        newlyAwarded.add(_findDef('badge_century_club'));
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

  /// Süreli rozetin kalan gün sayısını döner (-1: kalıcı veya kilitli, 0: koşullu dinamik).
  int remainingDays(String badgeId) {
    final ub = state[badgeId];
    if (ub == null || ub.isExpired) return 0;
    return ub.remainingDays;
  }
}
