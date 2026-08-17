import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import '../common/neo_game_layout.dart';
import '../../core/theme/widgets/app_card.dart';
import 'zip_models.dart';
import 'zip_logic.dart';
import 'zip_levels.dart';

class ZipScreen extends ConsumerStatefulWidget {
  final String levelId;

  const ZipScreen({super.key, required this.levelId});

  @override
  ConsumerState<ZipScreen> createState() => _ZipScreenState();
}

class _ZipScreenState extends ConsumerState<ZipScreen> {
  late ZipLevel _level;
  final List<Point> _path = [];
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = ZipLevelRepository.getLevelForDate(widget.levelId);
    _path.clear();
    _elapsedMs = 0;
    _isSolved = false;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isSolved) {
        setState(() {
          _elapsedMs += 100;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCellTap(int r, int c) {
    if (_isSolved) return;

    final targetPoint = Point(r, c);

    setState(() {
      if (_path.contains(targetPoint)) {
        // Truncate path to clicked point
        final idx = _path.indexOf(targetPoint);
        _path.removeRange(idx + 1, _path.length);
      } else {
        if (_path.isEmpty) {
          // Path must start at number 1
          if (_level.numberPoints[targetPoint] == 1) {
            _path.add(targetPoint);
          }
        } else {
          final last = _path.last;
          final dr = (last.row - r).abs();
          final dc = (last.col - c).abs();
          // Must be adjacent step
          if (dr + dc == 1) {
            _path.add(targetPoint);
          }
        }
      }

      _checkState();
    });
  }

  void _checkState() {
    final solved = ZipLogic.validatePath(_path, _level.numberPoints, _level.gridSize);
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      _handleWin();
    }
  }

  void _handleWin() {
    final score = (2000 - (_elapsedMs ~/ 1000) * 10).clamp(100, 2000);

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.zipPath,
      levelId: widget.levelId,
      userId: 'user_local',
      userName: 'Oyuncu',
      durationMs: _elapsedMs,
      moveCount: _path.length,
      score: score,
      completedAt: DateTime.now(),
    );

    ref.read(leaderboardServiceProvider).submitScore(result);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.alt_route_rounded, color: AppColors.zipGame, size: 64)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            const Text(
              'Yol Tamamlandı! 🚀',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WinRow(label: 'Tamamlama Süresi:', value: GameDateUtils.formatGameTime(_elapsedMs)),
              const Divider(color: AppColors.border),
              _WinRow(label: 'Yol Uzunluğu:', value: '${_path.length} Hücre'),
              const Divider(color: AppColors.border),
              _WinRow(
                label: 'Kazanılan Puan:',
                value: '$score P',
                valueColor: AppColors.success,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfa'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.zipGame,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initGame();
              });
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeoGameLayout(
      gameType: GameType.zipPath,
      levelId: widget.levelId,
      onRestart: () => setState(() => _initGame()),
      statsBar: AppCard(
        withGlassEffect: true,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_rounded, size: 18, color: AppColors.accentGreen),
                const SizedBox(width: 8),
                Text(
                  GameDateUtils.formatGameTime(_elapsedMs),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ADIM: ${_path.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentGreen,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Kurallar: 1 numaradan başla, sayıları sırayla takip eden kesişmeyen yol çiz!',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

            // Grid UI
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _level.gridSize,
                      ),
                      itemCount: _level.gridSize * _level.gridSize,
                      itemBuilder: (context, index) {
                        final r = index ~/ _level.gridSize;
                        final c = index % _level.gridSize;
                        final p = Point(r, c);

                        final inPath = _path.contains(p);
                        final pathIndex = _path.indexOf(p);
                        final numVal = _level.numberPoints[p];

                        return GestureDetector(
                          onTap: () => _onCellTap(r, c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: inPath
                                  ? AppColors.accentGreen.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: inPath ? AppColors.accentGreen : AppColors.borderLight.withOpacity(0.5),
                                width: inPath ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: numVal != null
                                  ? CircleAvatar(
                                      radius: 18,
                                      backgroundColor: inPath
                                          ? AppColors.accentGreen
                                          : AppColors.surfaceLight,
                                      child: Text(
                                        '$numVal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: inPath ? Colors.black : AppColors.textPrimary,
                                        ),
                                      ),
                                    )
                                  : (inPath
                                      ? Text(
                                          '${pathIndex + 1}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accentGreen,
                                          ),
                                        )
                                      : const SizedBox.shrink()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _WinRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
