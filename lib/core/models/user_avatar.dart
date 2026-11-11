import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sketch_decorations.dart';

/// Avatar kutusu için seçilebilir el çizimi arka plan renk seçeneği
class AvatarBgColorOption {
  final String id;
  final String label;
  final Color color;

  const AvatarBgColorOption({
    required this.id,
    required this.label,
    required this.color,
  });
}

/// Kullanıcı eskiz profil avatarı modeli
class UserAvatar {
  final String id;
  final String label;
  final String emoji;
  final Color accentColor;
  final String colorId;
  final bool hasVectorDoodle;

  const UserAvatar({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentColor,
    this.colorId = 'yellow',
    this.hasVectorDoodle = false,
  });

  static const String defaultAvatarId = 'crown';

  static const List<AvatarBgColorOption> bgColorOptions = [
    AvatarBgColorOption(
      id: 'yellow',
      label: 'Sarı',
      color: AppColors.sunYellow,
    ),
    AvatarBgColorOption(
      id: 'orange',
      label: 'Turuncu',
      color: AppColors.highlighterOrange,
    ),
    AvatarBgColorOption(
      id: 'pink',
      label: 'Pembe',
      color: AppColors.highlighterPink,
    ),
    AvatarBgColorOption(
      id: 'purple',
      label: 'Mor',
      color: AppColors.highlighterPurple,
    ),
    AvatarBgColorOption(
      id: 'cyan',
      label: 'Turkuaz',
      color: AppColors.highlighterCyan,
    ),
    AvatarBgColorOption(
      id: 'sky',
      label: 'Mavi',
      color: AppColors.skyBlue,
    ),
    AvatarBgColorOption(
      id: 'green',
      label: 'Yeşil',
      color: Color(0xFF4ADE80),
    ),
    AvatarBgColorOption(
      id: 'graphite',
      label: 'Antrasit',
      color: AppColors.pencilGraphite,
    ),
  ];

  static const List<UserAvatar> allAvatars = [
    UserAvatar(
      id: 'crown',
      label: 'Kral Taç',
      emoji: '👑',
      accentColor: AppColors.sunYellow,
      colorId: 'yellow',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'brain',
      label: 'Dahi Beyin',
      emoji: '🧠',
      accentColor: AppColors.highlighterPurple,
      colorId: 'purple',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'trophy',
      label: 'Şampiyon',
      emoji: '🏆',
      accentColor: AppColors.sunYellow,
      colorId: 'yellow',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'flame',
      label: 'Ateşli Seri',
      emoji: '🔥',
      accentColor: AppColors.highlighterPink,
      colorId: 'pink',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'target',
      label: 'Keskin Odak',
      emoji: '🎯',
      accentColor: AppColors.highlighterCyan,
      colorId: 'cyan',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'puzzle',
      label: 'Bulmaca Ustası',
      emoji: '🧩',
      accentColor: AppColors.highlighterPurple,
      colorId: 'purple',
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'owl',
      label: 'Bilge Baykuş',
      emoji: '🦉',
      accentColor: AppColors.skyBlue,
      colorId: 'sky',
    ),
    UserAvatar(
      id: 'fox',
      label: 'Kurnaz Tilki',
      emoji: '🦊',
      accentColor: AppColors.sunYellow,
      colorId: 'yellow',
    ),
    UserAvatar(
      id: 'wizard',
      label: 'Büyücü Zihin',
      emoji: '🧙‍♂️',
      accentColor: AppColors.highlighterPurple,
      colorId: 'purple',
    ),
    UserAvatar(
      id: 'ninja',
      label: 'Gölge Ninja',
      emoji: '🥷',
      accentColor: AppColors.pencilGraphite,
      colorId: 'graphite',
    ),
    UserAvatar(
      id: 'detective',
      label: 'Dedektif',
      emoji: '🕵️',
      accentColor: AppColors.skyBlue,
      colorId: 'sky',
    ),
    UserAvatar(
      id: 'rocket',
      label: 'Kozmik Roket',
      emoji: '🚀',
      accentColor: AppColors.highlighterPink,
      colorId: 'pink',
    ),
  ];

  UserAvatar copyWith({
    Color? accentColor,
    String? colorId,
  }) {
    return UserAvatar(
      id: id,
      label: label,
      emoji: emoji,
      accentColor: accentColor ?? this.accentColor,
      colorId: colorId ?? this.colorId,
      hasVectorDoodle: hasVectorDoodle,
    );
  }

  static AvatarBgColorOption getColorOptionById(String? colorId) {
    if (colorId == null || colorId.isEmpty) return bgColorOptions.first;
    return bgColorOptions.firstWhere(
      (c) => c.id == colorId,
      orElse: () => bgColorOptions.first,
    );
  }

  static String encodeId(String avatarId, String? colorId) {
    final cleanAvatar = avatarId.split(':').first.trim();
    if (colorId == null || colorId.trim().isEmpty) return cleanAvatar;
    return '$cleanAvatar:${colorId.trim()}';
  }

  static UserAvatar getById(String? rawId) {
    if (rawId == null || rawId.isEmpty) return allAvatars.first;
    final parts = rawId.split(':');
    final baseId = parts.first.trim();
    final customColorId = parts.length > 1 ? parts[1].trim() : null;

    final baseAvatar = allAvatars.firstWhere(
      (a) => a.id == baseId,
      orElse: () => allAvatars.first,
    );

    if (customColorId != null && customColorId.isNotEmpty) {
      final matchedColor = bgColorOptions.where((c) => c.id == customColorId);
      if (matchedColor.isNotEmpty) {
        return baseAvatar.copyWith(
          accentColor: matchedColor.first.color,
          colorId: matchedColor.first.id,
        );
      }
    }
    return baseAvatar;
  }

  Widget buildWidget({double size = 32, Color? tintColor}) {
    switch (id) {
      case 'crown':
        return SketchDoodleCrown(size: size, color: tintColor ?? AppColors.pencilBlack);
      case 'brain':
        return SketchDoodleBrain(size: size, color: tintColor ?? AppColors.pencilBlack);
      case 'trophy':
        return SketchDoodleTrophy(size: size, color: tintColor ?? AppColors.pencilBlack);
      case 'flame':
        return SketchDoodleFlame(size: size, color: tintColor ?? AppColors.pencilBlack);
      case 'target':
        return SketchDoodleTarget(size: size, color: tintColor ?? AppColors.pencilBlack);
      case 'puzzle':
        return SketchDoodlePuzzle(size: size, color: tintColor ?? AppColors.pencilBlack);
      default:
        return Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.72,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        );
    }
  }
}

