import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/network_checker.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/player_stats_service.dart';
import '../../core/services/league_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sketch_badge_icons.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';
import '../home/home_screen.dart';
import 'widgets/badge_showcase_section.dart';
import '../../core/services/badge_service.dart';
import '../league/league_screen.dart';
import '../../core/services/user_nickname_provider.dart';
import '../../core/widgets/nickname_prompt_dialog.dart';
import '../../core/models/user_avatar.dart';
import '../../core/services/user_avatar_provider.dart';
import 'widgets/avatar_picker_dialog.dart';
import 'settings_screen.dart';
import '../../core/widgets/daily_social_share_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAvatar = ref.watch(currentAvatarModelProvider);
    final headerPencil = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final headerGraphite = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    final isOnline = ref.watch(networkCheckerProvider);
    final userNickname = ref.watch(userNicknameProvider);
    final statsMap = ref.watch(gameStatsServiceProvider);
    final statsNotifier = ref.read(gameStatsServiceProvider.notifier);
    final userIQ = statsNotifier.getOverallIQ();
    final currentStreak = ref.watch(dailyPlayServiceProvider).getCurrentStreak();
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);
    final hasEinstein = badgeNotifier.isUnlocked('belt_einstein') || userIQ >= 148;
    final hasGrandmaster = badgeNotifier.isUnlocked('belt_grandmaster') || userIQ >= 120;

    final dailyPlay = ref.watch(dailyPlayServiceProvider);
    final serverStats = ref.watch(playerStatsServiceProvider);

    // Toplam istatistik ve dinamik reaksiyon hesaplamaları
    int totalPlayed = 0;
    int totalScore = 0;
    int totalBestDurationMs = 0;
    int durationGamesCount = 0;
    for (var perf in statsMap.values) {
      totalPlayed += perf.totalGamesPlayed;
      int gameBestScore = perf.bestScore;
      if (perf.gameType == GameType.queens) {
        // Vezirler için günlük toplam skoru (Kolay + Zor + Master) kontrol et
        for (final dateKey in dailyPlay.records.values.map((r) => r.dateId).toSet()) {
          final qRec = dailyPlay.getRecord(GameType.queens, dateKey);
          if (qRec != null && qRec.score > gameBestScore) {
            gameBestScore = qRec.score;
          }
        }
      }
      totalScore += gameBestScore;
      if (perf.bestDurationMs > 0) {
        totalBestDurationMs += perf.bestDurationMs;
        durationGamesCount++;
      }
    }

    final int effectiveTotalPlayed = math.max(totalPlayed, serverStats.totalGamesPlayed);

    final int avgReactionMs = serverStats.avgDurationMs > 0
        ? serverStats.avgDurationMs
        : (durationGamesCount > 0 ? (totalBestDurationMs / durationGamesCount).round() : 0);
    final String avgReactionStr = avgReactionMs > 0 ? '${(avgReactionMs / 1000).toStringAsFixed(1)} sn' : '--';
    final String avgReactionSubtitle = avgReactionMs > 0
        ? (avgReactionMs < 30000 ? 'Işık Hızı' : (avgReactionMs < 60000 ? 'Yüksek Hız' : 'Dengeli'))
        : 'Henüz Veri Yok';

    // Gerçek kariyer toplam puanı: Sunucudaki doğrulanmış kümülatif puan ile yerel kayıtların en yükseği
    // (Böylece liderlik tablosundaki tüm oyunların toplamı ile profil skoru %100 birebir aynı ve tutarlı olur)
    final int localCareerScore = dailyPlay.records.values
        .where((r) => !r.isArchivePlay && r.score > 0)
        .fold<int>(0, (sum, r) => sum + r.score);
    final int effectiveCareerScore = math.max(localCareerScore, serverStats.totalCareerScore);
    final int displayTotalScore = effectiveCareerScore > 0 ? effectiveCareerScore : totalScore;

    return RefreshIndicator(
      color: AppColors.sunYellow,
      backgroundColor: isDark ? AppColors.cardBgDark : Colors.white,
      onRefresh: () async {
        await ref.read(playerStatsServiceProvider.notifier).refreshStats();
        await ref.read(leagueServiceProvider.notifier).fetchLiveLeagueData();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
        // 1. ÜST BAŞLIK
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 54, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.highlighterPurple,
                            border: Border.fromBorderSide(
                              BorderSide(color: headerPencil, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KİŞİSEL GELİŞİM RAPORU',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: headerGraphite,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profil',
                      style: GoogleFonts.patrickHand(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: headerPencil,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Dinamik Seviye Rozeti
                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      borderRadius: 10,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: AppColors.highlighterPurple,
                      borderColor: AppColors.pencilBlack,
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_rounded, size: 16, color: AppColors.pencilBlack),
                          const SizedBox(width: 4),
                          Text(
                            'LVL ${(effectiveTotalPlayed / 5).floor() + 1}',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ayarlar Butonu
                    SketchCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      borderRadius: 10,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                      borderColor: headerPencil,
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 16, color: headerPencil),
                          const SizedBox(width: 4),
                          Text(
                            'Ayarlar',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: headerPencil,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 2. FOTOĞRAFTAKİ GİBİ SKEÇ KİMLİK KARTI & %92 ÇEMBER GÖSTERGESİ
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SketchCard(
                  borderRadius: 16,
                  borderWidth: 2.5,
                  shadowOffset: const Offset(4.0, 4.0),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Sol: Tıklanabilir ve Özelleştirilebilir Avatar Kutusu
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showDialog(
                                context: context,
                                builder: (_) => const AvatarPickerDialog(),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SketchPlaceholderBox(
                                  width: 64,
                                  height: 64,
                                  fillColor: currentAvatar.accentColor.withAlpha(isDark ? 80 : 110),
                                  lineColor: headerPencil,
                                  borderRadius: 12,
                                  child: Center(
                                    child: currentAvatar.buildWidget(
                                      size: 34,
                                      tintColor: headerPencil,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -3,
                                  right: -3,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.sunYellow,
                                      border: Border.all(color: headerPencil, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.pencilBlack,
                                          offset: Offset(1.0, 1.0),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 13,
                                        color: AppColors.pencilBlack,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Kullanıcı Bilgisi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        userNickname,
                                        style: GoogleFonts.patrickHand(
                                          color: headerPencil,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => const NicknamePromptDialog(isEditing: true),
                                        );
                                      },
                                      child: SketchCard(
                                        padding: const EdgeInsets.all(4),
                                        borderRadius: 6,
                                        borderWidth: 1.2,
                                        shadowOffset: const Offset(1.0, 1.0),
                                        backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                                        borderColor: headerPencil,
                                        child: Icon(Icons.edit, size: 14, color: headerPencil),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SketchCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      borderRadius: 4,
                                      borderWidth: 1.2,
                                      shadowOffset: const Offset(1.0, 1.0),
                                      backgroundColor: AppColors.sunYellow,
                                      borderColor: AppColors.pencilBlack,
                                      child: Text(
                                        'SİZ',
                                        style: GoogleFonts.patrickHand(
                                          color: AppColors.pencilBlack,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isOnline ? '🟢 Canlı Sıralamaya Bağlı' : '🔴 Çevrimdışı (Yerel Kayıt)',
                                  style: GoogleFonts.patrickHand(
                                    color: isOnline ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SketchCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  borderRadius: 6,
                                  borderWidth: 1.4,
                                  shadowOffset: const Offset(1.2, 1.2),
                                  backgroundColor: AppColors.highlighterCyan,
                                  borderColor: AppColors.pencilBlack,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SketchBadgeIcon(
                                        type: BadgeArtType.lightning,
                                        size: 12,
                                        strokeColor: AppColors.pencilBlack,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'KÜRESEL İLK %1 STATÜSÜ',
                                        style: GoogleFonts.patrickHand(
                                          color: AppColors.pencilBlack,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // FOTOĞRAFTAKİ EN MEŞHUR DETAY: El Çizimi %92 Çember Göstergesi & IQ
                      SketchCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        borderWidth: 1.8,
                        shadowOffset: const Offset(2.0, 2.0),
                        backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                        borderColor: headerPencil,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Dairesel %92 Göstergesi (Tam fotoğraftaki gibi!)
                            SketchCircularDoodle(
                              size: 72,
                              percentage: 92,
                              strokeColor: headerPencil,
                              fillColor: AppColors.highlighterCyan,
                              centerChild: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '%92',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: headerPencil,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Açıklama
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GENEL BAŞARI & IQ ENDEKSİ',
                                  style: GoogleFonts.patrickHand(
                                    color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGray,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'IQ $userIQ+ (Üstün Zekâ)',
                                  style: GoogleFonts.patrickHand(
                                    color: headerPencil,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Dünya ortalamasından 4.2 kat daha hızlı!',
                                  style: GoogleFonts.patrickHand(
                                    color: headerGraphite,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SketchCard(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          final todayId = GameDateUtils.getTodayLevelId();
                          DailySocialShareDialog.show(
                            context,
                            dateId: todayId,
                            overallIQ: userIQ,
                            dailyPlayState: dailyPlay,
                          );
                        },
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2.5, 2.5),
                        backgroundColor: AppColors.sunYellow,
                        borderColor: headerPencil,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share_rounded,
                                size: 18, color: AppColors.inkBlack),
                            const SizedBox(width: 8),
                            Text(
                              'Zeka Karneni Paylaş (WhatsApp & Insta)',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.inkBlack,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // SOL KÖŞEDEKİ EINSTEIN (148+ IQ) VEYA BÜYÜK USTA ROZETİ
                if (hasEinstein)
                  Positioned(
                    top: -12,
                    left: 14,
                    child: SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      borderRadius: 8,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: AppColors.highlighterPurple,
                      borderColor: AppColors.pencilBlack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SketchBadgeIcon(
                            type: BadgeArtType.einsteinBrain,
                            size: 16,
                            strokeColor: AppColors.pencilBlack,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'EINSTEIN STATÜSÜ (148+ IQ)',
                            style: GoogleFonts.patrickHand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (hasGrandmaster)
                  Positioned(
                    top: -12,
                    left: 14,
                    child: SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      borderRadius: 8,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.0, 2.0),
                      backgroundColor: AppColors.sunYellow,
                      borderColor: AppColors.pencilBlack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SketchBadgeIcon(
                            type: BadgeArtType.lightbulb,
                            size: 16,
                            strokeColor: AppColors.pencilBlack,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'BÜYÜK USTA (120+ IQ)',
                            style: GoogleFonts.patrickHand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 3. LIG ÖZET KARTI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIG DURUMU',
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                LeagueProfileCard(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(homeBottomNavIndexProvider.notifier).state = 2;
                  },
                ),
              ],
            ),
          ),
        ),

        // 4. KARA KALEM İSTATİSTİK 4'LÜ IZGARASI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.local_fire_department_rounded,
                    fillColor: AppColors.highlighterOrange,
                    title: 'GÜNLÜK SERİ',
                    value: '$currentStreak Gün',
                    subtitle: 'Kesintisiz Odak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.sports_esports_rounded,
                    fillColor: AppColors.highlighterCyan,
                    title: 'ÇÖZÜLEN OYUN',
                    value: '$effectiveTotalPlayed Oyun',
                    subtitle: 'Tamamlandı',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.speed_rounded,
                    fillColor: AppColors.highlighterPurple,
                    title: 'ORT. REAKSİYON',
                    value: avgReactionStr,
                    subtitle: avgReactionSubtitle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.military_tech_rounded,
                    fillColor: AppColors.sunYellow,
                    title: 'TOPLAM PUAN',
                    value: '$displayTotalScore P',
                    subtitle: 'Kariyer Skoru',
                  ),
                ),
              ],
            ),
          ),
        ),

        // ROZETLER & ŞAMPİYONLUK KEMERLERİ VİTRİNİ
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: BadgeShowcaseSection(),
          ),
        ),

        // 4. OYUN BAZLI ZEKA ANALİZİ BAŞLIĞI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
            child: Row(
              children: [
                Text(
                  'OYUN BAZLI SKEÇ KARNESİ',
                  style: GoogleFonts.patrickHand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: headerGraphite,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. 5 OYUNUN SKEÇ PERFORMANS LİSTESİ
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = GameType.values[index];
                final perf = statsMap[game] ??
                    GamePerformanceData(
                      gameType: game,
                      totalGamesPlayed: 0,
                      bestScore: 0,
                      bestDurationMs: 0,
                      geniusTitle: 'Zühtü Çırağı',
                    );

                final serverGameKey = game == GameType.zipPath ? 'zip_path' : game.id;
                final serverGame = serverStats.games[serverGameKey] ?? serverStats.games[game.id];
                final int serverBestScore = serverGame?.bestScore ?? 0;
                final int serverBestDuration = serverGame?.bestTimeMs ?? 0;

                final int displayBestScore;
                final int displayBestDuration;
                if (game == GameType.queens) {
                  int maxQueensScore = math.max(perf.bestScore, serverBestScore);
                  int bestQueensDuration = perf.bestDurationMs > 0 ? perf.bestDurationMs : serverBestDuration;
                  for (final dateKey in dailyPlay.records.values.map((r) => r.dateId).toSet()) {
                    final qRec = dailyPlay.getRecord(GameType.queens, dateKey);
                    if (qRec != null && qRec.score > maxQueensScore) {
                      maxQueensScore = qRec.score;
                      if (qRec.durationMs > 0) {
                        bestQueensDuration = qRec.durationMs;
                      }
                    }
                  }
                  displayBestScore = maxQueensScore;
                  displayBestDuration = bestQueensDuration;
                } else {
                  displayBestScore = math.max(perf.bestScore, serverBestScore);
                  displayBestDuration = (perf.bestDurationMs > 0 && serverBestDuration > 0)
                      ? math.min(perf.bestDurationMs, serverBestDuration)
                      : (perf.bestDurationMs > 0 ? perf.bestDurationMs : serverBestDuration);
                }

                final bool hasGamePlayed = perf.hasPlayed || (serverGame != null && serverGame.gamesPlayed > 0) || displayBestScore > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SketchCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    borderWidth: 2.0,
                    shadowOffset: const Offset(3.0, 3.0),
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    borderColor: headerPencil,
                    child: Row(
                      children: [
                        // Sol Renk İkonu (El Çizimi Skeç Resmi)
                        SketchCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 10,
                          borderWidth: 1.8,
                          shadowOffset: const Offset(1.5, 1.5),
                          backgroundColor: game.color,
                          borderColor: AppColors.pencilBlack,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: _GameSketchThumbnail(
                                game: game,
                                size: 28,
                                pencilColor: AppColors.pencilBlack,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Oyun ve Skor Detayı
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: headerPencil,
                                ),
                              ),
                              Text(
                                hasGamePlayed
                                    ? 'En İyi: ${GameDateUtils.formatGameTime(displayBestDuration)} • $displayBestScore Puan'
                                    : 'Henüz bugün çözülmedi',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.pencilGrayDark : AppColors.pencilGray,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Skeç Yüzdelik Rozeti
                        SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          borderRadius: 6,
                          borderWidth: 1.5,
                          shadowOffset: const Offset(1.2, 1.2),
                          backgroundColor: perf.hasPlayed
                              ? (perf.percentile! <= 1
                                  ? AppColors.sunYellow
                                  : game.color)
                              : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                          borderColor: isDark ? AppColors.pencilWhite : AppColors.pencilBlack,
                          child: (perf.hasPlayed && perf.percentile! <= 1)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SketchDoodleCrown(
                                      size: 13,
                                      color: AppColors.pencilBlack,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '%1',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pencilBlack,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  perf.hasPlayed
                                      ? '%${perf.percentile}'
                                      : 'HEDEF %1',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: perf.hasPlayed
                                        ? AppColors.pencilBlack
                                        : (isDark ? AppColors.pencilWhite : AppColors.pencilBlack),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: GameType.values.length,
            ),
          ),
        ),



        // 7. BİLGİLENDİRME & SİSTEM NOTU
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SketchCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 14,
              borderWidth: 2.0,
              shadowOffset: const Offset(3.0, 3.0),
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              borderColor: headerPencil,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: headerPencil, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tüm oyunların seviyeleri her gece 00:00\'da yenilenir. Günlük serinizi korumak için her gün en az 1 oyun tamamlayın.',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14.5,
                        color: headerGraphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120), // Floating nav bar için pay
        ),
      ],
    ),
  );
}
}

class _SketchMetricBox extends StatelessWidget {
  final IconData icon;
  final Color fillColor;
  final String title;
  final String value;
  final String subtitle;

  const _SketchMetricBox({
    required this.icon,
    required this.fillColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final grayColor = isDark ? AppColors.pencilGrayDark : AppColors.pencilGray;

    return SketchCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      borderWidth: 2.0,
      shadowOffset: const Offset(2.5, 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SketchCard(
            padding: const EdgeInsets.all(6),
            borderRadius: 8,
            borderWidth: 1.5,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: fillColor,
            borderColor: AppColors.pencilBlack,
            child: Icon(icon, color: AppColors.pencilBlack, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: grayColor,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: pencilColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.patrickHand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: graphiteColor,
            ),
          ),
        ],
      ),
    );
  }
}











/// Oyun Bazlı Skeç Karnesi için %100 El Çizimi Mini Skeç Resmi
class _GameSketchThumbnail extends StatelessWidget {
  final GameType game;
  final double size;
  final Color pencilColor;

  const _GameSketchThumbnail({
    required this.game,
    this.size = 28,
    required this.pencilColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (game) {
      case GameType.queens:
        return SketchDoodleCrown(
          size: size,
          color: pencilColor,
          fillColor: AppColors.sunYellow,
        );
      case GameType.pinpoint:
        return SketchDoodleTarget(
          size: size,
          color: pencilColor,
          fillColor: const Color(0xFF67E8F9),
        );
      case GameType.patches:
        return SketchDoodlePuzzle(
          size: size,
          color: pencilColor,
          fillColor: const Color(0xFFC084FC),
        );
      case GameType.tango:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DoodleTangoPainter(color: pencilColor),
          ),
        );
      case GameType.crossclimb:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DoodleCrossclimbPainter(color: pencilColor),
          ),
        );
      case GameType.zipPath:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DoodleZipPathPainter(color: pencilColor),
          ),
        );
    }
  }
}

