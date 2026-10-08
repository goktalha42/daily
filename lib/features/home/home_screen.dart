import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/game_stats_service.dart';
import '../../core/services/time_sync_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/widgets/sketch_countdown_timer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/game_card_logos.dart';
import '../../core/widgets/screen_shake.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';
import '../../games/queens/queens_lobby_screen.dart';
import '../../games/pinpoint/pinpoint_screen.dart';
import '../../games/crossclimb/crossclimb_screen.dart';
import '../../games/tango/tango_screen.dart';
import '../../games/zip_path/zip_screen.dart';
import '../../games/patches/patches_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      body: SketchPaperBackground(
        child: Stack(
          children: [
            IndexedStack(
              index: _bottomNavIndex,
              children: const [
                _GeniusLobbyTab(),
                LeaderboardScreen(),
                ProfileScreen(),
              ],
            ),

            // Fotoğraftaki Gibi Kara Kalem Skeç Navigasyon Çubuğu (Hand-Drawn Sketch Bar)
            Positioned(
              bottom: 22,
              left: 20,
              right: 20,
              child: SketchCard(
                borderRadius: 18,
                borderWidth: 2.5,
                shadowOffset: const Offset(4, 4),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavTabItem(
                      icon: Icons.flash_on_rounded,
                      label: 'Oyunlar',
                      isSelected: _bottomNavIndex == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _bottomNavIndex = 0);
                      },
                    ),
                    _NavTabItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Sıralama',
                      isSelected: _bottomNavIndex == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _bottomNavIndex = 1);
                      },
                    ),
                    _NavTabItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      isSelected: _bottomNavIndex == 2,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _bottomNavIndex = 2);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Expanded(
        child: SketchCard(
          onTap: onTap,
          borderRadius: 10,
          borderWidth: 2.0,
          shadowOffset: const Offset(2.0, 2.0),
          backgroundColor: AppColors.surfaceSecondaryLight,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.pencilBlack, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.patrickHand(
                  color: AppColors.pencilBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.pencilGraphite,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// ADHD & Dopamin Dolu Yeni Nesil Ana Sayfa Görünümü
class _GeniusLobbyTab extends ConsumerStatefulWidget {
  const _GeniusLobbyTab();

  @override
  ConsumerState<_GeniusLobbyTab> createState() => _GeniusLobbyTabState();
}

class _GeniusLobbyTabState extends ConsumerState<_GeniusLobbyTab> {
  String get _todayLevelId => GameDateUtils.getTodayLevelId();

  void _advanceToNextDay() {
    setState(() {
      GameDateUtils.advanceToNextDay();
      ref.read(timeSyncServiceProvider).advanceDay();
    });
    // Ekran sarsıntısı ve dopamin kutlaması
    ScreenShake.shake(context, intensity: 12.0);
    GeniusConfettiOverlay.explode(context);

    final newDateStr = GameDateUtils.getFormattedDate(GameDateUtils.getActiveDate());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌅 $newDateStr Yarışması Başladı! Tüm bölümler yenilendi.'),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showCompletedDialog(GameType game, DailyPlayRecord record) {
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
            const Icon(Icons.check_circle_rounded, color: AppColors.highlighterGreen, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${game.title} Tamamlandı!',
                style: GoogleFonts.patrickHand(
                  color: AppColors.pencilBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünkü bulmacayı zaten başarıyla çözdün! Günlük tek oynama kuralı gereği skorun kaydedildi.',
              style: GoogleFonts.patrickHand(
                color: AppColors.pencilGraphite,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SketchCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 12,
              borderWidth: 1.8,
              shadowOffset: const Offset(2, 2),
              backgroundColor: AppColors.surfaceSecondaryLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('SKOR', style: GoogleFonts.patrickHand(fontSize: 13, color: AppColors.pencilGray, fontWeight: FontWeight.w700)),
                      Text('${record.score}', style: GoogleFonts.patrickHand(fontSize: 22, color: AppColors.pencilBlack, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('SÜRE', style: GoogleFonts.patrickHand(fontSize: 13, color: AppColors.pencilGray, fontWeight: FontWeight.w700)),
                      Text(GameDateUtils.formatGameTime(record.durationMs), style: GoogleFonts.patrickHand(fontSize: 22, color: AppColors.pencilBlack, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.pencilBlack),
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
        actions: [
          SketchCard(
            onTap: () => Navigator.pop(ctx),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            backgroundColor: AppColors.surfaceSecondaryLight,
            borderRadius: 12,
            borderWidth: 2.0,
            shadowOffset: const Offset(2, 2),
            child: Text(
              'Tamam',
              style: GoogleFonts.patrickHand(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pencilBlack),
            ),
          ),
        ],
      ),
    );
  }

  void _launchGame(GameType game) {
    HapticFeedback.mediumImpact();

    if (game == GameType.queens) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QueensLobbyScreen(levelId: _todayLevelId)),
      );
      return;
    }

    // Günlük tek oynama kuralı: tamamlandıysa kilitli diyalog aç
    final dailyPlay = ref.read(dailyPlayServiceProvider);
    if (dailyPlay.isCompleted(game, _todayLevelId)) {
      final record = dailyPlay.getRecord(game, _todayLevelId)!;
      _showCompletedDialog(game, record);
      return;
    }
    Widget screen;
    switch (game) {
      case GameType.queens:
        screen = QueensLobbyScreen(levelId: _todayLevelId);
        break;
      case GameType.pinpoint:
        screen = PinpointScreen(levelId: _todayLevelId);
        break;
      case GameType.crossclimb:
        screen = CrossclimbScreen(levelId: _todayLevelId);
        break;
      case GameType.tango:
        screen = TangoScreen(levelId: _todayLevelId);
        break;
      case GameType.zipPath:
        screen = ZipScreen(levelId: _todayLevelId);
        break;
      case GameType.patches:
        screen = PatchesScreen(levelId: _todayLevelId);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final activeDate = GameDateUtils.getActiveDate();
    final formattedDate = GameDateUtils.getFormattedDate(activeDate);
    final statsMap = ref.watch(gameStatsServiceProvider);
    final statsNotifier = ref.read(gameStatsServiceProvider.notifier);
    final userIQ = statsNotifier.getOverallIQ();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. ÜST BAŞLIK & TARİH & YENİ GÜN BUTONU
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
                          formattedDate.toUpperCase(),
                          style: GoogleFonts.patrickHand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Zeka Arenası',
                      style: GoogleFonts.patrickHand(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Fotoğraftaki Gibi Kara Kalem "Yeni Gün" Butonu
                SketchCard(
                  onTap: _advanceToNextDay,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: AppColors.surfaceSecondaryLight,
                  borderRadius: 10,
                  borderWidth: 2.0,
                  shadowOffset: const Offset(2.5, 2.5),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 18, color: AppColors.pencilBlack),
                      const SizedBox(width: 4),
                      Text(
                        'Yeni Gün',
                        style: GoogleFonts.patrickHand(
                          fontSize: 15,
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

        // 2. KARA KALEM SKEÇ HERO KARTI: IQ & BEYİN GÜCÜ & SERİ
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SketchCard(
              enableHatching: true,
              borderWidth: 2.5,
              borderRadius: 16,
              shadowOffset: const Offset(4.0, 4.0),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sol: Sarı Fosforlu Rozet
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.highlighterYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const SketchDoodleCrown(size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'DÜNYANIN EN İYİ %1\'İ',
                              style: GoogleFonts.patrickHand(
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sağ: Skeç Sayaç
                      const SketchCountdownTimer(fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // IQ Endeksi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SketchDoodleBrain(size: 18, color: AppColors.pencilBlack),
                                const SizedBox(width: 5),
                                Text(
                                  'GÜNLÜK BEYİN GÜCÜ ENDEKSİ',
                                  style: GoogleFonts.patrickHand(
                                    color: AppColors.pencilGray,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'IQ $userIQ+',
                                  style: GoogleFonts.patrickHand(
                                    color: AppColors.pencilBlack,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.highlighterCyan,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                                  ),
                                  child: Text(
                                    'ZÜHTÜ SEVİYESİ',
                                    style: GoogleFonts.patrickHand(
                                      color: AppColors.pencilBlack,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Mantık reaksiyonun ortalamadan 4.8 kat daha keskin!',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilGraphite,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ateşli Seri (Fotoğraftaki gibi el çizimi alev doodle'ı)
                      SketchPlaceholderBox(
                        width: 72,
                        height: 76,
                        fillColor: AppColors.highlighterOrange,
                        lineColor: AppColors.pencilBlack,
                        lineWidth: 2.0,
                        borderRadius: 12,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SketchDoodleFlame(size: 26, color: AppColors.pencilBlack),
                            Text(
                              '5 GÜN',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilBlack,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'SERİ',
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
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 8),
            child: Row(
              children: [
                Text(
                  'GÜNLÜK YARIŞMALAR (6 BÖLÜM)',
                  style: GoogleFonts.patrickHand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Oyun kutulari: capraz (zigzag) iki sutun, 2. sutun yarim kart asagida baslar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 16.0;
                final cardSize =
                    math.max(0.0, (constraints.maxWidth - gap) / 2);

                Widget buildCard(GameType game) {
                  final perf = statsMap[game] ??
                      GamePerformanceData(
                        gameType: game,
                        bestScore: 0,
                        bestDurationMs: 0,
                        totalGamesPlayed: 0,
                        geniusTitle: 'Zühtü Ustası',
                      );
                  final dailyPlay = ref.watch(dailyPlayServiceProvider);
                  final isCompleted = dailyPlay.isCompleted(game, _todayLevelId);
                  final record = dailyPlay.getRecord(game, _todayLevelId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: SizedBox(
                      width: cardSize,
                      height: cardSize,
                      child: _GeniusGameButton(
                        game: game,
                        performance: perf,
                        isCompleted: isCompleted,
                        record: record,
                        onTap: () => _launchGame(game),
                      ),
                    ),
                  );
                }

                final games = GameType.values;
                final leftGames = [
                  for (var i = 0; i < games.length; i += 2) games[i]
                ];
                final rightGames = [
                  for (var i = 1; i < games.length; i += 2) games[i]
                ];

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LadderPathPainter(period: cardSize * 1.7),
                      ),
                    ),
                    Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: leftGames.map(buildCard).toList()),
                    const SizedBox(width: gap),
                    Padding(
                      padding: EdgeInsets.only(top: cardSize * 0.3),
                      child: Column(children: rightGames.map(buildCard).toList()),
                    ),
                  ],
                )],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 110), // Nav bar için boşluk
        ),
      ],
    );
  }
}

/// Kara Kalem & Wireframe Oyun Butonu:
/// - Referans fotoğraftaki gibi sol tarafta içinde çapraz "X" olan sarı/turkuaz skeç görsel kutusu
/// - Üst bölüm: SADECE oyunun adı (El yazısıyla büyük ve net)
/// - Alt bölüm: Kullanıcının en son girdiği yüzdelik dilim (Fosforlu skeç etiketi)
/// - 2.5px siyah kurşun kalem kenarlık ve sert skeç gölgesi
class _GeniusGameButton extends StatefulWidget {
  final GameType game;
  final GamePerformanceData performance;
  final bool isCompleted;
  final DailyPlayRecord? record;
  final VoidCallback onTap;

  const _GeniusGameButton({
    required this.game,
    required this.performance,
    this.isCompleted = false,
    this.record,
    required this.onTap,
  });

  @override
  State<_GeniusGameButton> createState() => _GeniusGameButtonState();
}

class _GeniusGameButtonState extends State<_GeniusGameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final perf = widget.performance;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2.0 : 0.0,
          _isPressed ? 2.0 : 0.0,
          0.0,
        ),
        child: SketchCard(
          backgroundColor: Color.lerp(game.color, Colors.white, 0.55)!,
          borderColor: AppColors.pencilBlack,
          borderWidth: 2.5,
          borderRadius: 16,
          shadowOffset: _isPressed ? const Offset(1.5, 1.5) : const Offset(4.0, 4.0),
          padding: EdgeInsets.zero,
          child: SizedBox.expand(
            child: Stack(
              children: [
                // Arka plan: oyuna ozgu eskiz logo
                Positioned.fill(
                  child: GameBackgroundLogo(
                    gameType: game,
                    opacity: 0.35,
                  ),
                ),
                if (widget.isCompleted)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.highlighterGreen,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.pencilBlack, width: 2.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pencilBlack,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.pencilBlack,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        game.title.toUpperCase(),
                        maxLines: 2,
                        style: GoogleFonts.patrickHand(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.isCompleted
                              ? AppColors.highlighterGreen
                              : (perf.hasPlayed
                                  ? (perf.percentile! <= 1
                                      ? AppColors.highlighterYellow
                                      : game.color)
                                  : AppColors.surfaceSecondaryLight),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.pencilBlack,
                            width: 1.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pencilBlack,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.isCompleted
                              ? 'BİTTİ • ${widget.record?.score ?? 0}P'
                              : perf.percentileBadgeText,
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}


/// Kartlarin arkasinda asagi dogru kivrilarak inen, icerik uzadikca uzayan
/// el cizimi merdiven / sarmal yol. Yukseklik icerige gore otomatik olusur.
class _LadderPathPainter extends CustomPainter {
  final double period;
  const _LadderPathPainter({required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final amp = size.width * 0.30;
    final strand = Paint()
      ..color = AppColors.pencilGraphite.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = AppColors.pencilGraphite.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final p1 = Path();
    final p2 = Path();
    for (double y = 0; y <= size.height; y += 4) {
      final s = math.sin(y / period * 2 * math.pi);
      final x1 = cx + amp * s;
      final x2 = cx - amp * s;
      if (y == 0) {
        p1.moveTo(x1, y);
        p2.moveTo(x2, y);
      } else {
        p1.lineTo(x1, y);
        p2.lineTo(x2, y);
      }
    }
    final step = period / 10;
    for (double y = step / 2; y <= size.height; y += step) {
      final s = math.sin(y / period * 2 * math.pi);
      canvas.drawLine(
          Offset(cx + amp * s, y), Offset(cx - amp * s, y), rung);
    }
    canvas.drawPath(p1, strand);
    canvas.drawPath(p2, strand);
  }

  @override
  bool shouldRepaint(covariant _LadderPathPainter old) => old.period != period;
}