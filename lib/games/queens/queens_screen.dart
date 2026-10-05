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
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'queens_models.dart';
import 'queens_logic.dart';
import 'queens_levels.dart';
import 'queens_board_painter.dart';

/// Tek bir hamle veya sürükleme (batch) hareketinin geri alınabilir geçmiş öğesi.
class _QueensHistoryItem {
  final Map<math.Point<int>, CellContent> changes; // Eski içerikler

  const _QueensHistoryItem({
    required this.changes,
  });
}

/// Sürükleme modunun tipi: Çarpı boyama mı, çarpı silme mi?
enum _DragMode {
  paintCross, // Boş hücreye basılıp sürüklendiğinde ✖ koyar
  eraseCross, // ✖ olan hücreye basılıp sürüklendiğinde siler
}

/// Her zorluk seviyesinin bağımsız oyun durumu ve sayacı
class _DifficultyState {
  final QueensLevel level;
  final List<List<QueensCell>> grid;
  final List<_QueensHistoryItem> history;
  int moveCount = 0;
  int elapsedMs = 0;
  bool isSolved = false;
  DateTime? lastHintTime;

  _DifficultyState({
    required this.level,
    required this.grid,
    required this.history,
  });
}

class QueensScreen extends ConsumerStatefulWidget {
  final String levelId;

  const QueensScreen({super.key, required this.levelId});

  @override
  ConsumerState<QueensScreen> createState() => _QueensScreenState();
}

class _QueensScreenState extends ConsumerState<QueensScreen> with SingleTickerProviderStateMixin {
  late QueensDifficulty _currentDifficulty;
  final Map<QueensDifficulty, _DifficultyState> _difficultyStates = {};
  Timer? _timer;

  // Taç Konulduğunda Hücreleri Sırayla Havaya Kaldıran 3D Dalga (Şimdilik Pasif)
  static const bool _enable3dEffect = false;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  math.Point<int>? _rippleCenterCell;

  // Sürükleme (Drag-to-Paint & Drag-to-Erase) ve Anlık Dokunma Durumu
  _DragMode? _currentDragMode;
  math.Point<int>? _dragStartCell;
  bool _hasDragged = false;
  final Set<math.Point<int>> _touchedInCurrentDrag = {};
  final Map<math.Point<int>, CellContent> _currentDragOriginals = {};

  // Çift Dokunma (Double Tap) Tespiti
  DateTime? _lastTapTime;
  math.Point<int>? _lastTapCell;

  // Organik Keçeli Kalem (Fosforlu) Renk Paleti
  static const List<Color> _sketchRegionColors = [
    Color(0xFFFFDE59), // Fosforlu Sarı
    Color(0xFF70E0D8), // Fosforlu Turkuaz
    Color(0xFFFF9F68), // Fosforlu Turuncu
    Color(0xFFFF85A1), // Fosforlu Pembe
    Color(0xFF86EFAC), // Fosforlu Nane Yeşili
    Color(0xFFC4B5FD), // Fosforlu Lavanta
    Color(0xFFBAE6FD), // Açık Gökyüzü
    Color(0xFFFED7AA), // Pastel Kayısı
    Color(0xFFDDD6FE), // Yumuşak Lila
    Color(0xFFD9F99D), // Taze Çimen
  ];

  // Aktif Zorluğun Durumuna ve Özelliklerine Kolay Erişim Getter'ları
  _DifficultyState get _currentState => _getOrCreateState(_currentDifficulty);
  QueensLevel get _level => _currentState.level;
  List<List<QueensCell>> get _grid => _currentState.grid;
  List<_QueensHistoryItem> get _history => _currentState.history;
  int get _moveCount => _currentState.moveCount;
  set _moveCount(int v) => _currentState.moveCount = v;
  int get _elapsedMs => _currentState.elapsedMs;
  bool get _isSolved => _currentState.isSolved;
  set _isSolved(bool v) => _currentState.isSolved = v;
  DateTime? get _lastHintTime => _currentState.lastHintTime;
  set _lastHintTime(DateTime? v) => _currentState.lastHintTime = v;

  @override
  void initState() {
    super.initState();
    _currentDifficulty = QueensDifficultyScheduler.getDifficultyForDate(widget.levelId);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOutCubic,
    );

