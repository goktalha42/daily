import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../../games/common/base_game.dart';
import 'screen_shake.dart';

/// ADHD karakterlere uygun, yüksek dopaminli, ekran sarsıntılı ve kullanıcıyı
/// "olağanüstü dahi" hissettiren yeni nesil zafer ekranı diyaloğu.
class GeniusWinDialog extends StatefulWidget {
  final GameResult result;
  final String gameTitle;
  final VoidCallback onRestart;

  const GeniusWinDialog({
    super.key,
    required this.result,
    required this.gameTitle,
    required this.onRestart,
  });

  static Future<void> show(
    BuildContext context, {
    required GameResult result,
    required String gameTitle,
    required VoidCallback onRestart,
  }) async {
    // Ekranı gümbür gümbür sars
    ScreenShake.shake(context, intensity: 18.0, duration: const Duration(milliseconds: 750));
    GeniusConfettiOverlay.explode(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GeniusWinDialog(
        result: result,
        gameTitle: gameTitle,
        onRestart: onRestart,
      ),
    );
  }

  @override
  State<GeniusWinDialog> createState() => _GeniusWinDialogState();
}

class _GeniusWinDialogState extends State<GeniusWinDialog> {
  @override
  void initState() {
    super.initState();
    // Açılışta ekstra haptik dopamin dalgası
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ADHD motivasyon metinleri
    final isTopTier = widget.result.durationMs < 60000 || widget.result.score > 800;
    final percentileStr = isTopTier ? "%1'LİK" : "%2'LİK";
    final iqScore = isTopTier ? "152+" : "146+";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.geniusGold.withOpacity(0.6),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.geniusGold.withOpacity(0.35),
              blurRadius: 40,
              spreadRadius: 6,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Arka plan zafer ışığı deseni
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.geniusGold.withOpacity(0.12),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Devasa Parlayan Altın Dahi Kupası / Tacı
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE066), Color(0xFFFFB800), Color(0xFFFF7A00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.geniusGold.withOpacity(0.55),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.08, duration: 800.ms, curve: Curves.easeInOut)
                        .animate()
                        .shake(duration: 500.ms, hz: 6),

                    const SizedBox(height: 18),

                    // "SEN RESMEN BİR DAHİSİN!" Başlığı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.geniusGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.geniusGold.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: AppColors.electricAmber, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'AKIL ALMAZ PERFORMANS!',
                            style: TextStyle(
                              color: AppColors.electricAmber,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 10),

                    const Text(
                      'SEN BİR DAHİSİN! 🔥',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 6),

                    // Yüzdelik Dilim Vurgusu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'DÜNYANIN EN İYİ $percentileStr DİLİMİNDESİN 🏆',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 20),

                    // Zeka ve Başarı İstatistikleri Kutusu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _StatRow(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Zeka Endeksi (Tahmini IQ)',
                            value: '$iqScore DAHİ',
                            valueColor: const Color(0xFF8B5CF6),
                            isHighlight: true,
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _StatRow(
                            icon: Icons.speed_rounded,
                            iconColor: const Color(0xFF00E5FF),
                            label: 'Çözüm Süresi',
                            value: GameDateUtils.formatGameTime(widget.result.durationMs),
                            valueColor: const Color(0xFF0284C7),
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _StatRow(
                            icon: Icons.ads_click_rounded,
                            iconColor: const Color(0xFFFF9E00),
                            label: 'Hamle Hassasiyeti',
                            value: '${widget.result.moveCount} Hamle (%99.1)',
                            valueColor: const Color(0xFFD97706),
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _StatRow(
                            icon: Icons.military_tech_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: 'Dahi Puanı',
                            value: '+${widget.result.score} P',
                            valueColor: const Color(0xFF059669),
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 22),

                    // Aksiyon Butonları
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              Navigator.pop(context); // Ana Sayfaya dön
                            },
                            child: const Text(
                              'Lobiye Dön',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onRestart();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.replay_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Tekrar Oyna',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool isHighlight;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
