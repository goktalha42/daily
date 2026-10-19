import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/services/game_session_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'zip_models.dart';
import 'zip_logic.dart';
import 'zip_levels.dart';

class ZipScreen extends ConsumerStatefulWidget {
  final String levelId;

  const ZipScreen({super.key, required this.levelId});

  @override
  ConsumerState<ZipScreen> createState() => _ZipScreenState();
}

class _ZipScreenState extends ConsumerState<ZipScreen> with WidgetsBindingObserver {
  late ZipLevel _level;
  final List<Point> _path = [];
  int _elapsedMs = 0;
  int _tickCount = 0;
  Timer? _timer;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveSession();
    }
  }

  void _initGame() {
    _level = ZipLevelRepository.getLevelForDate(widget.levelId);
    _path.clear();
    _elapsedMs = 0;
    _isSolved = false;
    _startTimer();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await GameSessionService.loadSession(
        game: GameType.zipPath,
        levelId: widget.levelId,
      );
      if (session != null && mounted) {
        final data = session['data'] as Map<String, dynamic>?;
        final savedElapsed = session['elapsedMs'] as int? ?? 0;
        if (data != null && data['path'] != null) {
          final rawPath = data['path'] as List;
          final loadedPath = rawPath.map((item) {
            final coords = item as List;
            return Point(coords[0] as int, coords[1] as int);
          }).toList();

          setState(() {
            _path.clear();
            _path.addAll(loadedPath);
            _elapsedMs = savedElapsed;
            _checkState();
          });
        }
      }
    } catch (_) {}
  }

  void _saveSession() {
    if (_isSolved) return;
    try {
      final pathCoords = _path.map((p) => [p.row, p.col]).toList();
      GameSessionService.saveSession(
        game: GameType.zipPath,
        levelId: widget.levelId,
        data: {
          'path': pathCoords,
        },
        elapsedMs: _elapsedMs,
      );
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _tickCount = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isSolved && mounted) {
        setState(() {
          _elapsedMs += 100;
        });
        _tickCount++;
        if (_tickCount % 10 == 0) {
          GameSessionService.updateElapsedMs(
            game: GameType.zipPath,
            levelId: widget.levelId,
            elapsedMs: _elapsedMs,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveSession();
    _timer?.cancel();
    super.dispose();
  }

  int _getNextTargetNumber() {
    int current = 1;
    for (final pt in _path) {
      if (_level.numberPoints.containsKey(pt)) {
        final val = _level.numberPoints[pt]!;
        if (val == current) {
          current++;
        }
      }
    }
    return current;
  }

  void _onCellTouch(int r, int c) {
    if (_isSolved) return;
    if (r < 0 || r >= _level.gridSize || c < 0 || c >= _level.gridSize) return;

    final targetPoint = Point(r, c);

    if (_path.contains(targetPoint)) {
      final idx = _path.indexOf(targetPoint);
      if (idx < _path.length - 1) {
        HapticFeedback.selectionClick();
        setState(() {
          _path.removeRange(idx + 1, _path.length);
          _checkState();
        });
        _saveSession();
      }
      return;
    }

    if (_path.isEmpty) {
      if (_level.numberPoints[targetPoint] == 1) {
        HapticFeedback.lightImpact();
        setState(() {
          _path.add(targetPoint);
          _checkState();
        });
        _saveSession();
      }
    } else {
      final last = _path.last;
      final dr = (last.row - r).abs();
      final dc = (last.col - c).abs();

      if (dr + dc == 1) {
        // LinkedIn Zip: İki kare arasındaki hat/çit üzerinden geçilemez!
        if (_level.edgeWalls.contains(ZipEdgeWall(last, targetPoint))) {
          HapticFeedback.vibrate();
          return;
        }

        final nextTarget = _getNextTargetNumber();
        final cellNum = _level.numberPoints[targetPoint];

        if (cellNum != null && cellNum > nextTarget) {
          HapticFeedback.vibrate();
          return;
        }

        HapticFeedback.lightImpact();
        setState(() {
          _path.add(targetPoint);
          _checkState();
        });
        _saveSession();
      }
    }
  }

  void _onPointerEvent(PointerEvent event, double boardSize) {
    if (_isSolved) return;
    final cellSize = boardSize / _level.gridSize;
    final r = (event.localPosition.dy / cellSize).floor();
    final c = (event.localPosition.dx / cellSize).floor();
    _onCellTouch(r, c);
  }

  void _undoMove() {
    if (_path.isEmpty || _isSolved) return;
    HapticFeedback.lightImpact();
    setState(() {
      _path.removeLast();
      _checkState();
    });
    _saveSession();
  }

  void _resetPath() {
    if (_isSolved) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _path.clear();
      // Süre sıfırlanmaz, o ana kadar geçen süre akmaya devam eder.
      _checkState();
    });
    _saveSession();
  }

  void _checkState() {
    final solved = ZipLogic.validatePath(
      _path,
      _level.numberPoints,
      _level.gridSize,
      walls: _level.walls,
      edgeWalls: _level.edgeWalls,
    );
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      _handleWin();
    }
  }

  void _handleWin() async {
    GameSessionService.clearSession(game: GameType.zipPath, levelId: widget.levelId);
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
    final statsResult = await ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.zipPath,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _path.length,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.zipPath,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
        );
    ref.read(badgeServiceProvider.notifier).evaluateBadges(
          gameType: GameType.zipPath,
          score: score,
          durationMs: _elapsedMs,
          overallIQ: statsResult.currentIQ,
          statsMap: ref.read(gameStatsServiceProvider),
          dailyPlayState: ref.read(dailyPlayServiceProvider),
        );

    if (!mounted) return;
    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Sayı Yolu',
      statsResult: statsResult,
      onRestart: () {
        Navigator.pop(context);
        GameSessionService.clearSession(game: GameType.zipPath, levelId: widget.levelId);
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
            const Icon(Icons.alt_route_rounded, color: AppColors.sunYellow, size: 28),
            const SizedBox(width: 8),
            Text(
              'Sayı Yolu: Nasıl Oynanır?',
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
              '1 Numaradan Başla',
              'Yol 1 numaralı başlangıç rozetinden başlamalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Sayıları Sırayla Bağla',
              '1 ➔ 2 ➔ 3... şeklinde sırayı atlamadan Bitiş Bayrağına kadar bağla.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Komşu Adımlar',
              'Yol yalnızca yatay ve dikey komşu kareler üzerinden ilerleyebilir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '4',
              'Tüm Kareleri Gez',
              'Tahtadaki istisnasız tüm kareler tek bir zincirle tam bir kez gezilmelidir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '5',
              'Hatlar ve Çitler',
              'Kareler arasındaki kalın siyah hatların üzerinden geçilemez, etrafından dolanmalısın.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunYellow,
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
              color: AppColors.skyBlue,
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
    final nextTarget = _getNextTargetNumber();
    final maxNumber = _level.numberPoints.values.reduce((a, b) => a > b ? a : b);
    final totalCells = _level.gridSize * _level.gridSize;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. ÜST KONTROL & BAŞLIK ÇUBUĞU
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SketchCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 10,
                      shadowOffset: const Offset(2.5, 2.5),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.pencilBlack),
                    ),

                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      borderRadius: 12,
                      shadowOffset: const Offset(2.5, 2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.alt_route_rounded, size: 18, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sayı Yolu',
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
                                  color: AppColors.skyBlue.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '⚡ Tüm Kareleri Dolaş',
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

                    // Kronometre (Titreme yapmayan sabit genişlikli kutu)
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

              // 2. İLERLEME VE HEDEF ÇUBUĞU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'Kare: ${_path.length} / $totalCells',
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (nextTarget > maxNumber && _path.length == totalCells)
                              ? const Color(0xFF34D399)
                              : AppColors.sunYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              (nextTarget > maxNumber && _path.length == totalCells)
                                  ? 'Tamamlandı! 🏁'
                                  : 'Sıradaki: $nextTarget / $maxNumber',
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

              // 3. ORGANİK SKEÇ SAYI YOLU TAHTASI
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
                            padding: const EdgeInsets.all(6),
                            borderRadius: 16,
                            shadowOffset: const Offset(4, 4),
                            borderWidth: 2.5,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (e) => _onPointerEvent(e, boardSize),
                              onPointerMove: (e) => _onPointerEvent(e, boardSize),
                              child: Stack(
                                children: [
                                  // 1. Zemin Hücreleri
                                  GridView.builder(
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
                                      final isHead = _path.isNotEmpty && _path.last == p;
                                      final numVal = _level.numberPoints[p];

                                      Color cellBg;
                                      if (inPath) {
                                        cellBg = AppColors.skyBlue.withValues(alpha: 0.22);
                                      } else {
                                        cellBg = Colors.white;
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.all(2.5),
                                        child: SketchCard(
                                          padding: EdgeInsets.zero,
                                          borderRadius: 10,
                                          borderWidth: isHead ? 2.6 : (inPath ? 2.0 : 1.3),
                                          shadowOffset: inPath ? const Offset(1.8, 1.8) : const Offset(1.0, 1.0),
                                          backgroundColor: cellBg,
                                          child: Center(
                                            child: numVal != null
                                                ? SizedBox(
                                                    width: cellSize * 0.76,
                                                    height: cellSize * 0.76,
                                                    child: CustomPaint(
                                                      painter: _OrganicZipNodePainter(
                                                        number: numVal,
                                                        maxNumber: maxNumber,
                                                        inPath: inPath,
                                                      ),
                                                      child: Center(
                                                        child: Padding(
                                                          padding: EdgeInsets.only(
                                                            top: numVal == 1 ? 2 : (numVal == maxNumber ? 4 : 0),
                                                          ),
                                                          child: Text(
                                                            '$numVal',
                                                            style: GoogleFonts.patrickHand(
                                                              fontSize: numVal == maxNumber ? 20 : 23,
                                                              fontWeight: FontWeight.w700,
                                                              color: AppColors.pencilBlack,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : (inPath
                                                    ? Container(
                                                        width: 7,
                                                        height: 7,
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.pencilBlack,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      )
                                                    : const SizedBox.shrink()),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // 2. Yol Bağlantı Çizgisi
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _ZipPathOverlayPainter(
                                          path: _path,
                                          gridSize: _level.gridSize,
                                          cellSize: cellSize,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. Kareler Arası Hatlar / Çitler (LinkedIn Zip)
                                  if (_level.edgeWalls.isNotEmpty)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: _ZipEdgeWallsPainter(
                                            edgeWalls: _level.edgeWalls,
                                            gridSize: _level.gridSize,
                                            cellSize: cellSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. ALT KONTROLLER (SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SketchCard(
                      backgroundColor: _path.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      shadowOffset: _path.isNotEmpty ? const Offset(2.5, 2.5) : Offset.zero,
                      borderWidth: 2.0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onTap: _path.isNotEmpty ? _undoMove : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.undo_rounded,
                            size: 18,
                            color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Geri Al',
                            style: GoogleFonts.patrickHand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    SketchCard(
                      backgroundColor: _path.isNotEmpty ? AppColors.sunYellow : AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      shadowOffset: _path.isNotEmpty ? const Offset(2.5, 2.5) : Offset.zero,
                      borderWidth: 2.0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onTap: _path.isNotEmpty ? _resetPath : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.restart_alt_rounded,
                            size: 18,
                            color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Yolu Sıfırla',
                            style: GoogleFonts.patrickHand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
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
}

/// Vezirler Tacı Tasarım Dilinde El Çizimi Başlangıç / Ara Düğüm / Bitiş Bayrağı Düğümü
class _OrganicZipNodePainter extends CustomPainter {
  final int number;
  final int maxNumber;
  final bool inPath;

  _OrganicZipNodePainter({
    required this.number,
    required this.maxNumber,
    required this.inPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.40;

    final pen = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final draft = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Renk Belirleme
    Color fillColor;
    if (number == 1) {
      fillColor = inPath ? const Color(0xFF34D399) : const Color(0xFFA7F3D0); // Başlangıç yeşili
    } else if (number == maxNumber) {
      fillColor = inPath ? const Color(0xFFFB7185) : const Color(0xFFFECDD3); // Bitiş mercan kırmızısı
    } else {
      fillColor = inPath ? AppColors.sunYellow : AppColors.surfaceSecondaryLight;
    }

    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;

    // 1. Organik Çift Hatlı Dalgalı Çember (Vezirler tacındaki gibi organik dalgalı eğriler)
    final path = Path();
    path.moveTo(center.dx + r * 0.98, center.dy);
    path.cubicTo(center.dx + r * 0.98, center.dy + r * 0.58, center.dx + r * 0.56, center.dy + r * 0.98, center.dx, center.dy + r * 0.98);
    path.cubicTo(center.dx - r * 0.54, center.dy + r * 0.96, center.dx - r * 0.96, center.dy + r * 0.52, center.dx - r * 0.98, center.dy);
    path.cubicTo(center.dx - r * 0.96, center.dy - r * 0.55, center.dx - r * 0.52, center.dy - r * 0.98, center.dx, center.dy - r * 0.98);
    path.cubicTo(center.dx + r * 0.55, center.dy - r * 0.96, center.dx + r * 0.96, center.dy - r * 0.52, center.dx + r * 0.98, center.dy);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, pen);

    // Çift hatlı taslak çizgi
    final draftPath = Path();
    final dr = r * 0.90;
    draftPath.moveTo(center.dx + dr, center.dy);
    draftPath.cubicTo(center.dx + dr, center.dy + dr * 0.55, center.dx + dr * 0.55, center.dy + dr, center.dx, center.dy + dr);
    draftPath.cubicTo(center.dx - dr * 0.55, center.dy + dr, center.dx - dr, center.dy + dr * 0.55, center.dx - dr, center.dy);
    draftPath.cubicTo(center.dx - dr, center.dy - dr * 0.55, center.dx - dr * 0.55, center.dy - dr, center.dx, center.dy - dr);
    draftPath.cubicTo(center.dx + dr * 0.55, center.dy - dr, center.dx + dr, center.dy - dr * 0.55, center.dx + dr, center.dy);
    draftPath.close();
    canvas.drawPath(draftPath, draft);

    // 2. Özel Durumlar:
    if (number == 1) {
      // Başlangıç: Tepesinde minik organik el çizimi pin / bayrak flama
      final flagPath = Path();
      flagPath.moveTo(center.dx - r * 0.40, center.dy - r * 0.95);
      flagPath.lineTo(center.dx - r * 0.40, center.dy - r * 1.35);
      flagPath.lineTo(center.dx + r * 0.10, center.dy - r * 1.15);
      flagPath.lineTo(center.dx - r * 0.40, center.dy - r * 0.95);
      canvas.drawPath(flagPath, Paint()..color = const Color(0xFF059669)..style = PaintingStyle.fill);
      canvas.drawPath(flagPath, pen..strokeWidth = 1.6);
      canvas.drawLine(Offset(center.dx - r * 0.40, center.dy - r * 0.70), Offset(center.dx - r * 0.40, center.dy - r * 1.38), pen..strokeWidth = 1.8);
    } else if (number == maxNumber) {
      // Bitiş: Tepesinde minik el çizimi damalı bitiş bayrağı (🏁)
      final flagPole = Path();
      flagPole.moveTo(center.dx + r * 0.20, center.dy - r * 0.75);
      flagPole.lineTo(center.dx + r * 0.20, center.dy - r * 1.40);
      canvas.drawPath(flagPole, pen..strokeWidth = 1.8);

      final flagBanner = Path();
      flagBanner.moveTo(center.dx + r * 0.20, center.dy - r * 1.40);
      flagBanner.lineTo(center.dx + r * 0.75, center.dy - r * 1.25);
      flagBanner.lineTo(center.dx + r * 0.20, center.dy - r * 1.05);
      flagBanner.close();
      canvas.drawPath(flagBanner, Paint()..color = AppColors.pencilBlack..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicZipNodePainter oldDelegate) {
    return oldDelegate.number != number ||
        oldDelegate.maxNumber != maxNumber ||
        oldDelegate.inPath != inPath;
  }
}

class _ZipPathOverlayPainter extends CustomPainter {
  final List<Point> path;
  final int gridSize;
  final double cellSize;

  _ZipPathOverlayPainter({
    required this.path,
    required this.gridSize,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final linePaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.75)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final drawPath = Path();

    for (int i = 0; i < path.length; i++) {
      final p = path[i];
      final x = p.col * cellSize + cellSize / 2;
      final y = p.row * cellSize + cellSize / 2;

      if (i == 0) {
        drawPath.moveTo(x, y);
      } else {
        drawPath.lineTo(x, y);
      }
    }

    canvas.drawPath(drawPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ZipPathOverlayPainter oldDelegate) {
    return oldDelegate.path.length != path.length;
  }
}

/// LinkedIn Zip tarzı kareler arasındaki organik hatları (çitleri/duvarları) çizer
class _ZipEdgeWallsPainter extends CustomPainter {
  final Set<ZipEdgeWall> edgeWalls;
  final int gridSize;
  final double cellSize;

  _ZipEdgeWallsPainter({
    required this.edgeWalls,
    required this.gridSize,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edgeWalls.isEmpty) return;

    // 1. Gölge / Derinlik boyası
    final shadowPaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 2. Ana Duvar / Çit boyası (Kalın ve net siyah hat)
    final wallPaint = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 3. Dikine Engel Tırnakları (Çit / Duvar deseni)
    final tickPaint = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 4. Uç Direkler / Perçinler
    final postOuterPaint = Paint()
      ..color = AppColors.pencilBlack
      ..style = PaintingStyle.fill;

    final postInnerPaint = Paint()
      ..color = AppColors.backgroundLight
      ..style = PaintingStyle.fill;

    for (final wall in edgeWalls) {
      final p1 = wall.p1;
      final p2 = wall.p2;

      double x1, y1, x2, y2;
      final bool isVertical = (p1.row == p2.row);

      if (isVertical) {
        // Dikey hat (yatay komşu iki hücre arasında)
        final cMax = math.max(p1.col, p2.col);
        x1 = cMax * cellSize;
        y1 = p1.row * cellSize + 2.0;
        x2 = cMax * cellSize;
        y2 = (p1.row + 1) * cellSize - 2.0;
      } else {
        // Yatay hat (dikey komşu iki hücre arasında)
        final rMax = math.max(p1.row, p2.row);
        x1 = p1.col * cellSize + 2.0;
        y1 = rMax * cellSize;
        x2 = (p1.col + 1) * cellSize - 2.0;
        y2 = rMax * cellSize;
      }

      // 1. Gölge hattı
      canvas.drawLine(Offset(x1 + 1.5, y1 + 1.5), Offset(x2 + 1.5, y2 + 1.5), shadowPaint);

      // 2. Ana kalın duvar hattı
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), wallPaint);

      // 3. Duvar üzerindeki belirgin engel tırnakları (Geçilemez olduğunu herkesin görmesi için)
      for (final t in [0.25, 0.50, 0.75]) {
        if (isVertical) {
          final my = y1 + (y2 - y1) * t;
          canvas.drawLine(Offset(x1 - 4.5, my), Offset(x1 + 4.5, my), tickPaint);
        } else {
          final mx = x1 + (x2 - x1) * t;
          canvas.drawLine(Offset(mx, y1 - 4.5), Offset(mx, y1 + 4.5), tickPaint);
        }
      }

      // 4. Uç perçin / bariyer direkleri
      canvas.drawCircle(Offset(x1, y1), 4.5, postOuterPaint);
      canvas.drawCircle(Offset(x1, y1), 2.0, postInnerPaint);

      canvas.drawCircle(Offset(x2, y2), 4.5, postOuterPaint);
      canvas.drawCircle(Offset(x2, y2), 2.0, postInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ZipEdgeWallsPainter oldDelegate) {
    return oldDelegate.edgeWalls != edgeWalls || oldDelegate.cellSize != cellSize;
  }
}
