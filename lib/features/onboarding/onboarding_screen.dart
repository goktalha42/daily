import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/league_service.dart';
import '../../core/theme/app_colors.dart';
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
/// 5. Liglerde Yarış & Arkadaşlarına Hava At (30 kişilik lig, WhatsApp/Instagram paylaşımı)
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

          // El Çizimi Kahve & Not Defteri İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleCoffeePainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Günde Sadece\n10 Dakika! ☕',
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

          Text.rich(
            TextSpan(
              text: 'Her Gece 00:00\'da\n6 Yeni Oyun ',
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: CustomPaint(
                      size: const Size(26, 26),
                      painter: _DoodleInlineMoonPainter(
                        pencilColor: pencilColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

          // 6 Oyunun Minik Vitrini (2x3 Izgara)
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
                        title: 'Vezirler',
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
                        title: 'Nokta Atışı',
                        desc: 'Görsel Hız',
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
                        title: 'Kelime T.',
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
                        title: 'Tango',
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
                        title: 'Sayı Yolu',
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
                        title: 'Yamalar',
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
            'Puanını ve Zeka\nSkorunu Gör 🧠',
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

          Text.rich(
            TextSpan(
              text: 'Ateşi Söndürme:\nSerini Koru! ',
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SketchDoodleFlame(
                      size: 28,
                      color: pencilColor,
                    ),
                  ),
                ),
              ],
            ),
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

          // El Çizimi Kupa & Paylaşım Balonu İllüstrasyonu
          Center(
            child: CustomPaint(
              size: const Size(120, 100),
              painter: _DoodleTrophyChallengePainter(
                isDark: isDark,
                pencilColor: pencilColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text.rich(
            TextSpan(
              text: 'Liglerde Yarış ve\nArkadaşlarına Hava At! ',
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SketchDoodleTrophy(
                      size: 27,
                      color: pencilColor,
                      fillColor: AppColors.sunYellow,
                    ),
                  ),
                ),
              ],
            ),
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
            'Haftalık ligde 30 kişiyle yarış, ilk 7\'ye girerek üst lige terfi et! Şık el çizimi karne kartını WhatsApp\'tan paylaşarak arkadaşlarına meydan oku.',
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.patrickHand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: pencilColor,
                    height: 1.1,
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

/// 2. Slayt Başlığı İçin Satır İçi El Çizimi Hilal Ay
class _DoodleInlineMoonPainter extends CustomPainter {
  final Color pencilColor;

  _DoodleInlineMoonPainter({required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final moonFill = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;
    final moonPen = Paint()
      ..color = pencilColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final moonPath = Path()
      ..moveTo(w * 0.62, h * 0.12)
      ..cubicTo(w * 0.16, h * 0.22, w * 0.16, h * 0.78, w * 0.68, h * 0.88)
      ..cubicTo(w * 0.42, h * 0.68, w * 0.42, h * 0.32, w * 0.62, h * 0.12)
      ..close();

    canvas.drawPath(moonPath, moonFill);
    canvas.drawPath(moonPath, moonPen);
  }

  @override
  bool shouldRepaint(covariant _DoodleInlineMoonPainter oldDelegate) =>
      oldDelegate.pencilColor != pencilColor;
}

// =============================================================================
// ÖZEL EL ÇİZİMİ VEKTÖR RESMEDİCİLERİ (DOODLE CUSTOM PAINTERS)
// =============================================================================

/// 1. Slayt İllüstrasyonu: El Çizimi Dumanı Tüten Kahve Fincanı & Kurşun Kalem
class _DoodleCoffeePainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleCoffeePainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cupFill = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;

    // Fincan Gövdesi
    final cupRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(30, 42, 52, 44),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(cupRect, cupFill);
    canvas.drawRRect(cupRect, pen);

    // Fincan Kulpu (Sağda)
    final handlePath = Path();
    handlePath.moveTo(82, 50);
    handlePath.cubicTo(98, 50, 98, 74, 82, 74);
    canvas.drawPath(handlePath, pen);

    // Fincan Tabağı
    final saucerPath = Path();
    saucerPath.moveTo(22, 88);
    saucerPath.quadraticBezierTo(56, 94, 90, 88);
    canvas.drawPath(saucerPath, pen);

    // Kahve Buharı Dalgaları (3 dalga)
    final steamPaint = Paint()
      ..color = isDark ? AppColors.sunYellow : const Color(0xFFD97706)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final sx = 42.0 + i * 14.0;
      final steam = Path();
      steam.moveTo(sx, 36);
      steam.cubicTo(sx - 5, 26, sx + 5, 18, sx, 10);
      canvas.drawPath(steam, steamPaint);
    }

    // Yanında Çizilen Minik Kurşun Kalem
    final pencilPaint = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;
    final pencilPath = Path();
    pencilPath.moveTo(102, 28);
    pencilPath.lineTo(112, 18);
    pencilPath.lineTo(116, 22);
    pencilPath.lineTo(106, 32);
    pencilPath.close();
    canvas.drawPath(pencilPath, pencilPaint);
    canvas.drawPath(pencilPath, pen..strokeWidth = 1.6);

    // Kalem Ucu
    final tipPath = Path();
    tipPath.moveTo(102, 28);
    tipPath.lineTo(96, 34);
    tipPath.lineTo(106, 32);
    tipPath.close();
    canvas.drawPath(
        tipPath,
        Paint()
          ..color = pencilColor
          ..style = PaintingStyle.fill);

    // Parıltı Yıldızları
    _drawSparkle(canvas, const Offset(20, 28), pencilColor);
    _drawSparkle(canvas, const Offset(105, 78), AppColors.sunYellow);
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(center.dx - 4, center.dy), Offset(center.dx + 4, center.dy), p);
    canvas.drawLine(
        Offset(center.dx, center.dy - 4), Offset(center.dx, center.dy + 4), p);
  }

  @override
  bool shouldRepaint(covariant _DoodleCoffeePainter oldDelegate) =>
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

/// 3. Slayt İllüstrasyonu: Gülen Zeki Beyin & Hız Göstergesi
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

    final brainFill = Paint()
      ..color = isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF)
      ..style = PaintingStyle.fill;

    // Beyin Lobları (Solda ve Sağda wobbly loblar)
    final brainPath = Path();
    brainPath.moveTo(60, 20);
    // Sol loblar
    brainPath.cubicTo(45, 15, 30, 25, 30, 40);
    brainPath.cubicTo(20, 48, 22, 65, 35, 70);
    brainPath.cubicTo(32, 80, 50, 84, 60, 80);
    // Sağ loblar
    brainPath.cubicTo(70, 84, 88, 80, 85, 70);
    brainPath.cubicTo(98, 65, 100, 48, 90, 40);
    brainPath.cubicTo(90, 25, 75, 15, 60, 20);
    brainPath.close();

    canvas.drawPath(brainPath, brainFill);
    canvas.drawPath(brainPath, pen);

    // Beyin Orta Kıvrım Çizgisi
    final midLine = Path();
    midLine.moveTo(60, 22);
    midLine.cubicTo(56, 40, 64, 60, 60, 78);
    canvas.drawPath(midLine, pen..strokeWidth = 1.8);

    // İç Kıvrımlar (Sulcus)
    final sulcus1 = Path();
    sulcus1.moveTo(38, 42);
    sulcus1.cubicTo(48, 44, 46, 56, 38, 62);
    canvas.drawPath(sulcus1, pen..strokeWidth = 1.5);

    final sulcus2 = Path();
    sulcus2.moveTo(82, 42);
    sulcus2.cubicTo(72, 44, 74, 56, 82, 62);
    canvas.drawPath(sulcus2, pen..strokeWidth = 1.5);

    // Gülen Gözler ve Ağız (^ ^ ve gülümseme)
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(46, 50), radius: 4),
        math.pi,
        math.pi,
        false,
        pen..strokeWidth = 2.0);
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(74, 50), radius: 4),
        math.pi,
        math.pi,
        false,
        pen..strokeWidth = 2.0);

    // Minik Ağız
    final smile = Path();
    smile.moveTo(54, 62);
    smile.quadraticBezierTo(60, 67, 66, 62);
    canvas.drawPath(smile, pen);

    // Beyin Etrafında Zeka Kıvılcımları (Şimşekler)
    final boltPaint = Paint()
      ..color = AppColors.sunYellow
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    // Sol Şimşek
    final boltLeft = Path();
    boltLeft.moveTo(18, 30);
    boltLeft.lineTo(14, 42);
    boltLeft.lineTo(20, 42);
    boltLeft.lineTo(12, 54);
    canvas.drawPath(boltLeft, boltPaint);

    // Sağ Şimşek
    final boltRight = Path();
    boltRight.moveTo(104, 30);
    boltRight.lineTo(100, 42);
    boltRight.lineTo(106, 42);
    boltRight.lineTo(98, 54);
    canvas.drawPath(boltRight, boltPaint);
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

