import 'crossclimb_models.dart';

class CrossclimbLevelRepository {
  // KURAL: Her adımda önceki kelimeyle TAM OLARAK 1 HARF değişmelidir.
  // Doğrulama: her ardışık çift arasında hamming distance = 1 olmalı.
  static final List<CrossclimbLevel> _presets = [
    // Seviye 1: KAR → TAR → TAS → TOS → TON
    CrossclimbLevel(
      id: 'level_kar_ton',
      startWord: 'KAR',
      endWord: 'TON',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'TAR', clue: 'Tarihi telli bir Türk çalgısı', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'TAS', clue: 'Hamam kabı, su kabı', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'TOS', clue: 'Bebek veya küçük çocuğa sevgiyle denir', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'TON', clue: '1000 kilogram ağırlık birimi', changedIndex: 2),
      ],
    ),
    // Seviye 2: SAL → SOL → KOL → KUL → KUT
    CrossclimbLevel(
      id: 'level_sal_kut',
      startWord: 'SAL',
      endWord: 'KUT',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'SOL', clue: 'Sağın karşıtı olan yön', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'KOL', clue: 'Vücudun omuzdan parmaklara uzanan uzvu', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'KUL', clue: 'Yaratıcıya bağlı olan insan / kul olmak', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'KUT', clue: 'Eski Türklerde ilahi uğur, kutsal güç', changedIndex: 2),
      ],
    ),
    // Seviye 3: ARI → ARA → ORA → ODA → ADA
    CrossclimbLevel(
      id: 'level_ari_ada',
      startWord: 'ARI',
      endWord: 'ADA',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'ARA', clue: 'İki şey arasındaki mesafe veya mola', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'ORA', clue: '"Burası" kelimesinin karşıtı olan yer', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'ODA', clue: 'Evin bölümlerinden her biri', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'ADA', clue: 'Dört tarafı sularla çevrili kara parçası', changedIndex: 0),
      ],
    ),
    // Seviye 4: KAS → KAŞ → BAŞ → BOŞ → BOR
    CrossclimbLevel(
      id: 'level_kas_bor',
      startWord: 'KAS',
      endWord: 'BOR',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KAŞ', clue: 'Gözün üstündeki kıllı yay biçimi', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'BAŞ', clue: 'Gövdenin üst kısmı, kafa', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'BOŞ', clue: 'Dolunun zıttı', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'BOR', clue: 'Türkiye\'nin zengin olduğu maden elementi', changedIndex: 2),
      ],
    ),
    // Seviye 5: BAL → DAL → DAM → ÇAM → ÇAY
    CrossclimbLevel(
      id: 'level_bal_cay',
      startWord: 'BAL',
      endWord: 'ÇAY',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'DAL', clue: 'Ağacın gövdesinden ayrılan kolları', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'DAM', clue: 'Evin çatısı, örtüsü', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'ÇAM', clue: 'İğne yapraklı orman ağacı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'ÇAY', clue: 'Demlenerek içilen geleneksel sıcak içecek', changedIndex: 2),
      ],
    ),
    // Seviye 6: KOR → KOY → SOY → SON → SEN
    CrossclimbLevel(
      id: 'level_kor_sen',
      startWord: 'KOR',
      endWord: 'SEN',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KOY', clue: 'Küçük körfez, denizin karaya girdiği girinti', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'SOY', clue: 'Bir atadan gelenlerin oluşturduğu sülale', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'SON', clue: 'İlk veya başlangıcın zıttı', changedIndex: 2),
        CrossclimbStep(index: 3, targetWord: 'SEN', clue: 'İkinci tekil şahıs zamiri', changedIndex: 1),
      ],
    ),
  ];

  static CrossclimbLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
