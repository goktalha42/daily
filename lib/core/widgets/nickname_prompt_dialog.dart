import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../network/api_client.dart';
import '../services/user_nickname_provider.dart';
import '../theme/app_colors.dart';
import 'sketch_decorations.dart';

class NicknamePromptDialog extends ConsumerStatefulWidget {
  final bool isEditing;

  const NicknamePromptDialog({
    super.key,
    this.isEditing = false,
  });

  @override
  ConsumerState<NicknamePromptDialog> createState() => _NicknamePromptDialogState();
}

class _NicknamePromptDialogState extends ConsumerState<NicknamePromptDialog> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userNicknameProvider);
    _controller = TextEditingController(
      text: (widget.isEditing && current != 'Oyuncu') ? current : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen bir takma ad yazın.';
      });
      HapticFeedback.lightImpact();
      return;
    }

    if (name.length < 3) {
      setState(() {
        _errorMessage = 'İsim en az 3 karakter olmalıdır.';
      });
      HapticFeedback.lightImpact();
      return;
    }

    if (name.length > 20) {
      setState(() {
        _errorMessage = 'İsim en fazla 20 karakter olabilir.';
      });
      HapticFeedback.lightImpact();
      return;
    }

    final validRegex = RegExp(r'^[\p{L}\p{N}_]{3,20}$', unicode: true);
    if (!validRegex.hasMatch(name)) {
      setState(() {
        _errorMessage = 'Yalnızca harf, rakam ve alt çizgi (_) kullanabilirsin; boşluk bırakılamaz.';
      });
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.registerNickname(name);

    if (!mounted) return;

    if (result['success'] == true) {
      await ref.read(userNicknameProvider.notifier).setNickname(name);
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'] ?? 'Bu isim alınamadı.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pencilColor = isDark ? AppColors.pencilWhite : AppColors.pencilBlack;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return PopScope(
      canPop: widget.isEditing, // İlk açılışta zorunludur, kapatılamaz!
      child: Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SketchCard(
              borderRadius: 20,
              borderWidth: 2.5,
              borderColor: pencilColor,
              shadowOffset: const Offset(5, 5),
              backgroundColor: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. İkon ve Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.pencilGraphiteDark.withValues(alpha: 0.3) : AppColors.sunYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pencilColor, width: 1.5),
                        ),
                        child: Text(
                          '✏️',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isEditing ? 'Takma Adını Değiştir' : 'Hoş Geldin Zühtü Sever!',
                          style: GoogleFonts.patrickHand(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: pencilColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Açıklama
                  Text(
                    widget.isEditing
                        ? 'Liderlik tablosunda ve liglerde görünecek yeni bir benzersiz isim seç:'
                        : 'Liderlik tablosunda ve haftalık liglerde diğer oyuncularla yarışabilmek için kendine bir isim belirlemelisin:',
                    style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      color: isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Giriş Alanı (Sketch Input)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceSecondaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _errorMessage != null ? AppColors.error : pencilColor,
                        width: 2.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 20,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: GoogleFonts.patrickHand(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: pencilColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'Örn: ZühtüUsta, Bilge_42, AkılKüpü',
                        hintStyle: GoogleFonts.patrickHand(
                          fontSize: 16,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 20, color: pencilColor),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (text) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),

                  // 4. Hata Mesajı (Varsa)
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.patrickHand(
                                fontSize: 14,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // 5. Bilgi Notu (Büyük/küçük harf kuralı)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 15,
                        color: isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tüm isimler benzersizdir. Büyük ve küçük harf fark etmeksizin aynı isim tekrar alınamaz (Örn: "Talha" varken "talha" alınamaz).',
                          style: GoogleFonts.patrickHand(
                            fontSize: 13,
                            color: isDark ? AppColors.pencilGraphiteDark : AppColors.pencilGraphite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. Butonlar
                  Row(
                    children: [
                      if (widget.isEditing) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: pencilColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Vazgeç',
                              style: GoogleFonts.patrickHand(
                                fontSize: 17,
                                color: pencilColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunYellow,
                            foregroundColor: AppColors.pencilBlack,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: pencilColor, width: 2),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                                )
                              : Text(
                                  widget.isEditing ? 'Güncelle' : 'Kaydet ve Başla 🚀',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