/// 5. Slayt İllüstrasyonu: Şampiyonluk Kupası & WhatsApp Paylaşım Balonu
class _DoodleTrophyChallengePainter extends CustomPainter {
  final bool isDark;
  final Color pencilColor;

  _DoodleTrophyChallengePainter({required this.isDark, required this.pencilColor});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = pencilColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldFill = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;

    // Kupa Gövdesi (Solda)
    final cupPath = Path();
    cupPath.moveTo(24, 28);
    cupPath.lineTo(66, 28);
    cupPath.cubicTo(66, 58, 45, 66, 45, 72);
    cupPath.lineTo(45, 78);
    cupPath.lineTo(54, 86);
    cupPath.lineTo(36, 86);
    cupPath.lineTo(45, 78);
    cupPath.lineTo(45, 72);
    cupPath.cubicTo(45, 66, 24, 58, 24, 28);
    cupPath.close();

    canvas.drawPath(cupPath, goldFill);
    canvas.drawPath(cupPath, pen);

    // Kupa Sol Kulpu
    final leftHandle = Path();
    leftHandle.moveTo(24, 34);
    leftHandle.cubicTo(10, 34, 10, 52, 27, 52);
    canvas.drawPath(leftHandle, pen);

    // Kupa Sağ Kulpu
    final rightHandle = Path();
    rightHandle.moveTo(66, 34);
    rightHandle.cubicTo(80, 34, 80, 52, 63, 52);
    canvas.drawPath(rightHandle, pen);

