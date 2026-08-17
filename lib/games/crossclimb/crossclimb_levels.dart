import 'crossclimb_models.dart';

class CrossclimbLevelRepository {
  // KURAL: Her adımda önceki kelimeyle TAM OLARAK 1 HARF değişmelidir.
  // Doğrulama: her ardışık çift arasında hamming distance = 1 olmalı.
  static final List<CrossclimbLevel> _presets = [
    // Seviye 1: KAR → TAR → TAS → TOS → TON (5 harf 3 adım, kolay)
    CrossclimbLevel(
      id: '2026-08-17',
      startWord: 'KAR',
      endWord: 'TON',
      steps: [
        // KAR → TAR: K→T (pozisyon 0)
        CrossclimbStep(index: 0, targetWord: 'TAR', clue: 'Bitkisel madde, çatıda kullanılır', changedIndex: 0),
        // TAR → TAS: R→S (pozisyon 2)
        CrossclimbStep(index: 1, targetWord: 'TAS', clue: 'Hamam kabı, su kabı', changedIndex: 2),
        // TAS → TOS: A→O (pozisyon 1)
        CrossclimbStep(index: 2, targetWord: 'TOS', clue: 'Bebek veya küçük çocuğa denir', changedIndex: 1),
        // TOS → TON: S→N (pozisyon 2)
        CrossclimbStep(index: 3, targetWord: 'TON', clue: '1000 kilogram ağırlık birimi', changedIndex: 2),
      ],
    ),
    // Seviye 2: SAL → SOL → SOK → KOK → KÖK → 4 harf, 4 adım
    CrossclimbLevel(
      id: '2026-08-18',
      startWord: 'SAL',
      endWord: 'KOL',
      steps: [
        // SAL → SOL: A→O (pozisyon 1)
        CrossclimbStep(index: 0, targetWord: 'SOL', clue: 'Sağın karşıtı, yön', changedIndex: 1),
        // SOL → KOL: S→K (pozisyon 0)
        CrossclimbStep(index: 1, targetWord: 'KOL', clue: 'Vücudun uzuvlarından biri', changedIndex: 0),
      ],
    ),
    // Seviye 3: ARI → ARA → ORA → ODA  
    CrossclimbLevel(
      id: '2026-08-19',
      startWord: 'ARI',
      endWord: 'ODA',
      steps: [
        // ARI → ARA: I→A (pozisyon 2)
        CrossclimbStep(index: 0, targetWord: 'ARA', clue: 'Aradaki mesafe, boşluk', changedIndex: 2),
        // ARA → ORA: A→O (pozisyon 0)
        CrossclimbStep(index: 1, targetWord: 'ORA', clue: '"Burası" nın karşıtı olan yer zarfı', changedIndex: 0),
        // ORA → ODA: R→D (pozisyon 1)
        CrossclimbStep(index: 2, targetWord: 'ODA', clue: 'Evin bölümleri, yatak ___', changedIndex: 1),
      ],
    ),
  ];

  static CrossclimbLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
