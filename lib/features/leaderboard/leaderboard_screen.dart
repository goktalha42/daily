import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'leaderboard_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardTimeframe _timeframe = LeaderboardTimeframe.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: GameType.values.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = GameType.values[_tabController.index];
    final service = ref.watch(leaderboardServiceProvider);
    final entries = service.getLeaderboard(gameType: currentGame, timeframe: _timeframe);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu 🏆'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: currentGame.color,
          labelColor: currentGame.color,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: GameType.values.map((game) {
            return Tab(
              icon: Icon(game.icon, size: 20),
              text: game.title,
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Timeframe filter chips
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: LeaderboardTimeframe.values.map((tf) {
                final isSelected = _timeframe == tf;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(tf.label),
                    selected: isSelected,
                    selectedColor: currentGame.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _timeframe = tf;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Leaderboard Body
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz bu dönemde skor kaydedilmedi.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      // Top 3 Podium
                      if (entries.length >= 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _PodiumCard(entry: entries[1], place: 2, color: const Color(0xFFC0C0C0)),
                              _PodiumCard(entry: entries[0], place: 1, color: const Color(0xFFFFD700)),
                              _PodiumCard(entry: entries[2], place: 3, color: const Color(0xFFCD7F32)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Rest of ranking list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final isMe = entry.userId == 'user_local';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? currentGame.color.withValues(alpha: 0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMe ? currentGame.color : AppColors.border,
                                  width: isMe ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRankColor(entry.rank),
                                  child: Text(
                                    '${entry.rank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  entry.userName + (isMe ? ' (Siz)' : ''),
                                  style: TextStyle(
                                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                    color: isMe ? currentGame.color : AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  'En İyi Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  '${entry.totalScore} P',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? currentGame.color : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .fade(duration: 200.ms, delay: (index * 40).ms)
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.surfaceLight;
    }
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;
  final Color color;

  const _PodiumCard({
    required this.entry,
    required this.place,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final height = place == 1 ? 130.0 : (place == 2 ? 110.0 : 95.0);

    return Column(
      children: [
        CircleAvatar(
          radius: place == 1 ? 24 : 20,
          backgroundColor: color,
          child: Text(
            place == 1 ? '🥇' : (place == 2 ? '🥈' : '🥉'),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.totalScore} P',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '#$place',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