    _getOrCreateState(_currentDifficulty);
    _startTimer();
  }

  _DifficultyState _getOrCreateState(QueensDifficulty diff) {
    return _difficultyStates.putIfAbsent(diff, () {
      final level = QueensLevelRepository.getLevelForDateAndDifficulty(widget.levelId, diff);
      final grid = List.generate(
        level.gridSize,
        (r) => List.generate(
          level.gridSize,
          (c) => QueensCell(row: r, col: c, regionId: level.regionMap[r][c]),
        ),
      );
      return _DifficultyState(
        level: level,
        grid: grid,
        history: [],
      );
    });
  }

  void _resetCurrentDifficulty() {
    final level = QueensLevelRepository.getLevelForDateAndDifficulty(widget.levelId, _currentDifficulty);
    final grid = List.generate(
      level.gridSize,
      (r) => List.generate(
        level.gridSize,
        (c) => QueensCell(row: r, col: c, regionId: level.regionMap[r][c]),
      ),
    );
    _difficultyStates[_currentDifficulty] = _DifficultyState(
      level: level,
      grid: grid,
      history: [],
    );
    _currentDragMode = null;
    _dragStartCell = null;
    _hasDragged = false;
    _rippleCenterCell = null;
    _rippleController.stop();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_currentState.isSolved && mounted) {
        setState(() {
          _currentState.elapsedMs += 100;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  void _switchDifficulty(QueensDifficulty newDifficulty) {
    if (_currentDifficulty == newDifficulty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentDifficulty = newDifficulty;
      _getOrCreateState(newDifficulty);
      _currentDragMode = null;
      _dragStartCell = null;
      _hasDragged = false;
      _rippleCenterCell = null;
      _rippleController.stop();
    });
  }

  // Taç Konulduğunda Kutuları Sırayla Yükseltip Alçaltan 3D Dalgayı Başlat
  void _triggerBoardRipple(int r, int c) {
    if (!_enable3dEffect) return;
    setState(() {
      _rippleCenterCell = math.Point(r, c);
    });
    _rippleController.forward(from: 0.0);
  }

  // Koordinattan (Local Offset) Hücre Satır/Sütun Bulma
  math.Point<int>? _cellFromOffset(Offset localOffset, double boardSize) {
    final cellSize = boardSize / _level.gridSize;
    final c = (localOffset.dx / cellSize).floor();
    final r = (localOffset.dy / cellSize).floor();

    if (r >= 0 && r < _level.gridSize && c >= 0 && c < _level.gridSize) {
      return math.Point(r, c);
    }
    return null;
  }

  // --- ANLIK TEKİL DOKUNMA, SÜRÜKLEME VE ÇİFT DOKUNMA (POINTER EVENTS) ---

  void _onPointerDown(PointerDownEvent event, double boardSize) {
    if (_isSolved) return;
    final cell = _cellFromOffset(event.localPosition, boardSize);
    if (cell == null) return;

    final now = DateTime.now();

    // 1. ÇİFT DOKUNMA (DOUBLE TAP) TESPİTİ:
    // Aynı hücreye 350 ms içinde tekrar dokunulduysa taç yerleştir / kaldır!
    if (_lastTapCell == cell &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 350) {
      _lastTapTime = null;
      _lastTapCell = null;
      _currentDragMode = null;
      _dragStartCell = null;
      _hasDragged = false;
      _touchedInCurrentDrag.clear();
      _currentDragOriginals.clear();

      _handleDoubleTapCell(cell.x, cell.y);
      return;
    }

    _lastTapTime = now;
    _lastTapCell = cell;

    _dragStartCell = cell;
    _hasDragged = false;
    _touchedInCurrentDrag.clear();
    _currentDragOriginals.clear();

    final currentContent = _grid[cell.x][cell.y].content;

    // KURAL:
    // - Eğer taç (Vezir) hücresine dokunulursa sürükleme KESİNLİKLE başlatılmaz!
    // - Boşsa -> Sürükleyerek ✖ boya
    // - Zaten ✖ ise -> Sürükleyerek ✖ sil
    if (currentContent == CellContent.queen) {
      _currentDragMode = null; // Taç üzerinden sürükleme işlemi yapılmaz
    } else if (currentContent == CellContent.empty) {
      _currentDragMode = _DragMode.paintCross;
    } else if (currentContent == CellContent.cross) {
      _currentDragMode = _DragMode.eraseCross;
    }
  }

  void _onPointerMove(PointerMoveEvent event, double boardSize) {
    if (_isSolved || _currentDragMode == null || _dragStartCell == null) return;
    final cell = _cellFromOffset(event.localPosition, boardSize);
    if (cell == null) return;

    if (cell != _dragStartCell) {
      if (!_hasDragged) {
        _hasDragged = true;
        // İlk dokunulan başlangıç hücresini de sürükleme işlemine dahil et
        _applyDragToCell(_dragStartCell!);
      }
      _applyDragToCell(cell);
    }
  }

  void _applyDragToCell(math.Point<int> cell) {
    if (_touchedInCurrentDrag.contains(cell)) return;

    final currentContent = _grid[cell.x][cell.y].content;

    // Vezir (Taç) olan hiçbir hücre sürükleme esnasında bozulmaz
    if (currentContent == CellContent.queen) return;

    if (_currentDragMode == _DragMode.paintCross && currentContent == CellContent.empty) {
      _currentDragOriginals[cell] = currentContent;
      _touchedInCurrentDrag.add(cell);
      setState(() {
        _grid[cell.x][cell.y].content = CellContent.cross;
      });
      HapticFeedback.selectionClick();
    } else if (_currentDragMode == _DragMode.eraseCross && currentContent == CellContent.cross) {
      _currentDragOriginals[cell] = currentContent;
      _touchedInCurrentDrag.add(cell);
      setState(() {
        _grid[cell.x][cell.y].content = CellContent.empty;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isSolved) return;

    // EĞER SÜRÜKLEME YAPILMADIYSA (TEKİL DOKUNMA):
    // Kullanıcı bir kutuya bir defa dokundu ve bıraktı -> ANINDA ÇARPI KOY VEYA SİL!
    if (!_hasDragged && _dragStartCell != null) {
      _handleSingleTapCell(_dragStartCell!.x, _dragStartCell!.y);
    } else if (_hasDragged && _currentDragOriginals.isNotEmpty) {
      // Sürükleme bittiğinde tek bir toplu işlem olarak geçmişe kaydet
      _history.add(_QueensHistoryItem(
        changes: Map.from(_currentDragOriginals),
      ));
      _moveCount++;
      _checkState();
    }

    _currentDragMode = null;
    _dragStartCell = null;
    _hasDragged = false;
    _touchedInCurrentDrag.clear();
    _currentDragOriginals.clear();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _currentDragMode = null;
    _dragStartCell = null;
    _hasDragged = false;
    _touchedInCurrentDrag.clear();
    _currentDragOriginals.clear();
  }

  /// Tek Dokunma:
  /// - Boşsa ✖ koyar
  /// - ✖ ise siler
  /// - KURAL: Taç varsa tek dokunmayla silinmez (kazara silinmeyi engeller)
  void _handleSingleTapCell(int r, int c) {
    final current = _grid[r][c].content;

    if (current == CellContent.queen) return;

    final CellContent next = (current == CellContent.empty) ? CellContent.cross : CellContent.empty;

    _history.add(_QueensHistoryItem(
      changes: {math.Point(r, c): current},
    ));

    setState(() {
      _grid[r][c].content = next;
      _moveCount++;
      _checkState();
    });
    HapticFeedback.lightImpact();
  }

  /// Çift Dokunma (Double Tap):
  /// - Taca çift dokunulursa taç yok olur!
  /// - Boş veya ✖ olan hücreye çift dokunulursa TAÇ (👑) yerleşir.
  /// - TAÇ YERLEŞTİĞİ AN: Tablo kutuları 3D dalgayla sırayla yükselip alçalır!
  void _handleDoubleTapCell(int r, int c) {
    if (_isSolved) return;
    HapticFeedback.mediumImpact();

    final current = _grid[r][c].content;
    final CellContent next;

    if (current == CellContent.queen) {
      // Taca çift dokunuldu -> Taç yok olur!
      next = CellContent.empty;
    } else {
      // Taç yerleştirilir
      next = CellContent.queen;
      // Tablo kutularına 3D dalga efektini tetikle
      _triggerBoardRipple(r, c);
    }

    _history.add(_QueensHistoryItem(
      changes: {math.Point(r, c): current},
    ));

    setState(() {
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

      lastMove.changes.forEach((pt, oldContent) {
        _grid[pt.x][pt.y].content = oldContent;
      });

      _moveCount++;
      _checkState();
    });
  }

  void _clearBoard() {
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
          'Tüm yerleştirdiğiniz vezir ve işaretler silinecek. Devam etmek istiyor musun?',
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
                    _grid[r][c].content = CellContent.empty;
                  }
                }
                _history.clear();
                _moveCount = 0;
                QueensLogic.validateGrid(_grid, _level.gridSize);
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
            const Icon(Icons.castle_rounded, color: AppColors.highlighterPink, size: 28),
            const SizedBox(width: 8),
            Text(
              'Vezirler: Nasıl Oynanır?',
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
            _buildRuleCard('1', 'Her Satır ve Sütunda 1 Vezir', 'Her satırda ve her sütunda tam 1 vezir bulunmalıdır.'),
            const SizedBox(height: 8),
            _buildRuleCard('2', 'Her Renk Bölgesinde 1 Vezir', 'Kalın skeç çizgileriyle ayrılmış her renkli bölgede tam 1 vezir olmalıdır.'),
            const SizedBox(height: 8),
            _buildRuleCard('3', 'Temas Yasağı (8-Yönlü)', 'Hiçbir vezir birbirine çapraz, yatay veya dikey temas edemez.'),
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
                      '• Parmağını sürükle: Hızlıca ✖ boya veya ✖ sil!\n• Çift dokun: 👑 (Vezir koy veya kaldır)\n• Tek dokun: ✖ koy veya kaldır',
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
              color: AppColors.highlighterPink,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
            ),
            child: Text(
              number,
              style: GoogleFonts.patrickHand(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.pencilBlack,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
          content: Text('Yeni ipucu için $remaining saniye beklemelisin.', style: GoogleFonts.patrickHand(fontSize: 16)),
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
            _history.add(_QueensHistoryItem(
              changes: {math.Point(r, c): CellContent.queen},
            ));
            setState(() {
              _grid[r][c].content = CellContent.cross;
              _checkState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💡 İpucu: Yanlış konulan vezir silindi ve ✖ ile elendi.', style: GoogleFonts.patrickHand(fontSize: 16)),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }
    }

    // 2. Doğru vezirlerden henüz konulmamış birini yerleştir + 3D Ripple
    for (final pt in _level.solution) {
      final r = pt[0];
      final c = pt[1];
      if (_grid[r][c].content != CellContent.queen) {
        final prev = _grid[r][c].content;
        _history.add(_QueensHistoryItem(
          changes: {math.Point(r, c): prev},
        ));
        _triggerBoardRipple(r, c);
        setState(() {
          _grid[r][c].content = CellContent.queen;
          _checkState();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💡 İpucu: Doğru bir vezir tahtaya yerleştirildi!', style: GoogleFonts.patrickHand(fontSize: 16)),
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
          _resetCurrentDifficulty();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int queenCount = 0;
    for (var row in _grid) {
      for (var cell in row) {
        if (cell.content == CellContent.queen) queenCount++;
      }
    }

    final cooldown = _getHintCooldown();
    final isHintReady = cooldown == 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. ÜST KONTROL & BAŞLIK ÇUBUĞU (Organik El Çizimi Skeç Kartları)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri Butonu (Organik SketchCard)
                    SketchCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 10,
                      shadowOffset: const Offset(2.5, 2.5),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.pencilBlack),
                    ),

                    // Zorluk Seçici (Organik Çizgili Skeç Kutusu)
                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      borderRadius: 12,
                      shadowOffset: const Offset(2.5, 2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: QueensDifficulty.values.map((diff) {
                          final isSelected = diff == _currentDifficulty;
                          return GestureDetector(
                            onTap: () => _switchDifficulty(diff),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.highlighterPink : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: AppColors.pencilBlack, width: 1.8) : null,
                              ),
                              child: Text(
                                diff.label,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
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

              const SizedBox(height: 4),

              // 2. KALAN VEZİR TEPSİSİ (Organik SketchCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalan Vezir: ${_level.gridSize - queenCount}',
                        style: GoogleFonts.patrickHand(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                      Row(
                        children: List.generate(_level.gridSize, (idx) {
                          final isPlaced = idx < queenCount;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isPlaced ? AppColors.highlighterYellow : AppColors.surfaceSecondaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pencilBlack,
                                width: isPlaced ? 2.0 : 1.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.castle_rounded,
                                size: 12,
                                color: isPlaced ? AppColors.pencilBlack : AppColors.pencilLight,
                              ),
                            ),
                          ).animate(target: isPlaced ? 1 : 0).scale(duration: 180.ms);
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. TAMAMEN ELLE ÇİZİLMİŞ VEZİRLER TAHTASI + RIPPLE EFFECT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = constraints.maxWidth;

                          return Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) => _onPointerDown(event, boardSize),
                            onPointerMove: (event) => _onPointerMove(event, boardSize),
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: AnimatedBuilder(
                              animation: _rippleAnimation,
                              builder: (context, child) {
                                return Stack(
                                  children: [
                                    // 1. Zemin: Organik Bölge Hatları ve Keçeli Boyama
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: QueensBoardPainter(
                                          gridSize: _level.gridSize,
                                          regionMap: _level.regionMap,
                                          grid: _grid,
                                          palette: _sketchRegionColors,
                                          isDark: false,
                                        ),
                                      ),
                                    ),
                                    // 2. Tablo Kutuları: Taç Koyulduğunda Sırayla Yükselip Alçalan 3D Dalga
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

                                        if (!_enable3dEffect) {
                                          return Center(
                                            child: _buildCellContent(cell),
                                          );
                                        }

                                        double lift = 0.0;
                                        double popScale = 1.0;
                                        double elevationFactor = 0.0;

                                        if (_rippleCenterCell != null && _rippleAnimation.value > 0.0) {
                                          final dist = math.sqrt(
                                            math.pow(r - _rippleCenterCell!.x, 2) +
                                            math.pow(c - _rippleCenterCell!.y, 2),
                                          );
                                          final maxDist = math.sqrt(2 * math.pow(_level.gridSize.toDouble(), 2));
                                          final normDist = dist / maxDist;
                                          final waveFront = _rippleAnimation.value * 1.35 - 0.15;
                                          final delta = (normDist - waveFront).abs();
                                          const waveWidth = 0.20;

                                          if (delta < waveWidth) {
                                            final bell = math.cos((delta / waveWidth) * (math.pi / 2));
                                            final damping = 1.0 - (normDist * 0.30);
                                            elevationFactor = (bell * damping).clamp(0.0, 1.0);
                                            lift = elevationFactor * 14.0;
                                            popScale = 1.0 + (elevationFactor * 0.18);
                                          }
                                        }

                                        final isElevated = elevationFactor > 0.02;
                                        final regionColor = _sketchRegionColors[_level.regionMap[r][c] % _sketchRegionColors.length];

                                        return Center(
                                          child: Transform.translate(
                                            offset: Offset(0, -lift),
                                            child: Transform.scale(
                                              scale: popScale,
                                              child: Container(
                                                margin: EdgeInsets.all(isElevated ? 2.0 : 0.0),
                                                decoration: isElevated
                                                    ? BoxDecoration(
                                                        color: regionColor,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: AppColors.pencilBlack,
                                                          width: 2.0,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppColors.pencilBlack.withValues(alpha: 0.35 * elevationFactor),
                                                            offset: Offset(2.0, 2.0 + lift * 0.65),
                                                            blurRadius: 3.0 * elevationFactor,
                                                          ),
                                                        ],
                                                      )
                                                    : null,
                                                child: Center(
                                                  child: _buildCellContent(cell),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. ALT İŞLEM BUTONLARI (Geri Al, Sıfırla, İpucu)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 14,
                  shadowOffset: const Offset(3.5, 3.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _OrganicSketchActionButton(
                        icon: Icons.undo_rounded,
                        label: 'Geri Al',
                        onTap: _history.isNotEmpty && !_isSolved ? _undoMove : null,
                      ),
                      Container(width: 2, height: 26, color: AppColors.pencilBlack.withValues(alpha: 0.2)),
                      _OrganicSketchActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Sıfırla',
                        onTap: !_isSolved ? _clearBoard : null,
                      ),
                      Container(width: 2, height: 26, color: AppColors.pencilBlack.withValues(alpha: 0.2)),
                      _OrganicSketchActionButton(
                        icon: isHintReady ? Icons.lightbulb_rounded : Icons.hourglass_bottom_rounded,
                        label: isHintReady ? 'İpucu' : '$cooldown s',
                        isActive: isHintReady,
                        activeColor: AppColors.highlighterYellow,
                        onTap: !_isSolved ? _useHint : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(QueensCell cell) {
    if (cell.content == CellContent.queen) {
      final crownSize = _level.gridSize >= 9 ? 24.0 : (_level.gridSize >= 8 ? 28.0 : 34.0);
      return CustomPaint(
        size: Size(crownSize, crownSize),
        painter: _OrganicDrawnCrownPainter(isConflict: cell.isConflict),
      )
          .animate()
          .scale(duration: 200.ms, curve: Curves.easeOutBack)
          .shake(duration: cell.isConflict ? 350.ms : 0.ms);
    } else if (cell.content == CellContent.cross) {
      final crossSize = _level.gridSize >= 9 ? 16.0 : (_level.gridSize >= 8 ? 18.0 : 22.0);
      return CustomPaint(
        size: Size(crossSize, crossSize),
        painter: _OrganicDrawnCrossPainter(),
      ).animate().scale(duration: 100.ms);
    }
    return const SizedBox.shrink();
  }
}

/// Tamamen Serbest El Çizimi Taç (Organik Eğrili Kurşun Kalem Karalaması)
class _OrganicDrawnCrownPainter extends CustomPainter {
  final bool isConflict;

  _OrganicDrawnCrownPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = isConflict ? AppColors.error : AppColors.highlighterYellow
      ..style = PaintingStyle.fill;

    final penPaint = Paint()
      ..color = AppColors.pencilBlack
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final draftPaint = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(w * 0.15, h * 0.82);
    path.quadraticBezierTo(w * 0.50, h * 0.85, w * 0.85, h * 0.82);
    path.lineTo(w * 0.92, h * 0.32);
    path.lineTo(w * 0.68, h * 0.54);
    path.lineTo(w * 0.50, h * 0.18);
    path.lineTo(w * 0.32, h * 0.54);
    path.lineTo(w * 0.08, h * 0.32);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, penPaint);

    final draftPath = Path();
    draftPath.moveTo(w * 0.14, h * 0.84);
    draftPath.lineTo(w * 0.86, h * 0.84);
    draftPath.lineTo(w * 0.90, h * 0.30);
    draftPath.lineTo(w * 0.67, h * 0.52);
    draftPath.lineTo(w * 0.50, h * 0.16);
    draftPath.lineTo(w * 0.33, h * 0.52);
    draftPath.lineTo(w * 0.10, h * 0.30);
    draftPath.close();
    canvas.drawPath(draftPath, draftPaint);

    canvas.drawLine(
      Offset(w * 0.18, h * 0.72),
      Offset(w * 0.82, h * 0.72),
      penPaint..strokeWidth = 1.8,
    );

    final dotPaint = Paint()
      ..color = AppColors.pencilBlack
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.08, h * 0.32), 2.2, dotPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), 2.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.92, h * 0.32), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OrganicDrawnCrownPainter oldDelegate) => oldDelegate.isConflict != isConflict;
}

/// Kurşun Kalemle Hızlıca Karalanmış Organik Çarpı (✖)
class _OrganicDrawnCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final draft = Paint()
      ..color = AppColors.pencilBlack.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final p1 = Path();
    p1.moveTo(w * 0.18, h * 0.20);
    p1.quadraticBezierTo(w * 0.52, h * 0.48, w * 0.82, h * 0.80);
    canvas.drawPath(p1, pen);

    canvas.drawLine(Offset(w * 0.22, h * 0.18), Offset(w * 0.84, h * 0.78), draft);

    final p2 = Path();
    p2.moveTo(w * 0.82, h * 0.20);
    p2.quadraticBezierTo(w * 0.48, h * 0.52, w * 0.18, h * 0.80);
    canvas.drawPath(p2, pen);

    canvas.drawLine(Offset(w * 0.80, h * 0.22), Offset(w * 0.16, h * 0.82), draft);
  }

  @override
  bool shouldRepaint(covariant _OrganicDrawnCrossPainter oldDelegate) => false;
}

/// Alt Çubuk İçin Organik Skeç Aksiyon Butonu
class _OrganicSketchActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color activeColor;

  const _OrganicSketchActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.activeColor = AppColors.highlighterYellow,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled ? AppColors.pencilBlack : AppColors.pencilLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AppColors.pencilBlack, width: 1.8) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.patrickHand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
