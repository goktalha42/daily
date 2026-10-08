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
import '../../core/widgets/screen_shake.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'patches_models.dart';
import 'patches_logic.dart';
import 'patches_levels.dart';

class PatchesScreen extends ConsumerStatefulWidget {
  final String levelId;

  const PatchesScreen({super.key, required this.levelId});

  @override
  ConsumerState<PatchesScreen> createState() => _PatchesScreenState();
}

class _PatchesScreenState extends ConsumerState<PatchesScreen> {
  late PatchesLevel _level;
  final List<PatchRect> _userRects = [];
  PatchPoint? _dragStart;
  PatchPoint? _dragCurrent;

  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;

  // Canlı, dengeli organik eskiz paleti (Çiğ neon sarı/yeşil yasak!)
  static const List<Color> _patchPalette = [
    AppColors.skyBlue,            // Gök Mavisi (#38BDF8)
    AppColors.sunYellow,          // Sıcak Kehribar Sarısı (#F59E0B)
    Color(0xFFFB7185),            // Tatlı Mercan Pembe (#FB7185)
    AppColors.highlighterOrange,  // Turuncu (#FF9F43)
    AppColors.highlighterPurple,  // Lavanta Mor (#A29BFE)
    Color(0xFF34D399),            // Ferah Nane Yeşili (#34D399)
    Color(0xFF2DD4BF),            // Turkuaz (#2DD4BF)
    Color(0xFFF472B6),            // Canlı Pembe (#F472B6)
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = PatchesLevelRepository.getLevelForDate(widget.levelId);
    _userRects.clear();
    _dragStart = null;
    _dragCurrent = null;
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

  PatchPoint _cellFromOffset(Offset localPos, double boardSize) {
    final cellSize = boardSize / _level.gridSize;
    final r = (localPos.dy / cellSize).floor().clamp(0, _level.gridSize - 1);
    final c = (localPos.dx / cellSize).floor().clamp(0, _level.gridSize - 1);
    return PatchPoint(r, c);
  }

  Color _getClueColor(int clueIndex) {
    return _patchPalette[clueIndex % _patchPalette.length];
  }

  Color _getRectColor(PatchRect rect) {
    final enclosedClues = _level.clues.where((clue) => rect.contains(clue.row, clue.col)).toList();
    if (enclosedClues.length == 1) {
      final clueIdx = _level.clues.indexOf(enclosedClues.first);
      return _getClueColor(clueIdx);
    }
    return _patchPalette[rect.colorIndex % _patchPalette.length];
  }

  void _onPointerDown(PointerDownEvent event, double boardSize) {
    if (_isSolved) return;
    final pt = _cellFromOffset(event.localPosition, boardSize);

    final existingIdx = _userRects.indexWhere((r) => r.contains(pt.row, pt.col));
    if (existingIdx != -1) {
      HapticFeedback.selectionClick();
      setState(() {
        _userRects.removeAt(existingIdx);
        _checkState();
      });
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _dragStart = pt;
      _dragCurrent = pt;
    });
  }

