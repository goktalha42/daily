import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/app_button.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sketch_decorations.dart';
import '../../../games/common/base_game.dart';
import '../leaderboard_service.dart';
import 'leaderboard_entry_card.dart';

class CompletedGameLeaderboardDialog extends ConsumerStatefulWidget {
  final GameType game;
  final int score;
  final int durationMs;
  final String title;
  final String subtitle;
  final String? difficulty;
  final String levelId;

  const CompletedGameLeaderboardDialog({
    super.key,
    required this.game,
    required this.score,
    required this.durationMs,
    required this.title,
    this.subtitle = 'Bugünkü bulmaca başarıyla çözüldü.',
    this.difficulty,
    required this.levelId,
  });

  @override
  ConsumerState<CompletedGameLeaderboardDialog> createState() =>
      _CompletedGameLeaderboardDialogState();
}

class _CompletedGameLeaderboardDialogState
    extends ConsumerState<CompletedGameLeaderboardDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardServiceProvider).refreshFromServer(
            gameType: widget.game,
            timeframe: LeaderboardTimeframe.daily,
            difficulty: widget.difficulty,
            levelId: widget.levelId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(leaderboardServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.pencilBlack;
    final secondaryTextColor =
        isDark ? AppColors.pencilLightDark : AppColors.pencilGray;
    final cardBorderColor = isDark ? Colors.white38 : AppColors.pencilBlack;

    final entries = service.getLeaderboard(
      gameType: widget.game,
      timeframe: LeaderboardTimeframe.daily,
      difficulty: widget.difficulty,
      levelId: widget.levelId,
    );

    final isSyncing = service.isSyncingWithServer;
    final isConnected = service.isServerConnected;

    final myEntryIndex = entries.indexWhere((e) => e.userId == 'user_local');
    final myEntry = myEntryIndex != -1 ? entries[myEntryIndex] : null;
    final myRank = myEntry?.rank;
    final top10 = entries.take(10).toList();
    final isUserInTop10 = myRank != null && myRank <= 10;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          maxWidth: 440,
        ),
        child: SketchCard(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          borderColor: isDark ? Colors.white : AppColors.pencilBlack,
          borderRadius: 18,
          borderWidth: 2.5,
          shadowOffset: const Offset(4.0, 4.0),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık Satırı
              Row(
                children: [
                  SketchCard(
                    padding: const EdgeInsets.all(6),
                    borderRadius: 18,
                    borderWidth: 1.8,
                    shadowOffset: const Offset(1.5, 1.5),
                    backgroundColor: AppColors.success
                        .withValues(alpha: isDark ? 0.25 : 0.15),
                    borderColor:
                        isDark ? AppColors.success : AppColors.pencilBlack,
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.patrickHand(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.patrickHand(
                            color: secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Canlı Sunucu Durum Rozeti
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? const Color(0xFF2E7D32)
                          : AppColors.sunYellow,
                      border: Border.fromBorderSide(
                        BorderSide(
                            color: AppColors.pencil(context), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSyncing
                        ? 'CANLI SKORLAR GÜNCELLENİYOR...'
                        : (isConnected
                            ? 'CANLI SUNUCU • ÇEVRİMİÇİ'
                            : 'GLOBAL ARENA • GÜNCEL'),
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isConnected
                          ? const Color(0xFF2E7D32)
                          : AppColors.graphite(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Kaydırılabilir İçerik
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Oyuncunun Skor & Süre & Sıralama Kartı
                      SketchCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        borderWidth: 2.0,
                        shadowOffset: const Offset(2.5, 2.5),
                        backgroundColor: isDark
                            ? AppColors.surfaceSecondaryDark
                            : AppColors.surfaceSecondaryLight,
                        borderColor: cardBorderColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('SKOR',
                                    style: GoogleFonts.patrickHand(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w700)),
                                Text('${widget.score}',
                                    style: GoogleFonts.patrickHand(
                                        fontSize: 22,
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Container(
                                width: 1.5,
                                height: 32,
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.pencilBlack
                                        .withValues(alpha: 0.2)),
                            Column(
                              children: [
                                Text('SÜRE',
                                    style: GoogleFonts.patrickHand(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    GameDateUtils.formatGameTime(
                                        widget.durationMs),
                                    style: GoogleFonts.patrickHand(
                                        fontSize: 20,
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Container(
                                width: 1.5,
                                height: 32,
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.pencilBlack
                                        .withValues(alpha: 0.2)),
                            Column(
                              children: [
                                Text('CANLI SIRA',
                                    style: GoogleFonts.patrickHand(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w700)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('#${myRank ?? '-'}',
                                        style: GoogleFonts.patrickHand(
                                            fontSize: 22,
                                            color: primaryTextColor,
                                            fontWeight: FontWeight.w700)),
                                    if (entries.isNotEmpty)
                                      Text('/${entries.length}',
                                          style: GoogleFonts.patrickHand(
                                              fontSize: 13,
                                              color: secondaryTextColor,
                                              fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Günlük İlk 10 Sıralaması Başlığı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.leaderboard_rounded,
                                  size: 16, color: primaryTextColor),
                              const SizedBox(width: 6),
                              Text(
                                'GÜNÜN İLK 10 SIRALAMASI',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          if (myRank != null && entries.isNotEmpty)
                            SketchCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              borderRadius: 6,
                              borderWidth: 1.2,
                              shadowOffset: const Offset(1, 1),
                              backgroundColor: isDark
                                  ? const Color(0xFF78350F)
                                  : AppColors.sunYellow.withValues(alpha: 0.25),
                              borderColor: isDark
                                  ? AppColors.sunYellow
                                  : AppColors.pencilBlack,
                              child: Text(
                                myRank <= 3
                                    ? '🏆 Podyumdasın!'
                                    : (myRank <= 10
                                        ? '🔥 İlk 10\'dasın!'
                                        : 'İlk %${((myRank / entries.length) * 100).ceil()}\'desin'),
                                style: GoogleFonts.patrickHand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.sunYellow
                                      : AppColors.pencilBlack,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 3. Sıralama Elemanları (Sıralama Sayfasıyla Birebir Aynı)
                      if (entries.isEmpty && isSyncing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.sunYellow),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Canlı sıralama yükleniyor...',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Bu seviye için henüz sıralama yok.\nİlk çözen sen oldun!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.patrickHand(
                                fontSize: 15,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ...top10.map((entry) {
                          final isMe = entry.userId == 'user_local';
                          return LeaderboardEntryCard(
                            entry: entry,
                            isMe: isMe,
                            customDetailText:
                                'Süre: ${GameDateUtils.formatGameTime(entry.bestTimeMs)}',
                          );
                        }),
                        if (!isUserInTop10 && myEntry != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Text(
                                '•   •   •',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray(context),
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                          LeaderboardEntryCard(
                            entry: myEntry,
                            isMe: true,
                            customDetailText:
                                'Süre: ${GameDateUtils.formatGameTime(myEntry.bestTimeMs)}',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Kapat Butonu
              AppButton(
                text: 'Harika!',
                onPressed: () => Navigator.of(context).pop(),
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
