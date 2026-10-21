import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/league_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/sketch_decorations.dart';

// ============================================================================
// ANA LİG EKRANI (Hand-Drawn Sketch Theme)
// ============================================================================

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(leagueServiceProvider.notifier).checkWeekTransition();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final league = ref.watch(leagueServiceProvider);
    final level = league.currentLevel;

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: _slideAnim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 0. BEKLEYEN LİG ATLAYIŞ/DÜŞÜŞ TEBRİK BANNERI ───────────
            if (league.pendingPromotion != null || league.pendingRelegation != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: _SketchLeagueTransitionBanner(
                    league: league,
                    onDismiss: () {
                      ref.read(leagueServiceProvider.notifier).clearPendingLeagueChange();
                    },
                  ),
                ),
              ),

            // ─── 1. ÜST BAŞLIK & SKEÇ LİG ROZETİ ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: (league.pendingPromotion != null || league.pendingRelegation != null) ? 14 : 54,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sunYellow,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: AppColors.pencil(context),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HAFTALIK LİG ARENASI • REKABET',
                              style: GoogleFonts.patrickHand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.graphite(context),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lig Tablosu',
                          style: GoogleFonts.patrickHand(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencil(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Sağ üst: El çizimi lig rozeti
                    _SketchLeagueTopBadge(level: level),
                  ],
                ),
              ),
            ),

            // ─── 2. DUOLINGO TARZI SKEÇ LİG BASAMAKLARI ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _SketchLeagueJourneyStepper(currentLevel: level),
              ),
            ),

            // ─── 3. ANA LİG SKEÇ KARTI (Gövde + İlerleme + Not) ───────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: _SketchMainLeagueCard(league: league),
              ),
            ),

            // ─── 4. SKEÇ BİTİŞ ZAMANLAYICISI ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _SketchCountdownRow(league: league),
              ),
            ),

            // ─── 5. LİSTE BAŞLIĞI VE OYUNCU SAYISI ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${level.emoji} ${level.displayName} Ligi Sıralaması',
                      style: GoogleFonts.patrickHand(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencil(context),
                      ),
                    ),
                    const Spacer(),
                    // El çizimi oyuncu adedi etiketi
                    _SketchMiniBadge(
                      text: '${league.players.length} Yarışmacı',
                      backgroundColor: AppColors.surfaceSecondaryOf(context),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 6. YÜKSELME BÖLGE AYIRICI ────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: _SketchZoneDivider(
                  label: '▲ YÜKSELME BÖLGESİ (İLK 10) • BİR ÜST LİGE ÇIKIŞ',
                  color: AppColors.success,
                  isPromotion: true,
                ),
              ),
            ),

            // ─── 7. OYUNCU TABLOSU LİSTESİ ────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final player = league.players[index];

                  Widget? zoneHeader;
                  if (index == 10) {
                    zoneHeader = _SketchZoneDivider(
                      label: '— GÜVENLİ BÖLGE • BU LİGDE KALINIR',
                      color: AppColors.gray(context),
                      isPromotion: false,
                    );
                  } else if (index == 32) {
                    zoneHeader = const _SketchZoneDivider(
                      label: '▼ DÜŞME BÖLGESİ (SON 10) • BİR ALT LİGE GERİLEME',
                      color: AppColors.error,
                      isPromotion: false,
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (zoneHeader != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                          child: zoneHeader,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 3.5,
                        ),
                        child: _SketchPlayerRow(
                          player: player,
                          league: league,
                          index: index,
                        ),
                      ),
                    ],
                  );
                },
                childCount: league.players.length,
              ),
            ),

            // ─── ALT NAV BAR BOŞLUĞU ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. ÜST SKEÇ LİG ROZETİ (Sağ Üst Köşe)
// ============================================================================

class _SketchLeagueTopBadge extends StatelessWidget {
  final LeagueLevel level;

