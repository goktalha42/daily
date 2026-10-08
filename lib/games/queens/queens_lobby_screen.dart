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
  QueensDifficulty _selectedDifficulty = QueensDifficulty.orta;
  QueensDifficulty _activeLeaderboardTab = QueensDifficulty.orta;

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
                        backgroundColor: AppColors.highlighterYellow,
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
                                'Her satır, sütun ve renkte tam 1 vezir! Hiçbir iki vezir birbirine temas edemez.',
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
                        color: AppColors.highlighterGreen,
                        icon: Icons.eco_rounded,
                        queensCount: 6,
                        dailyPlay: dailyPlay,
                      ),
                      const SizedBox(height: 10),
                      _buildDifficultyCard(
                        context: context,
                        diff: QueensDifficulty.orta,
                        title: 'Orta Seviye (Önerilen)',
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
                        diff: QueensDifficulty.zor,
                        title: 'Zor Seviye',
                        badge: '9×9 IZGARA',
                        desc: 'İç içe geçmiş karmaşık bölgeler. Gerçek Zühtü ustalarına özel.',
                        color: AppColors.highlighterPink,
                        icon: Icons.psychology_rounded,
                        queensCount: 9,
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
                            backgroundColor: AppColors.highlighterYellow,
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
        return AppColors.highlighterGreen;
      case QueensDifficulty.orta:
        return AppColors.highlighterOrange;
      case QueensDifficulty.zor:
        return AppColors.highlighterPink;
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
    final isCompleted = dailyPlay.isCompleted(GameType.queens, widget.levelId);
    final record = dailyPlay.getRecord(GameType.queens, widget.levelId);

    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDifficulty = diff;
          _activeLeaderboardTab = diff;
        });
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
          // İkon Kutusu (Organik SketchCard)
          SketchCard(
            padding: EdgeInsets.zero,
            borderRadius: 12,
            borderWidth: 2.0,
            shadowOffset: const Offset(2.0, 2.0),
            backgroundColor: color,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(icon, color: AppColors.pencilBlack, size: 28),
              ),
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
                    SketchCard(
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
            onTap: () => _launchQueens(context, diff),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: isSelected ? color : AppColors.highlighterYellow,
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
      timeframe: LeaderboardTimeframe.allTime,
      difficulty: diff.name,
    );

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
                '${diff.label} Skorbordu (En İyiler)',
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
          else
            ...entries.take(5).toList().asMap().entries.map((item) {
              final idx = item.key;
              final entry = item.value;
              final rank = idx + 1;
              final isTop3 = rank <= 3;
              final rankColor = rank == 1
                  ? AppColors.highlighterYellow
                  : (rank == 2 ? const Color(0xFFE2E8F0) : (rank == 3 ? const Color(0xFFFED7AA) : Colors.transparent));

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  backgroundColor: isTop3 ? rankColor.withValues(alpha: 0.35) : AppColors.backgroundLight,
                  borderRadius: 10,
                  borderWidth: 1.5,
                  shadowOffset: const Offset(2.0, 2.0),
                  child: Row(
                    children: [
                      // Sıra Numarası (Organik SketchCard)
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
                      // Kullanıcı Adı
                      Expanded(
                        child: Text(
                          entry.userName,
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ),
                      // Tamamlama Süresi
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
                      // Puan (Organik SketchCard)
                      SketchCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        backgroundColor: AppColors.highlighterYellow,
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
        ],
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.pencilBlack, width: 2.5),
        ),
        title: Row(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleItem('1', 'Her Satır ve Sütunda 1 Vezir', 'Izgaradaki her yatay satır ve dikey sütunda tam olarak 1 adet vezir yer almalıdır.'),
            const SizedBox(height: 8),
            _buildRuleItem('2', 'Her Renk Bölgesinde 1 Vezir', 'Kalın siyah hatlarla ayrılmış her renkli bölgede tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 8),
            _buildRuleItem('3', 'Temas Yasağı (8 Yön)', 'Vezirler birbirine çapraz, dikey veya yatay olarak ASLA komşu olamaz.'),
            const SizedBox(height: 12),
            SketchCard(
              padding: const EdgeInsets.all(10),
              backgroundColor: AppColors.highlighterYellow.withValues(alpha: 0.3),
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
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.highlighterYellow,
              foregroundColor: AppColors.pencilBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.pencilBlack, width: 2.0),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Anladım!',
              style: GoogleFonts.patrickHand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
