import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/services/daily_play_service.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'queens_models.dart';
import 'queens_screen.dart';

/// Zühtü - Vezirler (Queens) Giriş, Zorluk Seçimi ve Zorluk Skorbordları Ekranı
///
/// Kara Kalem Eskiz Defteri tasarım diline uygun olarak;
/// Kolay (6x6), Orta (8x8) ve Zor (9x9) modları için seçim kartları ve
/// her zorluk seviyesine özel bağımsız liderlik tablolarını sunar.
class QueensLobbyScreen extends ConsumerStatefulWidget {
  final String levelId;

  const QueensLobbyScreen({
    super.key,
    required this.levelId,
  });

  @override
  ConsumerState<QueensLobbyScreen> createState() => _QueensLobbyScreenState();
}

class _QueensLobbyScreenState extends ConsumerState<QueensLobbyScreen> {
  QueensDifficulty _selectedDifficulty = QueensDifficulty.kolay;
  QueensDifficulty _activeLeaderboardTab = QueensDifficulty.kolay;

  @override
  Widget build(BuildContext context) {
    final dailyPlay = ref.watch(dailyPlayServiceProvider);
    final activeDate = GameDateUtils.getActiveDate();
    final formattedDate = GameDateUtils.getFormattedDate(activeDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. ÜST GEZİNTİ VE BAŞLIK ÇUBUĞU
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SketchCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 10,
                        shadowOffset: const Offset(2.5, 2.5),
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SketchDoodleCrown(size: 16, color: AppColors.pencilBlack),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate.toUpperCase(),
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilGraphite,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'VEZİRLER ARENASI',
                            style: GoogleFonts.patrickHand(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                      // Bilgi & İpucu Butonu
                      SketchCard(
                        backgroundColor: AppColors.sunYellow,
                        padding: const EdgeInsets.all(8),
                        borderRadius: 10,
                        shadowOffset: const Offset(2.5, 2.5),
                        onTap: () => _showQueensRules(context),
                        child: const Icon(
                          Icons.question_mark_rounded,
                          size: 18,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. GİRİŞ VE MOTİVASYON HERO KARTI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: SketchCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    shadowOffset: const Offset(3.5, 3.5),
                    backgroundColor: AppColors.surfaceLight,
                    child: Row(
                      children: [
                        SketchCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 12,
                          borderWidth: 2.0,
                          shadowOffset: const Offset(2.0, 2.0),
                          backgroundColor: AppColors.highlighterPink.withValues(alpha: 0.35),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: SketchDoodleCrown(size: 26, color: AppColors.pencilBlack),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seviyeni Seç & Tahtayı Fethet',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                              Text(
                                'Kolay & Zor modlarda 1 vezir; Master modunda ise her renkte, satırda ve sütunda tam 2 vezir!',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 14,
                                  color: AppColors.pencilGraphite,
                                  height: 1.15,
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

              // 3. ZORLUK SEVİYELERİ BAŞLIĞI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Row(
                    children: [
                      SketchCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 4,
                        borderWidth: 1.2,
                        shadowOffset: const Offset(1.0, 1.0),
                        backgroundColor: AppColors.highlighterPink,
                        child: const SizedBox(width: 8, height: 8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ZORLUK SEVİYELERİ',
                        style: GoogleFonts.patrickHand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilGraphite,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. ÜÇ AYRI ZORLUK SEÇİM KARTI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      _buildDifficultyCard(
                        context: context,
                        diff: QueensDifficulty.kolay,
                        title: 'Kolay Seviye',
                        badge: '6×6 IZGARA',
                        desc: 'Geniş bölgeler, rahat çıkarımlar. Hızlı ve keyifli bir başlangıç.',
                        color: AppColors.accentCyan,
                        icon: Icons.eco_rounded,
                        queensCount: 6,
                        dailyPlay: dailyPlay,
                      ),
                      const SizedBox(height: 10),
                      _buildDifficultyCard(
                        context: context,
                        diff: QueensDifficulty.zor,
                        title: 'Zor Seviye',
                        badge: '8×8 IZGARA',
                        desc: 'Dengeli mantık zincirleri ve stratejik alan elemeleri.',
                        color: AppColors.highlighterOrange,
                        icon: Icons.bolt_rounded,
                        queensCount: 8,
                        dailyPlay: dailyPlay,
                      ),
                      const SizedBox(height: 10),
                      _buildDifficultyCard(
                        context: context,
                        diff: QueensDifficulty.master,
                        title: 'Master Seviye',
                        badge: '9×9 • ÇİFT VEZİR',
                        desc: 'Her renkte, satırda ve sütunda 2 vezir! Gerçek Zühtü ustalarına özel.',
                        color: AppColors.accentPurple,
                        icon: Icons.castle_rounded,
                        queensCount: 18,
                        dailyPlay: dailyPlay,
                      ),
                    ],
                  ),
                ),
              ),

              // 5. AYRI SKORBORDLAR BAŞLIĞI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SketchCard(
                            padding: EdgeInsets.zero,
                            borderRadius: 4,
                            borderWidth: 1.2,
                            shadowOffset: const Offset(1.0, 1.0),
                            backgroundColor: AppColors.sunYellow,
                            child: const SizedBox(width: 8, height: 8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SEVİYEYE ÖZEL SKORBORDLAR',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilGraphite,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Bugün',
                        style: GoogleFonts.patrickHand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. SKORBORD ZORLUK SEKMELERİ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: QueensDifficulty.values.map((diff) {
                      final isSelected = diff == _activeLeaderboardTab;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: SketchCard(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _activeLeaderboardTab = diff);
                            },
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: isSelected
                                ? _getDiffColor(diff)
                                : AppColors.surfaceLight,
                            borderRadius: 10,
                            borderWidth: isSelected ? 2.2 : 1.5,
                            shadowOffset: isSelected ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
                            enableHatching: isSelected,
                            child: Center(
                              child: Text(
                                '${diff.label} (${_getGridSize(diff)}x${_getGridSize(diff)})',
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

              // 7. AKTİF SEVİYENİN SKORBORD LİSTESİ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  child: _buildLeaderboardForDifficulty(_activeLeaderboardTab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getGridSize(QueensDifficulty diff) {
    return diff.gridSize;
  }

  Color _getDiffColor(QueensDifficulty diff) {
    switch (diff) {
      case QueensDifficulty.kolay:
        return AppColors.accentCyan;
      case QueensDifficulty.zor:
        return AppColors.highlighterOrange;
      case QueensDifficulty.master:
        return AppColors.accentPurple;
    }
  }

  Widget _buildDifficultyLogo(QueensDifficulty diff) {
    switch (diff) {
      case QueensDifficulty.kolay:
        return const Center(
          child: SketchDoodleCrown(
            size: 28,
            color: AppColors.pencilBlack,
            fillColor: AppColors.sunYellow,
          ),
        );
      case QueensDifficulty.zor:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.star_rounded, size: 9, color: AppColors.pencilBlack),
                  const SizedBox(width: 1),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: const Icon(Icons.star_rounded, size: 12, color: AppColors.pencilBlack),
                  ),
                  const SizedBox(width: 1),
                  const Icon(Icons.star_rounded, size: 9, color: AppColors.pencilBlack),
                ],
              ),
              const SizedBox(height: 1),
              const SketchDoodleCrown(
                size: 24,
                color: AppColors.pencilBlack,
                fillColor: AppColors.sunYellow,
              ),
            ],
          ),
        );
      case QueensDifficulty.master:
        return const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SketchDoodleCrown(
                size: 19,
                color: AppColors.pencilBlack,
                fillColor: AppColors.sunYellow,
              ),
              SizedBox(width: 2),
              SketchDoodleCrown(
                size: 19,
                color: AppColors.pencilBlack,
                fillColor: AppColors.sunYellow,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDifficultyCard({
    required BuildContext context,
    required QueensDifficulty diff,
    required String title,
    required String badge,
    required String desc,
    required Color color,
    required IconData icon,
    required int queensCount,
    required DailyPlayState dailyPlay,
  }) {
    final isSelected = _selectedDifficulty == diff;
    final isCompleted = dailyPlay.isCompleted(GameType.queens, widget.levelId, subKey: diff.name);
    final record = dailyPlay.getRecord(GameType.queens, widget.levelId, subKey: diff.name);

    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDifficulty = diff;
          _activeLeaderboardTab = diff;
        });
        if (isCompleted) {
          _showCompletedDialog(context, diff, record);
        }
      },
      backgroundColor: isSelected
          ? Color.lerp(color, Colors.white, 0.75)!
          : AppColors.surfaceLight,
      borderRadius: 16,
      borderWidth: isSelected ? 2.6 : 2.0,
      shadowOffset: isSelected ? const Offset(3.5, 3.5) : const Offset(2.0, 2.0),
      enableHatching: isSelected,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // İkon Kutusu (Kolay: Tek Vezir, Zor: Tek Vezir + 3 Yıldız, Master: Çift Vezir)
          SketchCard(
            padding: EdgeInsets.zero,
            borderRadius: 12,
            borderWidth: 2.0,
            shadowOffset: const Offset(2.0, 2.0),
            backgroundColor: color,
            child: SizedBox(
              width: 50,
              height: 50,
              child: _buildDifficultyLogo(diff),
            ),
          ),
          const SizedBox(width: 14),
          // Bilgi Bölümü
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.patrickHand(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          backgroundColor: color.withValues(alpha: 0.35),
                          borderRadius: 6,
                          borderWidth: 1.2,
                          shadowOffset: const Offset(1.0, 1.0),
                          child: Text(
                            badge,
                            style: GoogleFonts.patrickHand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    color: AppColors.pencilGraphite,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Başla / Oyna Butonu (Organik SketchCard)
          SketchCard(
            onTap: () {
              if (isCompleted) {
                _showCompletedDialog(context, diff, record);
              } else {
                _launchQueens(context, diff);
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: isSelected ? color : AppColors.sunYellow,
            borderRadius: 10,
            borderWidth: 2.0,
            shadowOffset: const Offset(2.0, 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompleted ? 'BİTTİ (${record?.score ?? 0}P)' : 'OYNA',
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isCompleted ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: AppColors.pencilBlack,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardForDifficulty(QueensDifficulty diff) {
    final leaderboardService = ref.watch(leaderboardServiceProvider);
    final entries = leaderboardService.getLeaderboard(
      gameType: GameType.queens,
      timeframe: LeaderboardTimeframe.daily,
      difficulty: diff.name,
      levelId: widget.levelId,
    );

    final myEntryIndex = entries.indexWhere((e) => e.userId == 'user_local');
    final isTop10 = myEntryIndex != -1 && myEntryIndex < 10;

    return SketchCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      shadowOffset: const Offset(3.5, 3.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${diff.label} Skorbordu (Bugün)',
                style: GoogleFonts.patrickHand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilBlack,
                ),
              ),
              SketchCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                backgroundColor: AppColors.surfaceSecondaryLight,
                borderRadius: 6,
                borderWidth: 1.2,
                shadowOffset: const Offset(1.0, 1.0),
                child: Text(
                  '${entries.length} Yarışmacı',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Bu seviye için henüz skor kaydedilmedi.\nİlk çözen sen ol!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    color: AppColors.pencilGray,
                  ),
                ),
              ),
            )
          else ...[
            ...entries.take(10).toList().asMap().entries.map((item) {
              final idx = item.key;
              final entry = item.value;
              final rank = idx + 1;
              final isTop3 = rank <= 3;
              final isMe = entry.userId == 'user_local';
              final rankColor = rank == 1
                  ? AppColors.sunYellow
                  : (rank == 2 ? const Color(0xFFE2E8F0) : (rank == 3 ? const Color(0xFFFED7AA) : Colors.transparent));

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  backgroundColor: isMe
                      ? AppColors.sunYellow.withValues(alpha: 0.35)
                      : (isTop3 ? rankColor.withValues(alpha: 0.35) : AppColors.backgroundLight),
                  borderRadius: 10,
                  borderWidth: isMe ? 2.2 : 1.5,
                  shadowOffset: isMe ? const Offset(2.5, 2.5) : const Offset(2.0, 2.0),
                  child: Row(
                    children: [
                      SketchCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 6,
                        borderWidth: 1.2,
                        shadowOffset: const Offset(1.0, 1.0),
                        backgroundColor: isTop3 ? rankColor : AppColors.surfaceLight,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Text(
                              '$rank',
                              style: GoogleFonts.patrickHand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.userName + (isMe ? ' (Sen)' : ''),
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.pencilGray),
                          const SizedBox(width: 4),
                          Text(
                            GameDateUtils.formatGameTime(entry.bestTimeMs),
                            style: GoogleFonts.patrickHand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilGraphite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      SketchCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        backgroundColor: AppColors.sunYellow,
                        borderRadius: 6,
                        borderWidth: 1.2,
                        shadowOffset: const Offset(1.0, 1.0),
                        child: Text(
                          '${entry.totalScore} P',
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (!isTop10 && myEntryIndex != -1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Center(
                  child: Text(
                    '•   •   •',
                    style: GoogleFonts.patrickHand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pencilGray,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              Builder(builder: (context) {
                final myEntry = entries[myEntryIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SketchCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: AppColors.sunYellow.withValues(alpha: 0.35),
                    borderRadius: 10,
                    borderWidth: 2.2,
                    shadowOffset: const Offset(2.5, 2.5),
                    child: Row(
                      children: [
                        SketchCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 6,
                          borderWidth: 1.2,
                          shadowOffset: const Offset(1.0, 1.0),
                          backgroundColor: AppColors.sunYellow,
                          child: SizedBox(
                            width: 28,
                            height: 24,
                            child: Center(
                              child: Text(
                                '#${myEntry.rank}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '${myEntry.userName} (Sen)',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.person_rounded, size: 14, color: AppColors.pencilBlack),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.pencilGray),
                            const SizedBox(width: 4),
                            Text(
                              GameDateUtils.formatGameTime(myEntry.bestTimeMs),
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilGraphite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          backgroundColor: AppColors.sunYellow,
                          borderRadius: 6,
                          borderWidth: 1.2,
                          shadowOffset: const Offset(1.0, 1.0),
                          child: Text(
                            '${myEntry.totalScore} P',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  void _showCompletedDialog(BuildContext context, QueensDifficulty diff, DailyPlayRecord? record) {
    final leaderboardService = ref.read(leaderboardServiceProvider);
    leaderboardService.syncWithDailyPlay(ref.read(dailyPlayServiceProvider));

    final entries = leaderboardService.getLeaderboard(
      gameType: GameType.queens,
      timeframe: LeaderboardTimeframe.daily,
      difficulty: diff.name,
      levelId: widget.levelId,
    );

    final myEntryIndex = entries.indexWhere((e) => e.userId == 'user_local');
    final myRank = myEntryIndex != -1 ? entries[myEntryIndex].rank : null;
    final isTop10 = myRank != null && myRank <= 10;
    final top10 = entries.take(10).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            maxWidth: 440,
          ),
          child: SketchCard(
            backgroundColor: Colors.white,
            borderRadius: 18,
            borderWidth: 2.5,
            shadowOffset: const Offset(4.0, 4.0),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık Satırı
                Row(
                  children: [
                    SketchCard(
                      padding: const EdgeInsets.all(6),
                      borderRadius: 18,
                      borderWidth: 1.8,
                      shadowOffset: const Offset(1.5, 1.5),
                      backgroundColor: AppColors.success.withValues(alpha: 0.15),
                      child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${diff.label} Seviyesi Tamamlandı!',
                            style: GoogleFonts.patrickHand(
                              color: AppColors.pencilBlack,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'Bugünkü ${diff.label} seviyesi başarıyla çözüldü.',
                            style: GoogleFonts.patrickHand(
                              color: AppColors.pencilGray,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Kaydırılabilir İçerik
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SketchCard(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          borderWidth: 2.0,
                          shadowOffset: const Offset(2.5, 2.5),
                          backgroundColor: AppColors.surfaceSecondaryLight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('SKOR', style: GoogleFonts.patrickHand(fontSize: 12, color: AppColors.pencilGray, fontWeight: FontWeight.w700)),
                                  Text('${record?.score ?? 0}', style: GoogleFonts.patrickHand(fontSize: 22, color: AppColors.pencilBlack, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Container(width: 1.5, height: 32, color: AppColors.pencilBlack.withValues(alpha: 0.2)),
                              Column(
                                children: [
                                  Text('SÜRE', style: GoogleFonts.patrickHand(fontSize: 12, color: AppColors.pencilGray, fontWeight: FontWeight.w700)),
                                  Text(
                                    GameDateUtils.formatGameTime(record?.durationMs ?? 0),
                                    style: GoogleFonts.patrickHand(fontSize: 20, color: AppColors.pencilBlack, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Container(width: 1.5, height: 32, color: AppColors.pencilBlack.withValues(alpha: 0.2)),
                              Column(
                                children: [
                                  Text('GÜNLÜK SIRA', style: GoogleFonts.patrickHand(fontSize: 12, color: AppColors.pencilGray, fontWeight: FontWeight.w700)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('#${myRank ?? '-'}', style: GoogleFonts.patrickHand(fontSize: 22, color: AppColors.pencilBlack, fontWeight: FontWeight.w700)),
                                      Text('/${entries.length}', style: GoogleFonts.patrickHand(fontSize: 13, color: AppColors.pencilGray, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.leaderboard_rounded, size: 16, color: AppColors.pencilBlack),
                                const SizedBox(width: 6),
                                Text(
                                  '${diff.label.toUpperCase()} İLK 10 SIRALAMASI',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencilBlack,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            if (myRank != null)
                              SketchCard(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                borderRadius: 6,
                                borderWidth: 1.2,
                                shadowOffset: const Offset(1, 1),
                                backgroundColor: AppColors.sunYellow.withValues(alpha: 0.25),
                                child: Text(
                                  myRank <= 3
                                      ? '🏆 Podyumdasın!'
                                      : (myRank <= 10 ? '🔥 İlk 10\'dasın!' : 'İlk %${((myRank / entries.length) * 100).ceil()}\'desin'),
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencilBlack,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...top10.map((entry) {
                          final isMe = entry.userId == 'user_local';
                          final isPodium = entry.rank <= 3;
                          final rankBg = entry.rank == 1
                              ? AppColors.sunYellow
                              : (entry.rank == 2
                                  ? const Color(0xFFE2E8F0)
                                  : (entry.rank == 3 ? const Color(0xFFFED7AA) : AppColors.surfaceLight));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SketchCard(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              borderRadius: 10,
                              borderWidth: isMe ? 2.2 : 1.4,
                              shadowOffset: isMe ? const Offset(2.0, 2.0) : const Offset(1.0, 1.0),
                              backgroundColor: isMe
                                  ? AppColors.sunYellow.withValues(alpha: 0.35)
                                  : (isPodium ? rankBg.withValues(alpha: 0.25) : AppColors.backgroundLight),
                              child: Row(
                                children: [
                                  SketchCard(
                                    borderRadius: 6,
                                    borderWidth: 1.2,
                                    shadowOffset: const Offset(1, 1),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: rankBg,
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Center(
                                        child: Text(
                                          '${entry.rank}',
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.pencilBlack,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.userName + (isMe ? ' (Sen)' : ''),
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 15,
                                        fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                                        color: AppColors.pencilBlack,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 12, color: AppColors.pencilGray),
                                      const SizedBox(width: 3),
                                      Text(
                                        GameDateUtils.formatGameTime(entry.bestTimeMs),
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 13,
                                          color: AppColors.pencilGraphite,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  SketchCard(
                                    borderRadius: 6,
                                    borderWidth: 1.2,
                                    shadowOffset: const Offset(1, 1),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    backgroundColor: AppColors.sunYellow,
                                    child: Text(
                                      '${entry.totalScore} P',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pencilBlack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (!isTop10 && myEntryIndex != -1) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Center(
                              child: Text(
                                '•   •   •',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilGray,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                          Builder(builder: (context) {
                            final myEntry = entries[myEntryIndex];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: SketchCard(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                borderRadius: 10,
                                borderWidth: 2.2,
                                shadowOffset: const Offset(2.0, 2.0),
                                backgroundColor: AppColors.sunYellow.withValues(alpha: 0.35),
                                child: Row(
                                  children: [
                                    SketchCard(
                                      borderRadius: 6,
                                      borderWidth: 1.2,
                                      shadowOffset: const Offset(1, 1),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: AppColors.sunYellow,
                                      child: SizedBox(
                                        width: 28,
                                        height: 24,
                                        child: Center(
                                          child: Text(
                                            '#${myEntry.rank}',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.pencilBlack,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            '${myEntry.userName} (Sen)',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.pencilBlack,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.person_rounded, size: 14, color: AppColors.pencilBlack),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.pencilGray),
                                        const SizedBox(width: 3),
                                        Text(
                                          GameDateUtils.formatGameTime(myEntry.bestTimeMs),
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 13,
                                            color: AppColors.pencilGraphite,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    SketchCard(
                                      borderRadius: 6,
                                      borderWidth: 1.2,
                                      shadowOffset: const Offset(1, 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      backgroundColor: AppColors.sunYellow,
                                      child: Text(
                                        '${myEntry.totalScore} P',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pencilBlack,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.lock_clock_rounded, size: 15, color: AppColors.pencilBlack),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Yeni bulmaca yarın saat 00:00 (UTC) sıfırlanmasında açılacak.',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  color: AppColors.pencilBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SketchCard(
                        onTap: () => Navigator.pop(ctx),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: AppColors.surfaceSecondaryLight,
                        borderRadius: 10,
                        borderWidth: 1.8,
                        shadowOffset: const Offset(2, 2),
                        child: Center(
                          child: Text(
                            'Kapat',
                            style: GoogleFonts.patrickHand(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pencilBlack),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchQueens(BuildContext context, QueensDifficulty diff) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QueensScreen(
          levelId: widget.levelId,
          initialDifficulty: diff,
        ),
      ),
    );
  }

  void _showQueensRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SketchCard(
            backgroundColor: Colors.white,
            borderRadius: 18,
            borderWidth: 2.5,
            shadowOffset: const Offset(4.0, 4.0),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.castle_rounded, color: AppColors.highlighterPink, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Vezirler Kuralları',
                      style: GoogleFonts.patrickHand(
                        color: AppColors.pencilBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRuleItem('1', 'Her Satır ve Sütunda Vezir Kuralı', 'Kolay ve Zor modlarda her satır ve sütunda tam 1 vezir; Master modunda ise tam 2 vezir yer almalıdır.'),
                const SizedBox(height: 8),
                _buildRuleItem('2', 'Her Renk Bölgesinde Vezir Kuralı', 'Her renkli bölgede moduna göre tam 1 (Master modda tam 2) vezir bulunmalıdır.'),
                const SizedBox(height: 8),
                _buildRuleItem('3', 'Temas Yasağı (8 Yön)', 'Vezirler birbirine çapraz, dikey veya yatay olarak ASLA komşu olamaz.'),
                const SizedBox(height: 12),
                SketchCard(
                  padding: const EdgeInsets.all(10),
                  backgroundColor: AppColors.sunYellow.withValues(alpha: 0.3),
                  borderRadius: 12,
                  borderWidth: 1.8,
                  shadowOffset: const Offset(2.0, 2.0),
                  child: Text(
                    '• Tek Dokun: Boş kutuya ✖ koy veya kaldır.\n• Sürükle: Çoklu ✖ boya veya temizle.\n• Çift Dokun: Kutuya 👑 (Vezir) yerleştir.',
                    style: GoogleFonts.patrickHand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pencilBlack,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SketchCard(
                  onTap: () => Navigator.pop(ctx),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: AppColors.sunYellow,
                  borderRadius: 10,
                  borderWidth: 1.8,
                  shadowOffset: const Offset(2, 2),
                  child: Center(
                    child: Text(
                      'Anladım!',
                      style: GoogleFonts.patrickHand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SketchCard(
          padding: EdgeInsets.zero,
          borderRadius: 6,
          borderWidth: 1.4,
          shadowOffset: const Offset(1.0, 1.0),
          backgroundColor: AppColors.highlighterPink,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.patrickHand(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.pencilBlack,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.patrickHand(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.pencilBlack,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  color: AppColors.pencilGraphite,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
