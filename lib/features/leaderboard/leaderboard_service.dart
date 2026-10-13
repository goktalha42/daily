import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/daily_play_service.dart';
import '../../core/utils/date_utils.dart';
import '../../games/common/base_game.dart';

final leaderboardServiceProvider =
    ChangeNotifierProvider<LeaderboardService>((ref) {
  final service = LeaderboardService();
  ref.listen<DailyPlayState>(dailyPlayServiceProvider, (prev, next) {
    service.syncWithDailyPlay(next);
  });
  service.syncWithDailyPlay(ref.read(dailyPlayServiceProvider));
  return service;
});

class LeaderboardService extends ChangeNotifier {
  final List<GameResult> _resultsStore = [];

  // 150 Özgün ve Gerçekçi Türk Oyuncu İsmi
  static const List<String> _seedUserNames = [
    'ZekaUstadı', 'Ece_Y', 'AlperenK', 'BeyinFırtınası', 'Kerem34',
    'DenizA', 'ZeynepBulmaca', 'MatematikKurdu', 'HızlıDüşünür', 'ZühtüSever',
    'KraliçeHamlesi', 'PikselAvcısı', 'GizemliZeka', 'Bora_99', 'Canan_T',
    'Mert_Zeka', 'AyseBulmaca', 'Caner_K', 'SelinA', 'BurakAkıl',
    'Elif_D', 'EmreMatematik', 'GamzeY', 'Onur_34', 'DeryaB',
    'Tolga_Z', 'Busra_K', 'KaanUsta', 'Ceren_L', 'YigitBeyin',
    'Esra_T', 'Arda_Kral', 'MelisaV', 'KeremFırtına', 'Tugba_S',
    'SinanZihni', 'Gizem_N', 'BarisLogik', 'Hazal_E', 'VolkanA',
    'IremG', 'Oguzhan_K', 'Fatma_D', 'Serkan_99', 'BusraBulmaca',
    'Deniz_Mavi', 'Merve_A', 'Ege_Zeka', 'Damla_K', 'Umut_Logik',
    'Dilara_S', 'BatuhanB', 'Kubra_T', 'Eren_Z', 'Seyma_K',
    'Alper_G', 'Zeynep_Usta', 'Gokhan_42', 'Hande_B', 'Furkan_S',
    'Sena_M', 'Tarik_Z', 'Bilge_K', 'Koray_V', 'Asli_H',
    'Ilker_D', 'Yasemin_T', 'Cihan_K', 'Begum_S', 'Semih_Z',
    'Ozlem_A', 'Tayfun_R', 'Tugce_K', 'Erdem_M', 'Hale_Z',
    'Hakan_B', 'Seda_N', 'Okan_L', 'Leyla_K', 'Zafer_T',
    'Melike_G', 'Berk_Zeka', 'Ebru_S', 'Doruk_A', 'Ezgi_K',
    'Ufuk_99', 'Nur_B', 'Cem_Logik', 'Sumeyye_T', 'Murat_K',
    'Nilay_M', 'Samet_Z', 'Pelin_A', 'Fatih_G', 'Defne_S',
    'Taner_K', 'Rabia_T', 'Levent_Z', 'Beyza_K', 'Harun_B',
    'Aylin_D', 'Nihat_S', 'Hilal_M', 'Sercan_K', 'Ilayda_T',
    'Mesut_Z', 'Busra_V', 'Eray_A', 'Selvi_K', 'Anil_G',
    'Esma_B', 'Enes_T', 'Selen_Z', 'Gokce_M', 'Halil_K',
    'Berna_D', 'Taha_S', 'Melis_K', 'Ozan_Z', 'Pinar_T',
    'Yunus_B', 'Selcuk_A', 'Sukran_K', 'Ilknur_M', 'Kenan_Z',
    'Ecevit_T', 'Nazli_B', 'Ridvan_K', 'Sibel_S', 'Alim_Z',
    'Gulsah_A', 'Mahmut_T', 'Nihan_K', 'Orkun_B', 'Sevgi_Z',
    'Ramazan_S', 'Tutku_M', 'Sabri_A', 'Zehra_K', 'Utku_T',
    'Yeliz_B', 'Vedat_Z', 'Zuhal_S', 'Yavuz_K', 'Belgin_M',
    'Bilal_A', 'Sevda_T', 'Bora_Z', 'Nergis_K', 'Burcu_S',
  ];

