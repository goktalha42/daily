import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'base_game.dart';

class NeoGameLayout extends StatelessWidget {
  final GameType gameType;
  final String levelId;
  final Widget child;
  final Widget? statsBar;
  final VoidCallback? onRestart;

  const NeoGameLayout({
    super.key,
    required this.gameType,
    required this.levelId,
    required this.child,
    this.statsBar,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Dynamic Mesh Background
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gameType.color.withOpacity(isDark ? 0.2 : 0.08),
                boxShadow: [
                  BoxShadow(color: gameType.color.withOpacity(0.15), blurRadius: 120),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.3, duration: 6.seconds),
          ),
          Positioned(
            bottom: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gameType.color.withOpacity(isDark ? 0.15 : 0.05),
                boxShadow: [
                  BoxShadow(color: gameType.color.withOpacity(0.1), blurRadius: 100),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.2, end: 1.0, duration: 5.seconds),
          ),

          SafeArea(
            child: Column(
              children: [
                // Neo Glass HUD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        color: theme.colorScheme.onSurface,
                        onPressed: () => Navigator.pop(context),
                      ),
                      
                      // Game Info
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(gameType.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          Text('Bölüm #$levelId', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      // Restart/Options Button
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22),
                        color: theme.colorScheme.onSurface,
                        onPressed: onRestart,
                      ),
                    ],
                  ),
                ),

                // Stats Bar if provided
                if (statsBar != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: statsBar!,
                  ),

                // Game Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
