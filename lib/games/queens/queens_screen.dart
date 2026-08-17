import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'queens_models.dart';
import 'queens_logic.dart';
import 'queens_levels.dart';

class _QueensHistoryItem {
  final int row;
  final int col;
  final CellContent previousContent;
  final CellContent newContent;

  const _QueensHistoryItem({
    required this.row,
    required this.col,
    required this.previousContent,
    required this.newContent,
  });
}

class QueensScreen extends ConsumerStatefulWidget {
  final String levelId;

  const QueensScreen({super.key, required this.levelId});

  @override
  ConsumerState<QueensScreen> createState() => _QueensScreenState();
}

class _QueensScreenState extends ConsumerState<QueensScreen> {
  late QueensLevel _level;
  late List<List<QueensCell>> _grid;
  final List<_QueensHistoryItem> _history = [];
  int _moveCount = 0;
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  DateTime? _lastHintTime;

  // Premium Pastel & Jewel Palette (LinkedIn Queens & NYT Games style)
  static const List<Color> _lightRegionColors = [
    Color(0xFFBAE6FD), // 0: Sky Blue
    Color(0xFFDDD6FE), // 1: Soft Lavender
    Color(0xFFFDE68A), // 2: Buttercup Yellow
    Color(0xFFA7F3D0), // 3: Mint Emerald
    Color(0xFFFECDD3), // 4: Peach Rose
    Color(0xFFFED7AA), // 5: Apricot Orange
    Color(0xFF99F6E4), // 6: Soft Teal
    Color(0xFFC7D2FE), // 7: Periwinkle
    Color(0xFFFBCFE8), // 8: Blossom Pink
    Color(0xFFD9F99D), // 9: Spring Lime
  ];

  static const List<Color> _darkRegionColors = [
    Color(0xFF0369A1), // 0: Deep Sky
    Color(0xFF6D28D9), // 1: Royal Violet
    Color(0xFFB45309), // 2: Warm Amber
    Color(0xFF047857), // 3: Deep Emerald
    Color(0xFFBE123C), // 4: Crimson Rose
    Color(0xFFC2410C), // 5: Sunset Orange
    Color(0xFF0F766E), // 6: Dark Teal
    Color(0xFF4338CA), // 7: Royal Indigo
    Color(0xFF9D174D), // 8: Magenta
    Color(0xFF4D7C0F), // 9: Forest Lime
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = QueensLevelRepository.getLevelForDate(widget.levelId);
    _grid = List.generate(
      _level.gridSize,
      (r) => List.generate(
        _level.gridSize,
        (c) => QueensCell(row: r, col: c, regionId: _level.regionMap[r][c]),
      ),
    );
    _history.clear();
    _moveCount = 0;
    _elapsedMs = 0;
    _isSolved = false;
    _lastHintTime = null;

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isSolved && mounted) {
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
    HapticFeedback.lightImpact();

    setState(() {
      final current = _grid[r][c].content;
      final CellContent next;
      if (current == CellContent.empty) {
        next = CellContent.cross;
      } else if (current == CellContent.cross) {
        next = CellContent.queen;
      } else {
        next = CellContent.empty;
      }

      _history.add(_QueensHistoryItem(row: r, col: c, previousContent: current, newContent: next));
      _grid[r][c].content = next;
      _moveCount++;
      _checkState();
    });
  }

  void _onCellLongPress(int r, int c) {
    if (_isSolved) return;
    HapticFeedback.mediumImpact();

    setState(() {
      final current = _grid[r][c].content;
      final next = current == CellContent.queen ? CellContent.empty : CellContent.queen;

      _history.add(_QueensHistoryItem(row: r, col: c, previousContent: current, newContent: next));
      _grid[r][c].content = next;
      _moveCount++;
      _checkState();
    });
  }

  void _undoMove() {
    if (_history.isEmpty || _isSolved) return;
    HapticFeedback.selectionClick();

    setState(() {
      final lastMove = _history.removeLast();
      _grid[lastMove.row][lastMove.col].content = lastMove.previousContent;
      _moveCount++;
      _checkState();
    });
  }