  const _SketchLeagueTopBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return SketchCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      borderRadius: 10,
      borderWidth: 2.0,
      shadowOffset: const Offset(2.5, 2.5),
      backgroundColor: AppColors.sunYellow,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 5),
          Text(
            level.displayName.toUpperCase(),
            style: GoogleFonts.patrickHand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkBlack,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. DUOLINGO TARZI SKEÇ LİG BASAMAKLARI (Yatay Stepper)
// ============================================================================

class _SketchLeagueJourneyStepper extends StatelessWidget {
  final LeagueLevel currentLevel;

  const _SketchLeagueJourneyStepper({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final currentIndex = LeagueLevel.values.indexOf(currentLevel);

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: LeagueLevel.values.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Center(
            child: CustomPaint(
              size: const Size(12, 4),
              painter: _DoodleArrowConnectorPainter(
                color: AppColors.graphite(context),
              ),
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final level = LeagueLevel.values[index];
          final isCurrent = index == currentIndex;
          final isCompleted = index < currentIndex;

          return _SketchLeagueStepItem(
            level: level,
            isCurrent: isCurrent,
            isCompleted: isCompleted,
          );
        },
      ),
    );
  }
}

class _SketchLeagueStepItem extends StatelessWidget {
  final LeagueLevel level;
  final bool isCurrent;
  final bool isCompleted;

  const _SketchLeagueStepItem({
    required this.level,
    required this.isCurrent,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isCurrent
        ? AppColors.sunYellow
        : isCompleted
            ? (isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight)
            : (isDark ? AppColors.surfaceDark : Colors.white);

    final borderColor = isCurrent
        ? (isDark ? AppColors.sunYellow : AppColors.pencilBlack)
        : isCompleted
            ? (isDark ? AppColors.pencilWhite.withValues(alpha: 0.6) : AppColors.pencilGraphite)
            : (isDark ? AppColors.pencilWhite.withValues(alpha: 0.25) : AppColors.pencilLight);

    return SketchCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 9,
      borderWidth: isCurrent ? 2.2 : 1.4,
      shadowOffset: isCurrent ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
      backgroundColor: bgColor,
      borderColor: borderColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.emoji,
            style: TextStyle(
              fontSize: 16,
              color: isCompleted || isCurrent ? null : (isDark ? Colors.white38 : Colors.black45),
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.displayName,
                style: GoogleFonts.patrickHand(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  color: isCurrent
                      ? AppColors.inkBlack
                      : isCompleted
                          ? AppColors.pencil(context)
                          : AppColors.gray(context),
                ),
              ),
              if (isCurrent)
                Text(
                  'BURADASIN',
                  style: GoogleFonts.patrickHand(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkBlack,
                    letterSpacing: 0.3,
                  ),
                )
              else if (isCompleted)
                Text(
                  '✓ GEÇİLDİ',
                  style: GoogleFonts.patrickHand(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                )
              else
                Text(
                  'KİLİTLİ',
                  style: GoogleFonts.patrickHand(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoodleArrowConnectorPainter extends CustomPainter {
  final Color? color;

  _DoodleArrowConnectorPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (color ?? AppColors.pencilGraphite).withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Titrek ok çizgisi
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    canvas.drawLine(
      Offset(size.width - 3, y - 2.5),
      Offset(size.width, y),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 3, y + 2.5),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 3. ANA SKEÇ LİG KARTI
// ============================================================================

class _SketchMainLeagueCard extends StatelessWidget {
  final LeagueState league;

  const _SketchMainLeagueCard({required this.league});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = league.currentLevel;
    final zone = league.userZone;
    final rank = league.userRank;

    // Bölgeye özel el çizimi mesaj ve ikon
    String noteTitle;
    String noteDesc;
    Color noteBg;
    Widget noteIcon;

    switch (zone) {
      case LeagueZone.promotion:
        noteTitle = 'Yükselme Potasındasın! 🎉';
        noteDesc = league.pointsSafetyMargin > 0
            ? '11. sıradaki rakibinden ${league.pointsSafetyMargin} LP öndesin. Pozisyonunu koru!'
            : 'İlk 10 sıradasın! Haftayı burada tamamlarsan üst lige çıkacaksın.';
        noteBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.45) : const Color(0xFFDCFCE7);
        noteIcon = SketchDoodleCrown(
          size: 24,
          color: isDark ? AppColors.pencilWhite : AppColors.pencilBlack,
          fillColor: AppColors.sunYellow,
        );
        break;
      case LeagueZone.safe:
        final pts = league.pointsToPromotion;
        noteTitle = 'Güvenli Bölgedesin 🛡️';
        noteDesc = pts > 0
            ? 'Yükselme potasına girmek için $pts LP daha kazanmalısın!'
            : 'Ligde kalmayı garantiledin. Şimdi üst sıralara oynama zamanı!';
        noteBg = AppColors.surfaceSecondaryOf(context);
        noteIcon = Icon(
          Icons.shield_outlined,
          size: 22,
          color: AppColors.pencil(context),
        );
        break;
      case LeagueZone.relegation:
        noteTitle = 'Düşme Tehlikesi! ⚠️';
        noteDesc = 'Son 10 sıradasın! Bir alt lige gerilememek için hemen oyun oyna!';
        noteBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.45) : AppColors.errorBgLight;
        noteIcon = const Icon(
          Icons.warning_amber_rounded,
          size: 24,
          color: AppColors.error,
        );
        break;
    }

    return SketchCard(
      enableHatching: true,
      borderRadius: 16,
      borderWidth: 2.5,
      shadowOffset: const Offset(3.5, 3.5),
      backgroundColor: AppColors.surfaceOf(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── ÜST SATIR: Skeç kutu içinde emoji + Başlık & Sıra ───────
          Row(
            children: [
              // El çizimi çapraz X'li kutu içine yerleşen lig emojisi
              SketchPlaceholderBox(
                width: 58,
                height: 58,
                fillColor: AppColors.sunYellow,
                lineColor: AppColors.pencil(context),
                borderRadius: 10,
                child: Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${level.displayName} Ligi',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.patrickHand(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencil(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SketchMiniBadge(
                          text: '#$rank. Sıra',
                          backgroundColor: AppColors.sunYellow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Haftalık Skorun: ${league.userWeeklyScore} LP (Lig Puanı)',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.graphite(context),
                      ),
                    ),
                    if (!level.isMax && level.next != null)
                      Text(
                        'Hedef: ${level.next!.emoji} ${level.next!.displayName} Ligi',
                        style: GoogleFonts.patrickHand(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── EL ÇİZİMİ İLERLEME ÇUBUĞU ─────────────────────────────────
          _SketchHandDrawnProgressBar(league: league),

          const SizedBox(height: 14),

          // ─── EL ÇİZİMİ DEĞERLENDİRME NOTU (Hand-Drawn Post-It Note) ───
          _SketchHandDrawnNoteBox(
            title: noteTitle,
            description: noteDesc,
            backgroundColor: noteBg,
            iconWidget: noteIcon,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3.1. EL ÇİZİMİ İLERLEME ÇUBUĞU (Wobbly Sketch Progress Bar)
// ============================================================================

class _SketchHandDrawnProgressBar extends StatelessWidget {
  final LeagueState league;

  const _SketchHandDrawnProgressBar({required this.league});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final players = league.players;
    if (players.isEmpty) return const SizedBox.shrink();

    final maxScore = players.first.weeklyScore;
    final userScore = league.userWeeklyScore;

    // 10. oyuncunun puanı (yükselme eşiği)
    final promotionPlayer = players.length >= 10 ? players[9] : players.last;
    final promotionScore = promotionPlayer.weeklyScore;

    final double progress = maxScore > 0
        ? (userScore / maxScore).clamp(0.0, 1.0)
        : 0.0;

    final double promotionMark = maxScore > 0
        ? (promotionScore / maxScore).clamp(0.05, 0.95)
        : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 16, color: AppColors.pencil(context)),
                const SizedBox(width: 4),
                Text(
                  'Haftalık İlerleme Skalan',
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencil(context),
                  ),
                ),
              ],
            ),
            Text(
              '$userScore LP / Lider: $maxScore LP',
              style: GoogleFonts.patrickHand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Serbest el çizimli progressBar
        SizedBox(
          height: 22,
          child: CustomPaint(
            painter: _WobblySketchProgressBarPainter(
              progress: progress,
              promotionMark: promotionMark,
              fillColor: AppColors.sunYellow,
              strokeColor: AppColors.pencil(context),
              barBackgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
              markColor: AppColors.success,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        const SizedBox(height: 4),

        // Çubuk altı el yazısı etiketleri
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 LP',
              style: GoogleFonts.patrickHand(
                fontSize: 11,
                color: AppColors.gray(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'İlk 10 Barajı (~$promotionScore LP)',
                  style: GoogleFonts.patrickHand(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.success : AppColors.successDark,
                  ),
                ),
              ],
            ),
            Text(
              'Zirve: $maxScore LP',
              style: GoogleFonts.patrickHand(
                fontSize: 11,
                color: AppColors.gray(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WobblySketchProgressBarPainter extends CustomPainter {
  final double progress;
  final double promotionMark;
  final Color fillColor;
  final Color strokeColor;
  final Color barBackgroundColor;
  final Color markColor;

  _WobblySketchProgressBarPainter({
    required this.progress,
    required this.promotionMark,
    required this.fillColor,
    required this.strokeColor,
    required this.barBackgroundColor,
    required this.markColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Zemin kurşun kalem gölgesi
    const shadowOffset = Offset(2.0, 2.0);
    final shadowRect = Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, w, h);
    final shadowPath = _buildWobblyRect(shadowRect, wobbleSeed: 1.0);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = strokeColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );

    // 2. Boş çubuk gövdesi (kağıt beyazı / hafif bej veya koyu arduvaz)
    final mainRect = Rect.fromLTWH(0, 0, w, h);
    final mainPath = _buildWobblyRect(mainRect, wobbleSeed: 0.0);
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = barBackgroundColor
        ..style = PaintingStyle.fill,
    );

    // 3. İlerleme Dolgusu (Fosforlu Sarı ile elle taranmış gibi)
    if (progress > 0.01) {
      final fillWidth = math.max(6.0, w * progress);
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, h);
      final fillPath = _buildWobblyRect(fillRect, wobbleSeed: 0.5);

      canvas.save();
      canvas.clipPath(mainPath);

      // Ana dolgu
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );

      // Elle tarama vuruşları (Hatching)
      final hatchPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.15)
        ..strokeWidth = 1.0;
      for (double x = -h; x < fillWidth + h; x += 6) {
        canvas.drawLine(Offset(x, 0), Offset(x + h, h), hatchPaint);
      }
      canvas.restore();
    }

    // 4. Ana Dış Kara Kalem Çerçevesi
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(mainPath, strokePaint);

    // 4.1 İkinci hafif taslak çizgisi (çift vuruş)
    final draftPath = _buildWobblyRect(mainRect, wobbleSeed: 2.2);
    canvas.drawPath(
      draftPath,
      strokePaint
        ..color = strokeColor.withValues(alpha: 0.3)
        ..strokeWidth = 1.0,
    );

    // 5. Yükselme Eşiği Çizgisi (Dikey kesik serbest el çizgisi)
    final markX = w * promotionMark;
    final markPaint = Paint()
      ..color = markColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(markX, -2),
      Offset(markX, h + 2),
      markPaint,
    );

    // Eşik minik el çizimi bayrağı / üçgeni
    final flagPath = Path();
    flagPath.moveTo(markX, -1);
    flagPath.lineTo(markX + 6, 3);
    flagPath.lineTo(markX, 7);
    flagPath.close();
    canvas.drawPath(flagPath, Paint()..color = markColor);
    canvas.drawPath(flagPath, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  Path _buildWobblyRect(Rect rect, {double wobbleSeed = 0.0}) {
    final path = Path();
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    const rad = 6.0;

    path.moveTo(l + rad, t);
    path.lineTo(r - rad, t + 0.6 * math.sin(wobbleSeed + 1.0));
    path.quadraticBezierTo(r, t, r, t + rad);
    path.lineTo(r + 0.5 * math.cos(wobbleSeed + 2.0), b - rad);
    path.quadraticBezierTo(r, b, r - rad, b);
    path.lineTo(l + rad, b + 0.6 * math.sin(wobbleSeed + 3.0));
    path.quadraticBezierTo(l, b, l, b - rad);
    path.lineTo(l + 0.5 * math.cos(wobbleSeed + 4.0), t + rad);
    path.quadraticBezierTo(l, t, l + rad, t);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _WobblySketchProgressBarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.promotionMark != promotionMark ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.barBackgroundColor != barBackgroundColor ||
      oldDelegate.markColor != markColor;
}

// ============================================================================
// 3.2. EL ÇİZİMİ NOT KUTUSU (Post-It Skeç Kutusu)
// ============================================================================

class _SketchHandDrawnNoteBox extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;
  final Widget iconWidget;

  const _SketchHandDrawnNoteBox({
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isLightBg = backgroundColor.computeLuminance() > 0.35;
    final titleColor = isLightBg ? AppColors.inkBlack : AppColors.inkWhite;
    final descColor = isLightBg ? const Color(0xFF44403C) : const Color(0xFFE2E8F0);

    return SketchCard(
      borderRadius: 10,
      borderWidth: 1.8,
      shadowOffset: const Offset(2.0, 2.0),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: iconWidget,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.patrickHand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.patrickHand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: descColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. SKEÇ BİTİŞ ZAMANLAYICISI (Eskiz Defteri Kapanış Damgası)
// ============================================================================

class _SketchCountdownRow extends StatelessWidget {
  final LeagueState league;

  const _SketchCountdownRow({required this.league});

  @override
  Widget build(BuildContext context) {
    return SketchCard(
      borderRadius: 11,
      borderWidth: 1.8,
      shadowOffset: const Offset(2.0, 2.0),
      backgroundColor: AppColors.surfaceSecondaryOf(context),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 18,
                color: AppColors.pencil(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Haftalık Lig Kapanışına:',
                style: GoogleFonts.patrickHand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite(context),
                ),
              ),
            ],
          ),
          _SketchMiniBadge(
            text: leagueDaysRemaining(),
            backgroundColor: AppColors.sunYellow,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. EL ÇİZİMİ BÖLGE AYIRICI (Wobbly Zone Divider)
// ============================================================================

class _SketchZoneDivider extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPromotion;

  const _SketchZoneDivider({
    required this.label,
    required this.color,
    required this.isPromotion,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isPromotion
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7))
        : AppColors.surfaceOf(context);

    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 10),
            painter: _WobblyLinePainter(color: color),
          ),
        ),
        const SizedBox(width: 8),
        SketchCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          borderRadius: 8,
          borderWidth: 1.6,
          shadowOffset: const Offset(1.5, 1.5),
          backgroundColor: cardBg,
          borderColor: color,
          child: Text(
            label,
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPromotion && isDark ? AppColors.success : color,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 10),
            painter: _WobblyLinePainter(color: color),
          ),
        ),
      ],
    );
  }
}

class _WobblyLinePainter extends CustomPainter {
  final Color color;

  _WobblyLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final y = size.height / 2;
    path.moveTo(0, y);

    for (double x = 0; x <= size.width; x += 12) {
      final wobble = math.sin(x * 0.25) * 1.5;
      path.lineTo(x, y + wobble);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WobblyLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ============================================================================
// 6. EL ÇİZİMİ OYUNCU SATIRI (Sketch Player Row Card)
// ============================================================================

class _SketchPlayerRow extends StatelessWidget {
  final LeaguePlayer player;
  final LeagueState league;
  final int index;

  const _SketchPlayerRow({
    required this.player,
    required this.league,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rank = player.rank;
    final isUser = player.isUser;
    final isTop3 = rank <= 3;
    final isPromotion = rank <= 10;
    final isRelegation = rank > 32;

    // Satır arka planı ve skeç gölgesi
    Color cardBg;
    Color borderColor;
    double borderWidth;
    Offset shadowOffset;

    final basePencil = AppColors.pencil(context);

    if (isUser) {
      cardBg = isDark
          ? AppColors.sunYellow.withValues(alpha: 0.22)
          : AppColors.sunYellow.withValues(alpha: 0.28);
      borderColor = isDark ? AppColors.sunYellow : basePencil;
      borderWidth = 2.4;
      shadowOffset = const Offset(3.0, 3.0);
    } else if (isTop3) {
      cardBg = AppColors.surfaceOf(context);
      borderColor = basePencil;
      borderWidth = 2.0;
      shadowOffset = const Offset(2.0, 2.0);
    } else if (isPromotion) {
      cardBg = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.28)
          : const Color(0xFFF0FDF4); // Çok hafif yeşil kağıt
      borderColor = basePencil.withValues(alpha: isDark ? 0.6 : 0.5);
      borderWidth = 1.6;
      shadowOffset = const Offset(1.5, 1.5);
    } else if (isRelegation) {
      cardBg = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.25)
          : const Color(0xFFFFF1F2); // Çok hafif kırmızımtırak kağıt
      borderColor = basePencil.withValues(alpha: isDark ? 0.55 : 0.45);
      borderWidth = 1.5;
      shadowOffset = const Offset(1.5, 1.5);
    } else {
      cardBg = AppColors.surfaceOf(context);
      borderColor = basePencil.withValues(alpha: isDark ? 0.5 : 0.4);
      borderWidth = 1.4;
      shadowOffset = const Offset(1.5, 1.5);
    }

    return SketchCard(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      enableHatching: isUser,
      backgroundColor: cardBg,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: 12,
      shadowOffset: shadowOffset,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // ─── 1. SIRA NUMARASI & DOODLE İKONU ────────────────────────
          _buildRankWidget(context, rank),

          const SizedBox(width: 8),

          // ─── 2. EL ÇİZİMİ AVATAR KUTUSU ─────────────────────────────
          SketchPlaceholderBox(
            width: 36,
            height: 36,
            fillColor: isUser
                ? AppColors.sunYellow
                : isTop3
                    ? (rank == 1
                        ? AppColors.sunYellow
                        : rank == 2
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFFFED7AA))
                    : AppColors.surfaceSecondaryOf(context),
            lineColor: basePencil,
            lineWidth: 1.6,
            borderRadius: 7,
            child: Text(
              isUser ? '😎' : _avatarEmoji(player.userName),
              style: const TextStyle(fontSize: 17),
            ),
          ),

          const SizedBox(width: 10),

          // ─── 3. OYUNCU ADI & "SİZ" ETİKETİ ──────────────────────────
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.userName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      fontWeight: isUser || isTop3
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: AppColors.pencil(context),
                    ),
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 6),
                  const _SketchMiniBadge(
                    text: 'SİZ',
                    backgroundColor: AppColors.sunYellow,
                  ),
                ],
              ],
            ),
          ),

          // ─── 4. LİG PUANI (LP) ──────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_formatScore(player.weeklyScore)} LP',
                style: GoogleFonts.patrickHand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: (isUser || isTop3)
                      ? AppColors.pencil(context)
                      : AppColors.graphite(context),
                ),
              ),
              if (isPromotion && !isTop3)
                Text(
                  '↑ Yükseliyor',
                  style: GoogleFonts.patrickHand(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.success : AppColors.successDark,
                  ),
                )
              else if (isRelegation)
                Text(
                  '↓ Tehlikede',
                  style: GoogleFonts.patrickHand(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankWidget(BuildContext context, int rank) {
    final pencilColor = AppColors.pencil(context);

    if (rank == 1) {
      return SizedBox(
        width: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SketchDoodleCrown(
              size: 16,
              color: pencilColor,
              fillColor: AppColors.sunYellow,
            ),
            Text(
              '#1',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: pencilColor,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 2) {
      return SizedBox(
        width: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SketchDoodleTrophy(
              size: 16,
              color: pencilColor,
              fillColor: const Color(0xFFCBD5E1),
            ),
            Text(
              '#2',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: pencilColor,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 3) {
      return SizedBox(
        width: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SketchDoodleTrophy(
              size: 16,
              color: pencilColor,
              fillColor: const Color(0xFFFED7AA),
            ),
            Text(
              '#3',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: pencilColor,
              ),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          '#$rank',
          style: GoogleFonts.patrickHand(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: rank <= 10
                ? (isDark ? AppColors.success : AppColors.successDark)
                : rank > 32
                    ? AppColors.error
                    : AppColors.gray(context),
          ),
        ),
      ),
    );
  }

  String _avatarEmoji(String name) {
    const emojis = [
      '🦊', '🐼', '🦁', '🐯', '🦅', '🦉', '🦋',
      '🐉', '🦚', '🦜', '🦈', '🐬', '🦞', '🦝'
    ];
    return emojis[name.length % emojis.length];
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(score % 1000 == 0 ? 0 : 1)}K';
    }
    return score.toString();
  }
}

// ============================================================================
// 7. PROFİL EKRANI İÇİN SKEÇ LİG ÖZET KARTI (LeagueProfileCard)
// ============================================================================

class LeagueProfileCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const LeagueProfileCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final league = ref.watch(leagueServiceProvider);
    final level = league.currentLevel;
    final zone = league.userZone;
    final rank = league.userRank;
    final score = league.userWeeklyScore;

    String zonePillText;
    Color zonePillBg;
    Color zonePillColor;

    switch (zone) {
      case LeagueZone.promotion:
        zonePillText = '↑ YÜKSELME POTASINDA';
        zonePillBg = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.45)
            : const Color(0xFFDCFCE7);
        zonePillColor = isDark ? AppColors.success : AppColors.successDark;
        break;
      case LeagueZone.safe:
        zonePillText = '— GÜVENLİ BÖLGE';
        zonePillBg = AppColors.surfaceSecondaryOf(context);
        zonePillColor = AppColors.graphite(context);
        break;
      case LeagueZone.relegation:
        zonePillText = '↓ DÜŞME TEHLİKESİ';
        zonePillBg = isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
            : AppColors.errorBgLight;
        zonePillColor = AppColors.error;
        break;
    }

    return SketchCard(
      onTap: onTap,
      enableHatching: true,
      borderWidth: 2.4,
      borderRadius: 16,
      shadowOffset: const Offset(3.5, 3.5),
      backgroundColor: AppColors.surfaceOf(context),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            children: [
              SketchPlaceholderBox(
                width: 48,
                height: 48,
                fillColor: AppColors.sunYellow,
                lineColor: AppColors.pencil(context),
                borderRadius: 8,
                child: Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${level.displayName} Ligi',
                          style: GoogleFonts.patrickHand(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencil(context),
                          ),
                        ),
                        SketchCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          borderRadius: 6,
                          borderWidth: 1.4,
                          shadowOffset: const Offset(1.0, 1.0),
                          backgroundColor: zonePillBg,
                          borderColor: zonePillColor,
                          child: Text(
                            zonePillText,
                            style: GoogleFonts.patrickHand(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: zonePillColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Sıralaman: #$rank · $score LP',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        color: AppColors.graphite(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // El çizimi ilerleme çubuğu
          _SketchHandDrawnProgressBar(league: league),

          const SizedBox(height: 8),

          // Alt bilgi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: AppColors.gray(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${leagueDaysRemaining()} kaldı',
                    style: GoogleFonts.patrickHand(
                      fontSize: 12,
                      color: AppColors.gray(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (!level.isMax && level.next != null)
                Text(
                  'İlk 10 → ${level.next!.displayName} Ligi',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    color: AppColors.gray(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// YARDIMCI SKEÇ MİNİ ROZET
// ============================================================================

class _SketchMiniBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const _SketchMiniBadge({
    required this.text,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLightBg = backgroundColor.computeLuminance() > 0.35;
    final contentColor = isLightBg ? AppColors.inkBlack : AppColors.inkWhite;
    final borderColor = isLightBg
        ? AppColors.pencilBlack
        : (isDark ? AppColors.pencilWhite.withValues(alpha: 0.5) : AppColors.pencilBlack);
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.6) : AppColors.pencilBlack;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.patrickHand(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: contentColor,
        ),
      ),
    );
  }
}

// ============================================================================
// 8. LİG GEÇİŞ KUTLAMA / BİLDİRİM BANNERI (Hand-Drawn Transition Banner)
// ============================================================================

class _SketchLeagueTransitionBanner extends StatelessWidget {
  final LeagueState league;
  final VoidCallback onDismiss;

  const _SketchLeagueTransitionBanner({
    required this.league,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isPromotion = league.pendingPromotion != null;
    final level = league.currentLevel;

    final bgColor = isPromotion ? const Color(0xFFDCFCE7) : AppColors.errorBgLight;
    final title = isPromotion
        ? 'TEBRİKLER! BİR ÜST LİGE YÜKSELDİN! 🎉'
        : 'DİKKAT! BİR ALT LİGE GERİLEDİN ⚠️';
    final desc = isPromotion
        ? 'Geçen haftayı ilk 10 sırada tamamlayarak ${level.emoji} ${level.displayName} Ligine terfi ettin!'
        : 'Geçen haftayı son 10 sırada bitirdiğin için ${level.emoji} ${level.displayName} Ligine geriledin. Bu hafta puanları topla ve geri dön!';

    return SketchCard(
      enableHatching: true,
      backgroundColor: bgColor,
      borderColor: AppColors.pencilBlack,
      borderWidth: 2.4,
      borderRadius: 14,
      shadowOffset: const Offset(3.5, 3.5),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isPromotion)
                const SketchDoodleCrown(
                  size: 26,
                  color: AppColors.pencilBlack,
                  fillColor: AppColors.sunYellow,
                )
              else
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 26,
                  color: AppColors.error,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.patrickHand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.patrickHand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SketchCard(
              onTap: onDismiss,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              borderRadius: 8,
              borderWidth: 1.8,
              shadowOffset: const Offset(1.5, 1.5),
              backgroundColor: isPromotion ? AppColors.sunYellow : Colors.white,
              child: Text(
                isPromotion ? 'Harika! 🚀' : 'Anladım 👍',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pencilBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
