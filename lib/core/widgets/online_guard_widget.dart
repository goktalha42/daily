import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../network/network_checker.dart';
import '../theme/app_theme.dart';

class OnlineGuardWidget extends ConsumerWidget {
  final Widget child;

  const OnlineGuardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkCheckerProvider);

    return Stack(
      children: [
        child,
        if (!isOnline)
          Material(
            color: Colors.black.withValues(alpha: 0.85),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 56,
                            color: AppColors.error,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
                        const SizedBox(height: 20),
                        Text(
                          'İnternet Bağlantısı Yok',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Günlük oyunlar ve adil sıralama için internete bağlı olmanız gerekmektedir.\nLütfen bağlantınızı kontrol edin.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // Trigger re-check
                              ref.read(networkCheckerProvider.notifier);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bağlantı kontrol ediliyor...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text(
                              'Yeniden Dene',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
