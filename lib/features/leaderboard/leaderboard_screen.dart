import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';
import 'leaderboard_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  GameType _selectedGame = GameType.queens;
  LeaderboardTimeframe _timeframe = LeaderboardTimeframe.daily;
  String? _selectedQueensDifficulty; // null = Toplam Puan

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(leaderboardServiceProvider);
    final entries = service.getLeaderboard(
      gameType: _selectedGame,
      timeframe: _timeframe,
      difficulty: _selectedGame == GameType.queens ? _selectedQueensDifficulty : null,
    );

    // Kullanıcının kendi derecesini bul
    final myEntryIndex = entries.indexWhere((e) => e.userId == 'user_local');
    final myEntry = myEntryIndex != -1 ? entries[myEntryIndex] : null;
    final myRank = myEntry?.rank;
    final topPercentile = myRank != null ? ((myRank / entries.length) * 100).ceil() : null;

    final top10 = entries.take(10).toList();
    final isUserInTop10 = top10.any((e) => e.userId == 'user_local');
    final showUserBottomRow = myEntry != null && !isUserInTop10;

    final isDark = AppColors.isDark(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. ÜST BAŞLIK & DÖNEM BİLGİSİ
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
                            color: AppColors.sunYellow,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.pencil(context), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GLOBAL ARENA • GÜNCEL',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.graphite(context),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Zeka Sıralaması',
                      style: GoogleFonts.patrickHand(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencil(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Skeç Lig Rozeti
                SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: 10,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(2.5, 2.5),
                  backgroundColor: AppColors.sunYellow,
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech_rounded, size: 18, color: AppColors.pencilBlack),
                      const SizedBox(width: 4),
                      Text(
                        '1. LİG',
                        style: GoogleFonts.patrickHand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. SKEÇ DÖNEM SEÇİCİ (BUGÜN / HAFTALIK / AYLIK / GENEL)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SketchCard(
              borderRadius: 14,
              borderWidth: 2.0,
              shadowOffset: const Offset(3.0, 3.0),
              backgroundColor: AppColors.surfaceOf(context),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: LeaderboardTimeframe.values.map((tf) {
                  final isSelected = _timeframe == tf;
                  return Expanded(
                    child: isSelected
                        ? SketchCard(
                            borderRadius: 8,
                            borderWidth: 1.6,
                            shadowOffset: const Offset(1.5, 1.5),
                            backgroundColor: AppColors.sunYellow,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Center(
                              child: Text(
                                tf.label,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkBlack,
                                ),
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _timeframe = tf);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Text(
                                  tf.label,
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencil(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // 3. YATAY OYUN SEÇİCİ SKEÇ ÇUBUĞU
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              physics: const BouncingScrollPhysics(),
              itemCount: GameType.values.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final game = GameType.values[index];
                final isSelected = _selectedGame == game;
                final itemBg = isSelected ? game.color : AppColors.surfaceOf(context);
                final itemTextColor = isSelected ? AppColors.onColor(game.color) : AppColors.pencil(context);

                return SketchCard(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGame = game);
                  },
                  borderRadius: 10,
                  borderWidth: isSelected ? 2.2 : 1.6,
                  shadowOffset: isSelected ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
                  backgroundColor: itemBg,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        game.icon,
                        size: 18,
                        color: itemTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        game.title,
                        style: GoogleFonts.patrickHand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: itemTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // 3.1. VEZİRLER ZORLUK SEÇİCİ & BİLGİ BANTLIĞI
        if (_selectedGame == GameType.queens)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  // Zorluk Filtre Çipleri
                  Row(
                    children: [
                      _buildQueensDifficultyChip(
                        label: 'Toplam Puan',
                        isSelected: _selectedQueensDifficulty == null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedQueensDifficulty = null);
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildQueensDifficultyChip(
                        label: 'Kolay',
                        isSelected: _selectedQueensDifficulty == 'kolay',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedQueensDifficulty = 'kolay');
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildQueensDifficultyChip(
                        label: 'Zor',
                        isSelected: _selectedQueensDifficulty == 'zor',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedQueensDifficulty = 'zor');
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildQueensDifficultyChip(
                        label: 'Master',
                        isSelected: _selectedQueensDifficulty == 'master',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedQueensDifficulty = 'master');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SketchCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.queensGame.withValues(alpha: isDark ? 0.25 : 0.18),
                    borderRadius: 10,
                    borderWidth: 1.6,
                    shadowOffset: const Offset(1.5, 1.5),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.pencil(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedQueensDifficulty == null
                                ? '👑 Vezirler Toplam Puanı = Kolay + Zor + Master seviyelerinin toplamıdır. Tekil sıralama görmek için yukarıdaki butonlara basabilirsiniz.'
                                : '👑 Vezirler ${_selectedQueensDifficulty!.toUpperCase()} seviyesi tekil sıralaması listeleniyor.',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencil(context),
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 4. KULLANICININ KENDİ DURUM KARTI (DİNAMİK SKOR VE SIRA)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SketchCard(
              enableHatching: true,
              borderRadius: 14,
              borderWidth: 2.5,
              shadowOffset: const Offset(3.5, 3.5),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Sol: Sıralama Kutusu
                  SketchPlaceholderBox(
                    width: 48,
                    height: 48,
                    fillColor: myRank != null ? _selectedGame.color : AppColors.surfaceSecondaryOf(context),
                    lineColor: AppColors.pencil(context),
                    borderRadius: 8,
                    child: Center(
                      child: Text(
                        myRank != null ? '#$myRank' : '-',
                        style: GoogleFonts.patrickHand(
                          color: myRank != null ? AppColors.pencilBlack : AppColors.pencil(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
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
                            Text(
                              'SİZİN SIRALAMANIZ',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.gray(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SketchDoodleCrown(size: 14, color: AppColors.pencil(context)),
                          ],
                        ),
                        Text(
                          myRank != null
                              ? (myRank == 1
                                  ? 'Zirvedesiniz! 👑'
                                  : (myRank <= 3 ? 'Podyumdasınız! 🏆' : 'Zirve %$topPercentile Dilimindesiniz'))
                              : 'Henüz Skorunuz Yok',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.pencil(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          myEntry != null
                              ? (myEntry.rank == 1
                                  ? 'Tebrikler! Liderlik koltuğundasınız!'
                                  : (myEntry.rank <= 3
                                      ? 'Harika bir performans, liderliği zorlayın!'
                                      : (entries[myEntryIndex - 1].totalScore - myEntry.totalScore > 0
                                          ? 'Bir üst sıra (#${myEntry.rank - 1}) için +${entries[myEntryIndex - 1].totalScore - myEntry.totalScore} puan gerekiyor!'
                                          : 'Bir üst sıra (#${myEntry.rank - 1}) için daha iyi süre gerekiyor!')))
                              : 'Bu kategoride henüz oyun oynamadınız.',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.graphite(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SketchCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    borderRadius: 8,
                    borderWidth: 1.6,
                    shadowOffset: const Offset(1.5, 1.5),
                    backgroundColor: AppColors.sunYellow,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          myEntry != null ? '${myEntry.totalScore}' : '0',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.pencilBlack,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'PUAN',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.pencilBlack,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
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

        // 5. ŞAMPİYONLAR KÜRSÜSÜ (KARA KALEM PODIUM)
        if (entries.length >= 3)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SketchCard(
                borderRadius: 16,
                borderWidth: 2.5,
                shadowOffset: const Offset(4.0, 4.0),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SketchDoodleTrophy(size: 20, color: AppColors.pencil(context)),
                        const SizedBox(width: 6),
                        Text(
                          'ŞAMPİYONLAR KÜRSÜSÜ',
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencil(context),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _SketchPodiumPillar(
                          entry: entries[1],
                          rank: 2,
                          fillColor: isDark ? const Color(0xFF3B4252) : const Color(0xFFE2E8F0),
                          pillarHeight: 80,
                          crownWidget: const Text('🥈', style: TextStyle(fontSize: 18)),
                        ),
                        _SketchPodiumPillar(
                          entry: entries[0],
                          rank: 1,
                          fillColor: AppColors.sunYellow,
                          pillarHeight: 105,
                          crownWidget: const SketchDoodleCrown(size: 26, color: AppColors.pencilBlack),
                          isFirst: true,
                        ),
                        _SketchPodiumPillar(
                          entry: entries[2],
                          rank: 3,
                          fillColor: AppColors.highlighterOrange,
                          pillarHeight: 68,
                          crownWidget: const Text('🥉', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 6. SIRALAMA LİSTESİ BAŞLIĞI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LİDERLİK TABLOSU (İLK 10 / ${entries.length} Yarışmacı)',
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite(context),
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'SÜRE / PUAN',
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. SIRALAMA ELEMANLARI (KARA KALEM SKEÇ LİSTE - İLK 10 + GEREKİRSE KULLANICI)
        entries.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'Bu dönem için henüz skor bulunmuyor.',
                      style: GoogleFonts.patrickHand(
                        color: AppColors.gray(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < top10.length) {
                        final entry = top10[index];
                        final isMe = entry.userId == 'user_local';
                        return _buildEntryCard(entry, isMe: isMe);
                      } else if (index == top10.length) {
                        return _buildSeparator();
                      } else {
                        return _buildEntryCard(myEntry!, isMe: true);
                      }
                    },
                    childCount: top10.length + (showUserBottomRow ? 2 : 0),
                  ),
                ),
              ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120), // Floating nav bar için pay
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 1.5,
            decoration: BoxDecoration(
              color: AppColors.pencil(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '•   •   •',
              style: GoogleFonts.patrickHand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gray(context),
                letterSpacing: 3,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 1.5,
            decoration: BoxDecoration(
              color: AppColors.pencil(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(LeaderboardEntry entry, {required bool isMe}) {
    final isDark = AppColors.isDark(context);
    final isTop3 = entry.rank <= 3;
    final detailText = _selectedGame == GameType.queens && _timeframe == LeaderboardTimeframe.daily
        ? '${entry.gamesPlayed}/3 Seviye • Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}'
        : (_timeframe == LeaderboardTimeframe.daily
            ? 'Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}'
            : '${entry.gamesPlayed} Oyun • En İyi: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SketchCard(
        borderRadius: 12,
        borderWidth: isMe ? 2.4 : 1.8,
        shadowOffset: isMe ? const Offset(3.5, 3.5) : const Offset(2.0, 2.0),
        backgroundColor: isMe
            ? (isDark ? AppColors.sunYellow.withValues(alpha: 0.22) : AppColors.sunYellow.withValues(alpha: 0.35))
            : AppColors.surfaceOf(context),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Rank Number
            SketchCard(
              borderRadius: 7,
              borderWidth: 1.4,
              shadowOffset: const Offset(1.5, 1.5),
              padding: EdgeInsets.zero,
              backgroundColor: isTop3
                  ? AppColors.sunYellow
                  : (isMe ? AppColors.sunYellow : AppColors.surfaceSecondaryOf(context)),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: (isTop3 || isMe) ? AppColors.pencilBlack : AppColors.pencil(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.userName + (isMe ? ' (Sen)' : ''),
                          style: GoogleFonts.patrickHand(
                            fontSize: 17,
                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.pencil(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.rank == 1) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.sunYellow),
                      ],
                      if (_selectedGame == GameType.queens &&
                          _timeframe == LeaderboardTimeframe.daily &&
                          entry.gamesPlayed == 3) ...[
                        const SizedBox(width: 6),
                        SketchCard(
                          borderRadius: 5,
                          borderWidth: 1.0,
                          shadowOffset: const Offset(1, 1),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          backgroundColor: AppColors.sunYellow.withValues(alpha: 0.25),
                          child: Text(
                            '3/3',
                            style: GoogleFonts.patrickHand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencil(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    detailText,
                    style: GoogleFonts.patrickHand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray(context),
                    ),
                  ),
                ],
              ),
            ),

            // Score Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalScore}',
                  style: GoogleFonts.patrickHand(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencil(context),
                  ),
                ),
                Text(
                  'PUAN',
                  style: GoogleFonts.patrickHand(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueensDifficultyChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SketchCard(
          borderRadius: 8,
          borderWidth: isSelected ? 2.0 : 1.4,
          shadowOffset: isSelected ? const Offset(1.8, 1.8) : const Offset(1.0, 1.0),
          backgroundColor: isSelected ? AppColors.sunYellow : AppColors.surfaceOf(context),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.patrickHand(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.inkBlack : AppColors.pencil(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchPodiumPillar extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Color fillColor;
  final double pillarHeight;
  final Widget crownWidget;
  final bool isFirst;

  const _SketchPodiumPillar({
    required this.entry,
    required this.rank,
    required this.fillColor,
    required this.pillarHeight,
    required this.crownWidget,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Taç Doodle
        crownWidget,
        const SizedBox(height: 2),

        // İsim
        SizedBox(
          width: 80,
          child: Text(
            entry.userId == 'user_local' ? 'Oyuncu (Sen)' : entry.userName,
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontWeight: FontWeight.w700,
              fontSize: isFirst ? 14 : 12,
              color: AppColors.pencil(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Puan
        Text(
          '${entry.totalScore} P',
          style: GoogleFonts.patrickHand(
            color: AppColors.pencil(context),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),

        // Podyum Kaidesi
        SketchCard(
          borderRadius: 8,
          borderWidth: 2.0,
          shadowOffset: const Offset(2.5, 2.5),
          backgroundColor: fillColor,
          enableHatching: true,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 82,
            height: pillarHeight,
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.patrickHand(
                  fontSize: isFirst ? 30 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onColor(fillColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