  void _clearBoard() {
    if (_isSolved) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Tahtayı Sıfırla', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Tüm yerleştirdiğiniz vezir ve işaretler temizlenecek. Devam etmek istiyor musunuz?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (var r = 0; r < _level.gridSize; r++) {
                  for (var c = 0; c < _level.gridSize; c++) {
                    _grid[r][c].content = CellContent.empty;
                  }
                }
                _history.clear();
                _moveCount = 0;
                QueensLogic.validateGrid(_grid, _level.gridSize);
              });
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 10),
            Text('Nasıl Oynanır?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleCard('1', 'Her Satır ve Sütunda 1 Vezir', 'Her satırda ve sütunda tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 10),
            _buildRuleCard('2', 'Her Renk Bölgesinde 1 Vezir', 'Her renkli bölgede tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 10),
            _buildRuleCard('3', 'Temas Yasağı', 'Hiçbir vezir birbirine çapraz, yatay veya dikey temas edemez (en az 1 boşluk kalmalıdır).'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 20, color: AppColors.accentCyan),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tek dokunuş: ✖ (İşaret) \nÇift dokunuş / basılı tut: 👑 (Vezir)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(String number, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkState() {
    final solved = QueensLogic.validateGrid(_grid, _level.gridSize);
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      _handleWin();
    }
  }

  int _getHintCooldown() {
    if (_lastHintTime == null) return 0;
    final diff = DateTime.now().difference(_lastHintTime!).inSeconds;
    return (15 - diff).clamp(0, 15);
  }

  void _useHint() {
    if (_isSolved) return;

    final now = DateTime.now();
    if (_lastHintTime != null && now.difference(_lastHintTime!).inSeconds < 15) {
      final remaining = 15 - now.difference(_lastHintTime!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni ipucu için $remaining saniye beklemelisin.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _lastHintTime = now;
    HapticFeedback.mediumImpact();

    // 1. Yanlış vezir varsa kaldır
    for (var r = 0; r < _level.gridSize; r++) {
      for (var c = 0; c < _level.gridSize; c++) {
        if (_grid[r][c].content == CellContent.queen) {
          bool isCorrect = false;
          for (final sol in _level.solution) {
            if (sol[0] == r && sol[1] == c) {
              isCorrect = true;
              break;
            }
          }
          if (!isCorrect) {
            setState(() {
              _grid[r][c].content = CellContent.empty;
              _moveCount++;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İpucu: Yanlış yerleştirilmiş bir vezir kaldırıldı!\n(Vezirler birbirine temas edemez, aynı satır, sütun veya aynı renkte olamaz.)'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
            _checkState();
            return;
          }
        }
      }
    }

    // 2. Doğru vezir yerleştir
    for (final sol in _level.solution) {
      final r = sol[0];
      final c = sol[1];
      if (_grid[r][c].content != CellContent.queen) {
        setState(() {
          _grid[r][c].content = CellContent.queen;
          _moveCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İpucu: Doğru bir vezir konumu yerleştirildi!\n(Bu bölge ve satır için tek güvenli hücre burasıydı.)'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        _checkState();
        return;
      }
    }
  }

  void _handleWin() {
    final score = (2000 - (_elapsedMs ~/ 1000) * 10 - _moveCount * 5).clamp(100, 2000);

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.queens,
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
      builder: (context) => _WinDialog(
        result: result,
        difficulty: _level.difficulty,
        onRestart: () {
          Navigator.pop(context);
          setState(() {
            _initGame();
          });
        },
      ),
    );
  }

  Border _buildCellBorder(int r, int c, QueensCell cell, Color regionColor, bool isDark) {
    if (cell.isConflict) {
      return Border.all(color: AppColors.error, width: 3.0);
    }

    final n = _level.gridSize;
    final isTopBoundary = r == 0 || _grid[r - 1][c].regionId != cell.regionId;
    final isBottomBoundary = r == n - 1 || _grid[r + 1][c].regionId != cell.regionId;
    final isLeftBoundary = c == 0 || _grid[r][c - 1].regionId != cell.regionId;
    final isRightBoundary = c == n - 1 || _grid[r][c + 1].regionId != cell.regionId;

    // LinkedIn Queens style: High-contrast thick boundary between regions, hairline within same region
    final boundaryColor = isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF0F172A).withOpacity(0.45);
    final boundarySide = BorderSide(color: boundaryColor, width: 2.8);
    final innerSide = BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08), width: 0.8);

    return Border(
      top: isTopBoundary ? boundarySide : innerSide,
      bottom: isBottomBoundary ? boundarySide : innerSide,
      left: isLeftBoundary ? boundarySide : innerSide,
      right: isRightBoundary ? boundarySide : innerSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final regionPalette = isDark ? _darkRegionColors : _lightRegionColors;

    final queenCount = _grid.fold<int>(
        0, (sum, row) => sum + row.where((c) => c.content == CellContent.queen).length);
    final cooldown = _getHintCooldown();
    final isHintReady = cooldown == 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background ambient soft gradient aura
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.queensGame.withOpacity(isDark ? 0.2 : 0.08),
                boxShadow: [
                  BoxShadow(color: AppColors.queensGame.withOpacity(0.12), blurRadius: 140),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  // 1. Sleek Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),

                      // Center Title & Difficulty Badge
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'VEZİRLER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _level.difficulty.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _level.difficulty.color.withOpacity(0.35)),
                                ),
                                child: Text(
                                  '${_level.difficulty.label} ${_level.gridSize}×${_level.gridSize}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _level.difficulty.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.levelId,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),

                      // Stopwatch & Help
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.accentCyan),
                                const SizedBox(width: 4),
                                Text(
                                  GameDateUtils.formatGameTime(_elapsedMs),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _showHelpDialog,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Modern Crown Progress Indicator Tray
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kalan: ${_level.gridSize - queenCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        Row(
                          children: List.generate(_level.gridSize, (idx) {
                            final isPlaced = idx < queenCount;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isPlaced ? AppColors.warning.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlaced ? AppColors.warning : AppColors.border,
                                  width: isPlaced ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: isPlaced ? AppColors.warning : AppColors.textMutedLight.withOpacity(0.3),
                                ),
                              ),
                            ).animate(target: isPlaced ? 1 : 0).scale(duration: 200.ms, curve: Curves.easeOutBack);
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. The Queens Board
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.25) : const Color(0xFF0F172A),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
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
                              final color = regionPalette[cell.regionId % regionPalette.length];

                              return GestureDetector(
                                onTap: () => _onCellTap(r, c),
                                onLongPress: () => _onCellLongPress(r, c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: color,
                                    border: _buildCellBorder(r, c, cell, color, isDark),
                                  ),
                                  child: Center(
                                    child: _buildCellContent(cell, isDark),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Bottom Action Bento Controls
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Undo
                        _ActionButton(
                          icon: Icons.undo_rounded,
                          label: 'Geri Al',
                          color: theme.colorScheme.onSurface,
                          onTap: _history.isNotEmpty && !_isSolved ? _undoMove : null,
                        ),

                        Container(width: 1, height: 26, color: AppColors.border),

                        // Reset
                        _ActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Sıfırla',
                          color: theme.colorScheme.onSurface,
                          onTap: !_isSolved ? _clearBoard : null,
                        ),

                        Container(width: 1, height: 26, color: AppColors.border),

                        // Hint
                        _ActionButton(
                          icon: isHintReady ? Icons.lightbulb_rounded : Icons.hourglass_bottom_rounded,
                          label: isHintReady ? 'İpucu' : '$cooldown s',
                          color: isHintReady ? AppColors.warning : AppColors.textMutedLight,
                          isHighlighted: isHintReady,
                          onTap: !_isSolved ? _useHint : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellContent(QueensCell cell, bool isDark) {
    if (cell.content == CellContent.queen) {
      return CustomPaint(
        size: Size(_level.gridSize >= 8 ? 26 : 34, _level.gridSize >= 8 ? 26 : 34),
        painter: _RoyalCrownPainter(isConflict: cell.isConflict),
      )
          .animate()
          .scale(duration: 220.ms, curve: Curves.elasticOut)
          .shake(duration: cell.isConflict ? 400.ms : 0.ms);
    } else if (cell.content == CellContent.cross) {
      return Container(
        width: _level.gridSize >= 8 ? 10 : 13,
        height: _level.gridSize >= 8 ? 10 : 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F172A).withOpacity(0.35),
        ),
      ).animate().scale(duration: 120.ms);
    }
    return const SizedBox.shrink();
  }
}

/// Custom Vector Royal Crown Painter (Authentic 3D Golden Crown with jewels)
class _RoyalCrownPainter extends CustomPainter {
  final bool isConflict;

  _RoyalCrownPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Conflict Glow / Drop Shadow
    final shadowPaint = Paint()
      ..color = (isConflict ? AppColors.error : const Color(0xFFD97706)).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Crown Path
    final path = Path();
    path.moveTo(w * 0.15, h * 0.82); // Bottom left
    path.lineTo(w * 0.85, h * 0.82); // Bottom right
    path.lineTo(w * 0.92, h * 0.32); // Top right peak
    path.lineTo(w * 0.68, h * 0.52); // Right inner dip
    path.lineTo(w * 0.50, h * 0.20); // Center high peak
    path.lineTo(w * 0.32, h * 0.52); // Left inner dip
    path.lineTo(w * 0.08, h * 0.32); // Top left peak
    path.close();

    canvas.drawPath(path, shadowPaint);

    // Crown Fill Gradient
    final fillGradient = isConflict
        ? const LinearGradient(
            colors: [Color(0xFFFF3366), Color(0xFFBE123C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFF3B0), Color(0xFFFFD000), Color(0xFFE69500)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Crown Stroke Outline
    final strokePaint = Paint()
      ..color = isConflict ? Colors.white.withOpacity(0.9) : const Color(0xFF78350F).withOpacity(0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Crown Base Bar
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.74, w * 0.68, h * 0.10),
      const Radius.circular(2),
    );
    final basePaint = Paint()
      ..color = isConflict ? const Color(0xFF9F1239) : const Color(0xFFB45309);
    canvas.drawRRect(baseRect, basePaint);

    // Center Jewel
    final jewelPaint = Paint()
      ..color = isConflict ? Colors.white : const Color(0xFFE11D48);
    canvas.drawCircle(Offset(w * 0.50, h * 0.79), w * 0.045, jewelPaint);

    // Peak Pearl Jewels
    final pearlPaint = Paint()
      ..color = isConflict ? Colors.white : const Color(0xFFFFFBEB);
    canvas.drawCircle(Offset(w * 0.08, h * 0.30), w * 0.04, pearlPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.055, pearlPaint);
    canvas.drawCircle(Offset(w * 0.92, h * 0.30), w * 0.04, pearlPaint);
  }

  @override
  bool shouldRepaint(covariant _RoyalCrownPainter oldDelegate) => oldDelegate.isConflict != isConflict;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final displayColor = isEnabled ? color : AppColors.textMutedLight.withOpacity(0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: displayColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinDialog extends StatelessWidget {
  final GameResult result;
  final QueensDifficulty difficulty;
  final VoidCallback onRestart;

  const _WinDialog({
    required this.result,
    required this.difficulty,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFFFB300)]),
              boxShadow: [
                BoxShadow(color: AppColors.warning.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF5A3A00), size: 46),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 14),
          const Text(
            'Tebrikler! 🎉',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Günün ${difficulty.label} (${difficulty.gridSize}x${difficulty.gridSize}) Vezirler bulmacasını çözdünüz!',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultRow(label: 'Zorluk Seviyesi:', value: difficulty.label, valueColor: difficulty.color),
            const Divider(color: AppColors.border),
            _ResultRow(label: 'Tamamlama Süresi:', value: GameDateUtils.formatGameTime(result.durationMs)),
            const Divider(color: AppColors.border),
            _ResultRow(label: 'Toplam Hamle:', value: '${result.moveCount}'),
            const Divider(color: AppColors.border),
            _ResultRow(
              label: 'Kazanılan Skor:',
              value: '${result.score} P',
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
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: onRestart,
          child: const Text('Tekrar Oyna'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ResultRow({
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, color: valueColor, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
