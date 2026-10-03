import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import '../common/neo_game_layout.dart';
import '../../core/theme/widgets/app_card.dart';
import 'crossclimb_models.dart';
import 'crossclimb_levels.dart';

class CrossclimbScreen extends ConsumerStatefulWidget {
  final String levelId;

  const CrossclimbScreen({super.key, required this.levelId});

  @override
  ConsumerState<CrossclimbScreen> createState() => _CrossclimbScreenState();
}

class _CrossclimbScreenState extends ConsumerState<CrossclimbScreen> {
  late CrossclimbLevel _level;
  int _currentStepIndex = 0;
  late List<String> _userWords;
  final TextEditingController _inputController = TextEditingController();
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = CrossclimbLevelRepository.getLevelForDate(widget.levelId);
    _currentStepIndex = 0;
    _userWords = List.filled(_level.steps.length, '');
    _inputController.clear();
    _elapsedMs = 0;
    _isSolved = false;
    _errorMsg = null;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isSolved) {
        setState(() {
          _elapsedMs += 100;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _submitStepWord() {
    final input = _inputController.text.trim().toUpperCase();
    if (input.isEmpty) return;

    final target = _level.steps[_currentStepIndex].targetWord;

    if (input == target) {
      setState(() {
        _userWords[_currentStepIndex] = target;
        _inputController.clear();
        _errorMsg = null;

        if (_currentStepIndex < _level.steps.length - 1) {
          _currentStepIndex++;
        } else {
          _isSolved = true;
          _timer?.cancel();
          _handleWin();
        }
      });
    } else {
      setState(() {
        _errorMsg = 'Yanlış kelime! İpucuna dikkat edin.';
      });
    }
  }

  void _handleWin() {
    final score = (1800 - (_elapsedMs ~/ 1000) * 8).clamp(100, 2000);

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
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.crossclimb,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _level.steps.length,
        );

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Kelime Tırmanışı',
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
    final currentStep = _level.steps[_currentStepIndex];
    // Determine the previous word for comparison
    final previousWord = _currentStepIndex == 0
        ? _level.startWord
        : _level.steps[_currentStepIndex - 1].targetWord;

    return NeoGameLayout(
      gameType: GameType.crossclimb,
      levelId: widget.levelId,
      onRestart: () => setState(() => _initGame()),
      statsBar: AppCard(
        withGlassEffect: true,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_rounded, size: 18, color: AppColors.accentPurple),
                const SizedBox(width: 8),
                Text(
                  GameDateUtils.formatGameTime(_elapsedMs),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ADIM: ${_currentStepIndex + 1} / ${_level.steps.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentPurple,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game rules hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentPurple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Her adımda yalnızca 1 harf değiştirerek yeni kelimeye ulaş!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ladder Display
            AppCard(
              withGlassEffect: true,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                    // Start word
                    _LadderWordTile(
                      word: _level.startWord,
                      isCompleted: true,
                      isCurrent: false,
                      label: 'BAŞLANGIÇ',
                      highlightIndex: -1,
                    ),
                    const SizedBox(height: 12),

                    // Intermediate steps
                    ...List.generate(_level.steps.length, (idx) {
                      final isComp = _userWords[idx].isNotEmpty;
                      final isCurr = idx == _currentStepIndex && !_isSolved;

                      return Column(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          _LadderWordTile(
                            word: isComp
                                ? _userWords[idx]
                                : (isCurr
                                    ? _buildHintWord(previousWord, _level.steps[idx].changedIndex)
                                    : '?' * _level.steps[idx].targetWord.length),
                            isCompleted: isComp,
                            isCurrent: isCurr,
                            label: 'Adım ${idx + 1}',
                            highlightIndex: isCurr ? _level.steps[idx].changedIndex : -1,
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
            ),
            const SizedBox(height: 24),

            // Clue Card
            if (!_isSolved) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentPurple.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'İPUCU',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: AppColors.textPrimaryLight),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${currentStep.changedIndex + 1}. HARF',
                            style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentStep.clue,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input field
              TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.characters,
                maxLength: currentStep.targetWord.length,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'KELİMEYİ GİR',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: AppColors.textSecondaryLight.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.accentPurple),
                    onPressed: _submitStepWord,
                  ),
                ),
                onSubmitted: (_) => _submitStepWord(),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMsg!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Build hint word: show unchanged letters from previous word, '?' for the changed position
  String _buildHintWord(String previousWord, int changedIndex) {
    final buffer = StringBuffer();
    for (int i = 0; i < previousWord.length; i++) {
      buffer.write(i == changedIndex ? '?' : previousWord[i]);
    }
    return buffer.toString();
  }
}

class _LadderWordTile extends StatelessWidget {
  final String word;
  final bool isCompleted;
  final bool isCurrent;
  final String label;
  final int highlightIndex;

  const _LadderWordTile({
    required this.word,
    required this.isCompleted,
    required this.isCurrent,
    required this.label,
    this.highlightIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.accentPurple.withOpacity(0.2)
            : (isCurrent ? AppColors.surfaceLight : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.accentPurple
              : (isCurrent ? AppColors.accentPurple.withOpacity(0.5) : AppColors.borderLight),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isCompleted ? AppColors.crossclimbGame : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: List.generate(word.length, (i) {
              final char = word[i];
              final isHighlighted = i == highlightIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.warning.withOpacity(0.3)
                      : (isCompleted ? Colors.transparent : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighlighted ? AppColors.warning : (isCompleted ? Colors.transparent : AppColors.borderLight),
                    width: isHighlighted ? 2 : 1,
                  ),
                ),
                child: Text(
                  char,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

