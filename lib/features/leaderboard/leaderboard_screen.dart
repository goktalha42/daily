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
  LeaderboardTimeframe _timeframe = LeaderboardTimeframe.weekly;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(leaderboardServiceProvider);
    final entries = service.getLeaderboard(
      gameType: _selectedGame,
      timeframe: _timeframe,
    );

    // Kullanıcının kendi derecesini bul veya simüle et
    final myEntryIndex = entries.indexWhere((e) => e.userId == 'user_local' || e.userName.contains('Siz'));
    final myRank = myEntryIndex != -1 ? myEntryIndex + 1 : 4;

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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.highlighterYellow,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.pencilBlack, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GLOBAL ARENA • GÜNCEL',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
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
                        color: AppColors.pencilBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Skeç Lig Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.highlighterYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.pencilBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
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

        // 2. FOTOĞRAFTAKİ GİBİ SKEÇ DÖNEM SEÇİCİ (HAFTALIK / AYLIK / GENEL)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pencilBlack,
                    offset: Offset(2.5, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: LeaderboardTimeframe.values.map((tf) {
                  final isSelected = _timeframe == tf;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _timeframe = tf);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.highlighterYellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppColors.pencilBlack, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            tf.label,
                            style: GoogleFonts.patrickHand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
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
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: GameType.values.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final game = GameType.values[index];
                final isSelected = _selectedGame == game;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGame = game);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? game.color : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.pencilBlack,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pencilBlack,
                          offset: isSelected ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          game.icon,
                          size: 18,
                          color: AppColors.pencilBlack,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          game.title,
                          style: GoogleFonts.patrickHand(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 4. KULLANICININ KENDİ DURUM KARTI (SKEÇ KUTUSU)
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
                  // Sol: Çapraz X Kutusu İçinde Sıralama
                  SketchPlaceholderBox(
                    width: 48,
                    height: 48,
                    fillColor: _selectedGame.color,
                    lineColor: AppColors.pencilBlack,
                    borderRadius: 8,
                    child: Center(
                      child: Text(
                        '#$myRank',
                        style: GoogleFonts.patrickHand(
                          color: AppColors.pencilBlack,
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
                                color: AppColors.pencilGray,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const SketchDoodleCrown(size: 14, color: AppColors.pencilBlack),
                          ],
                        ),
                        Text(
                          'Zirve %1 Dilimindesiniz',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.pencilBlack,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Podyuma girmeye sadece 80 puan kaldı!',
                          style: GoogleFonts.patrickHand(
                            color: AppColors.pencilGraphite,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.highlighterYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1,740',
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
                        const SketchDoodleTrophy(size: 20, color: AppColors.pencilBlack),
                        const SizedBox(width: 6),
                        Text(
                          'ŞAMPİYONLAR KÜRSÜSÜ',
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
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
                          fillColor: const Color(0xFFE2E8F0),
                          pillarHeight: 80,
                          crownWidget: const Text('🥈', style: TextStyle(fontSize: 18)),
                        ),
                        _SketchPodiumPillar(
                          entry: entries[0],
                          rank: 1,
                          fillColor: AppColors.highlighterYellow,
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
                  'TÜM YARIŞMACILAR',
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'SÜRE / PUAN',
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGray,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. SIRALAMA ELEMANLARI (KARA KALEM SKEÇ LİSTE)
        entries.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'Bu dönem için henüz skor bulunmuyor.',
                      style: GoogleFonts.patrickHand(
                        color: AppColors.pencilGray,
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
                      final entry = entries[index];
                      final isTop3 = entry.rank <= 3;
                      final isMe = entry.userId == 'user_local' || entry.userName.contains('Siz');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.highlighterYellow.withValues(alpha: 0.4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.pencilBlack,
                            width: isMe ? 2.2 : 1.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pencilBlack,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Rank Number
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? AppColors.highlighterYellow
                                    : AppColors.surfaceSecondaryLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.rank}',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencilBlack,
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
                                          entry.userName + (isMe ? ' (Siz)' : ''),
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.pencilBlack,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (entry.rank == 1) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, size: 16, color: AppColors.pencilBlack),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    'Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.pencilGray,
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
                                    color: AppColors.pencilBlack,
                                  ),
                                ),
                                Text(
                                  'PUAN',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencilGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120), // Floating nav bar için pay
        ),
      ],
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
            entry.userName,
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontWeight: FontWeight.w700,
              fontSize: isFirst ? 14 : 12,
              color: AppColors.pencilBlack,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Puan
        Text(
          '${entry.totalScore} P',
          style: GoogleFonts.patrickHand(
            color: AppColors.pencilBlack,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),

        // Podyum Kaidesi (Fotoğraftaki gibi kutu içinde çapraz skeç çizgileri)
        Container(
          width: 82,
          height: pillarHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: AppColors.pencilBlack,
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.pencilBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.patrickHand(
                fontSize: isFirst ? 30 : 24,
                fontWeight: FontWeight.w700,
                color: AppColors.pencilBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


