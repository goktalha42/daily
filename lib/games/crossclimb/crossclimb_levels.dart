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
    // Seviye 7: KAN → KAT → KOT → BOT → BOŞ
    CrossclimbLevel(
      id: 'level_kan_bos',
      startWord: 'KAN',
      endWord: 'BOŞ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KAT', clue: 'Bir yapının tabanları arasındaki bölüm', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'KOT', clue: 'Bir tür dayanıklı pamuklu kumaş veya pantolon', changedIndex: 1),
        CrossclimbStep(index: 2, targetWord: 'BOT', clue: 'Küçük deniz taşıtı veya kalın kışlık ayakkabı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'BOŞ', clue: 'İçinde hiçbir şey bulunmayan, dolunun zıttı', changedIndex: 2),
      ],
    ),
    // Seviye 8: MAT → MAL → NAL → NAR → NUR
    CrossclimbLevel(
      id: 'level_mat_nur',
      startWord: 'MAT',
      endWord: 'NUR',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'MAL', clue: 'Mülk, eşya veya ticari değeri olan ürün', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'NAL', clue: 'Atların tırnağına çakılan koruyucu demir', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'NAR', clue: 'İçi kırmızı tanelerle dolu bereketli meyve', changedIndex: 2),
        CrossclimbStep(index: 3, targetWord: 'NUR', clue: 'İlahi ışık, aydınlık', changedIndex: 1),
      ],
    ),
    // Seviye 9: YOL → YEL → KEL → KİL → DİL
    CrossclimbLevel(
      id: 'level_yol_dil',
      startWord: 'YOL',
      endWord: 'DİL',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'YEL', clue: 'Hafif esen tatlı rüzgar', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'KEL', clue: 'Saçı dökülmüş, saçsız baş', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'KİL', clue: 'Çömlek ve seramik yapılan sarımsı toprak', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'DİL', clue: 'Ağızdaki tat alma organı veya lisan', changedIndex: 0),
      ],
    ),
    // Seviye 10: CAM → ÇAM → ÇAY → PAY → PAK
    CrossclimbLevel(
      id: 'level_cam_pak',
      startWord: 'CAM',
      endWord: 'PAK',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'ÇAM', clue: 'Kışın yaprak dökmeyen iğne yapraklı ağaç', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'ÇAY', clue: 'Geleneksel olarak demlenen sıcak içecek', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'PAY', clue: 'Bölüşülen bir bütünden düşen hisse', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'PAK', clue: 'Tertemiz, arı, lekesiz', changedIndex: 2),
      ],
    ),
    // Seviye 11: KAŞ → YAŞ → YAĞ → DAĞ → BAĞ
    CrossclimbLevel(
      id: 'level_kas_bag',
      startWord: 'KAŞ',
      endWord: 'BAĞ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'YAŞ', clue: 'Islak, nemli veya insanın ömür yılı', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'YAĞ', clue: 'Zeytinyağı veya tereyağı gibi besin maddesi', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'DAĞ', clue: 'Yerkabuğunun yüksek tepe ve dorukları', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'BAĞ', clue: 'Üzüm bahçesi veya iki şey arasındaki ilişki', changedIndex: 0),
      ],
    ),
    // Seviye 12: GÖL → GÖZ → GÜZ → YÜZ → YAZ
    CrossclimbLevel(
      id: 'level_gol_yaz',
      startWord: 'GÖL',
      endWord: 'YAZ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'GÖZ', clue: 'Görme duyusu organı', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'GÜZ', clue: 'Yaprak dökümü mevsimi, sonbahar', changedIndex: 1),
        CrossclimbStep(index: 2, targetWord: 'YÜZ', clue: 'İnsan çehresi veya 100 sayısı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'YAZ', clue: 'En sıcak mevsim veya kalemle kağıda dökmek', changedIndex: 1),
      ],
    ),
  ];

  static CrossclimbLevel getLevelForDate(String levelId) {
    final hash = levelId.hashCode.abs();
    final index = hash % _presets.length;
    return _presets[index];
  }
}
