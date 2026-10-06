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
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/widgets/screen_shake.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
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
  final FocusNode _focusNode = FocusNode();
  String _currentInputText = '';

  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initGame();
    _inputController.addListener(() {
      setState(() {
        _currentInputText = _inputController.text.trim().toUpperCase();
        if (_errorMsg != null) {
          _errorMsg = null;
        }
      });
    });
  }

  void _initGame() {
    _level = CrossclimbLevelRepository.getLevelForDate(widget.levelId);
    _currentStepIndex = 0;
    _userWords = List.filled(_level.steps.length, '');
    _inputController.clear();
    _currentInputText = '';
    _elapsedMs = 0;
    _isSolved = false;
    _errorMsg = null;
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
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalizeTurkish(String text) {
    return text
        .trim()
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ç', 'Ç')
        .replaceAll('ş', 'Ş')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ö', 'Ö')
        .replaceAll('ü', 'Ü')
        .toUpperCase();
  }

  void _submitStepWord() {
    if (_isSolved) return;
    final rawInput = _inputController.text.trim();
    if (rawInput.isEmpty) return;

    final input = _normalizeTurkish(rawInput);
    final target = _normalizeTurkish(_level.steps[_currentStepIndex].targetWord);

    if (input == target) {
      HapticFeedback.mediumImpact();
      setState(() {
        _userWords[_currentStepIndex] = _level.steps[_currentStepIndex].targetWord;
        _inputController.clear();
        _currentInputText = '';
        _errorMsg = null;

        if (_currentStepIndex < _level.steps.length - 1) {
          _currentStepIndex++;
        } else {
          _isSolved = true;
          _focusNode.unfocus();
          _timer?.cancel();
          _handleWin();
        }
      });
    } else {
      HapticFeedback.vibrate();
      ScreenShake.shake(context, intensity: 6.0);
      setState(() {
        _errorMsg = 'Yanlış kelime! İpucuna ve değişen harfe dikkat et.';
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
            const Icon(Icons.stairs_rounded, color: AppColors.highlighterPurple, size: 28),
            const SizedBox(width: 8),
            Text(
              'Kelime Tırmanışı: Nasıl Oynanır?',
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
              'Sadece 1 Harf Değişir',
              'Her basamakta önceki kelimeden tam olarak 1 harf değiştirilerek yeni bir anlamlı kelime oluşturulur.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'İpucunu ve Pozisyonu Takip Et',
              'Her basamak için bir anlam ipucu verilir ve hangi harfin değiştiği sarı fosforla gösterilir.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Zirveye Ulaş',
              'Başlangıç kelimesinden başlayarak tüm basamakları adım adım tırman ve hedef kelimeye ulaş!',
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
                  const Icon(Icons.tips_and_updates_rounded, size: 20, color: AppColors.pencilBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '• Örnek: KAR → TAR → TAS → TOS → TON\n• Her adımda 1 harf değişir!\n• Klavyeden doğru kelimeyi yaz ve "Tırman"a bas!',
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
              color: AppColors.highlighterPurple,
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
    final currentStep = _level.steps[_currentStepIndex];
    final wordLength = _level.startWord.length;

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
                          const Icon(Icons.stairs_rounded, size: 18, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kelime Tırmanışı',
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
                                  color: AppColors.highlighterPurple,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '🪜 1 Harf Merdiveni',
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

              // 2. İLERLEME ÇUBUĞU (Organik SketchCard)
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
                          const Icon(Icons.hiking_rounded, size: 20, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Text(
                            _isSolved
                                ? 'Zirveye Ulaşıldı! 🏆'
                                : 'Basamak: ${_currentStepIndex + 1} / ${_level.steps.length}',
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                      // Basamak İlerleme Noktaları
                      Row(
                        children: List.generate(_level.steps.length, (idx) {
                          final isCompleted = _userWords[idx].isNotEmpty;
                          final isCurrent = idx == _currentStepIndex && !_isSolved;

                          Color bgColor;
                          if (isCompleted) {
                            bgColor = AppColors.highlighterGreen;
                          } else if (isCurrent) {
                            bgColor = AppColors.highlighterPurple;
                          } else {
                            bgColor = AppColors.surfaceSecondaryLight;
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
                                color: AppColors.pencilBlack,
                                width: isCompleted || isCurrent ? 2.0 : 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted || isCurrent ? AppColors.pencilBlack : AppColors.pencilLight,
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

              // 3. KELİME MERDİVENİ VE TAHMİN ALANI
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SKEÇ MERDİVEN KARTI
                      SketchCard(
                        borderRadius: 14,
                        shadowOffset: const Offset(3.5, 3.5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          children: [
                            // BAŞLANGIÇ KELİMESİ KARTI
                            _buildWordTile(
                              word: _level.startWord,
                              label: '🚩 BAŞLANGIÇ',
                              isCompleted: true,
                              isCurrent: false,
                              highlightIndex: -1,
                              isStartWord: true,
                            ),

                            // MERDİVEN ADIMLARI
                            for (int i = 0; i < _level.steps.length; i++) ...[
                              _buildLadderConnector(),
                              _buildStepTile(i),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4. AKTİF İPUCU DEFTER NOTU (Sticky Note)
                      if (!_isSolved) ...[
                        SketchCard(
                          backgroundColor: Colors.white,
                          borderRadius: 14,
                          shadowOffset: const Offset(3, 3),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.highlighterYellow),
                                      const SizedBox(width: 6),
                                      Text(
                                        'BASAMAK ${_currentStepIndex + 1} İPUCU',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pencilBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.highlighterYellow,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.pencilBlack, width: 1.4),
                                    ),
                                    child: Text(
                                      '📌 ${currentStep.changedIndex + 1}. HARF DEĞİŞİYOR',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pencilBlack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentStep.clue,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 5. HARF YUVALARI (CANLI ÖNİZLEME)
                        SketchCard(
                          borderRadius: 12,
                          shadowOffset: const Offset(2.5, 2.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(wordLength, (index) {
                              String letter = '';
                              if (index < _currentInputText.length) {
                                letter = _currentInputText[index];
                              }

                              final isChangedSlot = index == currentStep.changedIndex;
                              final hasLetter = letter.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                width: 46,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: hasLetter
                                      ? AppColors.highlighterYellow.withValues(alpha: 0.4)
                                      : (isChangedSlot ? AppColors.highlighterPurple.withValues(alpha: 0.25) : AppColors.surfaceSecondaryLight),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.pencilBlack,
                                    width: isChangedSlot || hasLetter ? 2.2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pencilBlack,
                                      offset: hasLetter ? const Offset(2, 2) : const Offset(1, 1),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    letter.isNotEmpty
                                        ? letter
                                        : (isChangedSlot ? '?' : _getPreviousLetter(index)),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: letter.isNotEmpty
                                          ? AppColors.pencilBlack
                                          : (isChangedSlot ? AppColors.pencilBlack : AppColors.pencilLight),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 6. TAHMİN ET VE TIRMAN GİRİŞ ALANI
                        Row(
                          children: [
                            // Yazı Alanı
                            Expanded(
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.pencilBlack, width: 2.2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.pencilBlack,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: TextField(
                                    controller: _inputController,
                                    focusNode: _focusNode,
                                    textCapitalization: TextCapitalization.characters,
                                    textInputAction: TextInputAction.done,
                                    maxLength: wordLength,
                                    onSubmitted: (_) => _submitStepWord(),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pencilBlack,
                                      letterSpacing: 3.0,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'Kelimeyi yaz...',
                                      hintStyle: GoogleFonts.patrickHand(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.pencilLight,
                                        letterSpacing: 0.5,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Tırman Butonu
                            GestureDetector(
                              onTap: _submitStepWord,
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.highlighterPurple,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.pencilBlack, width: 2.2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.pencilBlack,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 20, color: AppColors.pencilBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tırman',
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pencilBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // HATA MESAJI
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _errorMsg!,
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 15,
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

                      const SizedBox(height: 30),
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

  String _getPreviousLetter(int index) {
    if (_currentStepIndex == 0) {
      return _level.startWord[index];
    }
    final prevWord = _userWords[_currentStepIndex - 1];
    if (prevWord.isNotEmpty) {
      return prevWord[index];
    }
    return '';
  }

  Widget _buildLadderConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 10,
            color: AppColors.pencilBlack,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.pencilBlack),
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 10,
            color: AppColors.pencilBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(int stepIdx) {
    final isCompleted = _userWords[stepIdx].isNotEmpty;
    final isCurrent = stepIdx == _currentStepIndex && !_isSolved;
    final step = _level.steps[stepIdx];

    String displayWord;
    if (isCompleted) {
      displayWord = _userWords[stepIdx];
    } else if (isCurrent) {
      displayWord = '?' * step.targetWord.length;
    } else {
      displayWord = '?' * step.targetWord.length;
    }

    return _buildWordTile(
      word: displayWord,
      label: 'Basamak ${stepIdx + 1}',
      isCompleted: isCompleted,
      isCurrent: isCurrent,
      highlightIndex: isCurrent ? step.changedIndex : -1,
      isStartWord: false,
    );
  }

  Widget _buildWordTile({
    required String word,
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required int highlightIndex,
    required bool isStartWord,
  }) {
    Color cardBg;
    if (isStartWord) {
      cardBg = AppColors.highlighterYellow.withValues(alpha: 0.35);
    } else if (isCompleted) {
      cardBg = AppColors.highlighterGreen.withValues(alpha: 0.25);
    } else if (isCurrent) {
      cardBg = Colors.white;
    } else {
      cardBg = AppColors.surfaceSecondaryLight.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent || isCompleted || isStartWord ? AppColors.pencilBlack : AppColors.pencilLight,
          width: isCurrent ? 2.2 : 1.5,
        ),
        boxShadow: isCurrent || isCompleted || isStartWord
            ? const [
                BoxShadow(
                  color: AppColors.pencilBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isCompleted && !isStartWord) ...[
                const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
              ] else if (isCurrent) ...[
                const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.pencilBlack),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.patrickHand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isCurrent || isCompleted || isStartWord ? AppColors.pencilBlack : AppColors.pencilLight,
                ),
              ),
            ],
          ),
          Row(
            children: List.generate(word.length, (i) {
              final char = word[i];
              final isHighlighted = i == highlightIndex;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 32,
                height: 34,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.highlighterYellow
                      : (isCompleted || isStartWord ? Colors.white : AppColors.surfaceSecondaryLight),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isHighlighted || isCompleted || isStartWord ? AppColors.pencilBlack : AppColors.pencilLight,
                    width: isHighlighted ? 2.0 : 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    char,
                    style: GoogleFonts.patrickHand(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted || isCompleted || isStartWord
                          ? AppColors.pencilBlack
                          : AppColors.pencilLight,
                    ),
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