  LeaderboardService() {
    _seedMockData();
  }

  void _seedMockData() {
    final activeDate = GameDateUtils.getActiveDate();
    final todayLevelId = GameDateUtils.getTodayLevelId();
    final rng = Random(42);

    for (int i = 0; i < _seedUserNames.length; i++) {
      final name = _seedUserNames[i];
      final userId = 'mock_user_$i';
      // User skill: 0 (en güçlü) -> 149 (başlangıç), ufak rastlantısallıkla
      final skillFactor = (150 - i) / 150.0;
      final jitter = (rng.nextDouble() - 0.5) * 0.08;
      final effectiveSkill = (skillFactor + jitter).clamp(0.05, 1.0);

      // 1. VEZİRLER (QUEENS) OYUNU
      // Kolay: Tüm 150 oyuncu oynar
      final kolayScore = (760 + (effectiveSkill * 230)).round();
      final kolayDuration = (16000 + ((1.0 - effectiveSkill) * 44000)).round();
      _resultsStore.add(
        GameResult(
          id: 'queens_kolay_$userId',
          gameType: GameType.queens,
          levelId: todayLevelId,
          userId: userId,
          userName: name,
          durationMs: kolayDuration,
          moveCount: 6 + rng.nextInt(4),
          score: kolayScore,
          completedAt: activeDate.subtract(Duration(minutes: 10 + i * 4)),
          difficulty: 'kolay',
        ),
      );

      // Zor: İlk 100 oyuncu oynar
      if (i < 100) {
        final zorScore = (980 + (effectiveSkill * 310)).round();
        final zorDuration = (32000 + ((1.0 - effectiveSkill) * 65000)).round();
        _resultsStore.add(
          GameResult(
            id: 'queens_zor_$userId',
            gameType: GameType.queens,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: zorDuration,
            moveCount: 8 + rng.nextInt(6),
            score: zorScore,
            completedAt: activeDate.subtract(Duration(minutes: 15 + i * 4)),
            difficulty: 'zor',
          ),
        );
      }

      // Master: İlk 50 oyuncu oynar
      if (i < 50) {
        final masterScore = (1250 + (effectiveSkill * 420)).round();
        final masterDuration = (55000 + ((1.0 - effectiveSkill) * 110000)).round();
        _resultsStore.add(
          GameResult(
            id: 'queens_master_$userId',
            gameType: GameType.queens,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: masterDuration,
            moveCount: 18 + rng.nextInt(10),
            score: masterScore,
            completedAt: activeDate.subtract(Duration(minutes: 20 + i * 4)),
            difficulty: 'master',
          ),
        );
      }

      // 2. DİĞER TÜM OYUNLAR (Pinpoint, Crossclimb, Tango, ZipPath, Patches)
      const otherGames = [
        GameType.pinpoint,
        GameType.crossclimb,
        GameType.tango,
        GameType.zipPath,
        GameType.patches,
      ];

      for (var game in otherGames) {
        final gameJitter = ((i * 13 + game.index * 29) % 50) / 50.0 - 0.5;
        final gameSkill = (effectiveSkill + gameJitter * 0.12).clamp(0.05, 1.0);
        final score = (620 + (gameSkill * 370)).round();
        final duration = (22000 + ((1.0 - gameSkill) * 68000)).round();

        _resultsStore.add(
          GameResult(
            id: '${game.id}_$userId',
            gameType: game,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: duration,
            moveCount: 12 + rng.nextInt(8),
            score: score,
            completedAt: activeDate.subtract(Duration(minutes: 5 + i * 3 + game.index * 7)),
          ),
        );
      }

      // 3. HAFTALIK VE AYLIK GEÇMİŞ VERİLER (Son 6 gün)
      for (int dayBack = 1; dayBack <= 6; dayBack++) {
        final pastDate = activeDate.subtract(Duration(days: dayBack));
        final pastLevelId = DateFormat('yyyy-MM-dd').format(pastDate);

        // Her gün oyuncuların %70'i katılmış gibi simüle edelim
        if ((i + dayBack) % 3 != 0) {
          // Queens Kolay
          _resultsStore.add(
            GameResult(
              id: 'queens_kolay_${userId}_d$dayBack',
              gameType: GameType.queens,
              levelId: pastLevelId,
              userId: userId,
              userName: name,
              durationMs: kolayDuration + rng.nextInt(5000),
              moveCount: 6,
              score: (kolayScore * 0.95).round(),
              completedAt: pastDate,
              difficulty: 'kolay',
            ),
          );

          if (i < 80) {
            _resultsStore.add(
              GameResult(
                id: 'queens_zor_${userId}_d$dayBack',
                gameType: GameType.queens,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: 45000,
                moveCount: 9,
                score: 1100,
                completedAt: pastDate,
                difficulty: 'zor',
              ),
            );
          }

          // Diğer oyunlar
          for (var game in otherGames) {
            _resultsStore.add(
              GameResult(
                id: '${game.id}_${userId}_d$dayBack',
                gameType: game,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: 40000 + rng.nextInt(20000),
                moveCount: 10,
                score: 750 + rng.nextInt(200),
                completedAt: pastDate,
              ),
            );
          }
        }
      }
    }
  }

