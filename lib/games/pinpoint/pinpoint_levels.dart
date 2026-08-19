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
      id: 'level_kutuphane',
      categoryHint: 'Edebiyat & Bilgi',
      targetWord: 'KİTAP',
      clues: ['Sayfa', 'Cilt', 'Yazar', 'Ayraç', 'Raf'],
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
