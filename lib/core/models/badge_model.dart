import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../games/common/base_game.dart';

enum BadgeCategory {
  streak(
    label: 'Seri Rozetleri (Kalıcı)',
    subtitle: 'Aralıksız oynama disiplini ve istikrar rekorları',
  ),
  championship(
    label: 'Süreli Rozetler & Şampiyonluk Kemerleri',
    subtitle: 'Koşul sağlandığı sürece taşınan dinamik unvanlar',
  ),
  gameMastery(
    label: 'Oyun Ustalığı (Kalıcı)',
    subtitle: 'Oyun bazlı ustalıklar ve galibiyetler',
  ),
  brainPower(
    label: 'Zekâ & Başarı (Kalıcı)',
    subtitle: 'IQ seviyesi ve zihinsel rekorlar',
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
  final bool isTemporary; // Süreli / Dinamik rozet mi?
  final int validityDays; // Kaç gün geçerli? (0 ise koşula bağlı dinamik)
  final GameType? relatedGame;
  final int streakDays;

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
    this.streakDays = 0,
  });

  /// Kullanıcının istediği seri eşikleri:
  /// 3, 5, 10, 15, 30, 50, 75, 100, 150, 200, 250, 300, 365
  static const List<int> streakTiers = [
    3, 5, 10, 15, 30, 50, 75, 100, 150, 200, 250, 300, 365,
  ];

  static List<DailyBadge> _generateStreakBadges() {
    final list = <DailyBadge>[];

    final games = <(GameType?, String, Color)>[
      (GameType.queens, 'Vezirler', AppColors.accentPurple),
      (GameType.pinpoint, 'Kelime İzleri', AppColors.highlighterOrange),
      (GameType.crossclimb, 'Kelime Tırmanışı', AppColors.success),
      (GameType.tango, 'Güneş & Ay', AppColors.accentCyan),
      (GameType.zipPath, 'Sayı Yolu', AppColors.skyBlue),
      (GameType.patches, 'Alan Bölme', AppColors.highlighterPink),
      (null, 'Genel Zihin', AppColors.sunYellow),
    ];

    for (final (gameType, gameName, gameColor) in games) {
      final prefix = gameType != null ? 'streak_${gameType.id}' : 'streak_all';

      for (final days in streakTiers) {
        String tierName;
        String emoji;

        if (days == 365) {
          tierName = 'Efsanevi Yıllık Seri (1 Yıl)';
          emoji = '👑';
        } else if (days >= 250) {
          tierName = 'Büyük Üstat Serisi ($days Gün)';
          emoji = '🏆';
        } else if (days >= 150) {
          tierName = 'Yarım Yıl Zihin Serisi ($days Gün)';
          emoji = '💎';
        } else if (days >= 100) {
          tierName = 'Yüzyıl Kulübü Serisi (100 Gün)';
          emoji = '🎖️';
        } else if (days >= 50) {
          tierName = 'Demir İrade Serisi ($days Gün)';
          emoji = '⚡';
        } else if (days >= 30) {
          tierName = 'Aylık İstikrar Serisi (30 Gün)';
          emoji = '🌟';
        } else if (days >= 15) {
          tierName = 'Odak Ustası Serisi (15 Gün)';
          emoji = '🎯';
        } else if (days >= 10) {
          tierName = '10 Günlük Seri';
          emoji = '🔥';
        } else if (days >= 5) {
          tierName = '5 Günlük Seri';
          emoji = '🔥';
        } else {
          tierName = '3 Günlük Başlangıç Serisi';
          emoji = '🔥';
        }

        final title = '$gameName: $tierName';
        final description = gameType != null
            ? '$gameName oyununu aralıksız $days gün boyunca her gün başarıyla tamamlayarak kazandığın kalıcı istikrar rozeti.'
            : 'Günlük zeka egzersizlerini aralıksız $days gün boyunca aksatmadan sürdürerek kazandığın genel istikrar rozeti.';
        final req = gameType != null
            ? '$gameName oyununda $days günlük aralıksız seri yap'
            : 'Her gün en az 1 oyun oynayarak $days günlük seri yap';

        list.add(DailyBadge(
          id: '${prefix}_$days',
          title: title,
          description: description,
          requirement: req,
          emoji: emoji,
          color: gameColor,
          category: BadgeCategory.streak,
          isTemporary: false,
          relatedGame: gameType,
          streakDays: days,
        ));
      }
    }

    return list;
  }

  static final List<DailyBadge> allBadges = [
    // --- 1. SÜRELİ ROZETLER & ŞAMPİYONLUK KEMERLERİ (DİNAMİK) ---
    const DailyBadge(
      id: 'belt_einstein',
      title: 'Einstein Zekâ Rozeti',
      description: 'Zekâ endeksin 130 IQ barajının üzerinde olduğu sürece profilde sol üst köşede gururla parlar. 130 IQ altına inildiğinde otomatik düşer.',
      requirement: 'Genel Zekâ Endeksinde 130+ IQ seviyesini koru',
      emoji: '🧠',
      color: AppColors.highlighterPurple,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 0, // Dinamik IQ koşulu
    ),
    const DailyBadge(
      id: 'belt_grandmaster',
      title: 'Büyük Usta Rozeti',
      description: 'Zekâ endeksin 120 IQ üzerinde olduğu sürece profilde aktif kalır. 120 IQ altına inildiğinde düşer.',
      requirement: 'Genel Zekâ Endeksinde 120+ IQ seviyesini koru',
      emoji: '💡',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 0, // Dinamik IQ koşulu
    ),
    const DailyBadge(
      id: 'belt_daily_champion',
      title: 'Zirve Hükümdarı Kemeri',
      description: 'Bugün herhangi bir oyunda liderlik tablosunda #1 sıraya yerleşen günün şampiyonuna verilir.',
      requirement: 'Herhangi bir oyunda günün sıralamasında 1. sıraya otur',
      emoji: '👑',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
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
    const DailyBadge(
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
    const DailyBadge(
      id: 'belt_queens_master',
      title: 'Vezirler Şampiyonluk Kemeri',
      description: 'Vezirler Master seviyesinde çift vezir kuralını başarıyla dize getiren şampiyonlara verilir.',
      requirement: 'Vezirler oyununda Master seviyeyi tamamla',
      emoji: '♟️',
      color: AppColors.accentPurple,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 7,
      relatedGame: GameType.queens,
    ),
    const DailyBadge(
      id: 'belt_night_owl',
      title: 'Gece Baykuşu Rozeti',
      description: 'Gece 00:00 ile 04:00 arasında günün yeni seviyesini anında çözen gece zihinlerine verilir.',
      requirement: 'Gece yarısı 00:00 - 04:00 saatleri arasında oyun kazan',
      emoji: '🦉',
      color: AppColors.highlighterPurple,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
      id: 'belt_early_bird',
      title: 'Erken Kalkan Deha',
      description: 'Sabah 05:00 ile 08:30 arasında güne zeka egzersiziyle başlayanlara verilir.',
      requirement: 'Sabah 05:00 - 08:30 saatleri arasında oyun kazan',
      emoji: '🌅',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
      id: 'belt_clean_sweep',
      title: 'Günün 6\'da 6 Fatihi',
      description: 'Aynı gün içinde uygulamanın 6 oyununun tamamını bitiren maraton şampiyonlarına verilir.',
      requirement: 'Günün tüm oyunlarını (6/6) aynı gün tamamla',
      emoji: '🎖️',
      color: AppColors.success,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
      id: 'belt_flawless',
      title: 'Kusursuz Sezon Kemeri',
      description: 'Herhangi bir oyunu tek bir hata veya yanlış tahmin yapmadan bitiren kusursuz odak ustalarına verilir.',
      requirement: 'Herhangi bir oyunu 0 hata ile tamamla',
      emoji: '🎯',
      color: AppColors.highlighterPink,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 3,
    ),

    // --- 2. OYUN USTALIĞI ROZETLERİ (KALICI KOLEKSİYON) ---
    const DailyBadge(
      id: 'badge_queens_mastery',
      title: 'Vezirler Ustası',
      description: 'Satranç tahtasında vezirleri kusursuz bir uyumla yöneten satranç ve mantık ustası.',
      requirement: 'Vezirler oyununda 3 galibiyet al',
      emoji: '♟️',
      color: AppColors.accentPurple,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.queens,
    ),
    const DailyBadge(
      id: 'badge_pinpoint_mastery',
      title: 'Kelime Dedektifi',
      description: 'En az ipucuyla gizli kelimeyi gün yüzüne çıkaran sözcük avcısı.',
      requirement: 'Kelime İzleri oyununda 3 galibiyet al',
      emoji: '🔍',
      color: AppColors.highlighterOrange,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.pinpoint,
    ),
    const DailyBadge(
      id: 'badge_crossclimb_mastery',
      title: 'Zirve Tırmanıcısı',
      description: 'Harf dönüşümlerini adım adım takip ederek merdivenin tepesine ulaşan sözcük tırmanıcısı.',
      requirement: 'Kelime Tırmanışı oyununda 3 galibiyet al',
      emoji: '🧗',
      color: AppColors.success,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.crossclimb,
    ),
    const DailyBadge(
      id: 'badge_tango_mastery',
      title: 'Güneş & Ay Dengesi',
      description: 'Gündüzle geceyi, güneşle ayı satırlara eşit dağıtan zıtlıklar ustası.',
      requirement: 'Güneş & Ay oyununda 3 galibiyet al',
      emoji: '☀️',
      color: AppColors.accentCyan,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.tango,
    ),
    const DailyBadge(
      id: 'badge_zip_mastery',
      title: 'Sayıların Efendisi',
      description: 'Karmakarışık sayı ızgarasında tek bir kesintisiz yol çizen mantık ustası.',
      requirement: 'Sayı Yolu oyununda 3 galibiyet al',
      emoji: '🔢',
      color: AppColors.skyBlue,
      category: BadgeCategory.gameMastery,
      relatedGame: GameType.zipPath,
    ),
    const DailyBadge(
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
    const DailyBadge(
      id: 'badge_first_win',
      title: 'İlk Adım',
      description: 'Zihin egzersizi yolculuğuna ilk adımı atan ve ilk zaferini kazanan oyunculara verilir.',
      requirement: 'Herhangi bir oyunda ilk zaferini kazan',
      emoji: '🎓',
      color: AppColors.sunYellow,
      category: BadgeCategory.brainPower,
    ),
    const DailyBadge(
      id: 'badge_genius_club',
      title: 'Dahi Kulübü (120+ IQ)',
      description: 'IQ testlerinde nüfusun %90\'ını geride bırakıp parlak zekâ kulübüne girenler.',
      requirement: 'Toplam 120 IQ seviyesine ulaş',
      emoji: '💡',
      color: AppColors.highlighterPurple,
      category: BadgeCategory.brainPower,
    ),
    const DailyBadge(
      id: 'badge_all_rounder',
      title: 'Çok Yönlü Deha',
      description: 'Her alanda üstün: Kelimeler, sayılar, ızgaralar ve geometride eksiksiz zafer.',
      requirement: '6 farklı oyunun hepsinde en az 1 galibiyet elde et',
      emoji: '🌟',
      color: AppColors.highlighterCyan,
      category: BadgeCategory.brainPower,
    ),
    const DailyBadge(
      id: 'badge_speed_demon',
      title: 'Işık Hızı Efendisi',
      description: 'Herhangi bir oyunu 20 saniyenin altında akıl almaz bir refleksle tamamlayanlar.',
      requirement: 'Bir oyunu 20 saniyeden kısa sürede çöz',
      emoji: '🚀',
      color: AppColors.highlighterCyan,
      category: BadgeCategory.brainPower,
    ),
    const DailyBadge(
      id: 'badge_century_club',
      title: '100\'ler Kulübü',
      description: 'Uygulamada toplam 100 oyun tamamlama kilometre taşına ulaşan vefakar zihinler.',
      requirement: 'Toplam 100 oyun tamamla',
      emoji: '💯',
      color: AppColors.highlighterOrange,
      category: BadgeCategory.brainPower,
    ),
    const DailyBadge(
      id: 'badge_perfectionist',
      title: 'Mükemmeliyetçi',
      description: 'Hatasız ve eksiksiz zihinsel odaklanma sergileyen titiz oyuncular.',
      requirement: '3 farklı oyunu tek bir hata yapmadan bitir',
      emoji: '✨',
      color: AppColors.sunYellow,
      category: BadgeCategory.brainPower,
    ),

    // --- 4. TÜM OYUNLAR İÇİN SERİ ROZETLERİ (KALICI KOLEKSİYON) ---
    ..._generateStreakBadges(),
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
