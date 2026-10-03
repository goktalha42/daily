import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/game_stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/game_card_logos.dart';
import '../../core/widgets/screen_shake.dart';
import '../../games/common/base_game.dart';
import '../../games/queens/queens_screen.dart';
import '../../games/pinpoint/pinpoint_screen.dart';
import '../../games/crossclimb/crossclimb_screen.dart';
import '../../games/tango/tango_screen.dart';
import '../../games/zip_path/zip_screen.dart';
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
      backgroundColor: const Color(0xFFEDEFF3), // Kullanıcının istediği açık gri zemin
      extendBody: true,
      body: Stack(
        children: [
          // Arka plan açık gri ve hafif dinamik ışıltı dalgaları
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.geniusGold.withOpacity(0.08),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.3, duration: 4.seconds),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.hyperCyan.withOpacity(0.06),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.3, end: 1.0, duration: 5.seconds),
          ),

          IndexedStack(
            index: _bottomNavIndex,
            children: const [
              _GeniusLobbyTab(),
              LeaderboardScreen(),
              ProfileScreen(),
            ],
          ),

          // Alt Yüzen Navigasyon Çubuğu (Floating Nav Bar)
          Positioned(
            bottom: 22,
            left: 20,
            right: 20,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: const Color(0xFFDDE1E8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
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
                      label: 'Dahi Profil',
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
          ),
        ],
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
    final activeColor = const Color(0xFF0F172A);
    final inactiveColor = const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A).withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ).animate().fade(duration: 180.ms).slideX(begin: -0.15, end: 0),
            ],
          ],
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
  late Timer _countdownTimer;
  Duration _timeRemaining = GameDateUtils.getTimeUntilMidnight();
  String get _todayLevelId => GameDateUtils.getTodayLevelId();

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _timeRemaining = GameDateUtils.getTimeUntilMidnight());
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _advanceToNextDay() {
    setState(() {
      GameDateUtils.advanceToNextDay();
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

  void _launchGame(GameType game) {
    HapticFeedback.mediumImpact();
    Widget screen;
    switch (game) {
      case GameType.queens:
        screen = QueensScreen(levelId: _todayLevelId);
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
        // Üst Başlık & Tarih & Canlı Streak
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 54, bottom: 16),
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
                            color: Color(0xFF10B981),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 1.seconds),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Zeka Arenası',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
                // Yeni Gün ve Hızlı Tetikleyici
                Row(
                  children: [
                    InkWell(
                      onTap: _advanceToNextDay,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFB800)),
                            SizedBox(width: 4),
                            Text(
                              'Yeni Gün',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ADHD Dopamin Hero Kartı: Beyin Gücü / IQ / Top %1 Göstergesi
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sol: Zeka Durumu Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.6)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'DÜNYANIN EN İYİ %1\'İ',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFB800),
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sağ: Sayaç
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              GameDateUtils.formatCountdown(_timeRemaining),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // IQ Endeksi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GÜNLÜK BEYİN GÜCÜ ENDEKSİ',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'IQ $userIQ+',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DAHİ SEVİYESİ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mantık reaksiyonun ortalamadan 4.8 kat daha keskin!',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ateşli Seri
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A00), size: 30),
                            SizedBox(height: 2),
                            Text(
                              '5 GÜN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'SERİ',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 22, right: 22, top: 20, bottom: 8),
            child: Row(
              children: [
                Text(
                  'GÜNLÜK YARIŞMALAR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5 Oyun Butonları Listesi (Kullanıcının tam olarak istediği formatta!)
        // 1. Butonun arka planı oyunun kendine has özel logosunu içerir
        // 2. Üst bölümünde SADECE oyunun adı yazar
        // 3. Alt bölümünde kullanıcının en son girdiği yüzdelik dilim yazar
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = GameType.values[index];
                final perf = statsMap[game] ??
                    GamePerformanceData(
                      gameType: game,
                      bestScore: 0,
                      bestDurationMs: 0,
                      totalGamesPlayed: 0,
                      geniusTitle: 'Saf Dahi',
                    );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GeniusGameButton(
                    game: game,
                    performance: perf,
                    onTap: () => _launchGame(game),
                  ).animate().fade(duration: 350.ms, delay: (index * 80).ms).slideY(begin: 0.08, end: 0),
                );
              },
              childCount: GameType.values.length,
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

/// Kullanıcının Şart Koştuğu Özel Tasarım Oyun Butonu:
/// - Arka plan: Oyunun kendisine has olarak geliştirilmiş özel amblem logosu
/// - Üst bölüm: SADECE oyunun adı
/// - Alt bölüm: Kullanıcının en son oynadığı oyunda yüzde kaçlık dilime girdiyse o
class _GeniusGameButton extends StatefulWidget {
  final GameType game;
  final GamePerformanceData performance;
  final VoidCallback onTap;

  const _GeniusGameButton({
    required this.game,
    required this.performance,
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
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutQuad,
        child: Container(
          height: 140, // Ferah, prestijli yarışma kartı boyu
          decoration: BoxDecoration(
            color: Colors.white, // Açık gri zeminde parlayan saf beyaz kart
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: game.color.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // 1. ARKA PLAN: Oyunun Kendisine Has Geliştirilmiş Özel Logo!
                Positioned.fill(
                  child: GameBackgroundLogo(
                    gameType: game,
                    opacity: 0.92,
                  ),
                ),

                // Hafif sol degradeli cam katmanı (yazıların okunurluğu için kristal berraklık)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.96),
                          Colors.white.withOpacity(0.78),
                          Colors.white.withOpacity(0.18),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),

                // İçerik: Üstte SADECE oyunun adı, Altta kullanıcının girdiği yüzdelik dilim
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ÜST BÖLÜM: SADECE OYUNUN ADI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            game.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Sağ üstte oyunun tema renginde mini yarışma oku
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: game.color.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: game.color,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      // ALT BÖLÜM: KULLANICININ EN SON OYNADIĞI OYUNDA GİRDİĞİ YÜZDELİK DİLİM
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: perf.hasPlayed
                              ? (perf.percentile! <= 1
                                  ? const Color(0xFFFFB800).withOpacity(0.18)
                                  : game.color.withOpacity(0.12))
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: perf.hasPlayed
                                ? (perf.percentile! <= 1
                                    ? const Color(0xFFFFB800)
                                    : game.color.withOpacity(0.4))
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              perf.percentileBadgeText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: perf.hasPlayed
                                    ? (perf.percentile! <= 1
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF0F172A))
                                    : const Color(0xFF64748B),
                                letterSpacing: 0.3,
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
          ),
        ),
      ),
    );
  }
}