class _DoodleTangoPainter extends CustomPainter {
  final Color color;

  const _DoodleTangoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // 1. Sol Güneş (Sarı dolgulu yarım el çizimi çember + ışınlar)
    final sunPath = Path();
    sunPath.moveTo(w * 0.40, h * 0.18);
    sunPath.quadraticBezierTo(w * 0.12, h * 0.28, w * 0.12, h * 0.52);
    sunPath.quadraticBezierTo(w * 0.12, h * 0.76, w * 0.40, h * 0.86);
    sunPath.close();

    canvas.drawPath(sunPath, Paint()..color = AppColors.sunYellow..style = PaintingStyle.fill);
    canvas.drawPath(sunPath, stroke);

    // Güneş Işınları
    canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(0, h * 0.50), stroke);
    canvas.drawLine(Offset(w * 0.14, h * 0.28), Offset(w * 0.04, h * 0.20), stroke);
    canvas.drawLine(Offset(w * 0.14, h * 0.74), Offset(w * 0.04, h * 0.82), stroke);
    canvas.drawLine(Offset(w * 0.32, h * 0.14), Offset(w * 0.28, h * 0.04), stroke);
    canvas.drawLine(Offset(w * 0.32, h * 0.90), Offset(w * 0.28, 1.0), stroke);

    // 2. Sağ Hilal Ay (Açık gece mavisi dolgulu el çizimi hilal)
    final moonPath = Path();
    moonPath.moveTo(w * 0.52, h * 0.15);
    moonPath.quadraticBezierTo(w * 0.88, h * 0.25, w * 0.88, h * 0.54);
    moonPath.quadraticBezierTo(w * 0.88, h * 0.82, w * 0.52, h * 0.90);
    moonPath.quadraticBezierTo(w * 0.70, h * 0.68, w * 0.70, h * 0.52);
    moonPath.quadraticBezierTo(w * 0.70, h * 0.35, w * 0.52, h * 0.15);
    moonPath.close();

    canvas.drawPath(moonPath, Paint()..color = const Color(0xFF60A5FA)..style = PaintingStyle.fill);
    canvas.drawPath(moonPath, stroke);
  }

  @override
  bool shouldRepaint(covariant _DoodleTangoPainter oldDelegate) => oldDelegate.color != color;
}

