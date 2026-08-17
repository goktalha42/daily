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
import 'tango_models.dart';
import 'tango_logic.dart';
import 'tango_levels.dart';

class TangoScreen extends ConsumerStatefulWidget {
  final String levelId;

  const TangoScreen({super.key, required this.levelId});

  @override
  ConsumerState<TangoScreen> createState() => _TangoScreenState();
}

class _TangoScreenState extends ConsumerState<TangoScreen> {
  late TangoLevel _level;
  late List<List<TangoCell>> _grid;
  int _moveCount = 0;
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = TangoLevelRepository.getLevelForDate(widget.levelId);
    _grid = List.generate(
      _level.gridSize,
      (r) => List.generate(
        _level.gridSize,
        (c) {
          final initSym = _level.initialGrid[r][c];
          return TangoCell(
            row: r,
            col: c,
            isFixed: initSym != TangoSymbol.empty,
            symbol: initSym,
          );
        },
      ),
    );
    _moveCount = 0;
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
    if (_isSolved || _grid[r][c].isFixed) return;

    setState(() {
      final current = _grid[r][c].symbol;
      if (current == TangoSymbol.empty) {
        _grid[r][c].symbol = TangoSymbol.sun;
      } else if (current == TangoSymbol.sun) {
        _grid[r][c].symbol = TangoSymbol.moon;
      } else {
        _grid[r][c].symbol = TangoSymbol.empty;
      }
      _moveCount++;
      _checkState();
    });
  }

  void _checkState() {
    final solved = TangoLogic.validateGrid(_grid, _level.gridSize, _level.constraints);
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      _handleWin();
    }
  }

  void _handleWin() {
    final score = (2000 - (_elapsedMs ~/ 1000) * 10 - _moveCount * 4).clamp(100, 2000);

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.tango,
      levelId: widget.levelId,
      userId: 'user_local',
      userName: 'Oyuncu',
      durationMs: _elapsedMs,
      moveCount: _moveCount,
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
            const Icon(Icons.wb_sunny_rounded, color: AppColors.tangoGame, size: 64)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            const Text(
              'Güneş ve Ay Dengede! ☀️🌙',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
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
              _WinRow(label: 'Çözüm Süresi:', value: GameDateUtils.formatGameTime(_elapsedMs)),
              const Divider(color: AppColors.border),
              _WinRow(label: 'Hamle Sayısı:', value: '$_moveCount'),
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
              backgroundColor: AppColors.tangoGame,
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
    int sunCount = 0, moonCount = 0;
    for (var r = 0; r < _level.gridSize; r++) {
      for (var c = 0; c < _level.gridSize; c++) {
        if (_grid[r][c].symbol == TangoSymbol.sun) sunCount++;
        if (_grid[r][c].symbol == TangoSymbol.moon) moonCount++;
      }
    }

    return NeoGameLayout(
      gameType: GameType.tango,
      levelId: widget.levelId,
      onRestart: () => setState(() => _initGame()),
      statsBar: AppCard(
        withGlassEffect: true,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Badge(
              label: 'SÜRE',
              value: GameDateUtils.formatGameTime(_elapsedMs),
              color: AppColors.accentOrange,
            ),
            _Badge(
              label: '☀️ GÜNEŞ',
              value: '$sunCount / ${(_level.gridSize * _level.gridSize) ~/ 2}',
              color: sunCount == (_level.gridSize * _level.gridSize) ~/ 2 ? AppColors.accentGreen : AppColors.warning,
            ),
            _Badge(
              label: '🌙 AY',
              value: '$moonCount / ${(_level.gridSize * _level.gridSize) ~/ 2}',
              color: moonCount == (_level.gridSize * _level.gridSize) ~/ 2 ? AppColors.accentCyan : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Dokunuş: Boş ➔ ☀️ ➔ 🌙 | Her satır/sütun eşit | Yan yana max 2 aynı',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

            // Grid UI with constraint overlays
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellSize = constraints.maxWidth / _level.gridSize;

                      return Stack(
                        children: [
                          // Base Grid
                          Container(
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
                                final cell = _grid[r][c];

                                return GestureDetector(
                                  onTap: () => _onCellTap(r, c),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: cell.isConflict
                                          ? AppColors.error.withOpacity(0.9)
                                          : (cell.isFixed ? AppColors.surfaceLight : Colors.black.withOpacity(0.15)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: cell.isConflict
                                            ? AppColors.error
                                            : AppColors.borderLight.withOpacity(0.5),
                                        width: cell.isConflict ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: _buildSymbol(cell),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Constraint markers overlay
                          ..._level.constraints.map((cons) {
                            final isHorizontal = cons.r1 == cons.r2;
                            final markerText = cons.type == ConstraintType.equal ? '=' : '✕';
                            final markerColor = cons.type == ConstraintType.equal
                                ? AppColors.success
                                : AppColors.error;

                            double left, top;
                            if (isHorizontal) {
                              // Between (r, c1) and (r, c2) → center horizontally between them
                              left = (cons.c1 + 1) * cellSize - 10;
                              top = cons.r1 * cellSize + cellSize / 2 - 10;
                            } else {
                              // Between (r1, c) and (r2, c) → center vertically between them
                              left = cons.c1 * cellSize + cellSize / 2 - 10;
                              top = (cons.r1 + 1) * cellSize - 10;
                            }

                            return Positioned(
                              left: left,
                              top: top,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: markerColor, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: markerColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    markerText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: markerColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymbol(TangoCell cell) {
    if (cell.symbol == TangoSymbol.sun) {
      return const Text('☀️', style: TextStyle(fontSize: 26))
          .animate()
          .scale(duration: 150.ms);
    } else if (cell.symbol == TangoSymbol.moon) {
      return const Text('🌙', style: TextStyle(fontSize: 26))
          .animate()
          .scale(duration: 150.ms);
    }
    return const SizedBox.shrink();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Badge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
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
