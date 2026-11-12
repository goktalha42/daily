import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/league_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/sketch_badge_icons.dart';
import '../../core/widgets/sketch_decorations.dart';
import '../../core/widgets/sketch_league_emblems.dart';
import '../../games/common/base_game.dart';
import '../profile/profile_screen.dart';

/// Zühtü - İlk Açılış Karşılama ve Tanıtım Turu (Onboarding Walkthrough).
/// 5 adet sade, el çizimi ve samimi slayt ile oyunu tanıtır:
/// 1. Günde Sadece 10 Dakika (Sosyal medyada kaydırma, zihnini aç)
/// 2. Her Gece 00:00'da 6 Yeni Oyun (Tüm Türkiye aynı anda çözer)
/// 3. Puanını ve Zeka Skorunu Gör (Hızlı ve az hatayla çöz, resmi test değil eğlenceli zihin aynası)
/// 4. Ateşi Söndürme: Serini Koru (Her gün en az 1 oyun bitirerek serini büyüt)
/// 5. Liglerde yarış ve rozetleri topla (42 kişilik lig, ilk 10 terfi, rozetler ve paylaşım)
class OnboardingScreen extends StatefulWidget {
  final bool isRevisit;

  const OnboardingScreen({super.key, this.isRevisit = false});

  static const String completedPrefKey = 'zuhtu_onboarding_completed_v1';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.completedPrefKey, true);
    } catch (e) {
      debugPrint('[OnboardingScreen] Tercih kaydetme hatası: $e');
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor =
        isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SketchPaperBackground(
          child: Column(
            children: [
              // 1. ÜST BAR: ZÜHTÜ LOGO & ATLA/KAPAT BUTONU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SketchCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      borderRadius: 10,
                      borderWidth: 1.6,
                      shadowOffset: const Offset(1.5, 1.5),
                      backgroundColor: AppColors.sunYellow,
                      borderColor: pencilColor,
                      child: Row(
                        children: [
                          const Text('🧠', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            'ZÜHTÜ REHBERİ',
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        widget.isRevisit ? 'Kapat' : 'Atla',
                        style: GoogleFonts.patrickHand(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: graphiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 5 SLAYT (PAGEVIEW)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildSlide1(isDark: isDark, pencilColor: pencilColor),
                    _buildSlide2(isDark: isDark, pencilColor: pencilColor),
                    _buildSlide3(isDark: isDark, pencilColor: pencilColor),
                    _buildSlide4(isDark: isDark, pencilColor: pencilColor),
                    _buildSlide5(isDark: isDark, pencilColor: pencilColor),
                  ],
                ),
              ),

              // 3. ALT KONTROLLER: 5 NOkTA GÖSTERGESİ & EYLEM BUTONU
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Doodle Nokta Göstergeleri (5 Nokta)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 26 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.sunYellow
                                : (isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isActive
                                  ? pencilColor
                                  : pencilColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Büyük Eylem Butonu
                    SketchCard(
                      onTap: _nextPage,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: _currentPage == _totalPages - 1
                          ? AppColors.sunYellow
                          : (isDark
                              ? AppColors.surfaceDark
                              : Colors.white),
                      borderColor: pencilColor,
                      borderWidth: 2.4,
                      borderRadius: 16,
                      shadowOffset: const Offset(3.5, 3.5),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _totalPages - 1
                                  ? (widget.isRevisit
                                      ? 'Rehberi Tamamla ✨'
                                      : 'Zühtü\'ye Başla! 🚀')
                                  : 'Devam Et',
                              style: GoogleFonts.patrickHand(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _currentPage == _totalPages - 1
                                    ? AppColors.inkBlack
                                    : pencilColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _totalPages - 1
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                              color: _currentPage == _totalPages - 1
                                  ? AppColors.inkBlack
                                  : pencilColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SLAYT 1: GÜNDE SADECE 10 DAKİKA
  // ===========================================================================
  Widget _buildSlide1({required bool isDark, required Color pencilColor}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // El Çizimi 10 Dakikalık Kronometre İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleStopwatchPainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Günde Sadece\n10 Dakika!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: pencilColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Sosyal medyada saatlerce amaçsızca kaydırmak yerine, günde sadece 10 dakikanı zihnini çalıştırmaya ayır.',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16.5,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 20),

          // Alt Skeç Kutusu
          SketchCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 14,
            borderWidth: 1.8,
            shadowOffset: const Offset(2.5, 2.5),
            backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFFEF9C3),
            borderColor: pencilColor,
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sabah kahveni yudumlarken, otobüste veya kısa bir molada... Zihnini zinde tutmak bu kadar kolay!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pencilWhite : const Color(0xFF854D0E),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLAYT 2: HER GECE 00:00'DA 6 YENİ OYUN
  // ===========================================================================
  Widget _buildSlide2({required bool isDark, required Color pencilColor}) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // El Çizimi Gece Çalar Saati & Ay İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleMidnightClockPainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Her Gece 00:00\'da\n6 Yeni Oyun',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: pencilColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Her gece yarısı tüm Türkiye için yepyeni 6 oyun açılır. Herkes aynı gün aynı bulmacaları çözer!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16.5,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 16),

          // 6 Oyunun Minik Vitrini (2x3 Izgara — Ana sayfadaki gerçek oyun isimleri)
          SketchCard(
            padding: const EdgeInsets.all(10),
            borderRadius: 14,
            borderWidth: 1.8,
            shadowOffset: const Offset(2.5, 2.5),
            backgroundColor: cardBg,
            borderColor: pencilColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.queens,
                        title: GameType.queens.title,
                        desc: 'Strateji',
                        color: AppColors.queensGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.pinpoint,
                        title: GameType.pinpoint.title,
                        desc: 'Çağrışım',
                        color: AppColors.pinpointGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.crossclimb,
                        title: GameType.crossclimb.title,
                        desc: 'Kelime Dağarcığı',
                        color: AppColors.crossclimbGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.tango,
                        title: GameType.tango.title,
                        desc: 'Akıl Yürütme',
                        color: AppColors.tangoGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.zipPath,
                        title: GameType.zipPath.title,
                        desc: 'İşlem Hafızası',
                        color: AppColors.zipGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniGamePill(
                        game: GameType.patches,
                        title: GameType.patches.title,
                        desc: 'Şekil Mantığı',
                        color: AppColors.patchesGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLAYT 3: PUANINI VE SKORUNU GÖR
  // ===========================================================================
  Widget _buildSlide3({required bool isDark, required Color pencilColor}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // El Çizimi Gülen Beyin & Hız Göstergesi İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleBrainGaugePainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Puanını ve Zeka\nSkorunu Gör',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: pencilColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Bulmacaları ne kadar hızlı ve az hatayla bitirirsen, o kadar yüksek puan ve zeka skoru kazanırsın!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16.5,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 18),

          // Alçakgönüllü & Samimi Not Kutusu
          SketchCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 14,
            borderWidth: 1.8,
            shadowOffset: const Offset(2.5, 2.5),
            backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF3E8FF),
            borderColor: pencilColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'ZÜHTÜ SKORU NEDİR?',
                      style: GoogleFonts.patrickHand(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.sunYellow : const Color(0xFF6B21A8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Resmi bir tıp veya klinik testi değil tabii ki! Günlük bulmaca performansına göre kafanın ne kadar zehir gibi çalıştığını gösteren eğlenceli bir zihin aynası 😉',
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    color: isDark ? AppColors.pencilWhite : const Color(0xFF581C87),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLAYT 4: ATEŞİ SÖNDÜRME: SERİNİ KORU
  // ===========================================================================
  Widget _buildSlide4({required bool isDark, required Color pencilColor}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // El Çizimi Alev & Takvim İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleStreakCalendarPainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Ateşi Söndürme:\nSerini Koru!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: pencilColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Her gün en az 1 oyun bitirerek serini devam ettir. Bir gün bile atlarsan serin sıfırlanır, ona göre!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16.5,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 18),

          // İpucu Kartı
          SketchCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 14,
            borderWidth: 1.8,
            shadowOffset: const Offset(2.5, 2.5),
            backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFFEF3C7),
            borderColor: pencilColor,
            child: Row(
              children: [
                SketchDoodleFlame(
                  size: 30,
                  color: pencilColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'İster yoğun bir gününde sadece 1 oyun çöz, ister hepsini bitir. Önemli olan zinciri kırmamak ve her gün zihnini tazelemek!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pencilWhite : const Color(0xFF92400E),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLAYT 5: LİGLERDE YARIŞ & ARKADAŞLARINA HAVA AT
  // ===========================================================================
  Widget _buildSlide5({required bool isDark, required Color pencilColor}) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Kupa İçinden Taşan Profil Rozetleri İllüstrasyonu
          Center(
            child: _buildOverflowingBadgesCup(
              isDark: isDark,
              pencilColor: pencilColor,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Liglerde yarış ve\nrozetleri topla',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: pencilColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Haftalık ligde 42 kişiyle yarış, ilk 10\'a girerek üst lige terfi et! Şık el çizimi karne kartını WhatsApp\'tan paylaşarak arkadaşlarına meydan oku.',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 16),

          // 5 Lig Kademesi Şeridi
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            borderRadius: 14,
            borderWidth: 1.8,
            shadowOffset: const Offset(2.5, 2.5),
            backgroundColor: cardBg,
            borderColor: pencilColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HAFTALIK LİG KADEMELERİ:',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: pencilColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTierBadge(LeagueLevel.bronze, 'Bronz', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.pencilGraphite),
                    _buildTierBadge(LeagueLevel.silver, 'Gümüş', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.pencilGraphite),
                    _buildTierBadge(LeagueLevel.gold, 'Altın', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.pencilGraphite),
                    _buildTierBadge(LeagueLevel.diamond, 'Elmas', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.pencilGraphite),
                    _buildTierBadge(LeagueLevel.champion, 'Dâhi', pencilColor),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // WhatsApp Meydan Okuma Kutusu
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            borderRadius: 12,
            borderWidth: 1.6,
            shadowOffset: const Offset(2, 2),
            backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFE0F2FE),
            borderColor: pencilColor,
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bakalım arkadaşların senin çözüm süreni geçebilecek mi? WhatsApp\'tan tek tıkla kartını gönder!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pencilWhite : const Color(0xFF0369A1),
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGamePill({
    required GameType game,
    required String title,
    required String desc,
    required Color color,
    required Color pencilColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.35 : 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pencilColor, width: 1.4),
      ),
      child: Row(
        children: [
          SketchCard(
            padding: EdgeInsets.zero,
            borderRadius: 7,
            borderWidth: 1.4,
            shadowOffset: const Offset(1.0, 1.0),
            backgroundColor: color,
            borderColor: AppColors.pencilBlack,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: GameSketchThumbnail(
                  game: game,
                  size: 20,
                  pencilColor: AppColors.pencilBlack,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.patrickHand(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: pencilColor,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  desc,
                  maxLines: 1,
                  style: GoogleFonts.patrickHand(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.pencilWhite.withValues(alpha: 0.7)
                        : AppColors.pencilGraphite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverflowingBadgesCup({
    required bool isDark,
    required Color pencilColor,
  }) {
    Widget badgeCoin(BadgeArtType type, Color bgColor, double size) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? bgColor.withValues(alpha: 0.9) : bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: pencilColor, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: pencilColor.withValues(alpha: 0.35),
              offset: const Offset(1.2, 1.2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: SketchBadgeIcon(
            type: type,
            size: size * 0.62,
            strokeColor: AppColors.pencilBlack,
          ),
        ),
      );
    }

    return SizedBox(
      width: 156,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Arka Plan: Kupa kulpları, ayak ve ağız içi derinliği
          Positioned.fill(
            child: CustomPaint(
              painter: _DoodleCupBackPainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          // 2. Kupanın içindeki alt sıra rozetler (ön duvarın arkasında kalır)
          Positioned(
            left: 42,
            top: 33,
            child: badgeCoin(BadgeArtType.sprout, const Color(0xFFD1FAE5), 24),
          ),
          Positioned(
            left: 66,
            top: 30,
            child: badgeCoin(BadgeArtType.rocket, const Color(0xFFE0F2FE), 25),
          ),
          Positioned(
            left: 91,
            top: 33,
            child: badgeCoin(BadgeArtType.diamondGem, const Color(0xFFDBEAFE), 24),
          ),

          // 3. Kupanın ön altın gövdesi ve ağız kenarı
          Positioned.fill(
            child: CustomPaint(
              painter: _DoodleCupFrontPainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          // 4. Ağızdan dışarı taşan orta ve tepe rozet yığını
          Positioned(
            left: 48,
            top: 16,
            child: badgeCoin(BadgeArtType.einsteinBrain, const Color(0xFFEDE9FE), 25),
          ),
          Positioned(
            left: 81,
            top: 15,
            child: badgeCoin(BadgeArtType.lightning, const Color(0xFFFFEDD5), 25),
          ),
          Positioned(
            left: 64,
            top: 2,
            child: badgeCoin(BadgeArtType.royalCrown, AppColors.sunYellow, 28),
          ),

          // 5. Kenarlardan taşan ve aşağı sıçrayan rozetler
          Positioned(
            left: 22,
            top: 23,
            child: badgeCoin(BadgeArtType.queenPiece, const Color(0xFFFCE7F3), 22),
          ),
          Positioned(
            left: 112,
            top: 22,
            child: badgeCoin(BadgeArtType.mortarboard, const Color(0xFFFEF3C7), 22),
          ),
          Positioned(
            left: 22,
            top: 79,
            child: badgeCoin(BadgeArtType.sparkFlame, const Color(0xFFFFEDD5), 21),
          ),
          Positioned(
            left: 112,
            top: 78,
            child: badgeCoin(BadgeArtType.hexagramStar, const Color(0xFFFEF9C3), 21),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(LeagueLevel level, String name, Color pencilColor) {
    return Column(
      children: [
        SketchLeagueCrestMedallion(
          level: level,
          size: 36,
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: GoogleFonts.patrickHand(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: pencilColor,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ÖZEL EL ÇİZİMİ VEKTÖR RESMEDİCİLERİ (DOODLE CUSTOM PAINTERS)
// =============================================================================

/// 1. Slayt İllüstrasyonu: 10 Dakikayı Gösteren El Çizimi Kronometre
class _DoodleStopwatchPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleStopwatchPainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const center = Offset(60, 56);
    const double outerR = 34.0;
    const double dialR = 27.0;

    // Tepe Başlatma Düğmesi (Boyun + Taç)
    canvas.drawRect(
      const Rect.fromLTWH(55, 13, 10, 8),
      Paint()
        ..color = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(const Rect.fromLTWH(55, 13, 10, 8), pen..strokeWidth = 1.8);

    final crownRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 7, 20, 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      crownRect,
      Paint()
        ..color = AppColors.sunYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(crownRect, pen);

    // Sağ Üst Yan Sıfırlama Düğmesi (45 derece)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    final sideBtn = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-4, -outerR - 8, 8, 8),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      sideBtn,
      Paint()
        ..color = const Color(0xFFF97316)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(sideBtn, pen..strokeWidth = 1.6);
    canvas.restore();

    // Kronometre Dış Kasası
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = AppColors.sunYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, outerR, pen..strokeWidth = 2.4);

    // Kadran Zemini
    canvas.drawCircle(
      center,
      dialR,
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill,
    );

    // 10 Dakikalık Dilim Vurgusu (Saat 12'den Saat 2'ye = 60 derece = pi/3)
    final slicePaint = Paint()
      ..color = AppColors.sunYellow.withValues(alpha: isDark ? 0.55 : 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: dialR - 1),
      -math.pi / 2,
      math.pi / 3,
      true,
      slicePaint,
    );

    canvas.drawCircle(center, dialR, pen..strokeWidth = 1.8);

    // 12 adet saat/dakika çizgisi (5'er dakikalık aralıklar)
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 6);
      final isMajor = i == 0 || i == 2 || i == 3 || i == 6 || i == 9;
      final rStart = isMajor ? dialR - 6 : dialR - 3.5;
      final p1 = Offset(
        center.dx + rStart * math.cos(angle),
        center.dy + rStart * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (dialR - 1) * math.cos(angle),
        center.dy + (dialR - 1) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, pen..strokeWidth = isMajor ? 2.0 : 1.2);
    }

    // 10 Dakikayı Gösteren İbre (Saat 2 yönü = -pi/6)
    const double handAngle = -math.pi / 6;
    final handTip = Offset(
      center.dx + (dialR - 6) * math.cos(handAngle),
      center.dy + (dialR - 6) * math.sin(handAngle),
    );
    canvas.drawLine(
      center,
      handTip,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      3.4,
      Paint()
        ..color = pencilColor
        ..style = PaintingStyle.fill,
    );

    // Kadran Altında Net "10 dk" Etiketi
    final tp = TextPainter(
      text: TextSpan(
        text: '10 dk',
        style: GoogleFonts.patrickHand(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: pencilColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 6));

    // Parıltı ve Hareket Çizgileri
    _drawSparkle(canvas, const Offset(16, 30), AppColors.sunYellow);
    _drawSparkle(canvas, const Offset(104, 72), pencilColor);
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(center.dx - 4, center.dy), Offset(center.dx + 4, center.dy), p);
    canvas.drawLine(
        Offset(center.dx, center.dy - 4), Offset(center.dx, center.dy + 4), p);
  }

  @override
  bool shouldRepaint(covariant _DoodleStopwatchPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}

/// 2. Slayt İllüstrasyonu: El Çizimi Gece Çalar Saati (00:00) & Hilal Ay
class _DoodleMidnightClockPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleMidnightClockPainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final clockFill = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;

    const center = Offset(52, 54);
    const double radius = 32.0;

    // Saat Gövdesi Çemberi
    canvas.drawCircle(center, radius, clockFill);
    canvas.drawCircle(center, radius, pen);

    // Saatin Üst Zilleri (İki çan)
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(28, 28), radius: 10),
      math.pi * 0.8,
      math.pi,
      false,
      pen,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(76, 28), radius: 10),
      math.pi * 1.2,
      math.pi,
      false,
      pen,
    );

    // Saatin Ayakları
    canvas.drawLine(const Offset(32, 82), const Offset(24, 94), pen);
    canvas.drawLine(const Offset(72, 82), const Offset(80, 94), pen);

    // Akrep ve Yelkovan tam gece yarısı 00:00 (Yukarı dimdik)
    final handPaint = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, const Offset(52, 30), handPaint);
    canvas.drawLine(center, const Offset(52, 36), handPaint..strokeWidth = 3.2);
    canvas.drawCircle(
        center, 3.5, Paint()..color = pencilColor..style = PaintingStyle.fill);

    // Zil Titreşim Çizgileri
    canvas.drawLine(const Offset(16, 22), const Offset(12, 16), pen..strokeWidth = 1.4);
    canvas.drawLine(const Offset(88, 22), const Offset(92, 16), pen..strokeWidth = 1.4);

    // Sağda Gülen Hilal Ay
    final moonFill = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;
    final moonPen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final moonPath = Path();
    moonPath.moveTo(95, 20);
    moonPath.cubicTo(80, 30, 80, 65, 98, 75);
    moonPath.cubicTo(88, 62, 88, 35, 95, 20);
    moonPath.close();

    canvas.drawPath(moonPath, moonFill);
    canvas.drawPath(moonPath, moonPen);

    // Gece Yıldızları
    _drawStar(canvas, const Offset(110, 30), AppColors.sunYellow);
    _drawStar(canvas, const Offset(105, 84), pencilColor);
  }

  void _drawStar(Canvas canvas, Offset center, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(center.dx - 5, center.dy), Offset(center.dx + 5, center.dy), p);
    canvas.drawLine(
        Offset(center.dx, center.dy - 5), Offset(center.dx, center.dy + 5), p);
  }

  @override
  bool shouldRepaint(covariant _DoodleMidnightClockPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}

/// 3. Slayt İllüstrasyonu: Tatlı, Güler Yüzlü Zeki Beyin
class _DoodleBrainGaugePainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleBrainGaugePainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Yumuşak pastel pembe dolgu (zombi moru yerine sıcak ve sevimli)
    final brainFill = Paint()
      ..color = isDark ? const Color(0xFFBE185D) : const Color(0xFFFCE7F3)
      ..style = PaintingStyle.fill;

    // Tatlı, tombul ve yuvarlak hatlı chibi beyin silueti
    final brainPath = Path();
    brainPath.moveTo(60, 22);
    // Üst sol kıvrım -> sol yanak -> alt sol
    brainPath.cubicTo(48, 16, 33, 21, 30, 34);
    brainPath.cubicTo(19, 40, 19, 59, 29, 67);
    brainPath.cubicTo(31, 79, 48, 84, 60, 80);
    // Alt sağ -> sağ yanak -> üst sağ kıvrım
    brainPath.cubicTo(72, 84, 89, 79, 91, 67);
    brainPath.cubicTo(101, 59, 101, 40, 90, 34);
    brainPath.cubicTo(87, 21, 72, 16, 60, 22);
    brainPath.close();

    canvas.drawPath(brainPath, brainFill);

    // Alt gölge bandı (hacim hissi)
    final shadePaint = Paint()
      ..color = isDark
          ? const Color(0xFF9D174D).withValues(alpha: 0.45)
          : const Color(0xFFFBCFE8).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final shadePath = Path()
      ..moveTo(32, 68)
      ..cubicTo(42, 79, 78, 79, 88, 68)
      ..cubicTo(82, 78, 68, 82, 60, 79)
      ..cubicTo(52, 82, 38, 78, 32, 68)
      ..close();
    canvas.drawPath(shadePath, shadePaint);

    canvas.drawPath(brainPath, pen);

    // Yüzün etrafında nazik, kısa beyin kıvrımları (yüzü kalabalıklaştırmadan)
    final softFoldPen = Paint()
      ..color = pencilColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Üst ortadaki minik ayrım
    canvas.drawPath(
      Path()
        ..moveTo(60, 22)
        ..quadraticBezierTo(58, 29, 60, 34),
      softFoldPen,
    );
    // Sol ve sağ üst minik kıvrımlar
    canvas.drawPath(
      Path()
        ..moveTo(39, 31)
        ..quadraticBezierTo(45, 29, 49, 34),
      softFoldPen,
    );
    canvas.drawPath(
      Path()
        ..moveTo(81, 31)
        ..quadraticBezierTo(75, 29, 71, 34),
      softFoldPen,
    );

    // Pembe allıklar (sevimli yanaklar)
    final cheekPaint = Paint()
      ..color = isDark
          ? const Color(0xFFF472B6).withValues(alpha: 0.65)
          : const Color(0xFFFB7185).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(39, 57), width: 10, height: 6),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(81, 57), width: 10, height: 6),
      cheekPaint,
    );

    // Parlak, gülen büyük sevimli gözler
    final eyeFill = Paint()
      ..color = pencilColor
      ..style = PaintingStyle.fill;
    final eyeShine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(47, 49), 3.6, eyeFill);
    canvas.drawCircle(const Offset(73, 49), 3.6, eyeFill);
    canvas.drawCircle(const Offset(45.8, 47.7), 1.3, eyeShine);
    canvas.drawCircle(const Offset(71.8, 47.7), 1.3, eyeShine);

    // Sıcak, mutlu gülümseme
    final smilePen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(52, 57)
        ..quadraticBezierTo(60, 65, 68, 57),
      smilePen,
    );

    // Baş üstünde ve yanlarda neşeli pırıltılar & minik yıldızlar
    final sparklePen = Paint()
      ..color = AppColors.sunYellow
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawSparkle(Offset c, double r) {
      canvas.drawLine(
          Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), sparklePen);
      canvas.drawLine(
          Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), sparklePen);
    }

    drawSparkle(const Offset(16, 30), 4.5);
    drawSparkle(const Offset(104, 34), 4.5);
    drawSparkle(const Offset(60, 10), 3.8);

    // Yanlarda minik neşe noktaları
    canvas.drawCircle(const Offset(14, 60), 2.2, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(const Offset(106, 62), 2.2, Paint()..color = const Color(0xFFFB7185));
  }

  @override
  bool shouldRepaint(covariant _DoodleBrainGaugePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}

/// 4. Slayt İllüstrasyonu: Çıtırdayan Alev & Takvim Tikleri (Seri)
class _DoodleStreakCalendarPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleStreakCalendarPainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Solda Çıtırdayan El Çizimi Alev
    final flameOuter = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;
    final flameInner = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;

    final flamePath = Path();
    flamePath.moveTo(34, 86);
    flamePath.cubicTo(14, 86, 12, 60, 24, 48);
    flamePath.cubicTo(20, 36, 30, 22, 36, 14);
    flamePath.cubicTo(42, 28, 54, 34, 48, 52);
    flamePath.cubicTo(56, 62, 52, 86, 34, 86);
    flamePath.close();

    canvas.drawPath(flamePath, flameOuter);
    canvas.drawPath(flamePath, pen);

    // İç Alev Çekirdeği
    final innerFlame = Path();
    innerFlame.moveTo(34, 82);
    innerFlame.cubicTo(22, 82, 22, 65, 30, 56);
    innerFlame.cubicTo(32, 46, 36, 38, 36, 34);
    innerFlame.cubicTo(40, 42, 46, 48, 42, 60);
    innerFlame.cubicTo(46, 68, 44, 82, 34, 82);
    innerFlame.close();
    canvas.drawPath(innerFlame, flameInner);
    canvas.drawPath(innerFlame, pen..strokeWidth = 1.4);

    // Sağda Takvim Kağıdı
    final calBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;

    final calRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(62, 26, 48, 58),
      const Radius.circular(8),
    );
    canvas.drawRRect(calRect, calBg);
    canvas.drawRRect(calRect, pen..strokeWidth = 2.0);

    // Takvim Üst Kırmızı Bandı
    final calTop = RRect.fromRectAndCorners(
      Rect.fromLTWH(62, 26, 48, 14),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(
        calTop,
        Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.fill);
    canvas.drawRRect(calTop, pen..strokeWidth = 1.8);

    // Takvim Spiral Halkaları (2 halka)
    canvas.drawLine(const Offset(72, 20), const Offset(72, 28), pen..strokeWidth = 2.4);
    canvas.drawLine(const Offset(98, 20), const Offset(98, 28), pen..strokeWidth = 2.4);

    // Takvim Üzerindeki Yeşil El Çizimi Tikler (✓)
    final checkPaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Tik 1
    final t1 = Path()
      ..moveTo(70, 50)
      ..lineTo(74, 54)
      ..lineTo(80, 46);
    canvas.drawPath(t1, checkPaint);

    // Tik 2
    final t2 = Path()
      ..moveTo(88, 50)
      ..lineTo(92, 54)
      ..lineTo(98, 46);
    canvas.drawPath(t2, checkPaint);

    // Tik 3
    final t3 = Path()
      ..moveTo(78, 68)
      ..lineTo(82, 72)
      ..lineTo(90, 64);
    canvas.drawPath(t3, checkPaint);

    // Kıvılcım Karalamaları
    canvas.drawCircle(const Offset(14, 38), 2.0, Paint()..color = const Color(0xFFF97316));
    canvas.drawCircle(const Offset(54, 22), 2.5, Paint()..color = AppColors.sunYellow);
  }

  @override
  bool shouldRepaint(covariant _DoodleStreakCalendarPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}

/// 5. Slayt İllüstrasyonu (Arka Katman): Kupa Kulpları, Ayak ve Ağız İçi Derinliği
class _DoodleCupBackPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleCupBackPainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2; // 78.0

    // Kupa ağız içi (koyu altın/amber derinlik)
    final innerMouthRect = Rect.fromCenter(
      center: Offset(cx, 44),
      width: 86,
      height: 18,
    );
    canvas.drawOval(
      innerMouthRect,
      Paint()
        ..color = isDark ? const Color(0xFF78350F) : const Color(0xFFD97706)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(innerMouthRect, pen..strokeWidth = 2.0);

    // Sol Kulp
    final leftHandle = Path()
      ..moveTo(cx - 41, 50)
      ..cubicTo(cx - 62, 48, cx - 62, 71, cx - 35, 71);
    canvas.drawPath(leftHandle, pen..strokeWidth = 2.6);

    // Sağ Kulp
    final rightHandle = Path()
      ..moveTo(cx + 41, 50)
      ..cubicTo(cx + 62, 48, cx + 62, 71, cx + 35, 71);
    canvas.drawPath(rightHandle, pen..strokeWidth = 2.6);

    // Kupa Sapı & Kaidesi
    final goldFill = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;
    final darkGoldFill = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    // Boyun
    final stemPath = Path()
      ..moveTo(cx - 9, 80)
      ..lineTo(cx + 9, 80)
      ..lineTo(cx + 12, 92)
      ..lineTo(cx - 12, 92)
      ..close();
    canvas.drawPath(stemPath, darkGoldFill);
    canvas.drawPath(stemPath, pen..strokeWidth = 2.1);

    // Alt Kaide
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 28, 92, 56, 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(baseRect, goldFill);
    canvas.drawRRect(baseRect, pen..strokeWidth = 2.2);

    // Arka plan konfeti noktaları
    canvas.drawCircle(
      const Offset(14, 14),
      2.4,
      Paint()..color = const Color(0xFF38BDF8),
    );
    canvas.drawCircle(
      const Offset(142, 16),
      2.4,
      Paint()..color = const Color(0xFFF43F5E),
    );
    canvas.drawCircle(
      const Offset(10, 56),
      2.0,
      Paint()..color = AppColors.sunYellow,
    );
    canvas.drawCircle(
      const Offset(146, 56),
      2.0,
      Paint()..color = const Color(0xFFA855F7),
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleCupBackPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}

/// 5. Slayt İllüstrasyonu (Ön Katman): Kupanın Ön Altın Duvarı ve Ağız Kenarı
class _DoodleCupFrontPainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleCupFrontPainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2; // 78.0

    final goldFill = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;

    // Ön kupa duvarı (ağızın ön yayı y=45 civarından başlar; içteki rozetlerin alt yarısını örter)
    final bodyPath = Path()
      ..moveTo(cx - 43, 45)
      ..quadraticBezierTo(cx, 52, cx + 43, 45)
      ..cubicTo(cx + 42, 70, cx + 24, 82, cx, 82)
      ..cubicTo(cx - 24, 82, cx - 42, 70, cx - 43, 45)
      ..close();

    canvas.drawPath(bodyPath, goldFill);

    // Kupa üzerinde parlak şerit yansıması
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.45)
      ..style = PaintingStyle.fill;
    final shinePath = Path()
      ..moveTo(cx - 32, 51)
      ..quadraticBezierTo(cx - 24, 52, cx - 22, 52)
      ..cubicTo(cx - 21, 66, cx - 15, 75, cx - 10, 78)
      ..lineTo(cx - 17, 78)
      ..cubicTo(cx - 25, 73, cx - 31, 64, cx - 32, 51)
      ..close();
    canvas.drawPath(shinePath, highlightPaint);

    canvas.drawPath(bodyPath, pen);

    // Ön gövdede küçük yıldız arması
    final starCenter = Offset(cx, 66);
    final starPen = Paint()
      ..color = pencilColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(starCenter.dx - 5.5, starCenter.dy),
      Offset(starCenter.dx + 5.5, starCenter.dy),
      starPen,
    );
    canvas.drawLine(
      Offset(starCenter.dx, starCenter.dy - 5.5),
      Offset(starCenter.dx, starCenter.dy + 5.5),
      starPen,
    );
    canvas.drawLine(
      Offset(starCenter.dx - 3.6, starCenter.dy - 3.6),
      Offset(starCenter.dx + 3.6, starCenter.dy + 3.6),
      starPen..strokeWidth = 1.3,
    );
    canvas.drawLine(
      Offset(starCenter.dx + 3.6, starCenter.dy - 3.6),
      Offset(starCenter.dx - 3.6, starCenter.dy + 3.6),
      starPen,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleCupFrontPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}
