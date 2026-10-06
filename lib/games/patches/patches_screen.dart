import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/game_stats_service.dart';
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

  // Organik fosforlu keçeli kalem renk paleti
  static const List<Color> _patchColors = [
    Color(0xFFFFDE59), // Fosforlu Sarı
    Color(0xFF86EFAC), // Fosforlu Nane Yeşili
    Color(0xFF70E0D8), // Fosforlu Turkuaz
    Color(0xFFFF9F68), // Fosforlu Turuncu
    Color(0xFFC4B5FD), // Fosforlu Lavanta
    Color(0xFFFF85A1), // Fosforlu Pembe
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

  void _onPointerDown(PointerDownEvent event, double boardSize) {
    if (_isSolved) return;
    final pt = _cellFromOffset(event.localPosition, boardSize);

    // Eğer tıklanan hücrede zaten bir dikdörtgen varsa ve tek dokunuşsa, o dikdörtgeni sil
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
      colorIndex: _userRects.length % _patchColors.length,
    );

    setState(() {
      _dragStart = null;
      _dragCurrent = null;

      // Çakışma kontrolü: Başka bir dikdörtgenle çakışıyorsa kabul etme
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
            const Icon(Icons.dashboard_customize_rounded, color: AppColors.highlighterYellow, size: 28),
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
              'Sayı = Dikdörtgen Alanı',
              'Izgaradaki her sayı, onu kapsayan dikdörtgenin alanını (kare sayısını) belirtir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Tam 1 Sayı İçermeli',
              'Çizeceğin her dikdörtgenin içinde tam olarak 1 adet sayı bulunmalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Boşluk ve Çakışma Yok',
              'Tüm ızgara üst üste binmeyen dikdörtgenlerle tamamen kaplanmalıdır.',
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
                      '• Parmağını basılı tutup sürükleyerek dikdörtgen çiz!\n• Çizdiğin bir dikdörtgeni silmek için üzerine bir kez dokun.',
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
              color: AppColors.highlighterYellow,
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
                                  color: AppColors.highlighterYellow,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '📐 Dikdörtgen Alanlar',
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

              // 2. İLERLEME VE ALAN ÇUBUĞU (Organik SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Kaplanan Alan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: coveredArea == totalArea
                              ? AppColors.highlighterGreen.withValues(alpha: 0.4)
                              : AppColors.highlighterYellow.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.grid_on_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'Alan: $coveredArea / $totalArea',
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Blok Sayısı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _userRects.length == _level.clues.length
                              ? AppColors.highlighterGreen.withValues(alpha: 0.4)
                              : AppColors.highlighterCyan.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.crop_free_rounded, size: 16, color: AppColors.pencilBlack),
                            const SizedBox(width: 4),
                            Text(
                              'Blok: ${_userRects.length} / ${_level.clues.length}',
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

              // 3. ORGANİK SKEÇ ALAN BÖLME TAHTASI
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
                              colorIndex: _userRects.length % _patchColors.length,
                            );
                          }

                          return SketchCard(
                            padding: const EdgeInsets.all(4),
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
                                            color: AppColors.pencilLight.withValues(alpha: 0.5),
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
                                    final color = _patchColors[rect.colorIndex % _patchColors.length];

                                    return Positioned(
                                      left: left + 2,
                                      top: top + 2,
                                      width: width - 4,
                                      height: height - 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.40),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isValid ? AppColors.pencilBlack : AppColors.error,
                                            width: 2.2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppColors.pencilBlack,
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  // 3. Canlı Sürükleme Önizlemesi (Drag Preview)
                                  if (dragPreviewRect != null) ...[
                                    Positioned(
                                      left: dragPreviewRect.leftCol * cellSize + 2,
                                      top: dragPreviewRect.topRow * cellSize + 2,
                                      width: dragPreviewRect.width * cellSize - 4,
                                      height: dragPreviewRect.height * cellSize - 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.highlighterYellow.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.pencilBlack,
                                            width: 2.4,
                                            strokeAlign: BorderSide.strokeAlignInside,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                                            ),
                                            child: Text(
                                              '${dragPreviewRect.width}×${dragPreviewRect.height} = ${dragPreviewRect.area}',
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.pencilBlack,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // 4. Sabit Sayı İpuçları (Tüm katmanların üstünde net görünüm)
                                  ..._level.clues.map((clue) {
                                    final left = clue.col * cellSize;
                                    final top = clue.row * cellSize;

                                    // Bu ipucunu içeren bir dikdörtgen var mı?
                                    final isEnclosed = _userRects.any((r) => r.contains(clue.row, clue.col));

                                    return Positioned(
                                      left: left,
                                      top: top,
                                      width: cellSize,
                                      height: cellSize,
                                      child: Center(
                                        child: Container(
                                          width: cellSize * 0.65,
                                          height: cellSize * 0.65,
                                          decoration: BoxDecoration(
                                            color: isEnclosed ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.pencilBlack,
                                              width: 1.8,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: AppColors.pencilBlack,
                                                offset: Offset(1, 1),
                                                blurRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${clue.targetArea}',
                                              style: GoogleFonts.patrickHand(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.pencilBlack,
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

              // 4. ALT KONTROLLER (Geri Al & Sıfırla)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Geri Al Butonu
                    GestureDetector(
                      onTap: _userRects.isNotEmpty ? _undoMove : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _userRects.isNotEmpty ? Colors.white : AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            width: 2.0,
                          ),
                          boxShadow: _userRects.isNotEmpty
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
                    ),

                    const SizedBox(width: 16),

                    // Sıfırla Butonu
                    GestureDetector(
                      onTap: _userRects.isNotEmpty ? _resetBoard : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _userRects.isNotEmpty ? AppColors.highlighterYellow : AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _userRects.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                            width: 2.0,
                          ),
                          boxShadow: _userRects.isNotEmpty
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