  /// Yerel kullanıcının DailyPlayState kayıtlarını liderlik tablosu ile eşitler
  void syncWithDailyPlay(DailyPlayState dailyPlay) {
    if (dailyPlay.records.isEmpty) return;
    bool changed = false;

    for (final record in dailyPlay.records.values) {
      final resultId = 'user_local_${record.gameType.id}_${record.subKey ?? "main"}_${record.dateId}';
      final existingIndex = _resultsStore.indexWhere((r) => r.id == resultId);

      final result = GameResult(
        id: resultId,
        gameType: record.gameType,
        levelId: record.dateId,
        userId: 'user_local',
        userName: 'Oyuncu (Sen)',
        durationMs: record.durationMs,
        moveCount: 10,
        score: record.score,
        completedAt: record.completedAt,
        difficulty: record.subKey,
      );

      if (existingIndex >= 0) {
        if (_resultsStore[existingIndex].score != result.score ||
            _resultsStore[existingIndex].durationMs != result.durationMs) {
          _resultsStore[existingIndex] = result;
          changed = true;
        }
      } else {
        _resultsStore.add(result);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void submitScore(GameResult result) {
    final existingIndex = _resultsStore.indexWhere((r) =>
        r.userId == result.userId &&
        r.gameType == result.gameType &&
        r.levelId == result.levelId &&
        r.difficulty == result.difficulty);

    if (existingIndex >= 0) {
      if (result.score >= _resultsStore[existingIndex].score) {
        _resultsStore[existingIndex] = result;
      }
    } else {
      _resultsStore.add(result);
    }
    notifyListeners();
  }

  List<LeaderboardEntry> getLeaderboard({
    required GameType gameType,
    required LeaderboardTimeframe timeframe,
    String? difficulty,
    String? levelId,
  }) {
    final now = DateTime.now();
    final activeDate = GameDateUtils.getActiveDate();
    final targetLevelId = levelId ?? GameDateUtils.getTodayLevelId();

    // 1. Sonuçları filtrele
    final filtered = _resultsStore.where((r) {
      if (r.gameType != gameType) return false;
      if (difficulty != null && r.difficulty != difficulty) return false;

      if (timeframe == LeaderboardTimeframe.daily) {
        if (levelId != null) {
          return r.levelId == levelId;
        }
        return r.levelId == targetLevelId ||
            (r.completedAt.year == activeDate.year &&
                r.completedAt.month == activeDate.month &&
                r.completedAt.day == activeDate.day);
      } else if (timeframe == LeaderboardTimeframe.weekly) {
        return r.completedAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (timeframe == LeaderboardTimeframe.monthly) {
        return r.completedAt.isAfter(now.subtract(const Duration(days: 30)));
      }
      return true; // allTime
    }).toList();

    // 2. Kullanıcı bazında topla
    final Map<String, List<GameResult>> userMap = {};
    for (var res in filtered) {
      userMap.putIfAbsent(res.userId, () => []).add(res);
    }

    final entries = <LeaderboardEntry>[];

    // VEZİRLER (QUEENS) ÖZEL TOPLAM PUAN KURALI (Eğer belirli bir zorluk seçilmemişse):
    // "kolay, zor ve master seviyedeki oyuncuya ait bütün skorların toplamı olsun.
    // eğer oyuncu sadece kolayları oynamış ve diğerlerini oynamamış ise diğerleri de 0 olarak sayılsın."
    if (gameType == GameType.queens && difficulty == null) {
      userMap.forEach((userId, list) {
        final userName = list.first.userName;

        GameResult? findBestForDiff(String d) {
          final diffMatches = list.where((r) => r.difficulty == d);
          if (diffMatches.isEmpty) return null;
          return diffMatches.reduce((a, b) =>
              a.score > b.score ? a : (a.score == b.score && a.durationMs < b.durationMs ? a : b));
        }

        final kolay = findBestForDiff('kolay');
        final zor = findBestForDiff('zor');
        final master = findBestForDiff('master');

        final kolayScore = kolay?.score ?? 0;
        final zorScore = zor?.score ?? 0;
        final masterScore = master?.score ?? 0;

        final totalScore = kolayScore + zorScore + masterScore;
        final totalDuration = (kolay?.durationMs ?? 0) + (zor?.durationMs ?? 0) + (master?.durationMs ?? 0);
        final gamesPlayed = (kolay != null ? 1 : 0) + (zor != null ? 1 : 0) + (master != null ? 1 : 0);

        if (totalScore > 0 || gamesPlayed > 0) {
          entries.add(
            LeaderboardEntry(
              rank: 0,
              userId: userId,
              userName: userName,
              totalScore: totalScore,
              bestTimeMs: totalDuration,
              gamesPlayed: gamesPlayed,
            ),
          );
        }
      });
    } else {
      // DİĞER OYUNLAR VEYA BELİRLİ BİR VEZİRLER ZORLUĞU
      userMap.forEach((userId, list) {
        final userName = list.first.userName;
        if (timeframe == LeaderboardTimeframe.daily) {
          // Günlükte en iyi skor tekil alınır
          final best = list.reduce((a, b) =>
              a.score > b.score ? a : (a.score == b.score && a.durationMs < b.durationMs ? a : b));
          entries.add(
            LeaderboardEntry(
              rank: 0,
              userId: userId,
              userName: userName,
              totalScore: best.score,
              bestTimeMs: best.durationMs,
              gamesPlayed: 1,
            ),
          );
        } else {
          // Haftalık/Aylık/Genel: Toplam puan ve en iyi süre
          final totalScore = list.fold<int>(0, (sum, r) => sum + r.score);
          final bestTimeMs = list.map((r) => r.durationMs).reduce((a, b) => a < b ? a : b);
          entries.add(
            LeaderboardEntry(
              rank: 0,
              userId: userId,
              userName: userName,
              totalScore: totalScore,
              bestTimeMs: bestTimeMs,
              gamesPlayed: list.length,
            ),
          );
        }
      });
    }

    // 3. Sıralama: Önce toplam puan azalan, sonra süre artan
    entries.sort((a, b) {
      if (b.totalScore != a.totalScore) {
        return b.totalScore.compareTo(a.totalScore);
      }
      return a.bestTimeMs.compareTo(b.bestTimeMs);
    });

    // 4. Sıra numarası ata
    return List.generate(entries.length, (idx) {
      final e = entries[idx];
      return LeaderboardEntry(
        rank: idx + 1,
        userId: e.userId,
        userName: e.userName,
        totalScore: e.totalScore,
        bestTimeMs: e.bestTimeMs,
        gamesPlayed: e.gamesPlayed,
      );
    });
  }
}
