import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../games/common/base_game.dart';

enum BadgeCategory {
  mastery(
    label: 'Kişisel Başarılar',
    subtitle: 'Oyun ustalıkları, hız ve zeka rekorları',
  ),
  streak(
    label: 'İstikrar Serileri',
    subtitle: 'Aralıksız oynama disiplini ve istikrar rekorları',
  ),
  championship(
    label: 'Arena & Şampiyonluk',
    subtitle: 'Liderlik tablosu, podyum ve lig dereceleri',
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
  final bool isTemporary;
  final int validityDays;
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

  static const List<int> streakTiers = [3, 7, 14, 30, 60, 100, 365];

  static List<DailyBadge> _buildStreakBadges() {
    return const [
      DailyBadge(
        id: 'streak_all_3',
        title: '3 Günlük Kıvılcım',
        description: 'Zihinsel egzersiz disiplinini 3 gün boyunca aralıksız sürdürdün.',
        requirement: 'Aralıksız 3 gün bulmaca çöz',
        emoji: '🔥',
        color: AppColors.accentOrange,
        category: BadgeCategory.streak,
        streakDays: 3,
      ),
      DailyBadge(
        id: 'streak_all_7',
        title: 'Haftalık Meşale',
        description: 'Tam 1 hafta boyunca zihnini her gün aktif tuttun.',
        requirement: 'Aralıksız 7 gün bulmaca çöz',
        emoji: '🔥',
        color: AppColors.sunYellow,
        category: BadgeCategory.streak,
        streakDays: 7,
      ),
      DailyBadge(
        id: 'streak_all_14',
        title: '2 Haftalık Alışkanlık',
        description: '2 hafta boyunca her gün bulmaca çözerek kalıcı zihin alışkanlığı kurdun.',
        requirement: 'Aralıksız 14 gün bulmaca çöz',
        emoji: '🌟',
        color: AppColors.accentCyan,
        category: BadgeCategory.streak,
        streakDays: 14,
      ),
      DailyBadge(
        id: 'streak_all_30',
        title: 'Aylık Çelik İrade',
        description: 'Tam 1 ay boyunca aralıksız zeka disiplini sergiledin.',
        requirement: 'Aralıksız 30 gün bulmaca çöz',
        emoji: '⚡',
        color: AppColors.accentPurple,
        category: BadgeCategory.streak,
        streakDays: 30,
      ),
      DailyBadge(
        id: 'streak_all_60',
        title: '60 Günlük Bilge',
        description: '2 ay boyunca aksatmadan her gün zihinsel sınırlarını zorladın.',
        requirement: 'Aralıksız 60 gün bulmaca çöz',
        emoji: '💎',
        color: Color(0xFF38BDF8),
        category: BadgeCategory.streak,
        streakDays: 60,
      ),
      DailyBadge(
        id: 'streak_all_100',
        title: 'Yüzyıl Efsanesi',
        description: 'Tam 100 gün boyunca kesintisiz zeka serisi sürdürerek efsaneler arasına girdin.',
        requirement: 'Aralıksız 100 gün bulmaca çöz',
        emoji: '🎖️',
        color: Color(0xFF10B981),
        category: BadgeCategory.streak,
        streakDays: 100,
      ),
      DailyBadge(
        id: 'streak_all_365',
        title: '1 Yıllık Ölümsüz Zihin',
        description: '365 gün boyunca her gün bulmaca çözerek tarihe geçtin.',
        requirement: 'Aralıksız 365 gün bulmaca çöz',
        emoji: '👑',
        color: AppColors.sunYellow,
        category: BadgeCategory.streak,
        streakDays: 365,
      ),
    ];
  }

  static final List<DailyBadge> allBadges = [
    // ─── 1. KİŞİSEL BAŞARILAR & USTALIKLAR ──────────────────────────────────
    const DailyBadge(
      id: 'badge_first_win',
      title: 'İlk Zafer',
      description: 'Zühtü evrenindeki ilk bulmacanı başarıyla tamamlayarak zeka yolculuğuna başladın.',
      requirement: 'Herhangi bir oyunu başarıyla tamamla',
      emoji: '🌱',
      color: AppColors.success,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'belt_clean_sweep',
      title: 'Mükemmel Gün (6/6)',
      description: 'Günün tüm 6 bulmacasını eksiksiz çözerek zihnini her alanda kanıtladın.',
      requirement: 'Aynı günde 6 oyunun tamamını bitir',
      emoji: '🎯',
      color: AppColors.sunYellow,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'badge_speed_demon',
      title: 'Işık Hızı Efendisi',
      description: 'Herhangi bir bulmacayı 20 saniyenin altında çözerek insanüstü bir refleks gösterdin.',
      requirement: 'Bir oyunu 20 saniyeden kısa sürede bitir',
      emoji: '⚡',
      color: AppColors.accentCyan,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'belt_lightning',
      title: 'Şimşek Zihin',
      description: 'Herhangi bir oyunu 35 saniyenin altında bitiren hızlı düşünürlere verilir.',
      requirement: 'Bir oyunu 35 saniyeden kısa sürede bitir',
      emoji: '⚡',
      color: AppColors.accentOrange,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'belt_queens_master',
      title: 'Vezir Hükümdarı',
      description: 'Vezirler oyununun en zorlu Master modunu tek bir hata yapmadan dize getirdin.',
      requirement: 'Vezirler Master seviyesini başarıyla bitir',
      emoji: '👑',
      color: AppColors.accentPurple,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'badge_queens_mastery',
      title: 'Vezir Ustası',
      description: 'Vezirler tahtasında stratejik hamlelerinle en az 3 zafer kazandın.',
      requirement: 'Vezirler oyununda 3 galibiyet elde et',
      emoji: '👸',
      color: AppColors.accentPurple,
      category: BadgeCategory.mastery,
      relatedGame: GameType.queens,
    ),
    const DailyBadge(
      id: 'badge_pinpoint_mastery',
      title: 'Kelime Dedektifi',
      description: 'Kelime İzleri oyununda gizli çağrışımları en az 3 kez ustalıkla çözdün.',
      requirement: 'Kelime İzleri oyununda 3 galibiyet elde et',
      emoji: '🔍',
      color: AppColors.accentOrange,
      category: BadgeCategory.mastery,
      relatedGame: GameType.pinpoint,
    ),
    const DailyBadge(
      id: 'badge_crossclimb_mastery',
      title: 'Tırmanış Kralı',
      description: 'Kelime Tırmanışı merdivenini en az 3 kez zirveye kadar tırmandın.',
      requirement: 'Kelime Tırmanışı oyununda 3 galibiyet elde et',
      emoji: '🧗',
      color: AppColors.success,
      category: BadgeCategory.mastery,
      relatedGame: GameType.crossclimb,
    ),
    const DailyBadge(
      id: 'badge_tango_mastery',
      title: 'Güneş & Ay Dengesi',
      description: 'Güneş ve Ay ızgarasında göksel dengeyi en az 3 kez kurdun.',
      requirement: 'Güneş ve Ay oyununda 3 galibiyet elde et',
      emoji: '☀️',
      color: AppColors.accentCyan,
      category: BadgeCategory.mastery,
      relatedGame: GameType.tango,
    ),
    const DailyBadge(
      id: 'badge_zip_mastery',
      title: 'Labirent Gezgini',
      description: 'Sayı Yolu üzerinde tek hat çizerek en az 3 kez doğru yolu buldun.',
      requirement: 'Sayı Yolu oyununda 3 galibiyet elde et',
      emoji: '🧭',
      color: Color(0xFF38BDF8),
      category: BadgeCategory.mastery,
      relatedGame: GameType.zipPath,
    ),
    const DailyBadge(
      id: 'badge_patches_mastery',
      title: 'Bölge Mimarı',
      description: 'Alan Bölme tahtasını matematiksel kesinlikle en az 3 kez paylaştırdın.',
      requirement: 'Alan Bölme oyununda 3 galibiyet elde et',
      emoji: '🧩',
      color: AppColors.accentPink,
      category: BadgeCategory.mastery,
      relatedGame: GameType.patches,
    ),
    const DailyBadge(
      id: 'badge_all_rounder',
      title: 'Çok Yönlü Deha',
      description: '6 farklı oyunun tamamında galibiyet alarak her alanda yetenekli olduğunu kanıtladın.',
      requirement: 'Tüm 6 oyunun her birinde en az 1 galibiyet al',
      emoji: '🌟',
      color: AppColors.sunYellow,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'badge_century_club',
      title: '100 Oyun Kulübü',
      description: 'Zühtü evreninde toplam 100 bulmacayı çözerek elit zeka kulübüne dahil oldun.',
      requirement: 'Toplam 100 oyun tamamla',
      emoji: '💯',
      color: Color(0xFFD97706),
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'belt_night_owl',
      title: 'Gece Baykuşu',
      description: 'Gece yarısı 00:00 - 04:00 saatleri arasında zihnini diri tutarak bulmaca çözdün.',
      requirement: 'Gece 00:00 - 04:00 arasında bir oyun tamamla',
      emoji: '🦉',
      color: AppColors.accentPurple,
      category: BadgeCategory.mastery,
    ),
    const DailyBadge(
      id: 'belt_early_bird',
      title: 'Erken Kalkan Deha',
      description: 'Sabah 05:00 - 09:00 saatleri arasında güne zeka egzersiziyle başladın.',
      requirement: 'Sabah 05:00 - 09:00 arasında bir oyun tamamla',
      emoji: '🌅',
      color: AppColors.accentOrange,
      category: BadgeCategory.mastery,
    ),

    // ─── 2. İSTİKRAR SERİLERİ ──────────────────────────────────────────────
    ..._buildStreakBadges(),

    // ─── 3. ARENA & ŞAMPİYONLUK ───────────────────────────────────────────
    const DailyBadge(
      id: 'belt_daily_champion',
      title: 'Günün Zirve Şampiyonu',
      description: 'Bugün herhangi bir oyunda günün sıralamasında #1. sıraya oturarak zirveyi fethettin.',
      requirement: 'Herhangi bir oyunda günün sıralamasında 1. sıraya otur',
      emoji: '👑',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
      id: 'belt_weekly_podium',
      title: 'Podyum Yıldızı (İlk 3)',
      description: 'Liderlik tablosunda günün en iyi 3 zekası arasına adını yazdırdın.',
      requirement: 'Sıralamada ilk 3 dereceye gir',
      emoji: '🏆',
      color: AppColors.accentOrange,
      category: BadgeCategory.championship,
      isTemporary: true,
      validityDays: 1,
    ),
    const DailyBadge(
      id: 'belt_einstein',
      title: 'Einstein Zekâ Endeksi (148+)',
      description: 'Tüm kategorilerde mutlak ustalık ve 148+ IQ ile tarihe geçen efsane deha.',
      requirement: 'Tüm 6 kategoriyi fethedip 148+ IQ endeksine ulaş',
      emoji: '🧠',
      color: AppColors.accentPurple,
      category: BadgeCategory.championship,
      isTemporary: true,
    ),
    const DailyBadge(
      id: 'belt_grandmaster',
      title: 'Büyük Usta Endeksi (120+)',
      description: 'Genel Zekâ Endeksin 120 IQ üzerinde olduğu sürece profilde aktif kalır.',
      requirement: 'Genel IQ endeksinde 120+ puanı koru',
      emoji: '💡',
      color: AppColors.sunYellow,
      category: BadgeCategory.championship,
      isTemporary: true,
    ),
    const DailyBadge(
      id: 'badge_genius_club',
      title: 'Dahi Kulübü (Kalıcı)',
      description: 'Kariyerinde en az bir kez 120+ IQ seviyesine ulaşarak dahi diplomasını aldın.',
      requirement: 'En az bir kez 120+ IQ seviyesine ulaş',
      emoji: '🎓',
      color: Color(0xFF10B981),
      category: BadgeCategory.championship,
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
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() => {
        'badgeId': badgeId,
        'unlockedAt': unlockedAt.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
        badgeId: json['badgeId'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );
}
