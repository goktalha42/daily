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
import '../../core/services/daily_play_service.dart';
import '../../core/widgets/genius_win_dialog.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/widgets/screen_shake.dart';
import '../common/base_game.dart';
import '../../features/leaderboard/leaderboard_service.dart';
import 'pinpoint_models.dart';
import 'pinpoint_logic.dart';
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
  final FocusNode _focusNode = FocusNode();
  String _currentInputText = '';

  int _elapsedMs = 0;
  Timer? _timer;
  bool _isSolved = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initGame();
    _guessController.addListener(() {
      setState(() {
        _currentInputText = PinpointLogic.normalize(_guessController.text);
        if (_errorMessage != null) {
          _errorMessage = null;
        }
      });
    });
  }

  void _initGame() {
    _level = PinpointLevelRepository.getLevelForDate(widget.levelId);
    _revealedClues = 1;
    _wrongGuesses.clear();
    _guessController.clear();
    _currentInputText = '';
    _elapsedMs = 0;
    _isSolved = false;
    _errorMessage = null;
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
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitGuess() {
    if (_isSolved) return;
    final rawInput = _guessController.text.trim();
    if (rawInput.isEmpty) return;

    final input = PinpointLogic.normalize(rawInput);
    final isCorrect = PinpointLogic.isCorrectGuess(
      input,
      _level.targetWord,
      alternativeAnswers: _level.alternativeAnswers,
    );

    if (isCorrect) {
      _focusNode.unfocus();
      setState(() {
        _isSolved = true;
        _errorMessage = null;
      });
      _timer?.cancel();
      _handleWin();
    } else {
      HapticFeedback.vibrate();
      ScreenShake.shake(context, intensity: 6.0);
      setState(() {
        if (!_wrongGuesses.contains(input)) {
          _wrongGuesses.add(input);
        }
        _guessController.clear();
        _currentInputText = '';
        _errorMessage = 'Yanlış tahmin! İpuçlarını tekrar incele.';

        // Yanlış tahminde otomatik olarak bir sonraki ipucu açılır (varsa)
        if (_revealedClues < _level.clues.length) {
          _revealedClues++;
        }
      });
    }
  }

  void _revealNextClue() {
    if (_isSolved) return;
    if (_revealedClues < _level.clues.length) {
      HapticFeedback.mediumImpact();
      setState(() {
        _revealedClues++;
      });
    }
  }

  void _handleWin() {
    final score = PinpointLogic.calculateScore(
      durationMs: _elapsedMs,
      revealedClues: _revealedClues,
      wrongGuessesCount: _wrongGuesses.length,
    );


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
    ref.read(gameStatsServiceProvider.notifier).recordGameResult(
          gameType: GameType.pinpoint,
          score: score,
          durationMs: _elapsedMs,
          moveCount: _wrongGuesses.length + 1,
        );
    ref.read(dailyPlayServiceProvider.notifier).recordCompletion(
          game: GameType.pinpoint,
          dateId: widget.levelId,
          score: score,
          durationMs: _elapsedMs,
        );

    GeniusWinDialog.show(
      context,
      result: result,
      gameTitle: 'Kelime İzleri',
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
            const Icon(Icons.push_pin_rounded, color: AppColors.highlighterCyan, size: 28),
            const SizedBox(width: 8),
            Text(
              'Kelime İzleri: Nasıl Oynanır?',
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
              'Ortak Kavramı Bul',
              '5 farklı ipucu seni gizli bir anahtar kelimeye götürür. İpuçları arasındaki ortak bağı keşfet!',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Adım Adım İlerle',
              'Her ipucu hedef kelimeyi biraz daha belirginleştirir. Ne kadar az ipucuyla bilirsen o kadar yüksek puan kazanırsın!',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Yanlış Tahminler',
              'Yanlış tahmin yaptığında bir sonraki ipucu otomatik olarak açılır ve deftere not edilir.',
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
                      '• İpucu sayısı: 5 basamak\n• Harf yuvaları gizli kelimenin harf sayısını gösterir!\n• Klavyeden yaz ve "Tahmin Et" butonuna bas!',
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
              color: AppColors.highlighterCyan,
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
    final targetLength = _level.targetWord.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SketchPaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. ÜST KONTROL & BAŞLIK ÇUBUĞU (Kara Kalem Skeç Kartları)
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

                    // Oyun Başlığı ve Kategori Rozeti
                    SketchCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      borderRadius: 12,
                      shadowOffset: const Offset(2.5, 2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin_rounded, size: 18, color: AppColors.pencilBlack),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kelime İzleri',
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
                                  color: AppColors.highlighterCyan,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  _level.categoryHint,
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

              // 2. İPUCU İLERLEME ÇUBUĞU (Organik SketchCard)
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
                          const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.highlighterYellow),
                          const SizedBox(width: 6),
                          Text(
                            'İpucu: $_revealedClues / ${_level.clues.length}',
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ],
                      ),
                      // 5 Basamaklı İlerleme Daireleri
                      Row(
                        children: List.generate(_level.clues.length, (idx) {
                          final isRevealed = idx < _revealedClues;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isRevealed ? AppColors.highlighterCyan : AppColors.surfaceSecondaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pencilBlack,
                                width: isRevealed ? 2.0 : 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isRevealed ? AppColors.pencilBlack : AppColors.pencilLight,
                                ),
                              ),
                            ),
                          ).animate(target: isRevealed ? 1 : 0).scale(duration: 180.ms);
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. İPUCU LİSTESİ VE GİZLİ KELİME ALANI
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 5 ADET İPUCU SATIRI (Defter Notları)
                      SketchCard(
                        borderRadius: 14,
                        shadowOffset: const Offset(3.5, 3.5),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            for (int i = 0; i < _level.clues.length; i++) ...[
                              _buildClueItem(i),
                              if (i < _level.clues.length - 1) const SizedBox(height: 8),
                            ],
                            if (_revealedClues < _level.clues.length && !_isSolved) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _revealNextClue,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.highlighterYellow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.pencilBlack,
                                        offset: Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.pencilBlack),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Sonraki İpucunu Aç (${_level.clues.length - _revealedClues} kaldı)',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pencilBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. HEDEF KELİME HARF YUVALARI (Harf Kutucukları)
                      SketchCard(
                        backgroundColor: Colors.white,
                        borderRadius: 14,
                        shadowOffset: const Offset(3, 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isSolved ? '🎉 TEBRİKLER! GİZLİ KELİME:' : 'GİZLİ KELİME ($targetLength HARF):',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _isSolved ? AppColors.successDark : AppColors.pencilGray,
                                  ),
                                ),
                                if (!_isSolved)
                                  Text(
                                    '${_currentInputText.length} / $targetLength',
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pencilBlack,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Harf Kutucukları
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(targetLength, (index) {
                                  String letter = '';
                                  if (_isSolved) {
                                    letter = _level.targetWord[index];
                                  } else if (index < _currentInputText.length) {
                                    letter = _currentInputText[index];
                                  }

                                  final hasLetter = letter.isNotEmpty;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 44,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _isSolved
                                          ? AppColors.highlighterGreen
                                          : (hasLetter ? AppColors.highlighterYellow.withValues(alpha: 0.35) : AppColors.surfaceSecondaryLight),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.pencilBlack,
                                        width: hasLetter || _isSolved ? 2.2 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.pencilBlack,
                                          offset: hasLetter || _isSolved ? const Offset(2, 2) : const Offset(1, 1),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        letter,
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pencilBlack,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 5. TAHMİN ET GİRİŞ ALANI (Input Box & Tahmin Butonu)
                      if (!_isSolved) ...[
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
                                    controller: _guessController,
                                    focusNode: _focusNode,
                                    textCapitalization: TextCapitalization.characters,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submitGuess(),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pencilBlack,
                                      letterSpacing: 2.0,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Tahminini yaz...',
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
                            // Tahmin Et Butonu
                            GestureDetector(
                              onTap: _submitGuess,
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.highlighterYellow,
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
                                    const Icon(Icons.send_rounded, size: 20, color: AppColors.pencilBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tahmin Et',
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
                      ],

                      // HATA MESAJI
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.errorBgLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
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

                      // 6. YANLIŞ KARALAMALAR (Üstü Çizili Notlar)
                      if (_wrongGuesses.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.edit_off_rounded, size: 16, color: AppColors.pencilGray),
                            const SizedBox(width: 6),
                            Text(
                              'YANLIŞ KARALAMALAR:',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pencilGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _wrongGuesses.map((guess) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.pencilGray, width: 1.5),
                              ),
                              child: Text(
                                guess,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilGray,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.error,
                                  decorationThickness: 2.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _buildClueItem(int index) {
    final isRevealed = index < _revealedClues;
    final clueText = _level.clues[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRevealed ? AppColors.surfaceLight : AppColors.surfaceSecondaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRevealed ? AppColors.pencilBlack : AppColors.pencilLight,
          width: isRevealed ? 2.0 : 1.2,
        ),
        boxShadow: isRevealed
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
        children: [
          // Numaralandırma Rozeti
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRevealed ? AppColors.highlighterCyan : AppColors.surfaceSecondaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isRevealed ? AppColors.pencilBlack : AppColors.pencilLight,
                width: 1.6,
              ),
            ),
            child: Text(
              '#${index + 1}',
              style: GoogleFonts.patrickHand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isRevealed ? AppColors.pencilBlack : AppColors.pencilLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // İpucu Metni
          Expanded(
            child: Text(
              isRevealed ? clueText : '🔒 Kilitli İpucu',
              style: GoogleFonts.patrickHand(
                fontSize: 19,
                fontWeight: isRevealed ? FontWeight.w700 : FontWeight.w600,
                color: isRevealed ? AppColors.pencilBlack : AppColors.pencilLight,
                letterSpacing: isRevealed ? 0.3 : 0.0,
              ),
            ),
          ),
          if (isRevealed)
            const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppColors.successDark,
            ),
        ],
      ),
    );
  }
}
