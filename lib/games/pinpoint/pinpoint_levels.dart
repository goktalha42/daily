import 'pinpoint_models.dart';

class PinpointLevelRepository {
  static final List<PinpointLevel> _presetLevels = [
    PinpointLevel(
      id: '2026-08-17',
      categoryHint: 'Ortak Kavram / Tematik Bağlantı',
      targetWord: 'KAHVE',
      clues: ['Espresso', 'Kolombiya', 'Çekirdek', 'Fincan', 'Sabah'],
    ),
    PinpointLevel(
      id: '2026-08-18',
      categoryHint: 'Doğa ve Uzay',
      targetWord: 'GEZEGEN',
      clues: ['Yörünge', 'Yerçekimi', 'Jüpiter', 'Kutup', 'Atmosfer'],
    ),
    PinpointLevel(
      id: '2026-08-19',
      categoryHint: 'Müzik ve Sanat',
      targetWord: 'GİTAR',
      clues: ['Akort', 'Tel', 'Pena', 'Solo', 'Melodi'],
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
