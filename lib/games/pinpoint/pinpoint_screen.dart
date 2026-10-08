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

  static const List<Color> _clueBadgeColors = [
    AppColors.skyBlue,
    AppColors.sunYellow,
    Color(0xFFFB7185),
    AppColors.highlighterPurple,
    Color(0xFF34D399),
  ];

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
            const Icon(Icons.psychology_alt_rounded, color: AppColors.sunYellow, size: 28),
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
              'Açılan ipuçları tek bir gizli anahtar kelimeye veya kavrama işaret eder.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '2',
              'Az İpucu = Yüksek Puan',
              'Ne kadar az ipucuyla doğru kelimeyi tahmin edersen o kadar çok puan kazanırsın!',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              '3',
              'Doğrudan Kutulara Yaz',
              'Ayrı bir yazı kutusu arama, doğrudan kelime kutularına dokunup tahminini yaz!',
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
              color: AppColors.skyBlue,
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
              // 1. ÜST KONTROL & BAŞLIK ÇUBUĞU (Organik SketchCard)
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
                          const Icon(Icons.psychology_alt_rounded, size: 18, color: AppColors.pencilBlack),
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
                                  color: AppColors.sunYellow.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                ),
                                child: Text(
                                  '🔍 5 İpucu Tek Anlam',
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
                          const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.sunYellow),
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
                      // 5 Basamaklı İlerleme Daireleri (Renkli Boncuklar)
                      Row(
                        children: List.generate(_level.clues.length, (idx) {
                          final isRevealed = idx < _revealedClues;
                          final color = _clueBadgeColors[idx % _clueBadgeColors.length];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isRevealed ? color : AppColors.surfaceSecondaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pencilBlack,
                                width: isRevealed ? 2.0 : 1.2,
                              ),
                              boxShadow: isRevealed
                                  ? const [
                                      BoxShadow(
                                        color: AppColors.pencilBlack,
                                        offset: Offset(1, 1),
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
                      // 5 ADET İPUCU SATIRI (Defter Notları - Canlı Pastel Çerçeveler)
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
                              SketchCard(
                                backgroundColor: AppColors.sunYellow,
                                borderRadius: 12,
                                shadowOffset: const Offset(2.5, 2.5),
                                borderWidth: 2.0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                onTap: _revealNextClue,
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
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. HEDEF KELİME KUTULARI (Kullanıcı Doğrudan Buraya Yazar!)
                      // Arka planda gizli input focus'u tutar, kutulara dokunulduğunda klavye açılır
                      GestureDetector(
                        onTap: () {
                          if (!_isSolved) {
                            _focusNode.requestFocus();
                          }
                        },
                        child: SketchCard(
                          backgroundColor: Colors.white,
                          borderRadius: 14,
                          shadowOffset: const Offset(3.5, 3.5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isSolved ? Icons.celebration_rounded : Icons.edit_note_rounded,
                                        size: 18,
                                        color: _isSolved ? const Color(0xFF059669) : AppColors.pencilGraphite,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isSolved ? 'TEBRİKLER! GİZLİ KELİME:' : 'GİZLİ KELİME ($targetLength HARF):',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _isSolved ? const Color(0xFF059669) : AppColors.pencilBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!_isSolved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.skyBlue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                      ),
                                      child: Text(
                                        '${_currentInputText.length} / $targetLength',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pencilBlack,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Canlı & El Yapımı Harf Kutuları
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

                                    final isCurrentCaret = !_isSolved && _currentInputText.length == index;
                                    final hasLetter = letter.isNotEmpty;

                                    Color boxBg;
                                    if (_isSolved) {
                                      boxBg = const Color(0xFF34D399); // Ferah pastel nane
                                    } else if (hasLetter) {
                                      boxBg = AppColors.sunYellow.withValues(alpha: 0.3);
                                    } else if (isCurrentCaret) {
                                      boxBg = AppColors.skyBlue.withValues(alpha: 0.25);
                                    } else {
                                      boxBg = AppColors.backgroundLight;
                                    }

                                    return SketchCard(
                                      backgroundColor: boxBg,
                                      borderRadius: 12,
                                      shadowOffset: hasLetter || isCurrentCaret
                                          ? const Offset(2.2, 2.2)
                                          : const Offset(1.5, 1.5),
                                      borderWidth: isCurrentCaret ? 2.5 : (hasLetter || _isSolved ? 2.2 : 1.5),
                                      padding: EdgeInsets.zero,
                                      child: SizedBox(
                                        width: 48,
                                        height: 54,
                                        child: Center(
                                          child: Text(
                                            letter,
                                            style: GoogleFonts.patrickHand(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.pencilBlack,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              if (!_isSolved) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Harflere dokun ve doğrudan tahminini yaz',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13,
                                    color: AppColors.pencilLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Gizli TextField (Kullanıcı kutulara bastığında klavyeyi yönetir)
                      if (!_isSolved)
                        SizedBox(
                          height: 0,
                          width: 0,
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _guessController,
                              focusNode: _focusNode,
                              maxLength: targetLength,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitGuess(),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 5. TAHMİN ET BUTONU (Organik SketchCard)
                      if (!_isSolved) ...[
                        SketchCard(
                          backgroundColor: _currentInputText.isNotEmpty
                              ? AppColors.sunYellow
                              : AppColors.surfaceSecondaryLight,
                          borderRadius: 14,
                          shadowOffset: _currentInputText.isNotEmpty ? const Offset(3, 3) : Offset.zero,
                          borderWidth: 2.2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onTap: _currentInputText.isNotEmpty ? _submitGuess : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 22,
                                color: _currentInputText.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tahmin Et',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _currentInputText.isNotEmpty ? AppColors.pencilBlack : AppColors.pencilLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // HATA MESAJI (Canlı Eskiz Çerçeveli)
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        SketchCard(
                          backgroundColor: AppColors.errorBgLight,
                          borderRadius: 10,
                          shadowOffset: const Offset(2, 2),
                          borderWidth: 1.8,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 16,
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
                                fontSize: 14,
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
                            return SketchCard(
                              backgroundColor: Colors.white,
                              borderRadius: 8,
                              shadowOffset: const Offset(1.5, 1.5),
                              borderWidth: 1.5,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final badgeColor = _clueBadgeColors[index % _clueBadgeColors.length];

    return SketchCard(
      backgroundColor: isRevealed ? Colors.white : AppColors.surfaceSecondaryLight.withValues(alpha: 0.5),
      borderRadius: 12,
      shadowOffset: isRevealed ? const Offset(2.2, 2.2) : Offset.zero,
      borderWidth: isRevealed ? 2.0 : 1.2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Numaralandırma Rozeti (Canlı Renkli Boncuk)
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRevealed ? badgeColor : AppColors.surfaceSecondaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.pencilBlack,
                width: 1.8,
              ),
              boxShadow: isRevealed
                  ? const [
                      BoxShadow(
                        color: AppColors.pencilBlack,
                        offset: Offset(1, 1),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
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
              color: Color(0xFF059669),
            ),
        ],
      ),
    );
  }
}
