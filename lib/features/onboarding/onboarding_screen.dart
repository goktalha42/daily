import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/sketch_badge_icons.dart';
import '../../core/widgets/sketch_decorations.dart';

/// Zühtü - İlk Açılış Karşılama ve Tanıtım Turu (Onboarding Walkthrough).
/// 3 kaydırılabilir el çizimi skeç slaytı ile oyunun ana sütunlarını tanıtır:
/// 1. Gece 00:00'da 6 yeni bulmaca & Seri (Streak)
/// 2. Bilimsel WAIS-IV Bilişsel Zeka Karnesi & 4 Zeka Alanı
/// 3. Canlı Haftalık Ligler, Rozetler & Sosyal Rekabet
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
    if (_currentPage < 2) {
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sunYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: pencilColor, width: 1.6),
                          ),
                          child: Row(
                            children: [
                              const Text('🧠', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
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
                      ],
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

              // 2. SLAYTLAR (PAGEVIEW)
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
                  ],
                ),
              ),

              // 3. ALT KONTROLLER: NOKTA GÖSTERGELERİ & DEVAM/BAŞLA BUTONU
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Doodle Nokta Göstergeleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 10,
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

                    const SizedBox(height: 18),

                    // Büyük Eylem Butonu
                    SketchCard(
                      onTap: _nextPage,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _currentPage == 2
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
                              _currentPage == 2
                                  ? (widget.isRevisit
                                      ? 'Rehberi Tamamla ✨'
                                      : 'Zühtü\'ye Başla! 🚀')
                                  : 'Devam Et',
                              style: GoogleFonts.patrickHand(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _currentPage == 2
                                    ? AppColors.inkBlack
                                    : pencilColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == 2
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                              color: _currentPage == 2
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

  /// Slayt 1: Her Gece 00:00'da 6 Yeni Bulmaca & Seri (Streak)
  Widget _buildSlide1({required bool isDark, required Color pencilColor}) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // Üst İllüstrasyon / İkon Rozeti
          Center(
            child: SketchCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 28,
              borderWidth: 2.6,
              shadowOffset: const Offset(4, 4),
              backgroundColor: AppColors.sunYellow,
              borderColor: pencilColor,
              child: const Icon(
                Icons.nightlight_round,
                size: 54,
                color: AppColors.inkBlack,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Her Gece 00:00\'da\n6 Yeni Bulmaca 🌙',
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
            'Her gece yarısı tüm Türkiye ile aynı anda 6 yeni zihinsel bulmaca açılır. Günde sadece 10 dakika ayırarak zihinsel zindeliğini koru.',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 18),

          // 6 Oyunun Minik Vitrini (2x3 Izgara)
          SketchCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            borderWidth: 2.0,
            shadowOffset: const Offset(3, 3),
            backgroundColor: cardBg,
            borderColor: pencilColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        emoji: '👑',
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
                        emoji: '🎯',
                        title: 'Nokta Atışı',
                        desc: 'Görsel Hız',
                        color: AppColors.pinpointGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        emoji: '🧗',
                        title: 'Kelime T.',
                        desc: 'Sözel Mantık',
                        color: AppColors.crossclimbGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniGamePill(
                        emoji: '⚪',
                        title: 'Tango',
                        desc: 'Desen Zekası',
                        color: AppColors.tangoGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniGamePill(
                        emoji: '🔢',
                        title: 'Sayı Yolu',
                        desc: 'İşlem Belleği',
                        color: AppColors.zipGame,
                        pencilColor: pencilColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniGamePill(
                        emoji: '🧩',
                        title: 'Yamalar',
                        desc: 'Uzamsal Mantık',
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

          const SizedBox(height: 14),

          // İpucu / Seri Vurgusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pencilColor, width: 1.6),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seri (Streak) Sistemi: Her gün en az 1 oyun tamamlayarak serini büyüt, zihinsel disiplinini kanıtla!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
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

  /// Slayt 2: Bilimsel WAIS-IV Zeka Karnesi & 4 Bilişsel İndeks
  Widget _buildSlide2({required bool isDark, required Color pencilColor}) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // Üst İllüstrasyon / İkon Rozeti
          Center(
            child: SketchCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 28,
              borderWidth: 2.6,
              shadowOffset: const Offset(4, 4),
              backgroundColor: AppColors.highlighterPurple,
              borderColor: pencilColor,
              child: const Icon(
                Icons.psychology_outlined,
                size: 54,
                color: AppColors.inkBlack,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Bilimsel WAIS-IV\nZeka Karnesi 🧠',
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
            'Zühtü sadece bir oyun değil; çözümlerin Wechsler Yetişkin Zeka Ölçeği normlarına göre 4 ana bilişsel alanda analiz edilir.',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 18),

          // 4 Bilişsel Alan Kartı
          SketchCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            borderWidth: 2.0,
            shadowOffset: const Offset(3, 3),
            backgroundColor: cardBg,
            borderColor: pencilColor,
            child: Column(
              children: [
                _buildCognitiveRow(
                  icon: Icons.extension_outlined,
                  title: 'Algısal Akıl Yürütme',
                  games: 'Vezirler & Yamalar',
                  color: AppColors.queensGame,
                  pencilColor: pencilColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildCognitiveRow(
                  icon: Icons.speed_rounded,
                  title: 'İşlem Hızı & Odak',
                  games: 'Nokta Atışı',
                  color: AppColors.pinpointGame,
                  pencilColor: pencilColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildCognitiveRow(
                  icon: Icons.menu_book_rounded,
                  title: 'Sözel Kavrama',
                  games: 'Kelime Tırmanışı',
                  color: AppColors.crossclimbGame,
                  pencilColor: pencilColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildCognitiveRow(
                  icon: Icons.memory_rounded,
                  title: 'Çalışma Belleği',
                  games: 'Tango & Sayı Yolu',
                  color: AppColors.zipGame,
                  pencilColor: pencilColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Yüzdelik Başarı Vurgusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pencilColor, width: 1.6),
            ),
            child: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Her oyun sonrası gerçek IQ puanını, Türkiye geneli yüzdelik dilimini ve zeka unvanını öğren!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B21B6),
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

  /// Slayt 3: Haftalık Canlı Ligler & Rekabet
  Widget _buildSlide3({required bool isDark, required Color pencilColor}) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // Üst İllüstrasyon / İkon Rozeti
          Center(
            child: SketchCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 28,
              borderWidth: 2.6,
              shadowOffset: const Offset(4, 4),
              backgroundColor: AppColors.skyBlue,
              borderColor: pencilColor,
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 54,
                color: AppColors.inkBlack,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Haftalık Canlı Ligler\nve Sosyal Rekabet 🏆',
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
            'Her Pazartesi 00:00\'da haftalık ligler başlar. Kendi seviyendeki 30 oyuncuyla yarış, ilk 7\'ye girerek üst lige terfi et!',
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 16,
              color: isDark ? AppColors.pencilWhite : AppColors.pencilGraphite,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 18),

          // 5 Lig Kademesi Şeridi
          SketchCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 16,
            borderWidth: 2.0,
            shadowOffset: const Offset(3, 3),
            backgroundColor: cardBg,
            borderColor: pencilColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LİG KADEMELERİ (HAFTALIK TERFİ):',
                  style: GoogleFonts.patrickHand(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: pencilColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTierBadge('🥉', 'Bronz', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: AppColors.pencilGraphite),
                    _buildTierBadge('🥈', 'Gümüş', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: AppColors.pencilGraphite),
                    _buildTierBadge('🥇', 'Altın', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: AppColors.pencilGraphite),
                    _buildTierBadge('💎', 'Elmas', pencilColor),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: AppColors.pencilGraphite),
                    _buildTierBadge('👑', 'Elit Dâhi', pencilColor),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Özelleştirme ve Paylaşım Vurgusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pencilColor, width: 1.6),
            ),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profilinden dilediğin emojili avatarı ve takma adı seç! WhatsApp ve Instagram için şık zeka kartları paylaşarak arkadaşlarına meydan oku!',
                    style: GoogleFonts.patrickHand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0369A1),
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

  Widget _buildMiniGamePill({
    required String emoji,
    required String title,
    required String desc,
    required Color color,
    required Color pencilColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.35 : 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pencilColor, width: 1.4),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.patrickHand(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pencilColor,
                    height: 1.1,
                  ),
                ),
                Text(
                  desc,
                  maxLines: 1,
                  style: GoogleFonts.patrickHand(
                    fontSize: 11,
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

  Widget _buildCognitiveRow({
    required IconData icon,
    required String title,
    required String games,
    required Color color,
    required Color pencilColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.4 : 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: pencilColor, width: 1.4),
          ),
          child: Icon(icon, size: 16, color: pencilColor),
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
                  fontWeight: FontWeight.bold,
                  color: pencilColor,
                  height: 1.1,
                ),
              ),
              Text(
                games,
                style: GoogleFonts.patrickHand(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.pencilWhite.withValues(alpha: 0.7)
                      : AppColors.pencilGraphite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierBadge(String emoji, String name, Color pencilColor) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
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
