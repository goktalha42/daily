import 'dart:async';
import 'dart:math' as math;
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
    return SketchCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: AppColors.backgroundLight,
      borderRadius: 12,
      borderWidth: 1.8,
      shadowOffset: const Offset(2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SketchCard(
            padding: EdgeInsets.zero,
            borderRadius: 6,
            borderWidth: 1.4,
            shadowOffset: const Offset(1, 1),
            backgroundColor: AppColors.highlighterOrange,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.patrickHand(
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                    fontSize: 14,
                  ),
                ),
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
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text(
                                    GameDateUtils.formatGameTime(_elapsedMs),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pencilBlack,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SketchCard(
                          backgroundColor: AppColors.sunYellow,
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
                      // Güneş Sayacı (Organik El Çizimi)
                      SketchCard(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        borderRadius: 8,
                        borderWidth: 1.5,
                        shadowOffset: const Offset(1.5, 1.5),
                        backgroundColor: sunCount == targetCount
                            ? AppColors.sunYellow.withValues(alpha: 0.25)
                            : AppColors.surfaceLight,
                        child: Row(
                          children: [
                            CustomPaint(
                              size: const Size(20, 20),
                              painter: const _OrganicDrawnSunPainter(isConflict: false),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Güneş: $sunCount / $targetCount',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ay Sayacı (Organik El Çizimi)
                      SketchCard(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        borderRadius: 8,
                        borderWidth: 1.5,
                        shadowOffset: const Offset(1.5, 1.5),
                        backgroundColor: moonCount == targetCount
                            ? AppColors.skyBlue.withValues(alpha: 0.25)
                            : AppColors.surfaceLight,
                        child: Row(
                          children: [
                            CustomPaint(
                              size: const Size(20, 20),
                              painter: const _OrganicDrawnMoonPainter(isConflict: false),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ay: $moonCount / $targetCount',
                              style: GoogleFonts.patrickHand(
                                fontSize: 16,
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
                                      cellBg = const Color(0xFFFBF8F0);
                                    } else {
                                      cellBg = Colors.white;
                                    }

                                    return GestureDetector(
                                      onTap: () => _onCellTap(r, c),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.5),
                                        child: SketchCard(
                                          padding: EdgeInsets.zero,
                                          borderRadius: 10,
                                          borderWidth: cell.isConflict ? 2.4 : (cell.isFixed ? 1.8 : 1.4),
                                          shadowOffset: cell.isConflict
                                              ? const Offset(2.0, 2.0)
                                              : (cell.symbol != TangoSymbol.empty ? const Offset(2.0, 2.0) : const Offset(1.0, 1.0)),
                                          backgroundColor: cellBg,
                                          borderColor: cell.isConflict
                                              ? AppColors.error
                                              : (cell.isFixed ? AppColors.pencilBlack : AppColors.pencilBlack.withValues(alpha: 0.6)),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Sabit/Dolu Hücre için Minik Zarif Köşe Raptiyesi
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
                                      ),
                                    );
                                  },
                                ),

                                // Kısıt İşaretleri (Constraint Overlays: = ve ✕) - TAM ORTADA & ORGANİK SKETCH
                                ..._level.constraints.map((cons) {
                                  final isHorizontal = cons.r1 == cons.r2;
                                  final isEqual = cons.type == ConstraintType.equal;
                                  const markerSize = 22.0;

                                  double left, top;
                                  if (isHorizontal) {
                                    // İki yatay hücrenin tam ortak kenar çizgisi ortası
                                    left = (cons.c1 + 1) * cellSize - (markerSize / 2);
                                    top = cons.r1 * cellSize + (cellSize / 2) - (markerSize / 2);
                                  } else {
                                    // İki dikey hücrenin tam ortak kenar çizgisi ortası
                                    left = cons.c1 * cellSize + (cellSize / 2) - (markerSize / 2);
                                    top = (cons.r1 + 1) * cellSize - (markerSize / 2);
                                  }

                                  return Positioned(
                                    left: left,
                                    top: top,
                                    child: SketchCard(
                                      padding: EdgeInsets.zero,
                                      borderRadius: 6,
                                      borderWidth: 1.5,
                                      shadowOffset: const Offset(1.5, 1.5),
                                      backgroundColor: isEqual ? const Color(0xFFD1FAE5) : const Color(0xFFFECDD3),
                                      child: SizedBox(
                                        width: markerSize,
                                        height: markerSize,
                                        child: Center(
                                          child: Text(
                                            isEqual ? '=' : '✕',
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.pencilBlack,
                                              height: 1.0,
                                            ),
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

              // 4. ALT KONTROLLER (Geri Al & Sıfırla) - Tamamen Organik SketchCard!
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Geri Al Butonu
                    SketchCard(
                      onTap: _history.isNotEmpty ? _undoMove : null,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: _history.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      borderWidth: 2.0,
                      shadowOffset: _history.isNotEmpty ? const Offset(2.5, 2.5) : const Offset(1.0, 1.0),
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

                    const SizedBox(width: 16),

                    // Sıfırla Butonu
                    SketchCard(
                      onTap: _resetBoard,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      borderWidth: 2.0,
                      shadowOffset: const Offset(2.5, 2.5),
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
      return CustomPaint(
        size: const Size(32, 32),
        painter: _OrganicDrawnSunPainter(isConflict: cell.isConflict),
      )
          .animate()
          .scale(duration: 180.ms, curve: Curves.easeOutBack)
          .shake(duration: cell.isConflict ? 350.ms : 0.ms);
    } else if (cell.symbol == TangoSymbol.moon) {
      return CustomPaint(
        size: const Size(32, 32),
        painter: _OrganicDrawnMoonPainter(isConflict: cell.isConflict),
      )
          .animate()
          .scale(duration: 180.ms, curve: Curves.easeOutBack)
          .shake(duration: cell.isConflict ? 350.ms : 0.ms);
    }
    return const SizedBox.shrink();
  }
}

/// Elle Çizilmiş Organik Güneş (Sıcak Sarı & Hata Anında Kırmızıya Dönüp Çatlayan Güneş)
class _OrganicDrawnSunPainter extends CustomPainter {
  final bool isConflict;

  const _OrganicDrawnSunPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final pen = Paint()
      ..color = isConflict ? AppColors.error : AppColors.pencilBlack
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final draft = Paint()
      ..color = (isConflict ? AppColors.error : AppColors.pencilBlack).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillColor = isConflict ? AppColors.errorBgLight : AppColors.sunYellow;
    final raysColor = isConflict ? AppColors.error.withValues(alpha: 0.35) : AppColors.sunYellow.withValues(alpha: 0.50);

    // 1. Organik El Çizimi Güneş Işınları
    final rays = Path();
    const int rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * (360 / rayCount)) * 3.14159 / 180;
      final nextAngle = ((i + 1) * (360 / rayCount)) * 3.14159 / 180;
      final midAngle = (angle + nextAngle) / 2;

      final pStart = Offset(center.dx + (w * 0.30) * math.cos(angle), center.dy + (h * 0.30) * math.sin(angle));
      final pTip = Offset(center.dx + (w * 0.48) * math.cos(midAngle), center.dy + (h * 0.48) * math.sin(midAngle));
      final pEnd = Offset(center.dx + (w * 0.30) * math.cos(nextAngle), center.dy + (h * 0.30) * math.sin(nextAngle));

      if (i == 0) rays.moveTo(pStart.dx, pStart.dy);
      rays.quadraticBezierTo(pTip.dx, pTip.dy, pTip.dx, pTip.dy);
      rays.quadraticBezierTo(pEnd.dx, pEnd.dy, pEnd.dx, pEnd.dy);
    }
    rays.close();

    canvas.drawPath(rays, Paint()..color = raysColor..style = PaintingStyle.fill);
    canvas.drawPath(rays, pen);

    // 2. Güneş Gövdesi (Hafif yamuk serbest el çemberi)
    final sunBody = Path();
    sunBody.addOval(Rect.fromCircle(center: center, radius: w * 0.28));
    canvas.drawPath(sunBody, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(sunBody, pen);

    // Taslak vuruşu
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.25),
      0.4,
      3.14159 * 1.4,
      false,
      draft,
    );

    // Normal: Sevimli ufacık skeç gözler ve tebessüm
    if (!isConflict) {
      final eyePaint = Paint()..color = AppColors.pencilBlack..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - w * 0.10, center.dy - h * 0.04), 1.6, eyePaint);
      canvas.drawCircle(Offset(center.dx + w * 0.10, center.dy - h * 0.04), 1.6, eyePaint);
      // Tebessüm
      final smile = Path()
        ..moveTo(center.dx - w * 0.08, center.dy + h * 0.06)
        ..quadraticBezierTo(center.dx, center.dy + h * 0.14, center.dx + w * 0.08, center.dy + h * 0.06);
      canvas.drawPath(smile, pen..strokeWidth = 1.6);
    }

    // KURAL İHLALİ / HATA: KIRMIZIYA DÖNÜP ORTASINDAN ÇATLAYAN GÜNEŞ
    if (isConflict) {
      final crackPaint = Paint()
        ..color = AppColors.pencilBlack
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final crack = Path();
      crack.moveTo(center.dx, center.dy - h * 0.40);
      crack.lineTo(center.dx - w * 0.08, center.dy - h * 0.16);
      crack.lineTo(center.dx + w * 0.10, center.dy + h * 0.02);
      crack.lineTo(center.dx - w * 0.06, center.dy + h * 0.20);
      crack.lineTo(center.dx + w * 0.02, center.dy + h * 0.38);
      canvas.drawPath(crack, crackPaint);

      // Yan kırıklar ve kıymıklar
      canvas.drawLine(Offset(center.dx - w * 0.08, center.dy - h * 0.16), Offset(center.dx - w * 0.22, center.dy - h * 0.10), crackPaint..strokeWidth = 1.6);
      canvas.drawLine(Offset(center.dx + w * 0.10, center.dy + h * 0.02), Offset(center.dx + w * 0.24, center.dy + h * 0.08), crackPaint..strokeWidth = 1.6);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicDrawnSunPainter oldDelegate) => oldDelegate.isConflict != isConflict;
}

/// Elle Çizilmiş Organik Ay (Türk Bayrağındaki Sağa Bakan Hilal Formunda & Eskiz Diliyle)
class _OrganicDrawnMoonPainter extends CustomPainter {
  final bool isConflict;

  const _OrganicDrawnMoonPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final minDim = w < h ? w : h;
    final rOuter = minDim * 0.36;
    final rInner = rOuter * 0.80; // Türk bayrağı hilal iç çember oranı (~0.8)

    // Ağırlık merkezini dengelemek için dış çemberi hafif sola, iç çemberi sağa alıyoruz
    final centerOuter = Offset(w / 2 - rOuter * 0.12, h / 2);
    final centerInner = Offset(centerOuter.dx + rOuter * 0.28, h / 2);

    final pen = Paint()
      ..color = isConflict ? AppColors.error : AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final draft = Paint()
      ..color = (isConflict ? AppColors.error : AppColors.pencilBlack).withValues(alpha: 0.32)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillColor = isConflict ? AppColors.errorBgLight : AppColors.skyBlue;

    // 1. Türk Bayrağı Hilal Formu (Dış çember fark iç çember)
    final outerPath = Path()..addOval(Rect.fromCircle(center: centerOuter, radius: rOuter));
    final innerPath = Path()..addOval(Rect.fromCircle(center: centerInner, radius: rInner));
    final moon = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Dolgu ve ana el çizimi konturu
    canvas.drawPath(moon, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(moon, pen);

    // 2. Çift Hatlı Organik Taslak Çizgisi (Eskiz havası)
    final draftOuter = Path()
      ..addOval(Rect.fromCircle(center: Offset(centerOuter.dx + 0.6, centerOuter.dy + 0.6), radius: rOuter * 0.98));
    final draftInner = Path()
      ..addOval(Rect.fromCircle(center: Offset(centerInner.dx + 0.6, centerInner.dy + 0.6), radius: rInner * 1.01));
    final draftMoon = Path.combine(PathOperation.difference, draftOuter, draftInner);
    canvas.drawPath(draftMoon, draft);

    // 3. Zarif Kurşun Kalem Sırt Taraması (Organik eskiz dokusu)
    if (!isConflict) {
      final hatchPaint = Paint()
        ..color = AppColors.pencilBlack.withValues(alpha: 0.25)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;

      // Hilalin sol göbeğinde 3 adet kavisli gölgeleme taraması
      final hatch1 = Path()
        ..moveTo(centerOuter.dx - rOuter * 0.65, centerOuter.dy - rOuter * 0.25)
        ..quadraticBezierTo(
          centerOuter.dx - rOuter * 0.75, centerOuter.dy,
          centerOuter.dx - rOuter * 0.65, centerOuter.dy + rOuter * 0.25,
        );
      final hatch2 = Path()
        ..moveTo(centerOuter.dx - rOuter * 0.45, centerOuter.dy - rOuter * 0.40)
        ..quadraticBezierTo(
          centerOuter.dx - rOuter * 0.58, centerOuter.dy,
          centerOuter.dx - rOuter * 0.45, centerOuter.dy + rOuter * 0.40,
        );
      final hatch3 = Path()
        ..moveTo(centerOuter.dx - rOuter * 0.25, centerOuter.dy - rOuter * 0.55)
        ..quadraticBezierTo(
          centerOuter.dx - rOuter * 0.38, centerOuter.dy,
          centerOuter.dx - rOuter * 0.25, centerOuter.dy + rOuter * 0.55,
        );

      canvas.drawPath(hatch1, hatchPaint);
      canvas.drawPath(hatch2, hatchPaint);
      canvas.drawPath(hatch3, hatchPaint);
    }

    // 4. KURAL İHLALİ / HATA: ORTASINDAN ÇATLAYAN KIRMIZI HİLAL
    if (isConflict) {
      final crackPaint = Paint()
        ..color = AppColors.pencilBlack
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final crack = Path();
      crack.moveTo(centerOuter.dx - rOuter * 0.55, centerOuter.dy - rOuter * 0.50);
      crack.lineTo(centerOuter.dx - rOuter * 0.35, centerOuter.dy - rOuter * 0.15);
      crack.lineTo(centerOuter.dx - rOuter * 0.60, centerOuter.dy + rOuter * 0.15);
      crack.lineTo(centerOuter.dx - rOuter * 0.40, centerOuter.dy + rOuter * 0.55);
      canvas.drawPath(crack, crackPaint);

      canvas.drawLine(
        Offset(centerOuter.dx - rOuter * 0.35, centerOuter.dy - rOuter * 0.15),
        Offset(centerOuter.dx - rOuter * 0.15, centerOuter.dy - rOuter * 0.25),
        crackPaint..strokeWidth = 1.6,
      );
      canvas.drawLine(
        Offset(centerOuter.dx - rOuter * 0.60, centerOuter.dy + rOuter * 0.15),
        Offset(centerOuter.dx - rOuter * 0.80, centerOuter.dy + rOuter * 0.20),
        crackPaint..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicDrawnMoonPainter oldDelegate) => oldDelegate.isConflict != isConflict;
}
