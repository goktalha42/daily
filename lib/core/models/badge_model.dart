import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../games/common/base_game.dart';

enum BadgeCategory {
  championship(
    label: 'Şampiyonluk Kemerleri (Süreli)',
    subtitle: 'Sürekli hak edilmesi gereken prestijli unvan kemerleri',
  ),
  gameMastery(
    label: 'Oyun Ustalığı (Kalıcı)',
    subtitle: 'Oyun bazlı başarılar ve özel hamleler',
  ),
  brainPower(
    label: 'Zekâ & Başarı (Kalıcı)',
    subtitle: 'IQ seviyesi ve genel zihinsel dominasyon',
  );

  final String label;
  final String subtitle;
  const BadgeCategory({required this.label, required this.subtitle});
}

class DailyBadge {
  final String id;
  final String title;
  final String description;
  final String requirement;
  final String emoji;
  final Color color;
  final BadgeCategory category;
  final bool isTemporary; // Şampiyonluk kemeri mi?
  final int validityDays; // Kaç gün geçerli?
  final GameType? relatedGame;

  const DailyBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.emoji,
    required this.color,
    required this.category,
    this.isTemporary = false,
    this.validityDays = 0,
    this.relatedGame,
  });

  static const List<DailyBadge> allBadges = [
    // --- 1. SÜRELİ ŞAMPİYONLUK KEMERLERİ (GEÇİCİ / HAK EDİLMESİ GEREKEN) ---
    DailyBadge(
      id: 'belt_queens_master',
      title: 'Vezirler Şampiyonluk Kemeri',
      description: 'Vezirler Master seviyesinde çift vezir kuralını başarıyla dize getiren şampiyonlara verilir.',
      requirement: 'Vezirler oyununda Master seviyeyi tamamla',
      emoji: '👑',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 7,
      relatedGame: GameType.queens,
    ),
    DailyBadge(
      id: 'belt_weekly_podium',
      title: 'Podyum Lideri Kemeri',
      description: 'Herhangi bir oyunun liderlik tablosunda ilk 3 sıraya adını yazdıran seçkin oyuncular taşır.',
      requirement: 'Liderlik tablosunda ilk 3 sıraya yerleş',
      emoji: '🏆',
      color: AppColors.highlighterOrange,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 7,
    ),
    DailyBadge(
      id: 'belt_lightning',
      title: 'Günün Şimşeği Kemeri',
      description: 'Bir bulmacayı 35 saniyenin altında ışık hızında çözen reaksiyon canavarlarına verilir.',
      requirement: 'Herhangi bir oyunu 35 saniyeden kısa sürede bitir',
      emoji: '⚡',
      color: AppColors.highlighterCyan,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 3,
    ),
    DailyBadge(
      id: 'belt_einstein',
      title: 'Einstein Zekâ Kemeri',
      description: 'Zekâ endeksi 130 IQ barajını aşarak bilim dünyasının zirvesini zorlayan dehalar takar.',
      requirement: 'Genel Zekâ Endeksinde 130 IQ seviyesine ulaş',
      emoji: '🧠',
      color: AppColors.highlighterPurple,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 7,
    ),
    DailyBadge(
      id: 'belt_streak_keeper',
      title: 'Seri Koruyucusu Kemeri',
      description: 'Her gün aksatmadan antrenman yapan, odaklanma disiplinini asla kaybetmeyenlere verilir.',
      requirement: '3 gün aralıksız günlük oyun oyna',
      emoji: '🔥',
      color: AppColors.error,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 3,
    ),

    // --- 2. OYUN USTALIĞI ROZETLERİ (KALICI KOLEKSİYON) ---
    DailyBadge(
      id: 'badge_queens_mastery',
      title: 'Vezirler Ustası',
      description: 'Satranç tahtasında vezirleri kusursuz bir uyumla yöneten satranç ve mantık ustası.',
      requirement: 'Vezirler oyununda 3 galibiyet al',
      emoji: '♟️',
      color: AppColors.accentPurple,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.queens,
    ),
    DailyBadge(
      id: 'badge_pinpoint_mastery',
      title: 'Kelime Dedektifi',
      description: 'En az ipucuyla gizli kelimeyi gün yüzüne çıkaran sözcük avcısı.',
      requirement: 'Kelime İzleri oyununda 3 galibiyet al',
      emoji: '🔍',
      color: AppColors.highlighterOrange,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.pinpoint,
    ),
    DailyBadge(
      id: 'badge_crossclimb_mastery',
      title: 'Zirve Tırmanıcısı',
      description: 'Harf dönüşümlerini adım adım takip ederek merdivenin tepesine ulaşan sözcük tırmanıcısı.',
      requirement: 'Kelime Tırmanışı oyununda 3 galibiyet al',
      emoji: '🧗',
      color: AppColors.highlighterGreen,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.crossclimb,
    ),
    DailyBadge(
      id: 'badge_tango_mastery',
      title: 'Güneş & Ay Dengesi',
      description: 'Gündüzle geceyi, güneşle ayı satırlara eşit dağıtan zıtlıklar ustası.',
      requirement: 'Güneş & Ay oyununda 3 galibiyet al',
      emoji: '☀️',
      color: AppColors.accentCyan,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.tango,
    ),
    DailyBadge(
      id: 'badge_zip_mastery',
      title: 'Sayıların Efendisi',
      description: 'Karmakarışık sayı ızgarasında tek bir kesintisiz yol çizen mantık ustası.',
      requirement: 'Sayı Yolu oyununda 3 galibiyet al',
      emoji: '🔢',
      color: AppColors.skyBlue,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.zipPath,
    ),
    DailyBadge(
      id: 'badge_patches_mastery',
      title: 'Geometri Mimarı',
      description: 'Izgarayı kusursuz orantılarla kare ve dikdörtgen alanlara bölen mimar.',
      requirement: 'Alan Bölme oyununda 3 galibiyet al',
      emoji: '📐',
      color: AppColors.highlighterPink,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.patches,
    ),

    // --- 3. ZEKA & BAŞARI ROZETLERİ (KALICI KOLEKSİYON) ---
    DailyBadge(
      id: 'badge_first_win',
      title: 'İlk Adım',
      description: 'Zihin egzersizi yolculuğuna ilk adımı atan ve ilk zaferini kazanan oyunculara verilir.',
      requirement: 'Herhangi bir oyunda ilk zaferini kazan',
      emoji: '🎓',
      color: AppColors.sunYellow,
      category: BadgeCategory.brainPower,
    ),
    DailyBadge(
      id: 'badge_genius_club',
      title: 'Dahi Kulübü (120+ IQ)',
      description: 'IQ testlerinde nüfusun %90\'ını geride bırakıp parlak zekâ kulübüne girenler.',
      requirement: 'Toplam 120 IQ seviyesine ulaş',
      emoji: '💡',
      color: AppColors.highlighterPurple,
      category: BadgeCategory.brainPower,
    ),
    DailyBadge(
      id: 'badge_all_rounder',
      title: 'Çok Yönlü Deha',
      description: 'Her alanda üstün: Kelimeler, sayılar, ızgaralar ve geometride eksiksiz zafer.',
      requirement: '6 farklı oyunun hepsinde en az 1 galibiyet elde et',
      emoji: '🌟',
      color: AppColors.highlighterCyan,
      category: BadgeCategory.brainPower,
    ),
  ];
}

class UserBadge {
  final String badgeId;
  final DateTime unlockedAt;
  final DateTime? expiresAt;

  const UserBadge({
    required this.badgeId,
    required this.unlockedAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get remainingDays {
    if (expiresAt == null) return -1;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  Map<String, dynamic> toJson() => {
        'badgeId': badgeId,
        'unlockedAt': unlockedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
        badgeId: json['badgeId'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
      );
}
