import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'queens_models.dart';
import 'queens_logic.dart';
import 'queens_levels.dart';
import 'queens_board_painter.dart';

class _QueensHistoryItem {
  final int row;
  final int col;
  final CellContent previousContent;
  final CellContent newContent;
  final List<Point<int>> autoCrossed;

  const _QueensHistoryItem({
    required this.row,
    required this.col,
    required this.previousContent,
    required this.newContent,
    this.autoCrossed = const [],
  });
}

class QueensScreen extends ConsumerStatefulWidget {
  final String levelId;

  const QueensScreen({super.key, required this.levelId});

  @override
  ConsumerState<QueensScreen> createState() => _QueensScreenState();
}

class _QueensScreenState extends ConsumerState<QueensScreen> {
  late QueensDifficulty _currentDifficulty;
  late QueensLevel _level;
  late List<List<QueensCell>> _grid;
  final List<_QueensHistoryItem> _history = [];
  int _moveCount = 0;
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  bool _autoCrossEnabled = true;
  DateTime? _lastHintTime;

  // LinkedIn Queens Modern Pastel & Jewel Palettes
  static const List<Color> _lightRegionColors = [
    Color(0xFFBAE6FD), // Sky Blue
    Color(0xFFDDD6FE), // Lavender
    Color(0xFFFDE68A), // Buttercup Yellow
    Color(0xFFA7F3D0), // Mint Emerald
    Color(0xFFFECDD3), // Rose Peach
    Color(0xFFFED7AA), // Apricot
    Color(0xFF99F6E4), // Soft Teal
    Color(0xFFC7D2FE), // Periwinkle
    Color(0xFFFBCFE8), // Blossom Pink
    Color(0xFFD9F99D), // Spring Lime
  ];

  static const List<Color> _darkRegionColors = [
    Color(0xFF0369A1), // Deep Sky
    Color(0xFF6D28D9), // Royal Violet
    Color(0xFFB45309), // Warm Amber
    Color(0xFF047857), // Deep Emerald
    Color(0xFFBE123C), // Crimson Rose
    Color(0xFFC2410C), // Sunset Orange
    Color(0xFF0F766E), // Dark Teal
    Color(0xFF4338CA), // Royal Indigo
    Color(0xFF9D174D), // Magenta
    Color(0xFF4D7C0F), // Forest Lime
  ];

  @override
  void initState() {
    super.initState();
    _currentDifficulty = QueensDifficultyScheduler.getDifficultyForDate(widget.levelId);
    _initGame();
  }

  void _initGame() {
    _level = QueensLevelRepository.getLevelForDateAndDifficulty(widget.levelId, _currentDifficulty);
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

  void _switchDifficulty(QueensDifficulty newDifficulty) {
    if (_currentDifficulty == newDifficulty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentDifficulty = newDifficulty;
      _initGame();
    });
  }

  /// Tek Dokunuş: LinkedIn standardı: Empty -> Cross -> Empty (veya Queen ise kaldırır)
  void _onCellTap(int r, int c) {
    if (_isSolved) return;
    HapticFeedback.lightImpact();

    setState(() {
      final current = _grid[r][c].content;
      final CellContent next;

      if (current == CellContent.empty) {
        next = CellContent.cross;
      } else if (current == CellContent.cross) {
        next = CellContent.empty;
      } else {
        // Vezir ise tek dokunuşla kaldır
        next = CellContent.empty;
      }

      _history.add(_QueensHistoryItem(
        row: r,
        col: c,
        previousContent: current,
        newContent: next,
      ));

      _grid[r][c].content = next;
      _moveCount++;
      _checkState();
    });
  }