    // Kupa Üzerinde Yıldız Karalaması
    final starCenter = const Offset(45, 44);
    final p = Paint()
      ..color = pencilColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(starCenter.dx - 6, starCenter.dy),
        Offset(starCenter.dx + 6, starCenter.dy), p);
    canvas.drawLine(Offset(starCenter.dx, starCenter.dy - 6),
        Offset(starCenter.dx, starCenter.dy + 6), p);

    // Sağda WhatsApp / Mesaj Paylaşım Kartpostalı Balonu
    final bubbleFill = Paint()
      ..color = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)
      ..style = PaintingStyle.fill;

    final bubblePath = Path();
    bubblePath.moveTo(76, 20);
    bubblePath.lineTo(112, 20);
    bubblePath.quadraticBezierTo(118, 20, 118, 26);
    bubblePath.lineTo(118, 54);
    bubblePath.quadraticBezierTo(118, 60, 112, 60);
    bubblePath.lineTo(88, 60);
    bubblePath.lineTo(80, 68);
    bubblePath.lineTo(82, 60);
    bubblePath.lineTo(76, 60);
    bubblePath.quadraticBezierTo(70, 60, 70, 54);
    bubblePath.lineTo(70, 26);
    bubblePath.quadraticBezierTo(70, 20, 76, 20);
    bubblePath.close();

    canvas.drawPath(bubblePath, bubbleFill);
    canvas.drawPath(bubblePath, pen..strokeWidth = 1.8);

    // Balon İçindeki Simge (WhatsApp Benzeri Paylaşım Karalaması)
    final msgPen = Paint()
      ..color = isDark ? AppColors.pencilWhite : const Color(0xFF15803D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // İki minik satır çizgi
    canvas.drawLine(const Offset(78, 34), const Offset(110, 34), msgPen);
    canvas.drawLine(const Offset(78, 44), const Offset(102, 44), msgPen);

    // Konfeti parçacıkları
    canvas.drawCircle(const Offset(16, 18), 2.5, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(const Offset(52, 12), 2.0, Paint()..color = const Color(0xFFF43F5E));
    canvas.drawCircle(const Offset(108, 76), 2.5, Paint()..color = AppColors.sunYellow);
  }

  @override
  bool shouldRepaint(covariant _DoodleTrophyChallengePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pencilColor != pencilColor;
}
