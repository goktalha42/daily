import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import '../common/neo_game_layout.dart';
import '../../core/theme/widgets/app_card.dart';
import 'pinpoint_models.dart';
import 'pinpoint_levels.dart';

class PinpointScreen extends ConsumerStatefulWidget {
  final String levelId;

  const PinpointScreen({super.key, required this.levelId});

  @override
  ConsumerState<PinpointScreen> createState() => _PinpointScreenState();
}

class _PinpointScreenState extends ConsumerState<PinpointScreen> {
  late PinpointLevel _level;
  int _revealedClues = 1;
  final List<String> _wrongGuesses = [];
  final TextEditingController _guessController = TextEditingController();
  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _level = PinpointLevelRepository.getLevelForDate(widget.levelId);
    _revealedClues = 1;
    _wrongGuesses.clear();
    _guessController.clear();
    _elapsedMs = 0;
    _isSolved = false;
    _errorMessage = null;
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
    _guessController.dispose();
    super.dispose();
  }

  void _submitGuess() {
    final input = _guessController.text.trim().toUpperCase();
    if (input.isEmpty) return;

    if (input == _level.targetWord) {
      setState(() {
        _isSolved = true;
        _errorMessage = null;
      });
      _timer?.cancel();
      _handleWin();
    } else {
      setState(() {
        if (!_wrongGuesses.contains(input)) {
          _wrongGuesses.add(input);
        }
        _guessController.clear();
        _errorMessage = 'Yanlış tahmin! İncelemeye devam edin.';

        // Auto-reveal next clue on wrong guess if available
        if (_revealedClues < _level.clues.length) {
          _revealedClues++;
        }
      });
    }
  }

  void _revealNextClue() {
    if (_revealedClues < _level.clues.length) {
      setState(() {
        _revealedClues++;
      });
    }
  }

  void _handleWin() {
    // Score formula: Higher score for fewer revealed clues
    final clueBonus = (6 - _revealedClues) * 300;
    final score = (1000 + clueBonus - (_elapsedMs ~/ 1000) * 5).clamp(100, 2500);

    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.pinpoint,
      levelId: widget.levelId,
      userId: 'user_local',
      userName: 'Oyuncu',
      durationMs: _elapsedMs,
      moveCount: _wrongGuesses.length + 1,
      score: score,
      completedAt: DateTime.now(),
    );

    ref.read(leaderboardServiceProvider).submitScore(result);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.pinpointGame, size: 64)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            const Text(
              'Harika İsabete Ulaştınız!',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Gizli Kelime: ${_level.targetWord}',
              style: const TextStyle(fontSize: 16, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WinRow(label: 'Kullanılan İpucu:', value: '$_revealedClues / ${_level.clues.length}'),
              const Divider(color: AppColors.border),
              _WinRow(label: 'Geçen Süre:', value: GameDateUtils.formatGameTime(_elapsedMs)),
              const Divider(color: AppColors.border),
              _WinRow(
                label: 'Toplam Puan:',
                value: '$score P',
                valueColor: AppColors.success,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfa'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinpointGame,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initGame();
              });
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeoGameLayout(
      gameType: GameType.pinpoint,
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
                const Icon(Icons.timer_rounded, size: 18, color: AppColors.accentCyan),
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
                color: AppColors.accentCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'İPUCU: $_revealedClues / ${_level.clues.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentCyan,
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
            // Clues Box
            AppCard(
              withGlassEffect: true,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          _level.categoryHint,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_level.clues.length, (index) {
                      final isRevealed = index < _revealedClues;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isRevealed
                              ? AppColors.accentCyan.withOpacity(0.15)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRevealed ? AppColors.accentCyan.withOpacity(0.5) : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isRevealed
                                  ? AppColors.accentCyan
                                  : AppColors.surfaceSecondaryLight,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRevealed ? Colors.black : AppColors.textSecondaryLight),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isRevealed ? _level.clues[index] : '🔒 Kilitli İpucu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRevealed ? FontWeight.bold : FontWeight.normal,
                                color: isRevealed
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textSecondaryLight.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_revealedClues < _level.clues.length)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _revealNextClue,
                          style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Sonraki İpucu', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
            ),
            const SizedBox(height: 24),

            // Target word guess input
            TextField(
              controller: _guessController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'Gizli Kelimeyi Tahmin Et',
                hintStyle: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1,
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
                  borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.pinpointGame),
                  onPressed: _submitGuess,
                ),
              ),
              onSubmitted: (_) => _submitGuess(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],

            if (_wrongGuesses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Yanlış Denemeler:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _wrongGuesses
                    .map((g) => Chip(
                          backgroundColor: AppColors.error.withValues(alpha: 0.15),
                          label: Text(
                            g,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _WinRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
