import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/badge_model.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';

enum BadgeScreenTab {
  belts, // Şampiyonluk Kemerleri (Süreli / Dinamik)
  badges, // Rozet Koleksiyonu (Kalıcı)
}

enum BadgeStatusFilter {
  all,
  unlocked,
  locked,
}

class BadgesScreen extends ConsumerStatefulWidget {
  final BadgeScreenTab initialTab;

  const BadgesScreen({
    super.key,
    this.initialTab = BadgeScreenTab.belts,
  });

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;
  GameType? _selectedStreakGame;
  BadgeStatusFilter _statusFilter = BadgeStatusFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == BadgeScreenTab.belts ? 0 : 1,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Steam Tarzı Seviye ve Unvan Hesaplaması
  (int level, String title, int nextLevelThreshold) _calculateSteamLevel(int unlockedCount) {
    if (unlockedCount >= 100) {
      return (6, 'Efsanevi Deha', 113);
    } else if (unlockedCount >= 75) {
      return (5, 'Zirve Şampiyonu', 100);
    } else if (unlockedCount >= 50) {
      return (4, 'Büyük Usta', 75);
    } else if (unlockedCount >= 25) {
      return (3, 'Zekâ Avcısı', 50);
    } else if (unlockedCount >= 10) {
      return (2, 'Mantık Kâşifi', 25);
    } else {
      return (1, 'Zihin Çırağı', 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeState = ref.watch(badgeServiceProvider);
    final badgeNotifier = ref.read(badgeServiceProvider.notifier);
    final dailyPlayState = ref.watch(dailyPlayServiceProvider);
    final statsMap = ref.watch(gameStatsServiceProvider);

    final championships = DailyBadge.allBadges
        .where((b) => b.category == BadgeCategory.championship)
        .toList();

    final permanentBadges = DailyBadge.allBadges
        .where((b) => b.category != BadgeCategory.championship)
        .toList();

    final totalCount = DailyBadge.allBadges.length;
    final activeTotalCount = badgeNotifier.activeBadges.length;
    final activeBeltsCount = championships
        .where((b) => badgeState[b.id] != null && !badgeState[b.id]!.isExpired)
        .length;
    final unlockedPermanentCount = permanentBadges
        .where((b) => badgeState[b.id] != null && !badgeState[b.id]!.isExpired)
        .length;

    final (steamLevel, steamTitle, nextThreshold) = _calculateSteamLevel(activeTotalCount);
    final completionPercent = totalCount > 0 ? (activeTotalCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 1. ÜST BAR & STEAM PROFİL HEADER'I
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        // Geri Butonu ve Başlık
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black : AppColors.pencilBlack,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: isDark ? Colors.white : AppColors.pencilBlack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('🏆', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ROZETLER VE KEMERLER',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.pencilBlack,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Koleksiyon, Şampiyonluk Kemerleri ve Başarımlar',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 12,
                                      color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // STEAM STİLİ BAŞARIM VE SEVİYE KARTI
                        _buildSteamProfileHeader(
                          context,
                          isDark: isDark,
                          level: steamLevel,
                          title: steamTitle,
                          totalUnlocked: activeTotalCount,
                          totalBadges: totalCount,
                          completionPercent: completionPercent,
                          activeBelts: activeBeltsCount,
                          unlockedBadges: unlockedPermanentCount,
                        ),

                        const SizedBox(height: 12),

                        // SEKMELER: 👑 Şampiyonluk Kemerleri | 🎖️ Rozet Koleksiyonu
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black : AppColors.pencilBlack,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: _tabController.index == 0
                                  ? AppColors.sunYellow
                                  : AppColors.highlighterCyan,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.pencilBlack,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.pencilBlack,
                                  offset: Offset(1.5, 1.5),
                                ),
                              ],
                            ),
                            labelColor: AppColors.inkBlack,
                            unselectedLabelColor: isDark ? Colors.white70 : AppColors.pencilGray,
                            labelStyle: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            unselectedLabelStyle: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: [
                              Tab(
                                height: 42,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('👑', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text('KEMERLER ($activeBeltsCount/10)'),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 42,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🎖️', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text('ROZETLER ($unlockedPermanentCount/103)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // SEKME 1: ŞAMPİYONLUK KEMERLERİ (10 Dinamik Kemer)
                _buildBeltsTab(
                  context,
                  isDark: isDark,
                  belts: championships,
                  badgeState: badgeState,
                ),

                // SEKME 2: STEAM ROZET KOLEKSİYONU (103 Kalıcı Rozet)
                _buildBadgesTab(
                  context,
                  isDark: isDark,
                  allPermanentBadges: permanentBadges,
                  badgeState: badgeState,
                  dailyPlayState: dailyPlayState,
                  statsMap: statsMap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEAM HEADER & SEVİYE KARTI
  // ===========================================================================
  Widget _buildSteamProfileHeader(
    BuildContext context, {
    required bool isDark,
    required int level,
    required String title,
    required int totalUnlocked,
    required int totalBadges,
    required double completionPercent,
    required int activeBelts,
    required int unlockedBadges,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSecondaryDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : AppColors.pencilBlack,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Steam Seviye Rozet Halkası
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.pencilBlack, width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pencilBlack,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LVL',
                        style: GoogleFonts.patrickHand(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBlack,
                          height: 0.9,
                        ),
                      ),
                      Text(
                        '$level',
                        style: GoogleFonts.patrickHand(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBlack,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Unvan ve İstatistikler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.patrickHand(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.pencilBlack,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sunYellow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                          ),
                          child: Text(
                            '$totalUnlocked / $totalBadges',
                            style: GoogleFonts.patrickHand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tamamlanma Oranı: %${(completionPercent * 100).toStringAsFixed(0)}',
                      style: GoogleFonts.patrickHand(
                        fontSize: 13,
                        color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Steam İlerleme Çubuğu (XP Bar)
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
                    width: 1.2,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: completionPercent.clamp(0.02, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF10B981), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.0),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // İki mini rozet göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStatBadge(
                icon: '👑',
                label: 'Aktif Kemer',
                value: '$activeBelts / 10',
                color: AppColors.sunYellow,
                isDark: isDark,
              ),
              _buildMiniStatBadge(
                icon: '🎖️',
                label: 'Kazanılan Rozet',
                value: '$unlockedBadges / 103',
                color: AppColors.highlighterCyan,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBadge({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.sketchBorderDark.withValues(alpha: 0.5) : AppColors.pencilLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEKME 1: ŞAMPİYONLUK KEMERLERİ LİSTESİ
  // ===========================================================================
  Widget _buildBeltsTab(
    BuildContext context, {
    required bool isDark,
    required List<DailyBadge> belts,
    required Map<String, UserBadge> badgeState,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2411) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sunYellow, width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DİNAMİK ŞAMPİYONLUK KEMERLERİ',
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.amber[200] : const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          'Bu kemerler oyuncunun aktif performansına bağlıdır. Süresi bittiğinde veya koşul kaybedildiğinde otomatik düşer.',
                          style: GoogleFonts.patrickHand(
                            fontSize: 12,
                            color: isDark ? Colors.amber[100] : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final belt = belts[index];
                final userBadge = badgeState[belt.id];
                final isUnlocked = userBadge != null && !userBadge.isExpired;
                final remainingDays = userBadge?.remainingDays ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSteamBeltCard(
                    context,
                    isDark: isDark,
                    belt: belt,
                    userBadge: userBadge,
                    isUnlocked: isUnlocked,
                    remainingDays: remainingDays,
                  ),
                );
              },
              childCount: belts.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteamBeltCard(
    BuildContext context, {
    required bool isDark,
    required DailyBadge belt,
    required UserBadge? userBadge,
    required bool isUnlocked,
    required int remainingDays,
  }) {
    final borderColor = isUnlocked
        ? AppColors.sunYellow
        : (isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack);
    final cardBg = isUnlocked
        ? (isDark ? const Color(0xFF231F14) : const Color(0xFFFFFBEB))
        : (isDark ? AppColors.surfaceDark : Colors.white);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showSteamBadgeModal(context, badge: belt, userBadge: userBadge);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isUnlocked ? 2.4 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? AppColors.sunYellow.withValues(alpha: 0.4)
                  : (isDark ? Colors.black : AppColors.pencilBlack),
              offset: const Offset(2.5, 2.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kemer Amblem Kutusu
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.sunYellow.withValues(alpha: 0.25)
                        : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked ? AppColors.sunYellow : AppColors.pencilLight,
                      width: 1.8,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: AppColors.sunYellow.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      belt.emoji,
                      style: TextStyle(
                        fontSize: 30,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Başlık & Kalan Süre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              belt.title,
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.pencilBlack,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? (belt.validityDays == 0 ? AppColors.highlighterPurple : AppColors.sunYellow)
                                  : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isUnlocked ? AppColors.pencilBlack : AppColors.pencilLight,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              isUnlocked
                                  ? (belt.validityDays == 0 ? '🧠 130+ IQ' : '⏳ $remainingDays GÜN')
                                  : '🔒 KİLİTLİ',
                              style: GoogleFonts.patrickHand(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUnlocked ? AppColors.inkBlack : AppColors.pencilLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        belt.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.patrickHand(
                          fontSize: 13,
                          color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 8),

            // Kazanma Şartı & Durum
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.verified_rounded : Icons.military_tech_outlined,
                  size: 15,
                  color: isUnlocked ? const Color(0xFF10B981) : AppColors.pencilLight,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Şart: ${belt.requirement}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                          : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isUnlocked ? '👑 Taşınıyor' : 'Kazanılmadı',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? const Color(0xFF10B981) : AppColors.pencilLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SEKME 2: STEAM ROZET KOLEKSİYONU
  // ===========================================================================
  Widget _buildBadgesTab(
    BuildContext context, {
    required bool isDark,
    required List<DailyBadge> allPermanentBadges,
    required Map<String, UserBadge> badgeState,
    required DailyPlayState dailyPlayState,
    required Map<GameType, GamePerformanceData> statsMap,
  }) {
    // 1. Kategori Filtresi
    List<DailyBadge> filtered = allPermanentBadges;
    if (_selectedCategory != null) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
      if (_selectedCategory == BadgeCategory.streak && _selectedStreakGame != null) {
        filtered = filtered.where((b) => b.relatedGame == _selectedStreakGame).toList();
      }
    }

    // 2. Durum Filtresi (Kazanılanlar / Kilitliler)
    if (_statusFilter == BadgeStatusFilter.unlocked) {
      filtered = filtered.where((b) {
        final ub = badgeState[b.id];
        return ub != null && !ub.isExpired;
      }).toList();
    } else if (_statusFilter == BadgeStatusFilter.locked) {
      filtered = filtered.where((b) {
        final ub = badgeState[b.id];
        return ub == null || ub.isExpired;
      }).toList();
    }

    // 3. Arama Filtresi
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q) ||
            b.requirement.toLowerCase().contains(q);
      }).toList();
    }

    final unlockedCount = filtered
        .where((b) => badgeState[b.id] != null && !badgeState[b.id]!.isExpired)
        .length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // FİLTRELER, ARAMA VE SEÇİCİLER
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arama Kutusu
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black : AppColors.pencilBlack,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.pencilBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rozet adı veya kazanma koşulu ara...',
                      hintStyle: GoogleFonts.patrickHand(
                        fontSize: 14,
                        color: isDark ? AppColors.pencilLightDark : AppColors.pencilLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : AppColors.pencilGray,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Kategori Çipleri (Steam Stili)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        isDark: isDark,
                        label: 'Tümü (${allPermanentBadges.length})',
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() {
                          _selectedCategory = null;
                          _selectedStreakGame = null;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        isDark: isDark,
                        label: '🎮 Oyun Ustalığı (6)',
                        isSelected: _selectedCategory == BadgeCategory.gameMastery,
                        onTap: () => setState(() {
                          _selectedCategory = BadgeCategory.gameMastery;
                          _selectedStreakGame = null;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        isDark: isDark,
                        label: '🧠 Zekâ & Başarı (6)',
                        isSelected: _selectedCategory == BadgeCategory.brainPower,
                        onTap: () => setState(() {
                          _selectedCategory = BadgeCategory.brainPower;
                          _selectedStreakGame = null;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        isDark: isDark,
                        label: '🔥 Seri Rozetleri (91)',
                        isSelected: _selectedCategory == BadgeCategory.streak,
                        onTap: () => setState(() => _selectedCategory = BadgeCategory.streak),
                      ),
                    ],
                  ),
                ),

                // Eğer Seriler seçiliyse: Oyun Seçim Çipleri
                if (_selectedCategory == BadgeCategory.streak) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildSubGameChip(
                          isDark: isDark,
                          label: 'Tüm Oyunlar',
                          isSelected: _selectedStreakGame == null,
                          onTap: () => setState(() => _selectedStreakGame = null),
                        ),
                        const SizedBox(width: 6),
                        _buildSubGameChip(
                          isDark: isDark,
                          label: 'Genel Zihin',
                          isSelected: _selectedStreakGame == null,
                          currentStreak: dailyPlayState.getCurrentStreak(null),
                          onTap: () => setState(() => _selectedStreakGame = null),
                        ),
                        for (final g in GameType.values) ...[
                          const SizedBox(width: 6),
                          _buildSubGameChip(
                            isDark: isDark,
                            label: g.title,
                            isSelected: _selectedStreakGame == g,
                            currentStreak: dailyPlayState.getCurrentStreak(g),
                            onTap: () => setState(() => _selectedStreakGame = g),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Durum Filtresi: Hepsi / Açılanlar / Kilitliler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildStatusOption(
                          isDark: isDark,
                          label: 'Hepsi',
                          isSelected: _statusFilter == BadgeStatusFilter.all,
                          onTap: () => setState(() => _statusFilter = BadgeStatusFilter.all),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusOption(
                          isDark: isDark,
                          label: 'Açılanlar ✓',
                          isSelected: _statusFilter == BadgeStatusFilter.unlocked,
                          onTap: () => setState(() => _statusFilter = BadgeStatusFilter.unlocked),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusOption(
                          isDark: isDark,
                          label: 'Kilitliler 🔒',
                          isSelected: _statusFilter == BadgeStatusFilter.locked,
                          onTap: () => setState(() => _statusFilter = BadgeStatusFilter.locked),
                        ),
                      ],
                    ),
                    Text(
                      '$unlockedCount / ${filtered.length} Gösteriliyor',
                      style: GoogleFonts.patrickHand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ROZET KARTLARI LİSTESİ
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text(
                      'Aradığınız kriterlere uygun rozet bulunamadı.',
                      style: GoogleFonts.patrickHand(
                        fontSize: 16,
                        color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = filtered[index];
                  final userBadge = badgeState[badge.id];
                  final isUnlocked = userBadge != null && !userBadge.isExpired;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildSteamBadgeCard(
                      context,
                      isDark: isDark,
                      badge: badge,
                      userBadge: userBadge,
                      isUnlocked: isUnlocked,
                      dailyPlayState: dailyPlayState,
                      statsMap: statsMap,
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // STEAM TARZI ROZET KARTI
  // ===========================================================================
  Widget _buildSteamBadgeCard(
    BuildContext context, {
    required bool isDark,
    required DailyBadge badge,
    required UserBadge? userBadge,
    required bool isUnlocked,
    required DailyPlayState dailyPlayState,
    required Map<GameType, GamePerformanceData> statsMap,
  }) {
    // İlerleme oranı hesaplama
    double progressRatio = 0.0;
    String progressText = '';

    if (badge.category == BadgeCategory.streak) {
      final current = dailyPlayState.getCurrentStreak(badge.relatedGame);
      final target = badge.streakDays;
      if (target > 0) {
        progressRatio = (current / target).clamp(0.0, 1.0);
        progressText = 'İlerleme: $current / $target Gün (%${(progressRatio * 100).toInt()})';
      }
    } else if (badge.category == BadgeCategory.gameMastery && badge.relatedGame != null) {
      final stats = statsMap[badge.relatedGame!];
      final wins = stats?.totalGamesPlayed ?? 0;
      progressRatio = (wins / 3).clamp(0.0, 1.0);
      progressText = 'Galibiyet: $wins / 3 (%${(progressRatio * 100).toInt()})';
    } else if (badge.id == 'badge_century_club') {
      final total = statsMap.values.fold<int>(0, (sum, p) => sum + p.totalGamesPlayed);
      progressRatio = (total / 100).clamp(0.0, 1.0);
      progressText = 'Oyun: $total / 100 (%${(progressRatio * 100).toInt()})';
    }

    final cardBg = isUnlocked
        ? (isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFFAFAF5))
        : (isDark ? AppColors.surfaceDark : Colors.white);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showSteamBadgeModal(context, badge: badge, userBadge: userBadge);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnlocked
                ? (isDark ? AppColors.sunYellow : AppColors.pencilBlack)
                : (isDark ? AppColors.sketchBorderDark.withValues(alpha: 0.5) : AppColors.pencilLight),
            width: isUnlocked ? 2.0 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? (isDark ? Colors.amber.withValues(alpha: 0.2) : AppColors.pencilBlack)
                  : (isDark ? Colors.black : Colors.black12),
              offset: isUnlocked ? const Offset(2.2, 2.2) : const Offset(1.5, 1.5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // STEAM ROZET İKON KUTUSU
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.25)
                    : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked ? badge.color : AppColors.pencilLight,
                  width: 1.6,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 26,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // METİN BİLGİLERİ VE STEAM İLERLEME ÇUBUĞU
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          badge.title,
                          style: GoogleFonts.patrickHand(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.pencilBlack,
                          ),
                        ),
                      ),
                      // Durum Etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                              : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isUnlocked
                                ? const Color(0xFF059669)
                                : AppColors.pencilLight,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          isUnlocked ? '✓ Açıldı' : '🔒 Kilitli',
                          style: GoogleFonts.patrickHand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                : AppColors.pencilLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.requirement,
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.pencilLightDark : AppColors.pencilGray,
                    ),
                  ),

                  // Kilitliyse ve İlerleme varsa Steam Progress Bar
                  if (!isUnlocked && progressText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 5,
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          progressText,
                          style: GoogleFonts.patrickHand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FİLTRE & ÇİP BİLEŞENLERİ
  // ===========================================================================
  Widget _buildFilterChip({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final chipBg = isSelected
        ? AppColors.sunYellow
        : (isDark ? AppColors.surfaceDark : Colors.white);
    final borderColor = isSelected
        ? AppColors.pencilBlack
        : (isDark ? AppColors.sketchBorderDark : AppColors.pencilLight);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.2),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.inkBlack, offset: Offset(1.5, 1.5))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.patrickHand(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? AppColors.inkBlack
                : (isDark ? Colors.white70 : AppColors.pencilBlack),
          ),
        ),
      ),
    );
  }

  Widget _buildSubGameChip({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? currentStreak,
  }) {
    final chipBg = isSelected
        ? AppColors.accentCyan
        : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.inkBlack : AppColors.pencilLight,
            width: 1.2,
          ),
        ),
        child: Text(
          currentStreak != null && currentStreak > 0 ? '$label (🔥$currentStreak)' : label,
          style: GoogleFonts.patrickHand(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.inkBlack : (isDark ? Colors.white70 : AppColors.pencilGraphite),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppColors.sunYellow, width: 1.2)
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.patrickHand(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.sunYellow
                : (isDark ? AppColors.pencilLightDark : AppColors.pencilGray),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEAM TARZI BAŞARIM DETAY MODALI
  // ===========================================================================
  void _showSteamBadgeModal(
    BuildContext context, {
    required DailyBadge badge,
    required UserBadge? userBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = userBadge != null && !userBadge.isExpired;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isUnlocked ? AppColors.sunYellow : (isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? AppColors.sunYellow.withValues(alpha: 0.35)
                    : (isDark ? Colors.black : AppColors.pencilBlack),
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rozet Büyük İkonu (Steam Trophy)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? badge.color.withValues(alpha: 0.3) : AppColors.surfaceSecondaryLight,
                  border: Border.all(
                    color: isUnlocked ? badge.color : AppColors.pencilLight,
                    width: 3.0,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(badge.emoji, style: const TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 14),

              // Rozet Başlığı
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.pencilBlack,
                ),
              ),
              const SizedBox(height: 6),

              // Tür Etiketi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.isTemporary ? AppColors.sunYellow : AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                ),
                child: Text(
                  badge.isTemporary
                      ? (badge.validityDays == 0
                          ? '👑 KOŞULLU DİNAMİK KEMER'
                          : '👑 ŞAMPİYONLUK KEMERİ (${badge.validityDays} GÜN GEÇERLİ)')
                      : (badge.category == BadgeCategory.streak
                          ? '🔥 KALICI SERİ ROZETİ'
                          : '🎖️ KALICI KOLEKSİYON ROZETİ'),
                  style: GoogleFonts.patrickHand(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkBlack,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(
                  fontSize: 14,
                  color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              // Şart Kutusu
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSecondaryDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.sketchBorderDark : AppColors.pencilBlack,
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.sunYellow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kazanma Şartı: ${badge.requirement}',
                        style: GoogleFonts.patrickHand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.pencilBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (userBadge != null) ...[
                const SizedBox(height: 8),
                Text(
                  userBadge.expiresAt != null
                      ? 'Geçerlilik Bitişi: ${userBadge.expiresAt!.day}.${userBadge.expiresAt!.month}.${userBadge.expiresAt!.year}'
                      : 'Kazanılma Tarihi: ${userBadge.unlockedAt.day}.${userBadge.unlockedAt.month}.${userBadge.unlockedAt.year}',
                  style: GoogleFonts.patrickHand(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? const Color(0xFF10B981) : AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Kapat Butonu
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.sunYellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.pencilBlack, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.pencilBlack,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Tamam',
                      style: GoogleFonts.patrickHand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkBlack,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
