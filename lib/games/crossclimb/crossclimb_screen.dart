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
import '../../core/services/badge_service.dart';
import '../../core/services/daily_play_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/widgets/screen_shake.dart';
import '../../core/services/game_session_service.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'crossclimb_models.dart';
import 'crossclimb_logic.dart';
import 'crossclimb_levels.dart';

class CrossclimbScreen extends ConsumerStatefulWidget {
  final String levelId;

  const CrossclimbScreen({super.key, required this.levelId});

  @override
  ConsumerState<CrossclimbScreen> createState() => _CrossclimbScreenState();
}

class _CrossclimbScreenState extends ConsumerState<CrossclimbScreen> with WidgetsBindingObserver {
  late CrossclimbLevel _level;
  int _currentStepIndex = 0;
  late List<String> _userWords;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _currentInputChar = '';

  int _wrongAttempts = 0;
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _level = CrossclimbLevelRepository.getLevelForDate(widget.levelId);
    _userWords = List.filled(_level.steps.length, '');
    _inputController.addListener(() {
      final text = _inputController.text.trim();
      setState(() {
        if (text.isNotEmpty) {
          _currentInputChar = CrossclimbLogic.normalize(text.substring(text.length - 1));
        } else {
          _currentInputChar = '';
        }
        if (_errorMsg != null) {
          _errorMsg = null;
        }
      });
    });
    _loadSession().then((_) {
      if (mounted) _startTimer();
    });
  }

  Future<void> _loadSession() async {
    final session = await GameSessionService.loadSession(
      game: GameType.crossclimb,
      levelId: widget.levelId,
    );
    if (session != null && mounted) {
      final elapsed = session['elapsedMs'] as int? ?? 0;
      final data = session['data'] as Map<String, dynamic>?;
      if (data != null) {
        final stepIdx = data['currentStepIndex'] as int?;
        if (stepIdx != null && stepIdx >= 0) {
          _currentStepIndex = stepIdx.clamp(0, _level.steps.length - 1);
        }
        final words = data['userWords'] as List<dynamic>?;
        if (words != null && words.length == _level.steps.length) {
          _userWords = words.map((e) => e.toString()).toList();
        }
        final wrongs = data['wrongAttempts'] as int?;
        if (wrongs != null && wrongs >= 0) {
          _wrongAttempts = wrongs;
        }
      }
      setState(() {
        _elapsedMs = elapsed;
      });
    }
  }

  void _saveSession() {
    if (_isSolved) return;
    GameSessionService.saveSession(
      game: GameType.crossclimb,
      levelId: widget.levelId,
      elapsedMs: _elapsedMs,
      data: {
        'currentStepIndex': _currentStepIndex,
        'userWords': _userWords,
        'wrongAttempts': _wrongAttempts,
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveSession();
    }
  }

  void _initGame() {
    _level = CrossclimbLevelRepository.getLevelForDate(widget.levelId);
    _currentStepIndex = 0;
    _userWords = List.filled(_level.steps.length, '');
    _inputController.clear();
    _currentInputChar = '';
    _wrongAttempts = 0;
    _elapsedMs = 0;
    _isSolved = false;
    _errorMsg = null;
    GameSessionService.clearSession(game: GameType.crossclimb, levelId: widget.levelId);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    int ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isSolved && mounted) {
        setState(() {
          _elapsedMs += 100;
        });
        ticks++;
        if (ticks % 10 == 0) {
          GameSessionService.updateElapsedMs(
            game: GameType.crossclimb,
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
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _requestKeyboardFocus() {
    if (_isSolved || !mounted) return;
    _focusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isSolved) {
        _focusNode.requestFocus();
      }
    });
  }

  void _submitStepLetter() {
    if (_isSolved) return;
    if (_currentInputChar.isEmpty) return;

    final step = _level.steps[_currentStepIndex];
    final prevWord = _getPreviousWord();

    final buffer = StringBuffer();
    for (int i = 0; i < prevWord.length; i++) {
      if (i == step.changedIndex) {
        buffer.write(_currentInputChar);
      } else {
        buffer.write(prevWord[i]);
      }
    }
    final fullCandidateWord = buffer.toString();

    if (CrossclimbLogic.isStepValid(fullCandidateWord, step.targetWord)) {
      HapticFeedback.mediumImpact();
      setState(() {
        _userWords[_currentStepIndex] = step.targetWord;
        _inputController.clear();
        _currentInputChar = '';
        _errorMsg = null;

        if (_currentStepIndex < _level.steps.length - 1) {
          _currentStepIndex++;
          _requestKeyboardFocus();
        } else {
          _isSolved = true;
          _focusNode.unfocus();
          _timer?.cancel();
          _handleWin();
        }
      });
      _saveSession();
    } else {
      HapticFeedback.vibrate();
      ScreenShake.shake(context, intensity: 6.0);
      setState(() {
        _wrongAttempts++;
        _errorMsg = 'Yanlış harf! "${step.clue}" ipucuna uygun harfi bulmalısın.';
      });
      _saveSession();
    }
  }

  String _getPreviousWord() {
    if (_currentStepIndex == 0) {
      return _level.startWord;
    }
    final prev = _userWords[_currentStepIndex - 1];
    return prev.isNotEmpty ? prev : _level.startWord;
  }

  void _handleWin() async {
    final score = CrossclimbLogic.calculateScore(
      durationMs: _elapsedMs,
      stepCount: _level.steps.length,
      wrongAttempts: _wrongAttempts,
    );

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.crossclimb,
      levelId: widget.levelId,
      userId: 'user_local',
      userName: 'Oyuncu',
      durationMs: _elapsedMs,
      moveCount: _level.steps.length,
      score: score,
      completedAt: DateTime.now(),
    );

    ref.read(leaderboardServiceProvider).submitScore(result);
    final statsResult = await ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.crossclimb,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _level.steps.length,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.crossclimb,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
        );
    ref.read(badgeServiceProvider.notifier).evaluateBadges(
          gameType: GameType.crossclimb,
          score: score,
          durationMs: _elapsedMs,
          overallIQ: statsResult.currentIQ,
          statsMap: ref.read(gameStatsServiceProvider),
          dailyPlayState: ref.read(dailyPlayServiceProvider),
        );

    GameSessionService.clearSession(
      game: GameType.crossclimb,
      levelId: widget.levelId,
    );

    if (!mounted) return;
    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Kelime Tırmanışı',
      statsResult: statsResult,
      onRestart: () {
        Navigator.pop(context);
        setState(() {
          _initGame();
        });
      },
    );
  }

  void _showHelpDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white : AppColors.pencilBlack, width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.stairs_rounded, color: AppColors.sunYellow, size: 28),
            const SizedBox(width: 8),
            Text(
              'Kelime Tırmanışı: Nasıl Oynanır?',
              style: GoogleFonts.patrickHand(
                color: isDark ? Colors.white : AppColors.pencilBlack,
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
              'Aşağıdan Yukarı Tırman',
              'Oyun en alttaki başlangıç kelimesinden başlar ve yukarıya zirveye doğru tırmanır.',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Sadece 1 Harf Değişir',
              'Her basamakta önceki kelimeden tam olarak 1 harf değişerek yeni kelime oluşur.',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Eksik Harfe Dokun ve Yaz',
              'Ayrı bir kutu yok! Doğrudan basamaktaki sarı eksik harf kutusuna dokunup doğru harfi yaz.',
              isDark,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunYellow,
              foregroundColor: AppColors.inkBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.inkBlack, width: 2.0),
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

  Widget _buildRuleCard(String number, String title, String desc, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSecondaryDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white38 : AppColors.pencilBlack, width: 1.8),
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
              border: Border.all(color: isDark ? Colors.white : AppColors.pencilBlack, width: 1.5),
            ),
            child: Text(
              number,
              style: GoogleFonts.patrickHand(
                fontWeight: FontWeight.w700,
                color: AppColors.inkBlack,
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
                    color: isDark ? Colors.white : AppColors.pencilBlack,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    color: isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppColors.pencilBlack),
                    ),

                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      borderRadius: 12,
                      shadowOffset: const Offset(2.5, 2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stairs_rounded, size: 18, color: isDark ? Colors.white : AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kelime Tırmanışı',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.pencilBlack,
                                  height: 1.1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.skyBlue.withValues(alpha: isDark ? 0.25 : 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isDark ? Colors.white38 : AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '🧗 Aşağıdan Yukarı Zirveye',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.pencilBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Kronometre (Sabit genişlik - Titremez)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SketchCard(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          borderRadius: 10,
                          shadowOffset: const Offset(2, 2),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 15, color: isDark ? Colors.white : AppColors.pencilBlack),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text(
                                    GameDateUtils.formatGameTime(_elapsedMs),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.pencilBlack,
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
                          child: const Icon(Icons.question_mark_rounded, size: 16, color: AppColors.inkBlack),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. BASAMAK İLERLEME ÇUBUĞU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SketchCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSolved ? Icons.emoji_events_rounded : Icons.hiking_rounded,
                            size: 20,
                            color: _isSolved ? AppColors.sunYellow : (isDark ? Colors.white : AppColors.pencilBlack),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSolved
                                ? 'Zirveye Ulaşıldı! 🏆'
                                : 'Basamak: ${_currentStepIndex + 1} / ${_level.steps.length}',
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(_level.steps.length, (idx) {
                          final isCompleted = _userWords[idx].isNotEmpty;
                          final isCurrent = idx == _currentStepIndex && !_isSolved;

                          Color bgColor;
                          if (isCompleted) {
                            bgColor = const Color(0xFF34D399);
                          } else if (isCurrent) {
                            bgColor = AppColors.sunYellow;
                          } else {
                            bgColor = isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? (isCompleted || isCurrent ? Colors.white : Colors.white24) : AppColors.pencilBlack,
                                width: isCompleted || isCurrent ? 2.0 : 1.2,
                              ),
                              boxShadow: isCompleted || isCurrent
                                  ? [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.pencilBlack,
                                        offset: const Offset(1, 1),
                                        blurRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted || isCurrent ? AppColors.inkBlack : (isDark ? AppColors.pencilLightDark : AppColors.pencilLight),
                                ),
                              ),
                            ),
                          ).animate(target: isCompleted ? 1 : 0).scale(duration: 180.ms);
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. KELİME MERDİVENİ (AŞAĞIDAN YUKARIYA DOĞRU SIRALANMIŞ!)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // MERDİVEN KARTI (Tüm Basamaklar - En altta Başlangıç, En üstte Zirve!)
                      SketchCard(
                        borderRadius: 14,
                        shadowOffset: const Offset(3.5, 3.5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          children: [
                            // 1. En Üst Basamaktan Başlayarak Geriye Doğru Sıralama (Zirve En Üstte!)
                            for (int i = _level.steps.length - 1; i >= 0; i--) ...[
                              _buildStepTile(i, isDark),
                              _buildLadderConnector(isDark),
                            ],

                            // En Altta: 🚩 BAŞLANGIÇ KELİMESİ KARTI
                            _buildWordTile(
                              word: _level.startWord,
                              label: '🚩 BAŞLANGIÇ',
                              isCompleted: true,
                              isCurrent: false,
                              highlightIndex: -1,
                              isStartWord: true,
                              stepIndex: -1,
                              isDark: isDark,
                            ),
                          ],
                        ),
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

  Widget _buildStepTile(int stepIdx, bool isDark) {
    final isCompleted = _userWords[stepIdx].isNotEmpty;
    final isCurrent = stepIdx == _currentStepIndex && !_isSolved;
    final step = _level.steps[stepIdx];

    if (isCurrent) {
      return _buildActiveLadderTile(stepIdx, isDark);
    }

    return _buildWordTile(
      word: isCompleted ? _userWords[stepIdx] : step.targetWord,
      label: 'Basamak ${stepIdx + 1}',
      isCompleted: isCompleted,
      isCurrent: false,
      highlightIndex: -1,
      isStartWord: false,
      stepIndex: stepIdx,
      isDark: isDark,
    );
  }

  Widget _buildActiveLadderTile(int stepIdx, bool isDark) {
    final step = _level.steps[stepIdx];
    final prevWord = _getPreviousWord();

    return SketchCard(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: 14,
      borderWidth: 2.4,
      shadowOffset: const Offset(3.5, 3.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Başlık & Değişen Harf Rozeti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hiking_rounded, size: 20, color: AppColors.sunYellow),
                  const SizedBox(width: 6),
                  Text(
                    'BASAMAK ${stepIdx + 1} (AKTİF)',
                    style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.pencilBlack,
                    ),
                  ),
                ],
              ),
              SketchCard(
                backgroundColor: AppColors.sunYellow,
                borderRadius: 8,
                borderWidth: 1.5,
                shadowOffset: const Offset(1.2, 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  '📌 ${step.changedIndex + 1}. HARF DEĞİŞİYOR',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Doğrudan Basamak İçindeki Soru / İpucu Alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceSecondaryDark : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white38 : AppColors.pencilBlack, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.sunYellow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.clue,
                    style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.pencilBlack,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Basamak Üzerindeki Harf Kutuları ve İnteraktif Giriş
          GestureDetector(
            onTap: _requestKeyboardFocus,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(prevWord.length, (idx) {
                final isChanging = idx == step.changedIndex;

                if (isChanging) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 38,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _currentInputChar.isNotEmpty ? AppColors.sunYellow : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white : AppColors.pencilBlack,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.pencilBlack,
                          offset: const Offset(2.0, 2.0),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.patrickHand(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBlack,
                        ),
                        cursorColor: AppColors.inkBlack,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: '?',
                          hintStyle: GoogleFonts.patrickHand(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        onSubmitted: (_) => _submitStepLetter(),
                        onTap: _requestKeyboardFocus,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 34,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSecondaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white38 : AppColors.pencilBlack,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.pencilBlack,
                        offset: const Offset(1.0, 1.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      prevWord[idx],
                      style: GoogleFonts.patrickHand(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.pencilBlack,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Doğrudan Basamak İçindeki Tırman / Onayla Butonu
          Row(
            children: [
              if (_currentInputChar.isNotEmpty) ...[
                SketchCard(
                  backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                  borderRadius: 10,
                  borderWidth: 1.8,
                  shadowOffset: const Offset(1.5, 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onTap: () {
                    _inputController.clear();
                    _requestKeyboardFocus();
                  },
                  child: Icon(Icons.backspace_outlined, size: 18, color: isDark ? Colors.white : AppColors.pencilBlack),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SketchCard(
                  backgroundColor: _currentInputChar.isNotEmpty
                      ? AppColors.sunYellow
                      : (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight),
                  borderRadius: 10,
                  shadowOffset: _currentInputChar.isNotEmpty ? const Offset(2.0, 2.0) : Offset.zero,
                  borderWidth: 1.8,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onTap: _currentInputChar.isNotEmpty
                      ? _submitStepLetter
                      : _requestKeyboardFocus,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentInputChar.isNotEmpty ? Icons.arrow_upward_rounded : Icons.keyboard_rounded,
                        size: 18,
                        color: _currentInputChar.isNotEmpty ? AppColors.inkBlack : (isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentInputChar.isNotEmpty
                            ? 'Basamağa Tırman ("$_currentInputChar")'
                            : 'Harf Yazmak İçin Dokun',
                        style: GoogleFonts.patrickHand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _currentInputChar.isNotEmpty ? AppColors.inkBlack : (isDark ? AppColors.pencilLightDark : AppColors.pencilGraphite),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 5. Hata Mesajı
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            SketchCard(
              backgroundColor: isDark ? AppColors.errorBgDark : AppColors.errorBgLight,
              borderRadius: 8,
              shadowOffset: const Offset(1.5, 1.5),
              borderWidth: 1.6,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLadderConnector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 10,
            color: isDark ? Colors.white38 : AppColors.pencilBlack,
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_upward_rounded, size: 16, color: isDark ? Colors.white70 : AppColors.pencilBlack),
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 10,
            color: isDark ? Colors.white38 : AppColors.pencilBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildWordTile({
    required String word,
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required int highlightIndex,
    required bool isStartWord,
    required int stepIndex,
    required bool isDark,
  }) {
    Color cardBg;
    if (isStartWord) {
      cardBg = isDark ? AppColors.surfaceSecondaryDark : const Color(0xFFFBF8F0);
    } else if (isCompleted) {
      cardBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5);
    } else if (isCurrent) {
      cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    } else {
      cardBg = isDark ? AppColors.surfaceSecondaryDark.withValues(alpha: 0.3) : AppColors.surfaceSecondaryLight.withValues(alpha: 0.40);
    }

    final prevWord = isCurrent ? _getPreviousWord() : '';

    return GestureDetector(
      onTap: () {
        if (isCurrent && !_isSolved) {
          _requestKeyboardFocus();
        }
      },
      child: SketchCard(
        backgroundColor: cardBg,
        borderRadius: 12,
        shadowOffset: isCurrent || isCompleted || isStartWord
            ? const Offset(2.5, 2.5)
            : const Offset(1, 1),
        borderWidth: isCurrent ? 2.4 : 1.6,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isCompleted && !isStartWord) ...[
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                ] else if (isCurrent) ...[
                  Icon(Icons.play_arrow_rounded, size: 18, color: isDark ? Colors.white : AppColors.pencilBlack),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCurrent || isCompleted || isStartWord ? (isDark ? Colors.white : AppColors.pencilBlack) : (isDark ? AppColors.pencilLightDark : AppColors.pencilLight),
                  ),
                ),
              ],
            ),
            Row(
              children: List.generate(word.length, (i) {
                final isChangedSlot = i == highlightIndex;

                String char;
                if (isStartWord || isCompleted) {
                  char = word[i];
                } else if (isCurrent) {
                  if (isChangedSlot) {
                    char = _currentInputChar.isNotEmpty ? _currentInputChar : '?';
                  } else {
                    char = prevWord[i];
                  }
                } else {
                  char = '?';
                }

                Color boxBg;
                if (isChangedSlot && isCurrent) {
                  boxBg = AppColors.sunYellow;
                } else if (isCompleted || isStartWord) {
                  boxBg = isDark ? AppColors.surfaceDark : Colors.white;
                } else {
                  boxBg = isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight;
                }

                // Tamamen El Çizimi SketchCard Harf Kutuları!
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: GestureDetector(
                    onTap: () {
                      if (isCurrent && isChangedSlot && !_isSolved) {
                        _requestKeyboardFocus();
                      }
                    },
                    child: SketchCard(
                      backgroundColor: boxBg,
                      borderRadius: 8,
                      borderWidth: isChangedSlot ? 2.2 : 1.4,
                      shadowOffset: isChangedSlot ? const Offset(1.8, 1.8) : const Offset(1.0, 1.0),
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: 34,
                        height: 38,
                        child: Center(
                          child: Text(
                            char,
                            style: GoogleFonts.patrickHand(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isChangedSlot && isCurrent
                                  ? AppColors.inkBlack
                                  : (isCompleted || isStartWord ? (isDark ? Colors.white : AppColors.pencilBlack) : (isDark ? AppColors.pencilLightDark : AppColors.pencilLight)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
