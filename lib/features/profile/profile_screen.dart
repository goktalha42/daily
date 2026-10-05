import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/network_checker.dart';
import '../../core/services/game_stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../games/common/base_game.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkCheckerProvider);
    final statsMap = ref.watch(gameStatsServiceProvider);
    final statsNotifier = ref.read(gameStatsServiceProvider.notifier);
    final userIQ = statsNotifier.getOverallIQ();

    // Toplam istatistik hesaplamaları
    int totalPlayed = 0;
    int totalScore = 0;
    for (var perf in statsMap.values) {
      totalPlayed += perf.totalGamesPlayed;
      totalScore += perf.bestScore;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. ÜST BAŞLIK
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 54, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.highlighterPurple,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.pencilBlack, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KİŞİSEL GELİŞİM RAPORU',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGraphite,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profil',
                      style: GoogleFonts.patrickHand(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pencilBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Skeç Seviye Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.highlighterPurple,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.pencilBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_rounded, size: 18, color: AppColors.pencilBlack),
                      const SizedBox(width: 4),
                      Text(
                        'LVL 7',
                        style: GoogleFonts.patrickHand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pencilBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. FOTOĞRAFTAKİ GİBİ SKEÇ KİMLİK KARTI & %92 ÇEMBER GÖSTERGESİ
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SketchCard(
              enableHatching: true,
              borderRadius: 16,
              borderWidth: 2.5,
              shadowOffset: const Offset(4.0, 4.0),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Sol: Fotoğraftaki Çapraz X'li Avatar Kutusu
                      const SketchPlaceholderBox(
                        width: 64,
                        height: 64,
                        fillColor: AppColors.highlighterYellow,
                        lineColor: AppColors.pencilBlack,
                        borderRadius: 12,
                        child: Center(
                          child: SketchDoodleCrown(
                            size: 32,
                            color: AppColors.pencilBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Kullanıcı Bilgisi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Dahi #8492',
                                  style: GoogleFonts.patrickHand(
                                    color: AppColors.pencilBlack,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.highlighterYellow,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                                  ),
                                  child: Text(
                                    'SİZ',
                                    style: GoogleFonts.patrickHand(
                                      color: AppColors.pencilBlack,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isOnline ? '🟢 Canlı Sıralamaya Bağlı' : '🔴 Çevrimdışı (Yerel Kayıt)',
                              style: GoogleFonts.patrickHand(
                                color: isOnline ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.highlighterCyan,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                              ),
                              child: Text(
                                '⚡ KÜRESEL İLK %1 STATÜSÜ',
                                style: GoogleFonts.patrickHand(
                                  color: AppColors.pencilBlack,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // FOTOĞRAFTAKİ EN MEŞHUR DETAY: El Çizimi %92 Çember Göstergesi & IQ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.pencilBlack, width: 1.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Dairesel %92 Göstergesi (Tam fotoğraftaki gibi!)
                        SketchCircularDoodle(
                          size: 72,
                          percentage: 92,
                          strokeColor: AppColors.pencilBlack,
                          fillColor: AppColors.highlighterCyan,
                          centerChild: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '%92',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Açıklama
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GENEL BAŞARI & IQ ENDEKSİ',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'IQ $userIQ+ (Üstün Zekâ)',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Dünya ortalamasından 4.2 kat daha hızlı!',
                              style: GoogleFonts.patrickHand(
                                color: AppColors.pencilGraphite,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. KARA KALEM İSTATİSTİK 4'LÜ IZGARASI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.local_fire_department_rounded,
                    fillColor: AppColors.highlighterOrange,
                    title: 'GÜNLÜK SERİ',
                    value: '5 Gün',
                    subtitle: 'Kesintisiz Odak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.sports_esports_rounded,
                    fillColor: AppColors.highlighterCyan,
                    title: 'ÇÖZÜLEN OYUN',
                    value: '$totalPlayed Bölüm',
                    subtitle: 'Tamamlandı',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.speed_rounded,
                    fillColor: AppColors.highlighterPurple,
                    title: 'ORT. REAKSİYON',
                    value: '38 sn',
                    subtitle: '4.2x Işık Hızı',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SketchMetricBox(
                    icon: Icons.military_tech_rounded,
                    fillColor: AppColors.highlighterYellow,
                    title: 'TOPLAM PUAN',
                    value: '$totalScore P',
                    subtitle: 'Zirve Sıralama',
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. OYUN BAZLI ZEKA ANALİZİ BAŞLIĞI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
            child: Row(
              children: [
                Text(
                  'OYUN BAZLI SKEÇ KARNESİ',
                  style: GoogleFonts.patrickHand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. 5 OYUNUN SKEÇ PERFORMANS LİSTESİ
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = GameType.values[index];
                final perf = statsMap[game] ??
                    GamePerformanceData(
                      gameType: game,
                      bestScore: 0,
                      bestDurationMs: 0,
                      totalGamesPlayed: 0,
                      geniusTitle: 'Saf Dahi',
                    );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.pencilBlack,
                          offset: Offset(2.5, 2.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Fotoğraftaki gibi çapraz X'li skeç oyun kutusu
                        SketchPlaceholderBox(
                          width: 44,
                          height: 44,
                          fillColor: game.color,
                          lineColor: AppColors.pencilBlack,
                          borderRadius: 8,
                          child: Icon(game.icon, color: AppColors.pencilBlack, size: 22),
                        ),
                        const SizedBox(width: 12),

                        // Oyun Adı ve Durum
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: GoogleFonts.patrickHand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pencilBlack,
                                ),
                              ),
                              Text(
                                perf.hasPlayed
                                    ? 'En İyi: ${GameDateUtils.formatGameTime(perf.bestDurationMs)} • ${perf.bestScore} Puan'
                                    : 'Henüz bugün çözülmedi',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pencilGray,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Skeç Yüzdelik Rozeti
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: perf.hasPlayed
                                ? (perf.percentile! <= 1
                                    ? AppColors.highlighterYellow
                                    : game.color)
                                : AppColors.surfaceSecondaryLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.pencilBlack, width: 1.5),
                          ),
                          child: Text(
                            perf.hasPlayed
                                ? (perf.percentile! <= 1 ? '👑 %1' : '%${perf.percentile}')
                                : 'HEDEF %1',
                            style: GoogleFonts.patrickHand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pencilBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: GameType.values.length,
            ),
          ),
        ),

        // 6. DAHİ ROZETLERİ (BAŞARIMLAR)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 8),
            child: Row(
              children: [
                Text(
                  'KAZANILAN SKEÇ ROZETLERİ',
                  style: GoogleFonts.patrickHand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pencilGraphite,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            height: 95,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: const [
                _SketchBadgeCard(
                  icon: Icons.bolt_rounded,
                  title: 'Işık Hızı',
                  desc: '< 40 sn Çözüm',
                  fillColor: AppColors.highlighterYellow,
                  isUnlocked: true,
                ),
                _SketchBadgeCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Ateşli Zihin',
                  desc: '5 Günlük Seri',
                  fillColor: AppColors.highlighterOrange,
                  isUnlocked: true,
                ),
                _SketchBadgeCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Zirve %1',
                  desc: 'Global Dahi',
                  fillColor: AppColors.highlighterGreen,
                  isUnlocked: true,
                ),
                _SketchBadgeCard(
                  icon: Icons.military_tech_rounded,
                  title: 'Büyük Usta',
                  desc: '5 Oyunu Çöz',
                  fillColor: AppColors.highlighterPurple,
                  isUnlocked: false,
                ),
              ],
            ),
          ),
        ),

        // 7. BİLGİLENDİRME & SİSTEM NOTU
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.pencilBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pencilBlack,
                    offset: Offset(2.5, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.pencilBlack, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tüm oyunların seviyeleri her gece 00:00\'da yenilenir. Günlük serinizi korumak için her gün en az 1 oyun tamamlayın.',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        color: AppColors.pencilGraphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120), // Floating nav bar için pay
        ),
      ],
    );
  }
}

class _SketchMetricBox extends StatelessWidget {
  final IconData icon;
  final Color fillColor;
  final String title;
  final String value;
  final String subtitle;

  const _SketchMetricBox({
    required this.icon,
    required this.fillColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SketchCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      borderWidth: 2.0,
      shadowOffset: const Offset(2.5, 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.pencilBlack, width: 1.5),
            ),
            child: Icon(icon, color: AppColors.pencilBlack, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.patrickHand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.pencilGray,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.patrickHand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.pencilBlack,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.patrickHand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.pencilGraphite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchBadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color fillColor;
  final bool isUnlocked;

  const _SketchBadgeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.fillColor,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.pencilBlack,
          width: 1.8,
        ),
        boxShadow: isUnlocked
            ? const [
                BoxShadow(
                  color: AppColors.pencilBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isUnlocked ? fillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.pencilBlack, width: 1.2),
                ),
                child: Icon(icon, color: AppColors.pencilBlack, size: 18),
              ),
              Icon(
                isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: isUnlocked ? const Color(0xFF15803D) : AppColors.pencilGray,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.patrickHand(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.pencilBlack,
            ),
          ),
          Text(
            desc,
            style: GoogleFonts.patrickHand(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.pencilGray,
            ),
          ),
        ],
      ),
    );
  }
}


