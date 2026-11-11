import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sketch_decorations.dart';

/// Kullanıcı eskiz profil avatarı modeli
class UserAvatar {
  final String id;
  final String label;
  final String emoji;
  final Color accentColor;
  final bool hasVectorDoodle;

  const UserAvatar({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentColor,
    this.hasVectorDoodle = false,
  });

  static const String defaultAvatarId = 'crown';

  static const List<UserAvatar> allAvatars = [
    UserAvatar(
      id: 'crown',
      label: 'Kral Taç',
      emoji: '👑',
      accentColor: AppColors.sunYellow,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'brain',
      label: 'Dahi Beyin',
      emoji: '🧠',
      accentColor: AppColors.highlighterPurple,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'trophy',
      label: 'Şampiyon',
      emoji: '🏆',
      accentColor: AppColors.sunYellow,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'flame',
      label: 'Ateşli Seri',
      emoji: '🔥',
      accentColor: AppColors.highlighterPink,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'target',
      label: 'Keskin Odak',
      emoji: '🎯',
      accentColor: AppColors.highlighterCyan,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'puzzle',
      label: 'Bulmaca Ustası',
      emoji: '🧩',
      accentColor: AppColors.highlighterPurple,
      hasVectorDoodle: true,
    ),
    UserAvatar(
      id: 'owl',
      label: 'Bilge Baykuş',
      emoji: '🦉',
      accentColor: AppColors.skyBlue,
    ),
    UserAvatar(
      id: 'fox',
      label: 'Kurnaz Tilki',
      emoji: '🦊',
      accentColor: AppColors.sunYellow,
    ),
    UserAvatar(
      id: 'wizard',
      label: 'Büyücü Zihin',
      emoji: '🧙‍♂️',
      accentColor: AppColors.highlighterPurple,
    ),
    UserAvatar(
      id: 'ninja',
      label: 'Gölge Ninja',
      emoji: '🥷',
      accentColor: AppColors.pencilGraphite,
    ),
    UserAvatar(
      id: 'detective',
      label: 'Dedektif',
      emoji: '🕵️',
      accentColor: AppColors.skyBlue,
    ),
    UserAvatar(
      id: 'rocket',
      label: 'Kozmik Roket',
      emoji: '🚀',
      accentColor: AppColors.highlighterPink,
    ),
  ];

  static UserAvatar getById(String? id) {
    if (id == null || id.isEmpty) return allAvatars.first;
    return allAvatars.firstWhere(
      (a) => a.id == id,
      orElse: () => allAvatars.first,
    );
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