class _DoodleCrossclimbPainter extends CustomPainter {
  final Color color;

  const _DoodleCrossclimbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // İki dikey ahşap direk (hafif eğik tırmanış merdiveni)
    final leftRail = Path()
      ..moveTo(w * 0.30, h * 0.90)
      ..quadraticBezierTo(w * 0.34, h * 0.50, w * 0.38, h * 0.12);
    final rightRail = Path()
      ..moveTo(w * 0.68, h * 0.90)
      ..quadraticBezierTo(w * 0.72, h * 0.50, w * 0.76, h * 0.12);

    canvas.drawPath(leftRail, stroke);
    canvas.drawPath(rightRail, stroke);

    // 4 adet yatay basamak
    canvas.drawLine(Offset(w * 0.31, h * 0.78), Offset(w * 0.69, h * 0.78), stroke);
    canvas.drawLine(Offset(w * 0.33, h * 0.58), Offset(w * 0.71, h * 0.58), stroke);
    canvas.drawLine(Offset(w * 0.35, h * 0.38), Offset(w * 0.73, h * 0.38), stroke);
    canvas.drawLine(Offset(w * 0.37, h * 0.20), Offset(w * 0.75, h * 0.20), stroke);

    // En tepede ışıltı yıldızı
    final starPaint = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.58, h * 0.08), 2.2, starPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.08), 2.2, stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant _DoodleCrossclimbPainter oldDelegate) => oldDelegate.color != color;
}