  /// Çift Dokunuş veya Basılı Tutma: Vezir Yerleştir / Kaldır
  void _onCellDoubleTapOrLongPress(int r, int c) {
    if (_isSolved) return;
    HapticFeedback.mediumImpact();

    setState(() {
      final current = _grid[r][c].content;
      final CellContent next;
      List<Point<int>> autoCrossed = [];

      if (current == CellContent.queen) {
        next = CellContent.empty;
      } else {
        next = CellContent.queen;
        if (_autoCrossEnabled) {
          autoCrossed = QueensLogic.autoCrossNeighbors(_grid, r, c, _level.gridSize);
        }
      }

      _history.add(_QueensHistoryItem(
        row: r,
        col: c,
        previousContent: current,
        newContent: next,
        autoCrossed: autoCrossed,
      ));

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

      // Otomatik konulan X'leri de geri al
      for (final pt in lastMove.autoCrossed) {
        _grid[pt.x][pt.y].content = CellContent.empty;
      }

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
            Text(
              'Tahtayı Sıfırla',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
            Text(
              'Nasıl Oynanır?',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleCard('1', 'Her Satır ve Sütunda 1 Vezir', 'Her satırda ve her sütunda tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 10),
            _buildRuleCard('2', 'Her Renk Bölgesinde 1 Vezir', 'Kalın çizgilerle ayrılmış her renkli bölgede tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 10),
            _buildRuleCard('3', 'Temas Yasağı (8-Yönlü)', 'Hiçbir vezir birbirine çapraz, yatay veya dikey temas edemez.'),
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
                      '• Tek dokunuş: ✖ (Eleme İşareti)\n• Çift dokunuş veya basılı tut: 👑 (Vezir)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.4),
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

    // 1. Yanlış yerleştirilmiş vezir varsa kaldır
    for (var r = 0; r < _level.gridSize; r++) {
      for (var c = 0; c < _level.gridSize; c++) {
        if (_grid[r][c].content == CellContent.queen) {
          final isTrueQueen = _level.solution.any((pt) => pt[0] == r && pt[1] == c);
          if (!isTrueQueen) {
            setState(() {
              _grid[r][c].content = CellContent.cross;
              _checkState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💡 İpucu: Yanlış yerleştirilen vezir kaldırıldı ve ✖ ile elendi.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }
    }

    // 2. Doğru vezirlerden henüz konulmamış birini yerleştir
    for (final pt in _level.solution) {
      final r = pt[0];
      final c = pt[1];
      if (_grid[r][c].content != CellContent.queen) {
        setState(() {
          _grid[r][c].content = CellContent.queen;
          if (_autoCrossEnabled) {
            QueensLogic.autoCrossNeighbors(_grid, r, c, _level.gridSize);
          }
          _checkState();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💡 İpucu: Mantıksal çıkarımla bir vezir yerleştirildi!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
  }

  void _handleWin() {
    final durationSeconds = (_elapsedMs / 1000).ceil();
    final baseScore = _level.gridSize * 150;
    final timePenalty = (durationSeconds * 2).clamp(0, baseScore ~/ 2);
    final movePenalty = (_moveCount * 3).clamp(0, baseScore ~/ 4);
    final score = (baseScore - timePenalty - movePenalty).clamp(50, 1500);

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
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.queens,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _moveCount,
        );

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Vezirler',
      onRestart: () {
        Navigator.pop(context);
        setState(() {
          _initGame();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final regionPalette = isDark ? _darkRegionColors : _lightRegionColors;

    int queenCount = 0;
    for (var row in _grid) {
      for (var cell in row) {
        if (cell.content == CellContent.queen) queenCount++;
      }
    }

    final cooldown = _getHintCooldown();
    final isHintReady = cooldown == 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Kontrol & Başlık Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Geri Butonu
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),

                  // Segmented Difficulty Seçici
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: QueensDifficulty.values.map((diff) {
                        final isSelected = diff == _currentDifficulty;
                        return GestureDetector(
                          onTap: () => _switchDifficulty(diff),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF334155) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              diff.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                color: isSelected
                                    ? diff.color
                                    : AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Süre & Yardım
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
                          child: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 2. Kalan Vezir Tepsisi (Crown Tray)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kalan Vezir: ${_level.gridSize - queenCount}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Row(
                      children: List.generate(_level.gridSize, (idx) {
                        final isPlaced = idx < queenCount;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
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
            ),

            const SizedBox(height: 12),

            // 3. LinkedIn Standartlarında Vezirler Tahtası (Thick Border CustomPainter)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Bölge Arka Planı ve Kalın Sınırlar
                          Positioned.fill(
                            child: CustomPaint(
                              painter: QueensBoardPainter(
                                gridSize: _level.gridSize,
                                regionMap: _level.regionMap,
                                grid: _grid,
                                palette: regionPalette,
                                isDark: isDark,
                              ),
                            ),
                          ),

                          // Hücre İçi Etkileşim ve İkonlar
                          GridView.builder(
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
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _onCellTap(r, c),
                                onDoubleTap: () => _onCellDoubleTapOrLongPress(r, c),
                                onLongPress: () => _onCellDoubleTapOrLongPress(r, c),
                                child: Center(
                                  child: _buildCellContent(cell, isDark),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. Alt İşlem Butonları (Undo, Reset, Auto-X, Hint)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Geri Al
                    _ActionButton(
                      icon: Icons.undo_rounded,
                      label: 'Geri Al',
                      color: theme.colorScheme.onSurface,
                      onTap: _history.isNotEmpty && !_isSolved ? _undoMove : null,
                    ),

                    Container(width: 1, height: 26, color: AppColors.border),

                    // Sıfırla
                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Sıfırla',
                      color: theme.colorScheme.onSurface,
                      onTap: !_isSolved ? _clearBoard : null,
                    ),

                    Container(width: 1, height: 26, color: AppColors.border),

                    // Oto-X Toggle
                    _ActionButton(
                      icon: _autoCrossEnabled ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                      label: 'Oto-X',
                      color: _autoCrossEnabled ? AppColors.accentCyan : AppColors.textSecondary,
                      isHighlighted: _autoCrossEnabled,
                      onTap: () {
                        setState(() {
                          _autoCrossEnabled = !_autoCrossEnabled;
                        });
                      },
                    ),

                    Container(width: 1, height: 26, color: AppColors.border),

                    // İpucu
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
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCellContent(QueensCell cell, bool isDark) {
    if (cell.content == CellContent.queen) {
      final crownSize = _level.gridSize >= 9 ? 24.0 : (_level.gridSize >= 8 ? 28.0 : 34.0);
      return CustomPaint(
        size: Size(crownSize, crownSize),
        painter: _RoyalCrownPainter(isConflict: cell.isConflict),
      )
          .animate()
          .scale(duration: 200.ms, curve: Curves.elasticOut)
          .shake(duration: cell.isConflict ? 400.ms : 0.ms);
    } else if (cell.content == CellContent.cross) {
      final crossSize = _level.gridSize >= 9 ? 12.0 : (_level.gridSize >= 8 ? 14.0 : 16.0);
      return Icon(
        Icons.close_rounded,
        size: crossSize,
        color: (isDark ? Colors.white : const Color(0xFF0F172A)).withOpacity(0.55),
      ).animate().scale(duration: 120.ms);
    }
    return const SizedBox.shrink();
  }
}

/// LinkedIn & Royal Vector Crown Painter
class _RoyalCrownPainter extends CustomPainter {
  final bool isConflict;

  _RoyalCrownPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Çakışma Gölgelendirmesi
    final shadowPaint = Paint()
      ..color = (isConflict ? AppColors.error : const Color(0xFFD97706)).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    path.moveTo(w * 0.15, h * 0.82); // Sol alt
    path.lineTo(w * 0.85, h * 0.82); // Sağ alt
    path.lineTo(w * 0.92, h * 0.32); // Sağ tepe
    path.lineTo(w * 0.68, h * 0.52); // Sağ iç çukur
    path.lineTo(w * 0.50, h * 0.20); // Merkez yüksek tepe
    path.lineTo(w * 0.32, h * 0.52); // Sol iç çukur
    path.lineTo(w * 0.08, h * 0.32); // Sol tepe
    path.close();

    canvas.drawPath(path, shadowPaint);

    // Taç Renk Gradyanı
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

    // Taç Dış Çizgisi
    final strokePaint = Paint()
      ..color = isConflict ? Colors.white.withOpacity(0.9) : const Color(0xFF78350F).withOpacity(0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Taç Taban Şeridi
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.74, w * 0.68, h * 0.10),
      const Radius.circular(2),
    );
    final basePaint = Paint()
      ..color = isConflict ? const Color(0xFF9F1239) : const Color(0xFFB45309);
    canvas.drawRRect(baseRect, basePaint);

    // Merkez ve Uç İncileri
    final jewelPaint = Paint()
      ..color = isConflict ? Colors.white : const Color(0xFFE11D48);
    canvas.drawCircle(Offset(w * 0.50, h * 0.79), w * 0.045, jewelPaint);

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: displayColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
