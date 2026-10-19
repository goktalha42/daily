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
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/services/game_session_service.dart';
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
  final QueensDifficulty? initialDifficulty;

  const QueensScreen({
    super.key,
    required this.levelId,
    this.initialDifficulty,
  });

  @override
  ConsumerState<QueensScreen> createState() => _QueensScreenState();
}

class _QueensScreenState extends ConsumerState<QueensScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late QueensDifficulty _currentDifficulty;
  final Map<QueensDifficulty, _DifficultyState> _difficultyStates = {};
  Timer? _timer;

  // İpucu Açıklama Kartı ve Hücre Aydınlatma Durumu
  String? _activeHintTitle;
  String? _activeHintMessage;
  bool _activeHintIsWarning = false;
  Timer? _highlightTimer;

  // Taç Konulduğunda Hücreleri Sırayla Havaya Kaldıran 3D Dalga (Şimdilik Pasif)
  static const bool _enable3dEffect = false;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  // Sürükleme (Drag-to-Paint & Drag-to-Erase) ve Anlık Dokunma Durumu
  _DragMode? _currentDragMode;
  math.Point<int>? _dragStartCell;
  bool _hasDragged = false;
  final Set<math.Point<int>> _touchedInCurrentDrag = {};
  final Map<math.Point<int>, CellContent> _currentDragOriginals = {};

  // Çift Dokunma (Double Tap) Tespiti
  DateTime? _lastTapTime;
  math.Point<int>? _lastTapCell;

  static const List<Color> _sketchRegionColors = [
    AppColors.sunYellow,
    AppColors.highlighterCyan,
    AppColors.highlighterOrange,
    AppColors.highlighterPink,
    Color(0xFF6EE7B7), // Nane / adaçayı (tatlı pastel yeşil)
    AppColors.highlighterPurple,
    Color(0xFFBAE6FD), // Açık Gökyüzü
    Color(0xFFFED7AA), // Pastel Kayısı
    Color(0xFFDDD6FE), // Yumuşak Lila
    Color(0xFFFDE68A), // Sıcak vanilya / kehribar
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

  int get _placedQueenCount {
    int count = 0;
    for (var row in _grid) {
      for (var cell in row) {
        if (cell.content == CellContent.queen) count++;
      }
    }
    return count;
  }

  int get _remainingQueenCount => math.max(0, _level.totalQueens - _placedQueenCount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDifficulty = widget.initialDifficulty ?? QueensDifficultyScheduler.getDifficultyForDate(widget.levelId);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOutCubic,
    );

    _getOrCreateState(_currentDifficulty);
    _loadSession();
    _startTimer();
  }

  Future<void> _loadSession() async {
    final session = await GameSessionService.loadSession(
      game: GameType.queens,
      levelId: widget.levelId,
      subKey: _currentDifficulty.name,
    );
    if (session != null && mounted) {
      final elapsed = session['elapsedMs'] as int? ?? 0;
      final data = session['data'] as Map<String, dynamic>?;
      if (data != null) {
        final gridData = data['grid'] as List<dynamic>?;
        if (gridData != null && gridData.length == _level.gridSize) {
          for (int r = 0; r < _level.gridSize; r++) {
            final rowList = gridData[r] as List<dynamic>;
            for (int c = 0; c < _level.gridSize; c++) {
              final cellTypeStr = rowList[c] as String;
              if (cellTypeStr == 'queen') {
                _grid[r][c].content = CellContent.queen;
              } else if (cellTypeStr == 'cross') {
                _grid[r][c].content = CellContent.cross;
              } else {
                _grid[r][c].content = CellContent.empty;
              }
            }
          }
          QueensLogic.validateGrid(_grid, _level.gridSize);
        }
        final moves = data['moveCount'] as int?;
        if (moves != null) {
          _moveCount = moves;
        }
      }
      setState(() {
        _currentState.elapsedMs = elapsed;
      });
    }
  }

  void _saveSession() {
    if (_currentState.isSolved) return;
    final gridData = List.generate(
      _level.gridSize,
      (r) => List.generate(
        _level.gridSize,
        (c) => _grid[r][c].content.name,
      ),
    );
    GameSessionService.saveSession(
      game: GameType.queens,
      levelId: widget.levelId,
      subKey: _currentDifficulty.name,
      elapsedMs: _currentState.elapsedMs,
      data: {
        'moveCount': _moveCount,
        'grid': gridData,
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveSession();
    }
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

  void _startTimer() {
    _timer?.cancel();
    int ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_currentState.isSolved && mounted) {
        setState(() {
          _currentState.elapsedMs += 100;
        });
        ticks++;
        if (ticks % 10 == 0) {
          GameSessionService.updateElapsedMs(
            game: GameType.queens,
            levelId: widget.levelId,
            subKey: _currentDifficulty.name,
            elapsedMs: _currentState.elapsedMs,
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
    _highlightTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  // Taç Konulduğunda Kutuları Sırayla Yükseltip Alçaltan 3D Dalgayı Başlat
  void _triggerBoardRipple(int r, int c) {
    if (!_enable3dEffect) return;
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

    if (_activeHintMessage != null) {
      setState(() => _activeHintMessage = null);
    }

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
  /// - Vezir sayısı tahta boyutunu aşamaz (asla negatif kalan vezir olmaz).
  void _handleDoubleTapCell(int r, int c) {
    if (_isSolved) return;

    if (_activeHintMessage != null) {
      setState(() => _activeHintMessage = null);
    }

    final current = _grid[r][c].content;
    final CellContent next;

    if (current == CellContent.queen) {
      // Taca çift dokunuldu -> Taç yok olur!
      next = CellContent.empty;
      HapticFeedback.lightImpact();
    } else {
      // Taç yerleştirilirken sınır kontrolü:
      if (_placedQueenCount >= _level.totalQueens) {
        HapticFeedback.heavyImpact();
        _showHintBanner(
          'Maksimum vezir sınırına (${_level.totalQueens}/${_level.totalQueens}) ulaşıldı! Yeni vezir eklemek için önce mevcut vezirlerden birini kaldırın.',
          title: '⚠️ Vezir Sınırı',
          isWarning: true,
        );
        return;
      }
      next = CellContent.queen;
      HapticFeedback.mediumImpact();
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
                // Süre sıfırlanmaz, o ana kadar geçen süre akmaya devam eder.
                QueensLogic.validateGrid(_grid, _level.gridSize);
              });
              _saveSession();
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
    final isMaster = _level.queensPerUnit == 2;
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
            isMaster
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SketchDoodleCrown(size: 20, color: AppColors.pencilBlack, fillColor: AppColors.sunYellow),
                      SizedBox(width: 3),
                      SketchDoodleCrown(size: 20, color: AppColors.pencilBlack, fillColor: AppColors.sunYellow),
                    ],
                  )
                : const SketchDoodleCrown(size: 24, color: AppColors.pencilBlack, fillColor: AppColors.sunYellow),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMaster ? 'Master Seviye: Çift Vezir' : 'Vezirler: Nasıl Oynanır?',
                style: GoogleFonts.patrickHand(
                  color: AppColors.pencilBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: isMaster ? 21 : 23,
                ),
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
              isMaster ? 'Her Satır ve Sütunda 2 Vezir' : 'Her Satır ve Sütunda 1 Vezir',
              isMaster
                  ? 'Her satırda ve her sütunda tam 2 vezir bulunmalıdır.'
                  : 'Her satırda ve her sütunda tam 1 vezir bulunmalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              isMaster ? 'Her Renk Bölgesinde 2 Vezir' : 'Her Renk Bölgesinde 1 Vezir',
              isMaster
                  ? 'Kalın skeç çizgileriyle ayrılmış her renkli bölgede tam 2 vezir olmalıdır.'
                  : 'Kalın skeç çizgileriyle ayrılmış her renkli bölgede tam 1 vezir olmalıdır.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Temas Yasağı (8-Yönlü)',
              isMaster
                  ? 'Hiçbir vezir birbirine çapraz, yatay veya dikey temas edemez (aynı satır/sütundaki vezirler de dahil!).'
                  : 'Hiçbir vezir birbirine çapraz, yatay veya dikey temas edemez.',
            ),
            const SizedBox(height: 12),
            SketchCard(
              padding: const EdgeInsets.all(10),
              backgroundColor: AppColors.accentCyan.withValues(alpha: 0.25),
              borderRadius: 12,
              borderWidth: 1.8,
              shadowOffset: const Offset(2, 2),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 20, color: AppColors.pencilBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMaster
                          ? '• Master modda tahtada toplam 18 vezir yer alır (9×9 Izgara).\n• Parmağını sürükle: Hızlıca ✖ boya veya ✖ sil!\n• Çift dokun: 👑 (Vezir koy veya kaldır)\n• Tek dokun: ✖ koy veya kaldır'
                          : '• Parmağını sürükle: Hızlıca ✖ boya veya ✖ sil!\n• Çift dokun: 👑 (Vezir koy veya kaldır)\n• Tek dokun: ✖ koy veya kaldır',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
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
            backgroundColor: AppColors.highlighterPink,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.patrickHand(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.pencilBlack,
                  ),
                ),
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
    final solved = QueensLogic.validateGrid(_grid, _level.gridSize, queensPerUnit: _level.queensPerUnit);
    if (solved && !_isSolved) {
      _isSolved = true;
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      _handleWin();
    } else {
      _saveSession();
    }
  }

  int _getHintCooldown() {
    if (_lastHintTime == null) return 0;
    final diff = DateTime.now().difference(_lastHintTime!).inSeconds;
    return (8 - diff).clamp(0, 8);
  }

  void _clearHighlights() {
    _highlightTimer?.cancel();
    if (mounted) {
      setState(() {
        for (var row in _grid) {
          for (var cell in row) {
            cell.isHighlighted = false;
          }
        }
      });
    }
  }

  void _highlightCells(Set<math.Point<int>> points) {
    _clearHighlights();
    setState(() {
      for (final pt in points) {
        if (pt.x >= 0 && pt.x < _level.gridSize && pt.y >= 0 && pt.y < _level.gridSize) {
          _grid[pt.x][pt.y].isHighlighted = true;
        }
      }
    });

    _highlightTimer = Timer(const Duration(seconds: 4), () {
      _clearHighlights();
    });
  }

  void _showHintBanner(String message, {String? title, bool isWarning = false}) {
    setState(() {
      _activeHintTitle = title ?? (isWarning ? 'Dikkat' : '💡 İpucu Rehberi');
      _activeHintMessage = message;
      _activeHintIsWarning = isWarning;
    });
  }

  void _useHint() {
    if (_isSolved) return;

    final now = DateTime.now();
    if (_lastHintTime != null && now.difference(_lastHintTime!).inSeconds < 8) {
      final remaining = 8 - now.difference(_lastHintTime!).inSeconds;
      _showHintBanner('Yeni ipucu için $remaining saniye beklemelisin.', isWarning: true);
      return;
    }

    _lastHintTime = now;
    HapticFeedback.mediumImpact();

    final reqQueens = _level.queensPerUnit;
    final size = _level.gridSize;

    // ADIM 1: Çakışan veya kural hatası yapan vezir varsa kaldır, ✖ koy ve nedenini açıkla
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c].content == CellContent.queen) {
          final isTrueQueen = _level.solution.any((pt) => pt[0] == r && pt[1] == c);
          if (!isTrueQueen || _grid[r][c].isConflict) {
            String reason = 'kuralları ihlal ettiği için';
            QueensCell? touchingQueen;
            for (var dr = -1; dr <= 1; dr++) {
              for (var dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                final nr = r + dr;
                final nc = c + dc;
                if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
                  if (_grid[nr][nc].content == CellContent.queen) {
                    touchingQueen = _grid[nr][nc];
                    break;
                  }
                }
              }
              if (touchingQueen != null) break;
            }

            if (touchingQueen != null) {
              reason = '(${touchingQueen.row + 1}. Satır, ${touchingQueen.col + 1}. Sütun)\'daki diğer vezire temas ettiği (çapraz/komşu)';
            } else {
              final inRow = _grid[r].where((cell) => cell.content == CellContent.queen).length;
              if (inRow > reqQueens) {
                reason = '${r + 1}. Satırdaki $reqQueens vezir kotasını aştığı';
              } else {
                int inCol = 0;
                for (var ro = 0; ro < size; ro++) {
                  if (_grid[ro][c].content == CellContent.queen) inCol++;
                }
                if (inCol > reqQueens) {
                  reason = '${c + 1}. Sütundaki $reqQueens vezir kotasını aştığı';
                } else {
                  final regId = _level.regionMap[r][c];
                  int inReg = 0;
                  for (var ro = 0; ro < size; ro++) {
                    for (var co = 0; co < size; co++) {
                      if (_level.regionMap[ro][co] == regId && _grid[ro][co].content == CellContent.queen) inReg++;
                    }
                  }
                  if (inReg > reqQueens) {
                    reason = 'kendi renk bölgesindeki $reqQueens vezir kotasını aştığı';
                  }
                }
              }
            }

            _history.add(_QueensHistoryItem(
              changes: {math.Point(r, c): CellContent.queen},
            ));
            setState(() {
              _grid[r][c].content = CellContent.cross;
              _checkState();
            });
            _highlightCells({math.Point(r, c)});
            _showHintBanner(
              '${r + 1}. Satır, ${c + 1}. Sütun\'daki vezir $reason için kural hatası oluşturuyordu. Bu vezir kaldırıldı ve yerine ✖ konuldu.',
              title: '🚨 Kural Hatası Düzeltildi',
            );
            return;
          }
        }
      }
    }

    // ADIM 2: Vezir temas yasağı (Adjacency Rule) ile eleme
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c].content == CellContent.queen) {
          final isTrueQueen = _level.solution.any((pt) => pt[0] == r && pt[1] == c);
          if (isTrueQueen) {
            for (var dr = -1; dr <= 1; dr++) {
              for (var dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                final nr = r + dr;
                final nc = c + dc;
                if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
                  if (_grid[nr][nc].content == CellContent.empty) {
                    _history.add(_QueensHistoryItem(changes: {math.Point(nr, nc): CellContent.empty}));
                    setState(() {
                      _grid[nr][nc].content = CellContent.cross;
                      _moveCount++;
                      _checkState();
                    });
                    _highlightCells({math.Point(r, c), math.Point(nr, nc)});
                    _showHintBanner(
                      '(${r + 1}. Satır, ${c + 1}. Sütun)\'da yer alan vezire bitişik ve çapraz temas eden karelere asla başka vezir gelemez! Bu kural gereği (${nr + 1}. Satır, ${nc + 1}. Sütun) karesine ✖ yerleştirildi.',
                      title: '❌ Temas Yasağı Kuralı',
                    );
                    return;
                  }
                }
              }
            }
          }
        }
      }
    }

    // ADIM 3: Kotası dolan Satır, Sütun veya Bölgedeki boşlukları eleme
    // 3A. Satır kotası tamamlandıysa
    for (var r = 0; r < size; r++) {
      int queensInRow = 0;
      final emptyCols = <int>[];
      for (var c = 0; c < size; c++) {
        if (_grid[r][c].content == CellContent.queen) queensInRow++;
        if (_grid[r][c].content == CellContent.empty) emptyCols.add(c);
      }
      if (queensInRow == reqQueens && emptyCols.isNotEmpty) {
        final c = emptyCols.first;
        _history.add(_QueensHistoryItem(changes: {math.Point(r, c): CellContent.empty}));
        setState(() {
          _grid[r][c].content = CellContent.cross;
          _moveCount++;
          _checkState();
        });
        _highlightCells({math.Point(r, c)});
        _showHintBanner(
          '${r + 1}. Satırda gereken $reqQueens vezir zaten yerleştirilmiş durumda! Bu satıra başka vezir gelemeyeceği için (${r + 1}. Satır, ${c + 1}. Sütun) karesine ✖ yerleştirildi.',
          title: '📌 Satır Kotası Tamamlandı',
        );
        return;
      }
    }

    // 3B. Sütun kotası tamamlandıysa
    for (var c = 0; c < size; c++) {
      int queensInCol = 0;
      final emptyRows = <int>[];
      for (var r = 0; r < size; r++) {
        if (_grid[r][c].content == CellContent.queen) queensInCol++;
        if (_grid[r][c].content == CellContent.empty) emptyRows.add(r);
      }
      if (queensInCol == reqQueens && emptyRows.isNotEmpty) {
        final r = emptyRows.first;
        _history.add(_QueensHistoryItem(changes: {math.Point(r, c): CellContent.empty}));
        setState(() {
          _grid[r][c].content = CellContent.cross;
          _moveCount++;
          _checkState();
        });
        _highlightCells({math.Point(r, c)});
        _showHintBanner(
          '${c + 1}. Sütunda gereken $reqQueens vezir zaten tamamlandı! Bu sütunda başka vezir yer alamayacağı için (${r + 1}. Satır, ${c + 1}. Sütun) karesine ✖ konuldu.',
          title: '📌 Sütun Kotası Tamamlandı',
        );
        return;
      }
    }

    // 3C. Bölge kotası tamamlandıysa
    for (var reg = 0; reg < size; reg++) {
      int queensInReg = 0;
      final emptyInReg = <math.Point<int>>[];
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (_level.regionMap[r][c] == reg) {
            if (_grid[r][c].content == CellContent.queen) queensInReg++;
            if (_grid[r][c].content == CellContent.empty) emptyInReg.add(math.Point(r, c));
          }
        }
      }
      if (queensInReg == reqQueens && emptyInReg.isNotEmpty) {
        final pt = emptyInReg.first;
        _history.add(_QueensHistoryItem(changes: {pt: CellContent.empty}));
        setState(() {
          _grid[pt.x][pt.y].content = CellContent.cross;
          _moveCount++;
          _checkState();
        });
        _highlightCells({pt});
        _showHintBanner(
          'Bu renk bölgesinde gereken $reqQueens vezir tamamlandı! Bu bölgede başka vezir olamayacağı için (${pt.x + 1}. Satır, ${pt.y + 1}. Sütun) karesine ✖ yerleştirildi.',
          title: '🎨 Bölge Kotası Tamamlandı',
        );
        return;
      }
    }

    // ADIM 4: Tek Kalan Seçenek Mantığıyla Mecburi Vezir Yerleştirme (Naked Single / Forced Queens)
    // 4A. Bölgede mecburi vezir
    for (var reg = 0; reg < size; reg++) {
      int queensInReg = 0;
      final candidates = <math.Point<int>>[];
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (_level.regionMap[r][c] == reg) {
            if (_grid[r][c].content == CellContent.queen) queensInReg++;
            if (_grid[r][c].content != CellContent.cross) candidates.add(math.Point(r, c));
          }
        }
      }
      final needed = reqQueens - queensInReg;
      if (needed > 0 && candidates.length == needed) {
        // Çift vezir modunda adayların birbirine temas edip etmediğini doğrula
        bool touches = false;
        for (int i = 0; i < candidates.length; i++) {
          for (int j = i + 1; j < candidates.length; j++) {
            if ((candidates[i].x - candidates[j].x).abs() <= 1 &&
                (candidates[i].y - candidates[j].y).abs() <= 1) {
              touches = true;
              break;
            }
          }
        }
        if (!touches) {
          final pt = candidates.firstWhere((p) => _grid[p.x][p.y].content != CellContent.queen);
          final prev = _grid[pt.x][pt.y].content;
          _history.add(_QueensHistoryItem(changes: {pt: prev}));
          _triggerBoardRipple(pt.x, pt.y);
          setState(() {
            _grid[pt.x][pt.y].content = CellContent.queen;
            _moveCount++;
            _checkState();
          });
          _highlightCells({pt});
          final hintDesc = reqQueens == 2
              ? 'Bu renk bölgesinde gereken $needed vezir için birbirine temas etmeyen tam $needed adet boş kare kalmıştı! Bölge kuralını tamamlamak için (${pt.x + 1}. Satır, ${pt.y + 1}. Sütun) karesine vezir yerleştirildi.'
              : 'Bu renk bölgesinde vezir konulabilecek sadece $needed adet boş yer kalmıştı! Bölge kuralını tamamlamak için (${pt.x + 1}. Satır, ${pt.y + 1}. Sütun) karesine mecburen vezir yerleştirildi.';
          _showHintBanner(
            hintDesc,
            title: '👑 Bölgenin Tek Seçeneği',
          );
          return;
        }
      }
    }

    // 4B. Satırda mecburi vezir
    for (var r = 0; r < size; r++) {
      int queensInRow = 0;
      final candidates = <int>[];
      for (var c = 0; c < size; c++) {
        if (_grid[r][c].content == CellContent.queen) queensInRow++;
        if (_grid[r][c].content != CellContent.cross) candidates.add(c);
      }
      final needed = reqQueens - queensInRow;
      if (needed > 0 && candidates.length == needed) {
        bool touches = false;
        for (int i = 0; i < candidates.length; i++) {
          for (int j = i + 1; j < candidates.length; j++) {
            if ((candidates[i] - candidates[j]).abs() <= 1) {
              touches = true;
              break;
            }
          }
        }
        if (!touches) {
          final c = candidates.firstWhere((col) => _grid[r][col].content != CellContent.queen);
          final prev = _grid[r][c].content;
          _history.add(_QueensHistoryItem(changes: {math.Point(r, c): prev}));
          _triggerBoardRipple(r, c);
          setState(() {
            _grid[r][c].content = CellContent.queen;
            _moveCount++;
            _checkState();
          });
          _highlightCells({math.Point(r, c)});
          _showHintBanner(
            '${r + 1}. Satırda vezir konulabilecek tam $needed boş kare kalmıştı! Satır kotasını tamamlamak için (${r + 1}. Satır, ${c + 1}. Sütun) karesine vezir yerleştirildi.',
            title: '👑 Satırın Tek Seçeneği',
          );
          return;
        }
      }
    }

    // 4C. Sütunda mecburi vezir
    for (var c = 0; c < size; c++) {
      int queensInCol = 0;
      final candidates = <int>[];
      for (var r = 0; r < size; r++) {
        if (_grid[r][c].content == CellContent.queen) queensInCol++;
        if (_grid[r][c].content != CellContent.cross) candidates.add(r);
      }
      final needed = reqQueens - queensInCol;
      if (needed > 0 && candidates.length == needed) {
        bool touches = false;
        for (int i = 0; i < candidates.length; i++) {
          for (int j = i + 1; j < candidates.length; j++) {
            if ((candidates[i] - candidates[j]).abs() <= 1) {
              touches = true;
              break;
            }
          }
        }
        if (!touches) {
          final r = candidates.firstWhere((row) => _grid[row][c].content != CellContent.queen);
          final prev = _grid[r][c].content;
          _history.add(_QueensHistoryItem(changes: {math.Point(r, c): prev}));
          _triggerBoardRipple(r, c);
          setState(() {
            _grid[r][c].content = CellContent.queen;
            _moveCount++;
            _checkState();
          });
          _highlightCells({math.Point(r, c)});
          _showHintBanner(
            '${c + 1}. Sütunda vezir konulabilecek tam $needed boş kare kalmıştı! Sütun kotasını tamamlamak için (${r + 1}. Satır, ${c + 1}. Sütun) karesine vezir yerleştirildi.',
            title: '👑 Sütunun Tek Seçeneği',
          );
          return;
        }
      }
    }

    // ADIM 5: Master Çift Temas ve Bağımsız Çıkarımlar (Touching Pair & Partner Deductions)
    if (reqQueens == 2) {
      // 5A. Bölgede Çift Temas (3 adaydan 2'si temas ediyor -> 3. KESİN VEZİR)
      for (var reg = 0; reg < size; reg++) {
        int queensInReg = 0;
        final candidates = <math.Point<int>>[];
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            if (_level.regionMap[r][c] == reg) {
              if (_grid[r][c].content == CellContent.queen) queensInReg++;
              if (_grid[r][c].content == CellContent.empty) candidates.add(math.Point(r, c));
            }
          }
        }
        final needed = 2 - queensInReg;
        if (needed == 2 && candidates.length == 3) {
          for (int i = 0; i < 3; i++) {
            for (int j = i + 1; j < 3; j++) {
              final p1 = candidates[i];
              final p2 = candidates[j];
              if ((p1.x - p2.x).abs() <= 1 && (p1.y - p2.y).abs() <= 1) {
                final k = 3 - i - j;
                final forced = candidates[k];
                _history.add(_QueensHistoryItem(changes: {forced: CellContent.empty}));
                _triggerBoardRipple(forced.x, forced.y);
                setState(() {
                  _grid[forced.x][forced.y].content = CellContent.queen;
                  _moveCount++;
                  _checkState();
                });
                _highlightCells({p1, p2, forced});
                _showHintBanner(
                  'Bu bölgede 2 vezir gerekiyor. (${p1.x + 1}. Satır, ${p1.y + 1}. Sütun) ile (${p2.x + 1}. Satır, ${p2.y + 1}. Sütun) birbirine temas ettiği için ikisi birden vezir olamaz! Bu yüzden temas etmeyen (${forced.x + 1}. Satır, ${forced.y + 1}. Sütun) karesi kesinlikle vezir olmak zorundadır.',
                  title: '⚡ Çift Temas Çıkarımı (Master)',
                );
                return;
              }
            }
          }
        }

        // 5B. Bölgede Partner İmkânsızlığı (Bir aday diğer tüm adaylara değiyorsa vezir olamaz -> ✖)
        if (needed == 2 && candidates.length >= 3) {
          for (final p in candidates) {
            final hasPartner = candidates.any((other) =>
                other != p &&
                ((other.x - p.x).abs() > 1 || (other.y - p.y).abs() > 1));
            if (!hasPartner) {
              _history.add(_QueensHistoryItem(changes: {p: CellContent.empty}));
              setState(() {
                _grid[p.x][p.y].content = CellContent.cross;
                _moveCount++;
                _checkState();
              });
              _highlightCells({p, ...candidates.where((c) => c != p)});
              _showHintBanner(
                'Bu renk bölgesinde 2 vezir gerekiyor. (${p.x + 1}. Satır, ${p.y + 1}. Sütun) karesine vezir konulursa bölgedeki diğer tüm boş kareler engellenir ve 2. vezire yer kalmaz! Bu nedenle bu kare vezir olamaz (✖ konuldu).',
                title: '🚫 İmkânsız Partner Tespiti',
              );
              return;
            }
          }
        }
      }

      // 5C. Satırda Çift Temas (3 adaydan 2'si temas ediyor -> 3. KESİN VEZİR)
      for (var r = 0; r < size; r++) {
        int queensInRow = 0;
        final candidates = <int>[];
        for (var c = 0; c < size; c++) {
          if (_grid[r][c].content == CellContent.queen) queensInRow++;
          if (_grid[r][c].content == CellContent.empty) candidates.add(c);
        }
        final needed = 2 - queensInRow;
        if (needed == 2 && candidates.length == 3) {
          for (int i = 0; i < 3; i++) {
            for (int j = i + 1; j < 3; j++) {
              if ((candidates[i] - candidates[j]).abs() <= 1) {
                final k = 3 - i - j;
                final forcedCol = candidates[k];
                final forced = math.Point(r, forcedCol);
                _history.add(_QueensHistoryItem(changes: {forced: CellContent.empty}));
                _triggerBoardRipple(r, forcedCol);
                setState(() {
                  _grid[r][forcedCol].content = CellContent.queen;
                  _moveCount++;
                  _checkState();
                });
                _highlightCells({math.Point(r, candidates[i]), math.Point(r, candidates[j]), forced});
                _showHintBanner(
                  '${r + 1}. Satırda 2 vezir gerekiyor. Yan yana duran sütunlar aynı anda vezir alamayacağı için, temas etmeyen (${r + 1}. Satır, ${forcedCol + 1}. Sütun) karesi kesinlikle vezir olmak zorundadır.',
                  title: '⚡ Satır Çift Temas Çıkarımı',
                );
                return;
              }
            }
          }
        }
      }

      // 5D. Sütunda Çift Temas (3 adaydan 2'si temas ediyor -> 3. KESİN VEZİR)
      for (var c = 0; c < size; c++) {
        int queensInCol = 0;
        final candidates = <int>[];
        for (var r = 0; r < size; r++) {
          if (_grid[r][c].content == CellContent.queen) queensInCol++;
          if (_grid[r][c].content == CellContent.empty) candidates.add(r);
        }
        final needed = 2 - queensInCol;
        if (needed == 2 && candidates.length == 3) {
          for (int i = 0; i < 3; i++) {
            for (int j = i + 1; j < 3; j++) {
              if ((candidates[i] - candidates[j]).abs() <= 1) {
                final k = 3 - i - j;
                final forcedRow = candidates[k];
                final forced = math.Point(forcedRow, c);
                _history.add(_QueensHistoryItem(changes: {forced: CellContent.empty}));
                _triggerBoardRipple(forcedRow, c);
                setState(() {
                  _grid[forcedRow][c].content = CellContent.queen;
                  _moveCount++;
                  _checkState();
                });
                _highlightCells({math.Point(candidates[i], c), math.Point(candidates[j], c), forced});
                _showHintBanner(
                  '${c + 1}. Sütunda 2 vezir gerekiyor. Birbirine değen satırlar aynı anda vezir alamayacağı için, temas etmeyen (${forcedRow + 1}. Satır, ${c + 1}. Sütun) karesi kesinlikle vezir olmak zorundadır.',
                  title: '⚡ Sütun Çift Temas Çıkarımı',
                );
                return;
              }
            }
          }
        }
      }
    }

    // ADIM 6: Kilitli Aday İndirgemesi (Pointing & Claiming Line-Region Reduction)
    // 6A. Pointing: Bölge -> Satır / Sütun
    for (var reg = 0; reg < size; reg++) {
      final regCandidates = <math.Point<int>>[];
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (_level.regionMap[r][c] == reg && _grid[r][c].content == CellContent.empty) {
            regCandidates.add(math.Point(r, c));
          }
        }
      }
      if (regCandidates.length >= 2) {
        final firstRow = regCandidates.first.x;
        if (regCandidates.every((pt) => pt.x == firstRow)) {
          int queensInReg = 0;
          for (var r = 0; r < size; r++) {
            for (var c = 0; c < size; c++) {
              if (_level.regionMap[r][c] == reg && _grid[r][c].content == CellContent.queen) queensInReg++;
            }
          }
          final neededInReg = reqQueens - queensInReg;

          int queensInRow = 0;
          for (var c = 0; c < size; c++) {
            if (_grid[firstRow][c].content == CellContent.queen) queensInRow++;
          }
          final neededInRow = reqQueens - queensInRow;

          if (neededInRow == neededInReg) {
            for (var c = 0; c < size; c++) {
              if (_level.regionMap[firstRow][c] != reg && _grid[firstRow][c].content == CellContent.empty) {
                _history.add(_QueensHistoryItem(changes: {math.Point(firstRow, c): CellContent.empty}));
                setState(() {
                  _grid[firstRow][c].content = CellContent.cross;
                  _moveCount++;
                  _checkState();
                });
                _highlightCells({math.Point(firstRow, c), ...regCandidates});
                _showHintBanner(
                  'Bu renk bölgesinin kalan tüm vezir adayları sadece ${firstRow + 1}. Satır üzerinde yer alıyor. Satırın kalan kotasını bu bölge karşılayacağı için, satırın bölge dışındaki (${firstRow + 1}. Satır, ${c + 1}. Sütun) karesine vezir gelemez (✖ konuldu).',
                  title: '📐 Kilitli Aday İndirgemesi',
                );
                return;
              }
            }
          }
        }

        final firstCol = regCandidates.first.y;
        if (regCandidates.every((pt) => pt.y == firstCol)) {
          int queensInReg = 0;
          for (var r = 0; r < size; r++) {
            for (var c = 0; c < size; c++) {
              if (_level.regionMap[r][c] == reg && _grid[r][c].content == CellContent.queen) queensInReg++;
            }
          }
          final neededInReg = reqQueens - queensInReg;

          int queensInCol = 0;
          for (var r = 0; r < size; r++) {
            if (_grid[r][firstCol].content == CellContent.queen) queensInCol++;
          }
          final neededInCol = reqQueens - queensInCol;

          if (neededInCol == neededInReg) {
            for (var r = 0; r < size; r++) {
              if (_level.regionMap[r][firstCol] != reg && _grid[r][firstCol].content == CellContent.empty) {
                _history.add(_QueensHistoryItem(changes: {math.Point(r, firstCol): CellContent.empty}));
                setState(() {
                  _grid[r][firstCol].content = CellContent.cross;
                  _moveCount++;
                  _checkState();
                });
                _highlightCells({math.Point(r, firstCol), ...regCandidates});
                _showHintBanner(
                  'Bu renk bölgesinin kalan tüm vezir adayları sadece ${firstCol + 1}. Sütun üzerinde yer alıyor. Sütunun kalan kotasını bu bölge karşılayacağı için, sütunun bölge dışındaki (${r + 1}. Satır, ${firstCol + 1}. Sütun) karesine vezir gelemez (✖ konuldu).',
                  title: '📐 Kilitli Aday İndirgemesi',
                );
                return;
              }
            }
          }
        }
      }
    }

    // 6B. Claiming: Satır / Sütun -> Bölge
    for (var r = 0; r < size; r++) {
      final rowCandidates = <math.Point<int>>[];
      int queensInRow = 0;
      for (var c = 0; c < size; c++) {
        if (_grid[r][c].content == CellContent.queen) queensInRow++;
        if (_grid[r][c].content == CellContent.empty) rowCandidates.add(math.Point(r, c));
      }
      final neededInRow = reqQueens - queensInRow;
      if (neededInRow > 0 && rowCandidates.isNotEmpty) {
        final targetReg = _level.regionMap[r][rowCandidates.first.y];
        if (rowCandidates.every((pt) => _level.regionMap[r][pt.y] == targetReg)) {
          int queensInReg = 0;
          for (var ro = 0; ro < size; ro++) {
            for (var co = 0; co < size; co++) {
              if (_level.regionMap[ro][co] == targetReg && _grid[ro][co].content == CellContent.queen) queensInReg++;
            }
          }
          final neededInReg = reqQueens - queensInReg;
          if (neededInReg == neededInRow) {
            for (var ro = 0; ro < size; ro++) {
              if (ro == r) continue;
              for (var co = 0; co < size; co++) {
                if (_level.regionMap[ro][co] == targetReg && _grid[ro][co].content == CellContent.empty) {
                  _history.add(_QueensHistoryItem(changes: {math.Point(ro, co): CellContent.empty}));
                  setState(() {
                    _grid[ro][co].content = CellContent.cross;
                    _moveCount++;
                    _checkState();
                  });
                  _highlightCells({math.Point(ro, co), ...rowCandidates});
                  _showHintBanner(
                    '${r + 1}. Satırın tüm vezir adayları bu renk bölgesinde bulunuyor. Satırın vezirleri bu bölgeyi dolduracağı için, bölgenin satır dışındaki (${ro + 1}. Satır, ${co + 1}. Sütun) karesine vezir gelemez (✖ konuldu).',
                    title: '📐 Kilitli Satır İndirgemesi',
                  );
                  return;
                }
              }
            }
          }
        }
      }
    }

    // ADIM 7: Birim Açlığı / Kontradiksiyon Tespiti (Unit Starvation Impossibility Deduction)
    if (reqQueens == 2) {
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (_grid[r][c].content != CellContent.empty) continue;

          for (var reg = 0; reg < size; reg++) {
            if (_level.regionMap[r][c] == reg) continue;
            int queensInReg = 0;
            for (var ro = 0; ro < size; ro++) {
              for (var co = 0; co < size; co++) {
                if (_level.regionMap[ro][co] == reg && _grid[ro][co].content == CellContent.queen) queensInReg++;
              }
            }
            final needed = 2 - queensInReg;
            if (needed <= 0) continue;

            final valid = <math.Point<int>>[];
            for (var ro = 0; ro < size; ro++) {
              for (var co = 0; co < size; co++) {
                if (_level.regionMap[ro][co] == reg && _grid[ro][co].content == CellContent.empty) {
                  if ((ro - r).abs() > 1 || (co - c).abs() > 1) {
                    valid.add(math.Point(ro, co));
                  }
                }
              }
            }

            bool blocksUnit = false;
            if (valid.length < needed) {
              blocksUnit = true;
            } else if (needed == 2) {
              bool hasIndependentPair = false;
              for (int i = 0; i < valid.length; i++) {
                for (int j = i + 1; j < valid.length; j++) {
                  if ((valid[i].x - valid[j].x).abs() > 1 || (valid[i].y - valid[j].y).abs() > 1) {
                    hasIndependentPair = true;
                    break;
                  }
                }
                if (hasIndependentPair) break;
              }
              if (!hasIndependentPair) blocksUnit = true;
            }

            if (blocksUnit) {
              _history.add(_QueensHistoryItem(changes: {math.Point(r, c): CellContent.empty}));
              setState(() {
                _grid[r][c].content = CellContent.cross;
                _moveCount++;
                _checkState();
              });
              _highlightCells({math.Point(r, c)});
              _showHintBanner(
                '(${r + 1}. Satır, ${c + 1}. Sütun) karesine vezir yerleştirilirse, komşu renk bölgesinde gereken $needed vezir için yeterli boş kare kalmaz (kural ihlali oluşur). Dolayısıyla bu kareye vezir gelemez (✖ konuldu).',
                title: '🔍 Mantıksal Çelişki Tespiti',
              );
              return;
            }
          }
        }
      }
    }

    // ADIM 8: Mantıksal Çözüm İlerlemesi (Stratejik Vezir Yerleştirme)
    for (final pt in _level.solution) {
      final r = pt[0];
      final c = pt[1];
      if (_grid[r][c].content != CellContent.queen) {
        final prev = _grid[r][c].content;
        _history.add(_QueensHistoryItem(changes: {math.Point(r, c): prev}));
        _triggerBoardRipple(r, c);
        setState(() {
          _grid[r][c].content = CellContent.queen;
          _moveCount++;
          _checkState();
        });
        _highlightCells({math.Point(r, c)});
        final hintText = reqQueens == 2
            ? 'Master seviyenin çift vezir kuralı gereğince, (${r + 1}. Satır, ${c + 1}. Sütun) karesi bu bölgenin kesin vezir konumlarından biridir. Buraya vezir yerleştirildi!'
            : 'Tahtanın kısıtlamaları ve renk dengesi incelendiğinde, (${r + 1}. Satır, ${c + 1}. Sütun) karesi bu bölgenin kesin vezir konumudur. Buraya vezir yerleştirildi!';
        _showHintBanner(
          hintText,
          title: reqQueens == 2 ? '👑 Çift Vezir Stratejisi' : '💡 Stratejik Vezir Konumu',
        );
        return;
      }
    }
  }

  void _handleWin() async {
    final durationSeconds = (_elapsedMs / 1000).ceil();
    final baseScore = _level.gridSize * 150;
    final timePenalty = (durationSeconds * 2).clamp(0, baseScore ~/ 2);
    // Normal oyun hamleleri (vezir yerleştirme ve temel çarpı koyma) cezalandırılmaz;
    // yalnızca beklenen hamle sayısını aşan gereksiz tıklama/hatalar cezalandırılır.
    final expectedMoves = _level.totalQueens * 3;
    final excessMoves = math.max(0, _moveCount - expectedMoves);
    final movePenalty = (excessMoves * 2).clamp(0, baseScore ~/ 4);
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
      difficulty: _currentDifficulty.name,
    );

    ref.read(leaderboardServiceProvider).submitScore(result);
    final statsResult = await ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.queens,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _moveCount,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.queens,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
          subKey: _currentDifficulty.name,
        );

    ref.read(badgeServiceProvider.notifier).evaluateBadges(
          gameType: GameType.queens,
          score: score,
          durationMs: _elapsedMs,
          overallIQ: statsResult.currentIQ,
          statsMap: ref.read(gameStatsServiceProvider),
          dailyPlayState: ref.read(dailyPlayServiceProvider),
          difficulty: _currentDifficulty.name,
        );

    GameSessionService.clearSession(
      game: GameType.queens,
      levelId: widget.levelId,
      subKey: _currentDifficulty.name,
    );

    if (!mounted) return;
    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Vezirler',
      statsResult: statsResult,
      onRestart: () {
        Navigator.pop(context);
        Navigator.pop(context); // Lobiye dön (günlük oyun tek oynanır)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = _getHintCooldown();
    final isHintReady = cooldown == 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Sabit Oyun Düzeni (Tahta Asla Yukarı/Aşağı Kaymaz!)
              Column(
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
                            'Kalan Vezir: $_remainingQueenCount',
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(_level.totalQueens, (idx) {
                                    final isPlaced = idx < _placedQueenCount;
                                    final cardSize = _level.totalQueens > 9 ? 15.0 : 20.0;
                                    final iconSize = _level.totalQueens > 9 ? 9.0 : 12.0;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _level.totalQueens > 9 ? 1.0 : 2.0,
                                      ),
                                      child: SketchCard(
                                        padding: EdgeInsets.zero,
                                        borderRadius: _level.totalQueens > 9 ? 4 : 6,
                                        borderWidth: isPlaced ? 1.6 : 1.0,
                                        shadowOffset: isPlaced ? const Offset(1.0, 1.0) : const Offset(0.6, 0.6),
                                        backgroundColor: isPlaced ? AppColors.sunYellow : AppColors.surfaceSecondaryLight,
                                        child: SizedBox(
                                          width: cardSize,
                                          height: cardSize,
                                          child: Center(
                                            child: Icon(
                                              Icons.castle_rounded,
                                              size: iconSize,
                                              color: isPlaced ? AppColors.pencilBlack : AppColors.pencilLight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = math.min(constraints.maxWidth, constraints.maxHeight);

                          return Center(
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: Listener(
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
                                        // 2. Tablo Kutuları
                                        Positioned.fill(
                                          child: GridView.builder(
                                            padding: EdgeInsets.zero,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: _level.gridSize,
                                            ),
                                            itemCount: _level.gridSize * _level.gridSize,
                                            itemBuilder: (context, index) {
                                              final r = index ~/ _level.gridSize;
                                              final c = index % _level.gridSize;
                                              final cell = _grid[r][c];

                                              return Center(
                                                child: _buildCellContent(cell),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

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
                            activeColor: AppColors.sunYellow,
                            onTap: !_isSolved ? _useHint : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. YÜZEN İPUCU & UYARI KARTI (Tahtanın Boyutunu ve Yerini Kesinlikle Değiştirmez!)
              if (_activeHintMessage != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 74,
                  child: _buildHintInfoCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintInfoCard() {
    if (_activeHintMessage == null) return const SizedBox.shrink();

    final isWarning = _activeHintIsWarning;

    return SketchCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      borderWidth: 2.2,
      shadowOffset: const Offset(3.5, 3.5),
      backgroundColor: isWarning ? AppColors.errorBgLight : AppColors.surfaceLight,
      borderColor: isWarning ? AppColors.error : AppColors.pencilBlack,
      enableHatching: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organik İkon Kutusu
          SketchCard(
            padding: const EdgeInsets.all(6),
            borderRadius: 8,
            borderWidth: 1.6,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: isWarning
                ? AppColors.highlighterPink.withValues(alpha: 0.4)
                : AppColors.sunYellow,
            borderColor: isWarning ? AppColors.error : AppColors.pencilBlack,
            child: Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_rounded,
              size: 20,
              color: isWarning ? AppColors.error : AppColors.pencilBlack,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_activeHintTitle != null)
                  Text(
                    _activeHintTitle!,
                    style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isWarning ? AppColors.error : AppColors.pencilBlack,
                    ),
                  ),
                Text(
                  _activeHintMessage!,
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    color: AppColors.pencilBlack,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Organik Kapatma Butonu
          SketchCard(
            padding: const EdgeInsets.all(4),
            borderRadius: 8,
            borderWidth: 1.4,
            shadowOffset: const Offset(1.5, 1.5),
            backgroundColor: AppColors.surfaceSecondaryLight,
            onTap: () {
              setState(() {
                _activeHintMessage = null;
                _clearHighlights();
              });
            },
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.pencilBlack),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.15, end: 0, duration: 180.ms, curve: Curves.easeOutBack).fadeIn(duration: 120.ms);
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
/// Çatışma / Hata anında: Kırmızı Çatlamış Taç (Cracked Crown)
class _OrganicDrawnCrownPainter extends CustomPainter {
  final bool isConflict;

  _OrganicDrawnCrownPainter({required this.isConflict});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = isConflict ? AppColors.error : AppColors.sunYellow
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

    // KURAL İHLALİ / HATA: KIRMIZI ÇATLAYAN TAÇ ÇİZGİLERİ (CRACKED CROWN)
    if (isConflict) {
      final crackPaint = Paint()
        ..color = AppColors.pencilBlack
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // 1. Ana Zikzak Çatlak Hattı (Tepe noktasından aşağıya doğru inen derin yarık)
      final mainCrack = Path();
      mainCrack.moveTo(w * 0.50, h * 0.18);
      mainCrack.lineTo(w * 0.44, h * 0.34);
      mainCrack.lineTo(w * 0.55, h * 0.48);
      mainCrack.lineTo(w * 0.41, h * 0.64);
      mainCrack.lineTo(w * 0.52, h * 0.74);
      mainCrack.lineTo(w * 0.48, h * 0.83);
      canvas.drawPath(mainCrack, crackPaint);

      // 2. Yan Çatlak Dalları
      final branch1 = Path();
      branch1.moveTo(w * 0.44, h * 0.34);
      branch1.lineTo(w * 0.28, h * 0.42);
      canvas.drawPath(branch1, crackPaint..strokeWidth = 1.8);

      final branch2 = Path();
      branch2.moveTo(w * 0.55, h * 0.48);
      branch2.lineTo(w * 0.72, h * 0.58);
      canvas.drawPath(branch2, crackPaint..strokeWidth = 1.8);

      // 3. Çatlamış Bilye
      canvas.drawLine(
        Offset(w * 0.46, h * 0.14),
        Offset(w * 0.54, h * 0.22),
        crackPaint..strokeWidth = 2.0,
      );

      // 4. Kırık / Kıymık Eskiz Çizgileri (Havada uçuşan minik taç parçacıkları)
      final splinterPaint = Paint()
        ..color = AppColors.pencilBlack
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.36, h * 0.22), Offset(w * 0.32, h * 0.26), splinterPaint);
      canvas.drawLine(Offset(w * 0.62, h * 0.20), Offset(w * 0.66, h * 0.24), splinterPaint);
      canvas.drawLine(Offset(w * 0.58, h * 0.68), Offset(w * 0.64, h * 0.71), splinterPaint);
    }
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
    this.activeColor = AppColors.sunYellow,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled ? AppColors.pencilBlack : AppColors.pencilLight;

    if (isActive) {
      return SketchCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderRadius: 8,
        borderWidth: 1.8,
        shadowOffset: const Offset(1.5, 1.5),
        backgroundColor: activeColor,
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
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
