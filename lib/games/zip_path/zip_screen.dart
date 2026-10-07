import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Duvar hücresine basılamaz veya geçilemez
    if (_level.walls.contains(targetPoint)) return;

    if (_path.contains(targetPoint)) {
      // Yoldaki bir noktaya basılırsa o noktadan sonrasını kes
      final idx = _path.indexOf(targetPoint);
      if (idx < _path.length - 1) {
        HapticFeedback.selectionClick();
        setState(() {
          _path.removeRange(idx + 1, _path.length);
          _checkState();
        });
      }
      return;
    }

    if (_path.isEmpty) {
      // Yol sadece 1 numaradan başlayabilir
      if (_level.numberPoints[targetPoint] == 1) {
        HapticFeedback.lightImpact();
        setState(() {
          _path.add(targetPoint);
          _checkState();
        });
      }
    } else {
      final last = _path.last;
      final dr = (last.row - r).abs();
      final dc = (last.col - c).abs();

      // Yalnızca komşu kareler (yatay veya dikey)
      if (dr + dc == 1) {
        // Eğer hedef hücre bir numara içeriyorsa, sıradaki numara olmalı
        final nextTarget = _getNextTargetNumber();
        final cellNum = _level.numberPoints[targetPoint];

        if (cellNum != null && cellNum > nextTarget) {
          // Sırası gelmeyen bir numaraya atlanamaz
          HapticFeedback.vibrate();
          return;
        }

        HapticFeedback.lightImpact();
        setState(() {
          _path.add(targetPoint);
          _checkState();
        });
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
  }

  void _resetPath() {
    if (_isSolved || _path.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _path.clear();
      _checkState();
    });
  }

  void _checkState() {
    final solved = ZipLogic.validatePath(
      _path,
      _level.numberPoints,
      _level.gridSize,
      walls: _level.walls,
    );
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
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
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

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Sayı Yolu',
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
            const Icon(Icons.alt_route_rounded, color: AppColors.highlighterGreen, size: 28),
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
              '1\'den Başla',
              'Çizeceğin yol her zaman 1 numaralı daireden başlamalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Sayıları Sırayla Bağla',
              '1 ➔ 2 ➔ 3... şeklinde tüm sayıları sırasını atlamadan birbirine bağla.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Komşu Adımlar',
              'Yol yalnızca yatay ve dikey komşu kareler üzerinden ilerleyebilir, çapraz atlayamaz.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '4',
              'Engeller & Tüm Kareler',
              'Taranmış gri kareler duvardır, geçilemez. Diğer tüm boş kareler tam bir kez ziyaret edilmelidir.',
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
                      '• Parmağını sürükle veya karelere dokunarak yolu çiz!\n• Yoldaki bir kareye tekrar dokunursan oradan sonrasını geri alır.',
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
              color: AppColors.highlighterGreen,
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
                                  color: AppColors.highlighterGreen,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '⚡ 1\'den Zirveye Patika',
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

              // 2. İLERLEME VE HEDEF ÇUBUĞU (Organik SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Adım Sayısı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.highlighterGreen.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'Adım: ${_path.length}',
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sıradaki Hedef
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: nextTarget > maxNumber
                              ? AppColors.highlighterGreen
                              : AppColors.highlighterYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              nextTarget > maxNumber
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
                            padding: const EdgeInsets.all(4),
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
                                      final isWall = _level.walls.contains(p);

                                      if (isWall) {
                                        return Container(
                                          margin: const EdgeInsets.all(2.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceSecondaryLight.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.pencilLight,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.texture_rounded,
                                              size: cellSize * 0.45,
                                              color: AppColors.pencilGraphite.withValues(alpha: 0.4),
                                            ),
                                          ),
                                        );
                                      }

                                      Color cellBg;
                                      if (inPath) {
                                        cellBg = AppColors.highlighterGreen.withValues(alpha: 0.35);
                                      } else {
                                        cellBg = Colors.white;
                                      }

                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          color: cellBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: inPath ? AppColors.pencilBlack : AppColors.pencilLight,
                                            width: isHead ? 2.4 : (inPath ? 1.8 : 1.2),
                                          ),
                                          boxShadow: inPath
                                              ? const [
                                                  BoxShadow(
                                                    color: AppColors.pencilBlack,
                                                    offset: Offset(1.5, 1.5),
                                                    blurRadius: 0,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: numVal != null
                                              ? Container(
                                                  width: cellSize * 0.65,
                                                  height: cellSize * 0.65,
                                                  decoration: BoxDecoration(
                                                    color: inPath
                                                        ? AppColors.highlighterGreen
                                                        : AppColors.surfaceSecondaryLight,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppColors.pencilBlack,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$numVal',
                                                      style: GoogleFonts.patrickHand(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.pencilBlack,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : (inPath
                                                  ? Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.pencilBlack,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink()),
                                        ),
                                      );
                                    },
                                  ),

                                  // 2. Yol Bağlantı Çizgisi (Path Line Painter)
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

              // 4. ALT KONTROLLER (Geri Al & Yolu Sıfırla)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Geri Al Butonu
                    GestureDetector(
                      onTap: _path.isNotEmpty ? _undoMove : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _path.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            width: 2.0,
                          ),
                          boxShadow: _path.isNotEmpty
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
                    ),

                    const SizedBox(width: 16),

                    // Sıfırla Butonu
                    GestureDetector(
                      onTap: _path.isNotEmpty ? _resetPath : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _path.isNotEmpty ? AppColors.highlighterYellow : AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _path.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            width: 2.0,
                          ),
                          boxShadow: _path.isNotEmpty
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
      ..color = AppColors.pencilBlack.withValues(alpha: 0.65)
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
