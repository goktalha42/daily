import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'tango_models.dart';
import 'tango_logic.dart';
import 'tango_levels.dart';

class _TangoHistoryItem {
  final int r;
  final int c;
  final TangoSymbol oldSymbol;

  const _TangoHistoryItem(this.r, this.c, this.oldSymbol);
}

class TangoScreen extends ConsumerStatefulWidget {
  final String levelId;

  const TangoScreen({super.key, required this.levelId});

  @override
  ConsumerState<TangoScreen> createState() => _TangoScreenState();
}

class _TangoScreenState extends ConsumerState<TangoScreen> {
  late TangoLevel _level;
  late List<List<TangoCell>> _grid;
  final List<_TangoHistoryItem> _history = [];
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
    _history.clear();
    _moveCount = 0;
    _elapsedMs = 0;
    _isSolved = false;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
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
    if (_isSolved || _grid[r][c].isFixed) return;

    HapticFeedback.selectionClick();
    final current = _grid[r][c].symbol;
    _history.add(_TangoHistoryItem(r, c, current));

    setState(() {
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

  void _undoMove() {
    if (_history.isEmpty || _isSolved) return;
    HapticFeedback.lightImpact();

    setState(() {
      final last = _history.removeLast();
      _grid[last.r][last.c].symbol = last.oldSymbol;
      _moveCount++;
      _checkState();
    });
  }

  void _resetBoard() {
    if (_isSolved) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.pencilBlack, width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.restart_alt_rounded, color: AppColors.error, size: 26),
            const SizedBox(width: 8),
            Text(
              'Tahtayı Sıfırla',
              style: GoogleFonts.patrickHand(
                color: AppColors.pencilBlack,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Text(
          'Yerleştirdiğin tüm güneş ve aylar sıfırlanacak. Devam etmek istiyor musun?',
          style: GoogleFonts.patrickHand(
            color: AppColors.pencilGraphite,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.patrickHand(
                fontSize: 18,
                color: AppColors.pencilGraphite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.pencilBlack, width: 2.0),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (var r = 0; r < _level.gridSize; r++) {
                  for (var c = 0; c < _level.gridSize; c++) {
                    if (!_grid[r][c].isFixed) {
                      _grid[r][c].symbol = TangoSymbol.empty;
                    }
                  }
                }
                _history.clear();
                _moveCount = 0;
                TangoLogic.validateGrid(_grid, _level.gridSize, _level.constraints);
              });
            },
            child: Text(
              'Temizle',
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
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.tango,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _moveCount,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.tango,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
        );

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Güneş & Ay',
      onRestart: () {
        Navigator.pop(context);
        setState(() {
          _initGame();
        });
      },
    );
  }

  void _showHelpDialog() {
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
            const Icon(Icons.wb_sunny_rounded, color: AppColors.highlighterOrange, size: 28),
            const SizedBox(width: 8),
            Text(
              'Güneş & Ay: Nasıl Oynanır?',
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
            _buildRuleCard(
              '1',
              'Eşit Denge',
              'Her satır ve sütunda eşit sayıda ☀️ Güneş ve 🌙 Ay olmalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Üçleme Yasağı',
              'Yan yana veya üst üste asla 3 aynı sembol gelemez! En fazla 2 aynı sembol peş peşe gelebilir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'İşaretler (= ve ✕)',
              '= işareti bağlı iki hücrenin aynı sembol olduğunu, ✕ işareti ise zıt semboller olduğunu belirtir.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.highlighterYellow.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pencilBlack, width: 2.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 20, color: AppColors.pencilBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '• Hücreye dokun: Boş ➔ ☀️ ➔ 🌙 ➔ Boş\n• Gri zeminli hücreler başlangıçta sabittir!',
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  Widget _buildRuleCard(String number, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.pencilBlack, width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.highlighterOrange,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
            ),
            child: Text(
              number,
              style: GoogleFonts.patrickHand(
                fontWeight: FontWeight.w700,
                color: AppColors.pencilBlack,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    int sunCount = 0, moonCount = 0;
    final targetCount = (_level.gridSize * _level.gridSize) ~/ 2;

    for (var r = 0; r < _level.gridSize; r++) {
      for (var c = 0; c < _level.gridSize; c++) {
        if (_grid[r][c].symbol == TangoSymbol.sun) sunCount++;
        if (_grid[r][c].symbol == TangoSymbol.moon) moonCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. ÜST KONTROL & BAŞLIK ÇUBUĞU (Organik Kara Kalem Skeç Kartları)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri Butonu
                    SketchCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 10,
                      shadowOffset: const Offset(2.5, 2.5),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.pencilBlack),
                    ),

                    // Oyun Başlığı ve Rozet
                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      borderRadius: 12,
                      shadowOffset: const Offset(2.5, 2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_rounded, size: 18, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Güneş & Ay',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                  height: 1.1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.highlighterOrange,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '☀️🌙 Denge & Mantık',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pencilBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sayaç & Yardım Butonları
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          borderRadius: 10,
                          shadowOffset: const Offset(2, 2),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 15, color: AppColors.pencilBlack),
                              const SizedBox(width: 4),
                              Text(
                                GameDateUtils.formatGameTime(_elapsedMs),
                                style: GoogleFonts.patrickHand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SketchCard(
                          backgroundColor: AppColors.highlighterYellow,
                          padding: const EdgeInsets.all(7),
                          borderRadius: 10,
                          shadowOffset: const Offset(2, 2),
                          onTap: _showHelpDialog,
                          child: const Icon(Icons.question_mark_rounded, size: 16, color: AppColors.pencilBlack),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. SEMBOL SAYAÇLARI VE DENGE ÇUBUĞU (Organik SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Güneş Sayacı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sunCount == targetCount
                              ? AppColors.highlighterGreen.withValues(alpha: 0.4)
                              : AppColors.highlighterYellow.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text('☀️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              'Güneş: $sunCount / $targetCount',
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ay Sayacı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: moonCount == targetCount
                              ? AppColors.highlighterGreen.withValues(alpha: 0.4)
                              : AppColors.highlighterCyan.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text('🌙', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              'Ay: $moonCount / $targetCount',
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

              const SizedBox(height: 10),

              // 3. ORGANİK SKEÇ TANGO TAHTASI
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = constraints.maxWidth;
                          final cellSize = boardSize / _level.gridSize;

                          return SketchCard(
                            padding: const EdgeInsets.all(4),
                            borderRadius: 16,
                            shadowOffset: const Offset(4, 4),
                            borderWidth: 2.5,
                            child: Stack(
                              children: [
                                // Izgara Hücreleri
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

                                    Color cellBg;
                                    if (cell.isConflict) {
                                      cellBg = AppColors.errorBgLight;
                                    } else if (cell.isFixed) {
                                      cellBg = AppColors.surfaceSecondaryLight.withValues(alpha: 0.6);
                                    } else {
                                      cellBg = Colors.white;
                                    }

                                    return GestureDetector(
                                      onTap: () => _onCellTap(r, c),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        margin: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          color: cellBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: cell.isConflict
                                                ? AppColors.error
                                                : (cell.isFixed ? AppColors.pencilBlack : AppColors.pencilLight),
                                            width: cell.isConflict ? 2.4 : (cell.isFixed ? 1.8 : 1.2),
                                          ),
                                          boxShadow: cell.isConflict
                                              ? const [
                                                  BoxShadow(
                                                    color: AppColors.error,
                                                    offset: Offset(1.5, 1.5),
                                                    blurRadius: 0,
                                                  ),
                                                ]
                                              : (cell.symbol != TangoSymbol.empty
                                                  ? const [
                                                      BoxShadow(
                                                        color: AppColors.pencilBlack,
                                                        offset: Offset(1.5, 1.5),
                                                        blurRadius: 0,
                                                      ),
                                                    ]
                                                  : null),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (cell.isFixed)
                                              Positioned(
                                                top: 3,
                                                left: 3,
                                                child: Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.pencilBlack,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            _buildSymbol(cell),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Kısıt İşaretleri (Constraint Overlays: = ve ✕)
                                ..._level.constraints.map((cons) {
                                  final isHorizontal = cons.r1 == cons.r2;
                                  final isEqual = cons.type == ConstraintType.equal;
                                  final markerText = isEqual ? '=' : '✕';
                                  final markerColor = isEqual ? AppColors.highlighterGreen : AppColors.highlighterOrange;

                                  double left, top;
                                  if (isHorizontal) {
                                    left = (cons.c1 + 1) * cellSize - 11;
                                    top = cons.r1 * cellSize + cellSize / 2 - 11;
                                  } else {
                                    left = cons.c1 * cellSize + cellSize / 2 - 11;
                                    top = (cons.r1 + 1) * cellSize - 11;
                                  }

                                  return Positioned(
                                    left: left,
                                    top: top,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: markerColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.pencilBlack, width: 1.8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.pencilBlack,
                                            offset: Offset(1.5, 1.5),
                                            blurRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          markerText,
                                          style: GoogleFonts.patrickHand(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.pencilBlack,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. ALT KONTROLLER (Geri Al & Sıfırla)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Geri Al Butonu
                    GestureDetector(
                      onTap: _history.isNotEmpty ? _undoMove : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _history.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _history.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            width: 2.0,
                          ),
                          boxShadow: _history.isNotEmpty
                              ? const [
                                  BoxShadow(
                                    color: AppColors.pencilBlack,
                                    offset: Offset(2.5, 2.5),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.undo_rounded,
                              size: 18,
                              color: _history.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Geri Al',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _history.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Sıfırla Butonu
                    GestureDetector(
                      onTap: _resetBoard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.highlighterYellow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pencilBlack,
                              offset: Offset(2.5, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.pencilBlack),
                            const SizedBox(width: 6),
                            Text(
                              'Sıfırla',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymbol(TangoCell cell) {
    if (cell.symbol == TangoSymbol.sun) {
      return const Text('☀️', style: TextStyle(fontSize: 26))
          .animate()
          .scale(duration: 150.ms, curve: Curves.easeOutBack);
    } else if (cell.symbol == TangoSymbol.moon) {
      return const Text('🌙', style: TextStyle(fontSize: 26))
          .animate()
          .scale(duration: 150.ms, curve: Curves.easeOutBack);
    }
    return const SizedBox.shrink();
  }
}
