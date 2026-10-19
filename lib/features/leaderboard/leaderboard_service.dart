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

  static int _excess(int value) => value > 0 ? value : 0;

  LeaderboardService() {
    _seedMockData();
  }

  void _seedMockData() {
    final activeDate = GameDateUtils.getActiveDate();
    final todayLevelId = GameDateUtils.getTodayLevelId();

    const allOtherGames = [
      GameType.pinpoint,
      GameType.crossclimb,
      GameType.tango,
      GameType.zipPath,
      GameType.patches,
    ];

    // Geçmiş günler simülasyon haritası:
    // Haftalık: 1..6 gün önce
    // Aylık: 7..29 gün aralığından örnekleme (11 gün)
    // Genel (Tüm Zamanlar): 32..95 gün aralığından örnekleme (10 gün)
    const weeklyDays = [1, 2, 3, 4, 5, 6];
    const monthlyExtraDays = [8, 10, 12, 14, 16, 18, 21, 23, 25, 27, 29];
    const allTimeExtraDays = [33, 38, 43, 49, 55, 62, 70, 78, 86, 95];

    for (int i = 0; i < _seedUserNames.length; i++) {
      final name = _seedUserNames[i];
      final userId = 'mock_user_$i';

      // Katılım sıklığı dilimleri:
      // Tier 1 (ilk 25): %90 katılım, neredeyse her gün oynar
      // Tier 2 (25..65): %75 katılım
      // Tier 3 (65..115): %50 katılım
      // Tier 4 (115..150): %30 katılım
      final double weeklyRate = i < 25 ? 0.90 : (i < 65 ? 0.75 : (i < 115 ? 0.50 : 0.30));
      final double monthlyRate = i < 25 ? 0.85 : (i < 65 ? 0.70 : (i < 115 ? 0.45 : 0.25));
      final double allTimeRate = i < 25 ? 0.85 : (i < 65 ? 0.65 : (i < 115 ? 0.40 : 0.20));

      // --- 1. BUGÜN (GÜNLÜK) OYUNLARI ---
      // A) VEZİRLER (Queens)
      // Gerçekçi katılım: Herkes 3 seviyeyi birden oynamaz!
      // - Kolay: ~110 oyuncu oynar
      // - Zor: ~40 oyuncu oynar
      // - Master: ~18 oyuncu oynar
      // - 3 seviyeyi birden (Kolay + Zor + Master) sadece en iddialı ~12 oyuncu tamamlar!
      final playsKolay = true;
      final playsZor = i < 100;
      final playsMaster = i < 50;

      // Kolay:
      if (playsKolay) {
        final kolayDuration = (12200 + i * 360 + ((i * 13) % 240)).round();
        final kolaySec = (kolayDuration / 1000).ceil();
        final excessMoves = _excess((i - 20) ~/ 15);
        final kolayScore = (900 - kolaySec * 2 - excessMoves * 2).clamp(400, 880);
        _resultsStore.add(
          GameResult(
            id: 'queens_kolay_$userId',
            gameType: GameType.queens,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: kolayDuration,
            moveCount: 18 + excessMoves,
            score: kolayScore,
            completedAt: activeDate.subtract(Duration(minutes: 10 + (i * 4) % 400)),
            difficulty: 'kolay',
          ),
        );
      }

      // Zor:
      if (playsZor) {
        final zorDuration = (24000 + i * 580 + ((i * 17) % 320)).round();
        final zorSec = (zorDuration / 1000).ceil();
        final excessMoves = _excess((i - 15) ~/ 10);
        final zorScore = (1200 - zorSec * 2 - excessMoves * 2).clamp(500, 1160);
        _resultsStore.add(
          GameResult(
            id: 'queens_zor_$userId',
            gameType: GameType.queens,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: zorDuration,
            moveCount: 24 + excessMoves,
            score: zorScore,
            completedAt: activeDate.subtract(Duration(minutes: 15 + (i * 4) % 400)),
            difficulty: 'zor',
          ),
        );
      }

      // Master:
      // Master'da i=0 için süre 18s -> timePenalty 36 -> 1350 - 36 = 1314 P (> 1300)
      if (playsMaster) {
        final masterDuration = (18000 + i * 920 + ((i * 19) % 380)).round();
        final masterSec = (masterDuration / 1000).ceil();
        final excessMoves = _excess((i - 10) ~/ 6);
        final masterScore = (1350 - masterSec * 2 - excessMoves * 2).clamp(600, 1315);
        _resultsStore.add(
          GameResult(
            id: 'queens_master_$userId',
            gameType: GameType.queens,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: masterDuration,
            moveCount: 54 + excessMoves,
            score: masterScore,
            completedAt: activeDate.subtract(Duration(minutes: 20 + (i * 4) % 400)),
            difficulty: 'master',
          ),
        );
      }

      // B) DİĞER TÜM OYUNLAR (Bugün)
      // Süreler ve puanlar birbiriyle %100 uyumlu: Süresi daha iyi olanın puanı ve sırası DAHA İYİDİR.
      for (final game in allOtherGames) {
        final baseOffset = (game.index * 7) % 11;
        final duration = (13000 + (i * 420) + ((i * 23 + baseOffset * 100) % 300)).round();
        final sec = (duration / 1000).ceil();

        int score;
        int moveCount = 10;
        switch (game) {
          case GameType.pinpoint:
            final clues = i < 15 ? 1 : (i < 55 ? 2 : (i < 105 ? 3 : 4));
            final wrong = i < 25 ? 0 : (i < 80 ? 1 : 2);
            score = (2000 - clues * 250 - wrong * 100 - sec * 5).clamp(200, 1920);
            moveCount = clues + wrong;
            break;
          case GameType.crossclimb:
            final wrong = i < 30 ? 0 : (i < 90 ? 1 : 2);
            score = (2000 - sec * 6 - wrong * 50).clamp(200, 1920);
            moveCount = 5 + wrong;
            break;
          case GameType.tango:
            final excessMoves = _excess((i - 20) ~/ 12);
            score = (2000 - sec * 10 - excessMoves * 4).clamp(200, 1910);
            moveCount = 22 + excessMoves;
            break;
          case GameType.zipPath:
            score = (2000 - sec * 10).clamp(200, 1920);
            moveCount = 1;
            break;
          case GameType.patches:
            final excessRects = _excess((i - 25) ~/ 14);
            score = (2000 - sec * 10 - excessRects * 5).clamp(200, 1910);
            moveCount = 7 + excessRects;
            break;
          default:
            score = (2000 - sec * 10).clamp(200, 1920);
        }

        _resultsStore.add(
          GameResult(
            id: '${game.id}_$userId',
            gameType: game,
            levelId: todayLevelId,
            userId: userId,
            userName: name,
            durationMs: duration,
            moveCount: moveCount,
            score: score,
            completedAt: activeDate.subtract(Duration(minutes: 8 + (i * 3 + game.index * 11) % 480)),
          ),
        );
      }

      // --- 2. GEÇMİŞ GÜNLER SİMÜLASYONU (HAFTALIK, AYLIK, GENEL) ---
      void seedPastDays(List<int> daysList, double participationRate, String prefix) {
        for (final dayBack in daysList) {
          final roll = ((i * 37 + dayBack * 19) % 100) / 100.0;
          if (roll > participationRate) continue;

          final pastDate = activeDate.subtract(Duration(days: dayBack));
          final pastLevelId = DateFormat('yyyy-MM-dd').format(pastDate);

          // Queens Kolay
          final pPlaysKolay = i < 80 || (i % 2 == 0);
          if (pPlaysKolay) {
            final pKolayDur = (12500 + i * 380 + ((i * 17 + dayBack * 71) % 260)).round();
            final pKolaySec = (pKolayDur / 1000).ceil();
            final pExcessMoves = _excess((i - 20) ~/ 15);
            final pKolayScore = (900 - pKolaySec * 2 - pExcessMoves * 2).clamp(400, 880);
            _resultsStore.add(
              GameResult(
                id: 'queens_kolay_${userId}_${prefix}_d$dayBack',
                gameType: GameType.queens,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: pKolayDur,
                moveCount: 18 + pExcessMoves,
                score: pKolayScore,
                completedAt: pastDate.add(Duration(hours: 9 + (i * 5) % 13, minutes: (i * 11) % 60)),
                difficulty: 'kolay',
              ),
            );
          }

          // Queens Zor
          final pPlaysZor = i < 22 || (i % 3 == 0 && i < 75);
          if (pPlaysZor && (i + dayBack) % 4 != 0) {
            final pZorDur = (25000 + i * 600 + ((i * 19 + dayBack * 53) % 340)).round();
            final pZorSec = (pZorDur / 1000).ceil();
            final pExcessMoves = _excess((i - 15) ~/ 10);
            final pZorScore = (1200 - pZorSec * 2 - pExcessMoves * 2).clamp(500, 1160);
            _resultsStore.add(
              GameResult(
                id: 'queens_zor_${userId}_${prefix}_d$dayBack',
                gameType: GameType.queens,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: pZorDur,
                moveCount: 24 + pExcessMoves,
                score: pZorScore,
                completedAt: pastDate.add(Duration(hours: 10 + (i * 5) % 12, minutes: (i * 13) % 60)),
                difficulty: 'zor',
              ),
            );
          }

          // Queens Master (Sadece elit oyuncular)
          final pPlaysMaster = i < 12 || (i % 7 == 0 && i < 50);
          if (pPlaysMaster && (i + dayBack) % 3 != 0) {
            final pMasterDur = (19000 + i * 950 + ((i * 23 + dayBack * 47) % 390)).round();
            final pMasterSec = (pMasterDur / 1000).ceil();
            final pExcessMoves = _excess((i - 10) ~/ 6);
            final pMasterScore = (1350 - pMasterSec * 2 - pExcessMoves * 2).clamp(600, 1315);
            _resultsStore.add(
              GameResult(
                id: 'queens_master_${userId}_${prefix}_d$dayBack',
                gameType: GameType.queens,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: pMasterDur,
                moveCount: 54 + pExcessMoves,
                score: pMasterScore,
                completedAt: pastDate.add(Duration(hours: 11 + (i * 5) % 11, minutes: (i * 17) % 60)),
                difficulty: 'master',
              ),
            );
          }

          // Diğer tüm oyunlar
          for (final game in allOtherGames) {
            if ((i + dayBack * 3 + game.index * 7) % 5 == 0) continue;

            final duration = (13500 + i * 440 + ((i * 29 + dayBack * 37 + game.index * 83) % 320)).round();
            final sec = (duration / 1000).ceil();

            int score;
            int moveCount = 10;
            switch (game) {
              case GameType.pinpoint:
                final clues = i < 15 ? 1 : (i < 55 ? 2 : (i < 105 ? 3 : 4));
                final wrong = i < 25 ? 0 : (i < 80 ? 1 : 2);
                score = (2000 - clues * 250 - wrong * 100 - sec * 5).clamp(200, 1920);
                moveCount = clues + wrong;
                break;
              case GameType.crossclimb:
                final wrong = i < 30 ? 0 : (i < 90 ? 1 : 2);
                score = (2000 - sec * 6 - wrong * 50).clamp(200, 1920);
                moveCount = 5 + wrong;
                break;
              case GameType.tango:
                final excessMoves = _excess((i - 20) ~/ 12);
                score = (2000 - sec * 10 - excessMoves * 4).clamp(200, 1910);
                moveCount = 22 + excessMoves;
                break;
              case GameType.zipPath:
                score = (2000 - sec * 10).clamp(200, 1920);
                moveCount = 1;
                break;
              case GameType.patches:
                final excessRects = _excess((i - 25) ~/ 14);
                score = (2000 - sec * 10 - excessRects * 5).clamp(200, 1910);
                moveCount = 7 + excessRects;
                break;
              default:
                score = (2000 - sec * 10).clamp(200, 1920);
            }

            _resultsStore.add(
              GameResult(
                id: '${game.id}_${userId}_${prefix}_d$dayBack',
                gameType: game,
                levelId: pastLevelId,
                userId: userId,
                userName: name,
                durationMs: duration,
                moveCount: moveCount,
                score: score,
                completedAt: pastDate.add(Duration(hours: 8 + (i * 3 + game.index * 5) % 14, minutes: (i * 7) % 60)),
              ),
            );
          }
        }
      }

      // Haftalık geçmiş (Son 6 gün) -> Haftalık Liderlik Tablosunu oluşturur
      seedPastDays(weeklyDays, weeklyRate, 'w');

      // Aylık geçmiş (Son 7..29 gün) -> Aylık Liderlik Tablosunu güçlendirir
      seedPastDays(monthlyExtraDays, monthlyRate, 'm');

      // Genel geçmiş (33..95 gün) -> Genel (Tüm Zamanlar) Liderlik Tablosunu zenginleştirir
      seedPastDays(allTimeExtraDays, allTimeRate, 'all');
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
        userName: 'Oyuncu',
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
        return r.completedAt.isAfter(activeDate.subtract(const Duration(days: 7)));
      } else if (timeframe == LeaderboardTimeframe.monthly) {
        return r.completedAt.isAfter(activeDate.subtract(const Duration(days: 30)));
      }
      return true; // allTime
    }).toList();

    // 2. Kullanıcı bazında topla
    final Map<String, List<GameResult>> userMap = {};
    for (var res in filtered) {
      userMap.putIfAbsent(res.userId, () => []).add(res);
    }

    final entries = <LeaderboardEntry>[];

    // VEZİRLER (QUEENS) GÜNLÜK TOPLAM PUAN KURALI (Eğer belirli bir zorluk seçilmemişse ve günlük moddaysa):
    // "kolay, zor ve master seviyedeki oyuncuya ait bütün skorların toplamı olsun.
    // eğer oyuncu sadece kolayları oynamış ve diğerlerini oynamamış ise diğerleri de 0 olarak sayılsın."
    if (gameType == GameType.queens && difficulty == null && timeframe == LeaderboardTimeframe.daily) {
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
      // DİĞER OYUNLAR VEYA HAFTALIK/AYLIK/GENEL (VEYA TEK BİR ZORLUK)
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
