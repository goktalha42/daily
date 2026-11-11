import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_avatar.dart';
import '../../../core/services/user_avatar_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sketch_decorations.dart';

/// Kullanıcının profil ve liderlik sıralaması için özel eskiz avatarını seçmesini sağlayan diyalog
class AvatarPickerDialog extends ConsumerStatefulWidget {
  const AvatarPickerDialog({super.key});

  @override
  ConsumerState<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends ConsumerState<AvatarPickerDialog> {
  late String _selectedAvatarId;
  late String _selectedColorId;

  @override
  void initState() {
    super.initState();
    final currentAvatar = UserAvatar.getById(ref.read(userAvatarProvider));
    _selectedAvatarId = currentAvatar.id;
    _selectedColorId = currentAvatar.colorId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final graphiteColor = isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite;
    final cardBg = isDark ? AppColors.cardBgDark : Colors.white;
    final selectedColorOption = UserAvatar.getColorOptionById(_selectedColorId);
    final selectedAvatarModel = UserAvatar.getById(
      UserAvatar.encodeId(_selectedAvatarId, _selectedColorId),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 670),
        child: SketchCard(
          borderRadius: 20,
          borderWidth: 2.5,
          shadowOffset: const Offset(4.0, 4.0),
          backgroundColor: cardBg,
          borderColor: pencilColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık & Canlı Önizleme Alanı
              Row(
                children: [
                  SketchPlaceholderBox(
                    width: 48,
                    height: 48,
                    fillColor: selectedColorOption.color.withAlpha(isDark ? 95 : 130),
                    lineColor: pencilColor,
                    borderRadius: 11,
                    child: Center(
                      child: selectedAvatarModel.buildWidget(
                        size: 28,
                        tintColor: pencilColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avatarını Özelleştir',
                          style: GoogleFonts.patrickHand(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: pencilColor,
                          ),
                        ),
                        Text(
                          'İkonunu ve arka plan rengini özgürce belirle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: graphiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: pencilColor),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: pencilColor.withAlpha(50), height: 1),
              const SizedBox(height: 12),

              // 1. İkon Listesi (3 Sütunlu Grid)
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: UserAvatar.allAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = UserAvatar.allAvatars[index];
                    final isSelected = avatar.id == _selectedAvatarId;
                    final effectiveAccent = isSelected
                        ? selectedColorOption.color
                        : avatar.accentColor;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedAvatarId = avatar.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuad,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? effectiveAccent.withAlpha(isDark ? 75 : 95)
                              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? effectiveAccent : pencilColor.withAlpha(80),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: effectiveAccent.withAlpha(80),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  avatar.buildWidget(size: 32, tintColor: pencilColor),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      avatar.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.patrickHand(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: pencilColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: effectiveAccent,
                                    border: Border.all(color: pencilColor, width: 1.5),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 12,
                                      color: AppColors.pencilBlack,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 2. Arka Plan Rengi Seçici Şerit
              Text(
                'ARKA PLAN RENGİ',
                style: GoogleFonts.patrickHand(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: graphiteColor,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: UserAvatar.bgColorOptions.map((opt) {
                    final isColorSelected = opt.id == _selectedColorId;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedColorId = opt.id;
                        });
                      },
                      child: Tooltip(
                        message: opt.label,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isColorSelected ? 34 : 30,
                          height: isColorSelected ? 34 : 30,
                          decoration: BoxDecoration(
                            color: opt.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: pencilColor,
                              width: isColorSelected ? 2.4 : 1.5,
                            ),
                            boxShadow: isColorSelected
                                ? [
                                    BoxShadow(
                                      color: pencilColor.withAlpha(110),
                                      offset: const Offset(1.5, 1.5),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isColorSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 17,
                                    color: opt.color.computeLuminance() > 0.35
                                        ? AppColors.pencilBlack
                                        : Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: pencilColor.withAlpha(50), height: 1),
              const SizedBox(height: 14),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: pencilColor, width: 1.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Vazgeç',
                        style: GoogleFonts.patrickHand(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: pencilColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunYellow,
                        foregroundColor: AppColors.pencilBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        side: BorderSide(color: pencilColor, width: 2.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final encoded = UserAvatar.encodeId(
                          _selectedAvatarId,
                          _selectedColorId,
                        );
                        await ref.read(userAvatarProvider.notifier).setAvatar(encoded);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: cardBg,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: pencilColor, width: 1.5),
                              ),
                              content: Text(
                                'Avatarın ve arka plan rengin güncellendi! ✨',
                                style: GoogleFonts.patrickHand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: pencilColor,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Kaydet & Kullan',
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
            ],
          ),
        ),
      ),
    );
  }
}

