import 'pinpoint_models.dart';

class PinpointLevelRepository {
  static final List<PinpointLevel> _presetLevels = [
    // Seviye 1
    PinpointLevel(
      id: 'level_kahve',
      categoryHint: 'İçecek & Günlük Yaşam',
      targetWord: 'KAHVE',
      clues: ['Espresso', 'Kolombiya', 'Çekirdek', 'Fincan', 'Sabah'],
    ),
    // Seviye 2
    PinpointLevel(
      id: 'level_gezegen',
      categoryHint: 'Doğa ve Uzay',
      targetWord: 'GEZEGEN',
      clues: ['Yörünge', 'Yerçekimi', 'Jüpiter', 'Kutup', 'Atmosfer'],
    ),
    // Seviye 3
    PinpointLevel(
      id: 'level_gitar',
      categoryHint: 'Müzik ve Sanat',
      targetWord: 'GİTAR',
      clues: ['Akort', 'Tel', 'Pena', 'Solo', 'Melodi'],
    ),
    // Seviye 4
    PinpointLevel(
      id: 'level_sinema',
      categoryHint: 'Kültür & Eğlence',
      targetWord: 'SİNEMA',
      clues: ['Koltuk', 'Kamera', 'Patlamış Mısır', 'Perde', 'Yönetmen'],
    ),
    // Seviye 5
    PinpointLevel(
      id: 'level_kaptan',
      categoryHint: 'Denizcilik & Macera',
      targetWord: 'KAPTAN',
      clues: ['Pusula', 'Dümen', 'Liman', 'Güverte', 'Dalga'],
    ),
    // Seviye 6
    PinpointLevel(
      id: 'level_mutfak',
      categoryHint: 'Gastronomi & Ev',
      targetWord: 'MUTFAK',
      clues: ['Önlük', 'Tencere', 'Baharat', 'Bıçak', 'Yemek'],
    ),
    // Seviye 7
    PinpointLevel(
      id: 'level_futbol',
      categoryHint: 'Spor & Rekabet',
      targetWord: 'FUTBOL',
      clues: ['Düdük', 'Krampon', 'Kale', 'Penaltı', 'Taraftar'],
    ),
    // Seviye 8
    PinpointLevel(
      id: 'level_kitap',
      categoryHint: 'Edebiyat & Bilgi',
      targetWord: 'KİTAP',
      clues: ['Sayfa', 'Cilt', 'Yazar', 'Ayraç', 'Raf'],
    ),
    // Seviye 9
    PinpointLevel(
      id: 'level_piyano',
      categoryHint: 'Enstrüman & Klasik',
      targetWord: 'PİYANO',
      clues: ['Tuş', 'Pedal', 'Kuyruk', 'Konser', 'Nota'],
    ),
    // Seviye 10
    PinpointLevel(
      id: 'level_doktor',
      categoryHint: 'Tıp & Sağlık',
      targetWord: 'DOKTOR',
      clues: ['Stetoskop', 'Beyaz Önlük', 'Reçete', 'Muayene', 'Şifa'],
    ),
    // Seviye 11
    PinpointLevel(
      id: 'level_astronot',
      categoryHint: 'Bilim & Kozmos',
      targetWord: 'ASTRONOT',
      clues: ['Kask', 'Yerçekimsiz', 'Uzay İstasyonu', 'Ay', 'Roket'],
    ),
    // Seviye 12
    PinpointLevel(
      id: 'level_kamp',
      categoryHint: 'Doğa & Macera',
      targetWord: 'KAMP',
      clues: ['Çadır', 'Uyku Tulumu', 'Ateş', 'Matara', 'Yıldızlar'],
    ),
    // Seviye 13
    PinpointLevel(
      id: 'level_dedektif',
      categoryHint: 'Gizem & Suç',
      targetWord: 'DEDEKTİF',
      clues: ['Büyüteç', 'İpucu', 'Parmak İzi', 'Şüpheli', 'Gizem'],
    ),
    // Seviye 14
    PinpointLevel(
      id: 'level_saat',
      categoryHint: 'Zaman & Günlük',
      targetWord: 'SAAT',
      clues: ['Yelkovan', 'Akrep', 'Tik Tak', 'Alarm', 'Zaman'],
    ),
    // Seviye 15
    PinpointLevel(
      id: 'level_ucak',
      categoryHint: 'Havacılık & Seyahat',
      targetWord: 'UÇAK',
      clues: ['Kanat', 'Kokpit', 'Hostes', 'İniş Pisti', 'Bulutlar'],
    ),
    // Seviye 16
    PinpointLevel(
      id: 'level_ressam',
      categoryHint: 'Görsel Sanatlar',
      targetWord: 'RESSAM',
      clues: ['Tuval', 'Şövale', 'Fırça', 'Palet', 'Boya'],
    ),
    // Seviye 17
    PinpointLevel(
      id: 'level_deprem',
      categoryHint: 'Coğrafya & Doğa Olayı',
      targetWord: 'DEPREM',
      clues: ['Fay Hattı', 'Richter', 'Sarsıntı', 'Sismograf', 'Artçı'],
    ),
    // Seviye 18
    PinpointLevel(
      id: 'level_tiyatro',
      categoryHint: 'Sahne Sanatları',
      targetWord: 'TİYATRO',
      clues: ['Sahne', 'Kostüm', 'Alkış', 'Replik', 'Perde'],
    ),
    // Seviye 19
    PinpointLevel(
      id: 'level_volkan',
      categoryHint: 'Jeoloji & Doğa',
      targetWord: 'VOLKAN',
      clues: ['Lav', 'Magma', 'Krater', 'Kül', 'Püskürme'],
    ),
    // Seviye 20
    PinpointLevel(
      id: 'level_ari',
      categoryHint: 'Biyoloji & Canlılar',
      targetWord: 'ARI',
      clues: ['Kovan', 'Polen', 'Petek', 'Kraliçe', 'Bal'],
    ),
  ];

  static PinpointLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presetLevels.length;
    final preset = _presetLevels[index];

    return PinpointLevel(
      id: levelId,
      categoryHint: preset.categoryHint,
      targetWord: preset.targetWord.toUpperCase(),
      clues: preset.clues,
    );
  }
}
