import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/widgets/app_card.dart';
import '../../core/utils/date_utils.dart';
import '../../games/common/base_game.dart';
import '../../games/queens/queens_screen.dart';
import '../../games/pinpoint/pinpoint_screen.dart';
import '../../games/crossclimb/crossclimb_screen.dart';
import '../../games/tango/tango_screen.dart';
import '../../games/zip_path/zip_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Subtle Mesh/Glow background effect
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.1),
                    blurRadius: 100,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.2, duration: 4.seconds),
          ),
          Positioned(
            bottom: -50, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withOpacity(isDark ? 0.1 : 0.05),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 1.2, end: 1.0, duration: 5.seconds),
          ),

          IndexedStack(
            index: _bottomNavIndex,
            children: const [
              _GamesTab(),
              LeaderboardScreen(),
              ProfileScreen(),
            ],
          ),

          // Floating Glass Navbar
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavTabItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Bento',
                      isSelected: _bottomNavIndex == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _bottomNavIndex = 0);
                      },
                    ),
                    _NavTabItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Skorlar',
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
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ).animate().fade(duration: 200.ms).slideX(begin: -0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class _GamesTab extends StatefulWidget {
  const _GamesTab();

  @override
  State<_GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<_GamesTab> {
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
    HapticFeedback.mediumImpact();
    final newDateStr = GameDateUtils.getFormattedDate(GameDateUtils.getActiveDate());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌅 Yeni Gün Başladı: $newDateStr! Tüm oyunlar yeni bölümlerle yenilendi.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _launchGame(GameType game) {
    Widget screen;
    switch (game) {
      case GameType.queens: screen = QueensScreen(levelId: _todayLevelId); break;
      case GameType.pinpoint: screen = PinpointScreen(levelId: _todayLevelId); break;
      case GameType.crossclimb: screen = CrossclimbScreen(levelId: _todayLevelId); break;
      case GameType.tango: screen = TangoScreen(levelId: _todayLevelId); break;
      case GameType.zipPath: screen = ZipScreen(levelId: _todayLevelId); break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDate = GameDateUtils.getActiveDate();
    final formattedDate = GameDateUtils.getFormattedDate(activeDate);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 56, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedDate.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentPurple, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('Bento Lobi', style: theme.textTheme.headlineLarge),
                  ],
                ),
                Row(
                  children: [
                    // Yeni Gün Butonu
                    InkWell(
                      onTap: _advanceToNextDay,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_mode_rounded, size: 16, color: AppColors.accentCyan),
                            SizedBox(width: 4),
                            Text(
                              'Yeni Gün',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Bento Grid Area
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Hero Bento Card (Countdown & Progress)
              AppCard(
                withGlassEffect: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, color: AppColors.accentCyan, size: 16),
                              SizedBox(width: 4),
                              Text('5 GÜN SERİ', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentCyan, fontSize: 11, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14),
                              const SizedBox(width: 4),
                              Text(GameDateUtils.formatCountdown(_timeRemaining), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Günlük 5 oyun seni bekliyor!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.2)),
                    const SizedBox(height: 8),
                    Text('Skorunu artır, yeteneklerini kanıtla.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 16),

              // 2. Wide Game Card (Queens)
              _BentoWideGameCard(
                game: GameType.queens,
                onTap: () => _launchGame(GameType.queens),
              ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // 3. Two Square Cards (Pinpoint & Crossclimb)
              Row(
                children: [
                  Expanded(
                    child: _BentoSquareGameCard(
                      game: GameType.pinpoint,
                      onTap: () => _launchGame(GameType.pinpoint),
                    ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BentoSquareGameCard(
                      game: GameType.crossclimb,
                      onTap: () => _launchGame(GameType.crossclimb),
                    ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Two Square Cards (Tango & ZipPath)
              Row(
                children: [
                  Expanded(
                    child: _BentoSquareGameCard(
                      game: GameType.tango,
                      onTap: () => _launchGame(GameType.tango),
                    ).animate().fade(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BentoSquareGameCard(
                      game: GameType.zipPath,
                      onTap: () => _launchGame(GameType.zipPath),
                    ).animate().fade(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1, end: 0),
                  ),
                ],
              ),
              
              const SizedBox(height: 120), // Bottom padding for navbar
            ]),
          ),
        ),
      ],
    );
  }
}

class _BentoWideGameCard extends StatelessWidget {
  final GameType game;
  final VoidCallback onTap;

  const _BentoWideGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: game.gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: game.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(game.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(game.description, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: game.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: game.color),
          ),
        ],
      ),
    );
  }
}

class _BentoSquareGameCard extends StatelessWidget {
  final GameType game;
  final VoidCallback onTap;

  const _BentoSquareGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: game.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(game.icon, color: game.color, size: 24),
              ),
              Icon(Icons.arrow_outward_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Text(game.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(game.categoryTag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: game.color, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