  void _onPointerMove(PointerMoveEvent event, double boardSize) {
    if (_isSolved || _dragStart == null) return;
    final pt = _cellFromOffset(event.localPosition, boardSize);
    if (_dragCurrent != pt) {
      setState(() {
        _dragCurrent = pt;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event, double boardSize) {
    if (_isSolved || _dragStart == null || _dragCurrent == null) return;

    final newRect = PatchRect.fromPoints(
      _dragStart!,
      _dragCurrent!,
      colorIndex: _userRects.length % _patchPalette.length,
    );

    setState(() {
      _dragStart = null;
      _dragCurrent = null;

      if (PatchesLogic.hasOverlap(newRect, _userRects)) {
        HapticFeedback.vibrate();
        ScreenShake.shake(context, intensity: 4.0);
        return;
      }

      _userRects.add(newRect);
      HapticFeedback.mediumImpact();
      _checkState();
    });
  }

  void _undoMove() {
    if (_userRects.isEmpty || _isSolved) return;
    HapticFeedback.lightImpact();
    setState(() {
      _userRects.removeLast();
      _checkState();
    });
  }

  void _resetBoard() {
    if (_isSolved || _userRects.isEmpty) return;

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
          'Çizdiğin tüm alanlar ve dikdörtgenler silinecek. Devam etmek istiyor musun?',
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
                _userRects.clear();
                _checkState();
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
    final solved = PatchesLogic.validateBoard(_userRects, _level.clues, _level.gridSize);
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      _handleWin();
    }
  }

  void _handleWin() {
    final score = (2000 - (_elapsedMs ~/ 1000) * 10 - _userRects.length * 5).clamp(100, 2000);

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.patches,
      levelId: widget.levelId,
      userId: 'user_local',
      userName: 'Oyuncu',
      durationMs: _elapsedMs,
      moveCount: _userRects.length,
      score: score,
      completedAt: DateTime.now(),
    );

    ref.read(leaderboardServiceProvider).submitScore(result);
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.patches,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _userRects.length,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.patches,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
        );

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Alan Bölme',
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
            const Icon(Icons.dashboard_customize_rounded, color: AppColors.sunYellow, size: 28),
            const SizedBox(width: 8),
            Text(
              'Alan Bölme: Nasıl Oynanır?',
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
              'Sayı = Alan Kutucuğu',
              'Rozetteki sayı, kaplayacağın dikdörtgenin kaç kutucuktan oluşacağını belirtir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Şekil Simgelerine Dikkat',
              'Kare simgesi ➔ Kare (2x2 vb.)\nUzun simgesi ➔ Dikey Dikdörtgen\nGeniş simgesi ➔ Yatay Dikdörtgen\nYıldız simgesi ➔ Herhangi biri serbest!',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Boşluk & Çakışma Yok',
              'Tüm ızgara üst üste binmeyen alanlarla eksiksiz kaplanmalıdır.',
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
              color: AppColors.sunYellow,
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
    int coveredArea = 0;
    for (final rect in _userRects) {
      coveredArea += rect.area;
    }
    final totalArea = _level.gridSize * _level.gridSize;

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
                          const Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Alan Bölme',
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
                                  '🧩 Şekil ve Alan Rozetleri',
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

                    // Kronometre (Titremeyen sabit genişlikli kutu)
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

              // 2. İLERLEME VE ŞEKİL LEJANDI (image.png Standart Rehberi)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: 12,
                  shadowOffset: const Offset(2.5, 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Kare Simgesi
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondaryLight,
                              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Kare', style: GoogleFonts.patrickHand(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // Uzun Simgesi
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondaryLight,
                              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Uzun', style: GoogleFonts.patrickHand(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // Geniş Simgesi
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondaryLight,
                              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Geniş', style: GoogleFonts.patrickHand(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // Herhangi Biri
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.pencilBlack),
                          const SizedBox(width: 3),
                          Text('Serbest', style: GoogleFonts.patrickHand(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // 3. KAPLANAN ALAN VE BLOK SAYACI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  borderRadius: 12,
                  shadowOffset: const Offset(2.5, 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: coveredArea == totalArea
                              ? const Color(0xFF34D399).withValues(alpha: 0.35)
                              : AppColors.sunYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Text(
                          'Alan: $coveredArea / $totalArea',
                          style: GoogleFonts.patrickHand(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _userRects.length == _level.clues.length
                              ? const Color(0xFF34D399).withValues(alpha: 0.35)
                              : AppColors.skyBlue.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Text(
                          'Blok: ${_userRects.length} / ${_level.clues.length}',
                          style: GoogleFonts.patrickHand(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 4. ORGANİK SKEÇ ALAN BÖLME TAHTASI
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

                          PatchRect? dragPreviewRect;
                          if (_dragStart != null && _dragCurrent != null) {
                            dragPreviewRect = PatchRect.fromPoints(
                              _dragStart!,
                              _dragCurrent!,
                              colorIndex: _userRects.length % _patchPalette.length,
                            );
                          }

                          return SketchCard(
                            padding: const EdgeInsets.all(5),
                            borderRadius: 16,
                            shadowOffset: const Offset(4, 4),
                            borderWidth: 2.5,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (e) => _onPointerDown(e, boardSize),
                              onPointerMove: (e) => _onPointerMove(e, boardSize),
                              onPointerUp: (e) => _onPointerUp(e, boardSize),
                              child: Stack(
                                children: [
                                  // 1. Zemin Izgarası
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _level.gridSize,
                                    ),
                                    itemCount: _level.gridSize * _level.gridSize,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.all(1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.pencilLight.withValues(alpha: 0.4),
                                            width: 1.0,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // 2. Kullanıcının Çizdiği Dikdörtgen Bloklar
                                  ..._userRects.map((rect) {
                                    final left = rect.leftCol * cellSize;
                                    final top = rect.topRow * cellSize;
                                    final width = rect.width * cellSize;
                                    final height = rect.height * cellSize;

                                    final isValid = PatchesLogic.isValidRect(rect, _level.clues);
                                    final color = _getRectColor(rect);

                                    return Positioned(
                                      left: left + 2,
                                      top: top + 2,
                                      width: width - 4,
                                      height: height - 4,
                                      child: SketchCard(
                                        padding: EdgeInsets.zero,
                                        borderRadius: 10,
                                        borderWidth: 2.2,
                                        borderColor: isValid ? AppColors.pencilBlack : AppColors.error,
                                        shadowOffset: isValid ? const Offset(2.2, 2.2) : const Offset(1.5, 1.5),
                                        backgroundColor: color.withValues(alpha: 0.35),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CustomPaint(
                                            painter: _CrumpledPaperPainter(
                                              seed: rect.topRow * 37 + rect.leftCol * 13 + rect.width * 7 + rect.height * 3,
                                              isValid: isValid,
                                            ),
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                  // 3. Canlı Sürükleme Önizlemesi
                                  if (dragPreviewRect != null) ...[
                                    Positioned(
                                      left: dragPreviewRect.leftCol * cellSize + 2,
                                      top: dragPreviewRect.topRow * cellSize + 2,
                                      width: dragPreviewRect.width * cellSize - 4,
                                      height: dragPreviewRect.height * cellSize - 4,
                                      child: SketchCard(
                                        padding: EdgeInsets.zero,
                                        borderRadius: 10,
                                        borderWidth: 2.4,
                                        backgroundColor: AppColors.skyBlue.withValues(alpha: 0.22),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CustomPaint(
                                            painter: _CrumpledPaperPainter(
                                              seed: dragPreviewRect.topRow * 37 + dragPreviewRect.leftCol * 13 + dragPreviewRect.width * 7,
                                              isValid: true,
                                            ),
                                            child: Center(
                                              child: SketchCard(
                                                borderRadius: 8,
                                                borderWidth: 1.5,
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                child: Text(
                                                  '${dragPreviewRect.width}×${dragPreviewRect.height} = ${dragPreviewRect.area}',
                                                  style: GoogleFonts.patrickHand(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.pencilBlack,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // 4. Sabit Sayı Boncukları (Vezirler Tacı Tasarım Dilinde Rozetler!)
                                  ..._level.clues.asMap().entries.map((entry) {
                                    final clueIdx = entry.key;
                                    final clue = entry.value;
                                    final left = clue.col * cellSize;
                                    final top = clue.row * cellSize;
                                    final beadColor = _getClueColor(clueIdx);

                                    return Positioned(
                                      left: left,
                                      top: top,
                                      width: cellSize,
                                      height: cellSize,
                                      child: Center(
                                        child: SizedBox(
                                          width: cellSize * 0.78,
                                          height: cellSize * 0.78,
                                          child: CustomPaint(
                                            painter: _OrganicPatchesCluePainter(
                                              color: beadColor,
                                              shapeType: clue.shapeType,
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${clue.targetArea}',
                                                    style: GoogleFonts.patrickHand(
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.pencilBlack,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  _buildShapeMiniIcon(clue.shapeType),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
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

              // 5. ALT KONTROLLER (SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SketchCard(
                      backgroundColor: _userRects.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      shadowOffset: _userRects.isNotEmpty ? const Offset(2.5, 2.5) : Offset.zero,
                      borderWidth: 2.0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onTap: _userRects.isNotEmpty ? _undoMove : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.undo_rounded,
                            size: 18,
                            color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Geri Al',
                            style: GoogleFonts.patrickHand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    SketchCard(
                      backgroundColor: _userRects.isNotEmpty ? AppColors.sunYellow : AppColors.surfaceSecondaryLight,
                      borderRadius: 12,
                      shadowOffset: _userRects.isNotEmpty ? const Offset(2.5, 2.5) : Offset.zero,
                      borderWidth: 2.0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onTap: _userRects.isNotEmpty ? _resetBoard : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.restart_alt_rounded,
                            size: 18,
                            color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sıfırla',
                            style: GoogleFonts.patrickHand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
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

  Widget _buildShapeMiniIcon(PatchShapeType shapeType) {
    switch (shapeType) {
      case PatchShapeType.square:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.pencilBlack, width: 1.2),
          ),
        );
      case PatchShapeType.tall:
        return Container(
          width: 6,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.pencilBlack, width: 1.2),
          ),
        );
      case PatchShapeType.wide:
        return Container(
          width: 10,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.pencilBlack, width: 1.2),
          ),
        );
      case PatchShapeType.any:
        return const Icon(
          Icons.auto_awesome_rounded,
          size: 9,
          color: AppColors.pencilBlack,
        );
    }
  }
}

/// Vezirler Tacı Tasarım Dilinde El Çizimi Patches Boncuğu
class _OrganicPatchesCluePainter extends CustomPainter {
  final Color color;
  final PatchShapeType shapeType;

  _OrganicPatchesCluePainter({
    required this.color,
    required this.shapeType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.42;

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

    // Organik dalgalı rozet çizgisi
    final path = Path();
    path.moveTo(center.dx + r * 0.98, center.dy);
    path.cubicTo(center.dx + r * 0.98, center.dy + r * 0.56, center.dx + r * 0.56, center.dy + r * 0.98, center.dx, center.dy + r * 0.98);
    path.cubicTo(center.dx - r * 0.54, center.dy + r * 0.96, center.dx - r * 0.96, center.dy + r * 0.52, center.dx - r * 0.98, center.dy);
    path.cubicTo(center.dx - r * 0.96, center.dy - r * 0.55, center.dx - r * 0.52, center.dy - r * 0.98, center.dx, center.dy - r * 0.98);
    path.cubicTo(center.dx + r * 0.55, center.dy - r * 0.96, center.dx + r * 0.96, center.dy - r * 0.52, center.dx + r * 0.98, center.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(path, pen);

    // Çift hatlı taslak çizgi
    final dr = r * 0.90;
    final draftPath = Path();
    draftPath.moveTo(center.dx + dr, center.dy);
    draftPath.cubicTo(center.dx + dr, center.dy + dr * 0.54, center.dx + dr * 0.54, center.dy + dr, center.dx, center.dy + dr);
    draftPath.cubicTo(center.dx - dr * 0.54, center.dy + dr, center.dx - dr, center.dy + dr * 0.54, center.dx - dr, center.dy);
    draftPath.cubicTo(center.dx - dr, center.dy - dr * 0.54, center.dx - dr * 0.54, center.dy - dr, center.dx, center.dy - dr);
    draftPath.cubicTo(center.dx + dr * 0.54, center.dy - dr, center.dx + dr, center.dy - dr * 0.54, center.dx + dr, center.dy);
    draftPath.close();
    canvas.drawPath(draftPath, draft);
  }

  @override
  bool shouldRepaint(covariant _OrganicPatchesCluePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shapeType != shapeType;
  }
}

/// Buruşmuş Kağıt Dokusu Çizici (Crumpled Paper Creases & Fold Lines)
class _CrumpledPaperPainter extends CustomPainter {
  final int seed;
  final bool isValid;

  const _CrumpledPaperPainter({
    required this.seed,
    this.isValid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Deterministik LCG rastgele sayı üretici (render başına titremeyi önler)
    int state = (seed ^ 0x5DEECE66) & 0xFFFFFFFF;
    double nextDouble() {
      state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (state & 0x7FFFFFFF) / 0x7FFFFFFF;
    }

    final mainLineColor = (isValid ? AppColors.pencilBlack : AppColors.error).withValues(alpha: 0.28);
    final subLineColor = (isValid ? AppColors.pencilGraphite : AppColors.error).withValues(alpha: 0.18);
    final shadeColor = Colors.black.withValues(alpha: 0.04);
    final lightColor = Colors.white.withValues(alpha: 0.08);

    final mainPen = Paint()
      ..color = mainLineColor
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final subPen = Paint()
      ..color = subLineColor
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Alan büyüklüğüne göre kırışıklık düğüm sayısı
    final areaUnit = ((w * h) / (45 * 45)).clamp(1.0, 8.0).toInt();
    final nodeCount = 3 + areaUnit * 2;

    final List<Offset> nodes = [];
    for (int i = 0; i < nodeCount; i++) {
      final nx = (0.10 + nextDouble() * 0.80) * w;
      final ny = (0.10 + nextDouble() * 0.80) * h;
      nodes.add(Offset(nx, ny));
    }

    // 1. Kenarlardan ve köşelerden başlayan ana buruşukluk hatları
    final edgeStarts = [
      Offset(0, nextDouble() * h),
      Offset(w, nextDouble() * h),
      Offset(nextDouble() * w, 0),
      Offset(nextDouble() * w, h),
      if (nextDouble() > 0.4) Offset(0, nextDouble() * h),
      if (nextDouble() > 0.4) Offset(w, nextDouble() * h),
    ];

    for (int i = 0; i < edgeStarts.length; i++) {
      final start = edgeStarts[i];
      final targetNode = nodes[i % nodes.length];

      final midPoint = Offset(
        (start.dx + targetNode.dx) / 2 + (nextDouble() - 0.5) * (w * 0.15),
        (start.dy + targetNode.dy) / 2 + (nextDouble() - 0.5) * (h * 0.15),
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(midPoint.dx, midPoint.dy)
        ..lineTo(targetNode.dx, targetNode.dy);

      canvas.drawPath(path, mainPen);

      // Kırışıklığın bir tarafında hafif kağıt katlanma gölgesi
      if (nextDouble() > 0.35) {
        final foldShade = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(midPoint.dx, midPoint.dy)
          ..lineTo(midPoint.dx + (nextDouble() - 0.5) * 14, midPoint.dy + (nextDouble() - 0.5) * 14)
          ..close();
        canvas.drawPath(foldShade, Paint()..color = shadeColor..style = PaintingStyle.fill);
      }
    }

    // 2. Düğümler arası birbirine bağlanan iç kırışıklık hatları
    for (int i = 0; i < nodes.length - 1; i++) {
      final p1 = nodes[i];
      final p2 = nodes[(i + 1 + (nextDouble() * 2).toInt()) % nodes.length];

      final kink = Offset(
        (p1.dx + p2.dx) / 2 + (nextDouble() - 0.5) * (w * 0.12),
        (p1.dy + p2.dy) / 2 + (nextDouble() - 0.5) * (h * 0.12),
      );

      final creasePath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(kink.dx, kink.dy)
        ..lineTo(p2.dx, p2.dy);

      canvas.drawPath(creasePath, mainPen);

      // İnce dallanan kılcal buruşma çizgileri
      if (nextDouble() > 0.3) {
        final branchEnd = Offset(
          kink.dx + (nextDouble() - 0.5) * (w * 0.22),
          kink.dy + (nextDouble() - 0.5) * (h * 0.22),
        );
        canvas.drawLine(kink, branchEnd, subPen);
      }

      // Hafif ışık/yansıma faseti
      if (nextDouble() > 0.6) {
        final lightFacet = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(kink.dx, kink.dy)
          ..lineTo(kink.dx + (nextDouble() - 0.5) * 8, kink.dy + (nextDouble() - 0.5) * 8)
          ..close();
        canvas.drawPath(lightFacet, Paint()..color = lightColor..style = PaintingStyle.fill);
      }
    }

    // 3. Küçük çapraz kılcal kırışıklıklar
    final microFolds = (nodeCount * 0.8).toInt();
    for (int i = 0; i < microFolds; i++) {
      final base = nodes[i % nodes.length];
      final len = 6.0 + nextDouble() * 14.0;
      final end = Offset(
        (base.dx + len * (nextDouble() > 0.5 ? 1 : -1)).clamp(3.0, w - 3.0),
        (base.dy + len * (nextDouble() > 0.5 ? 1 : -1)).clamp(3.0, h - 3.0),
      );
      canvas.drawLine(base, end, subPen);
    }
  }

  @override
  bool shouldRepaint(covariant _CrumpledPaperPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.isValid != isValid;
  }
}