class _DoodleZipPathPainter extends CustomPainter {
  final Color color;

  const _DoodleZipPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dot1 = Offset(w * 0.24, h * 0.76);
    final dot2 = Offset(w * 0.76, h * 0.52);
    final dot3 = Offset(w * 0.32, h * 0.22);

    // Birleştiren zikzak el çizimi rota yolu
    final path = Path()
      ..moveTo(dot1.dx, dot1.dy)
      ..quadraticBezierTo(w * 0.48, h * 0.68, dot2.dx, dot2.dy)
      ..quadraticBezierTo(w * 0.58, h * 0.34, dot3.dx, dot3.dy);

    canvas.drawPath(path, stroke);

    // 3 adet el çizimi daire düğüm
    final fillDot = Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.fill;
    canvas.drawCircle(dot1, 4.5, fillDot);
    canvas.drawCircle(dot2, 4.5, fillDot);
    canvas.drawCircle(dot3, 4.5, fillDot);

    canvas.drawCircle(dot1, 4.5, stroke..strokeWidth = 1.3);
    canvas.drawCircle(dot2, 4.5, stroke);
    canvas.drawCircle(dot3, 4.5, stroke);

    // Merkez minik noktalar
    canvas.drawCircle(dot1, 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(dot2, 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(dot3, 1.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DoodleZipPathPainter oldDelegate) => oldDelegate.color != color;
}
