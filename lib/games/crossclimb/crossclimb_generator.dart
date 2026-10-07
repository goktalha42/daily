import '../../core/puzzle/puzzle_seed.dart';
import 'crossclimb_logic.dart';
import 'crossclimb_models.dart';

/// Crossclimb (Kelime Tırmanışı) günlük seviyelerini tohumdan deterministik olarak üretir / seçer.
class CrossclimbGenerator {
  const CrossclimbGenerator._();

  static final DateTime _epoch = DateTime.utc(2026, 1, 1);

  static CrossclimbLevel generate({required String levelId}) {
    DateTime date;
    try {
      date = DateTime.parse(levelId);
    } catch (_) {
      date = DateTime.now();
    }
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final days = normalizedDate.difference(_epoch).inDays.abs();

    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('crossclimb-daily', '$days'));
    final index = seed % _pool.length;
    final item = _pool[index];

    final level = CrossclimbLevel(
      id: levelId,
      startWord: CrossclimbLogic.normalize(item.startWord),
      endWord: CrossclimbLogic.normalize(item.endWord),
      steps: item.steps,
    );

    assert(CrossclimbLogic.validateLevel(level), 'Geçersiz Crossclimb zinciri: ${level.id}');
    return level;
  }

  static List<CrossclimbLevel> get pool => List.unmodifiable(_pool);

  /// Zengin Türkçe kelime merdiveni (1 harf değişim zinciri) havuzu
  static final List<CrossclimbLevel> _pool = [
    // 1: KAR → TAR → TAS → TOS → TON
    CrossclimbLevel(
      id: 'cc_kar_ton',
      startWord: 'KAR',
      endWord: 'TON',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'TAR', clue: 'Tarihi telli bir Türk çalgısı', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'TAS', clue: 'Hamam kabı veya su kabı', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'TOS', clue: 'Bebek veya küçük çocuğa sevgiyle söylenir', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'TON', clue: '1000 kilogram ağırlık birimi', changedIndex: 2),
      ],
    ),
    // 2: SAL → SOL → KOL → KUL → KUT
    CrossclimbLevel(
      id: 'cc_sal_kut',
      startWord: 'SAL',
      endWord: 'KUT',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'SOL', clue: 'Sağın karşıtı olan yön', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'KOL', clue: 'Vücudun omuzdan parmaklara uzanan uzvu', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'KUL', clue: 'Yaratıcıya bağlı olan insan / kul olmak', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'KUT', clue: 'Eski Türklerde ilahi uğur, kutsal güç', changedIndex: 2),
      ],
    ),
    // 3: ARI → ARA → ORA → ODA → ADA
    CrossclimbLevel(
      id: 'cc_ari_ada',
      startWord: 'ARI',
      endWord: 'ADA',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'ARA', clue: 'İki şey arasındaki mesafe veya mola', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'ORA', clue: '"Burası" kelimesinin karşıtı olan yer', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'ODA', clue: 'Evin bölümlerinden her biri', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'ADA', clue: 'Dört tarafı sularla çevrili kara parçası', changedIndex: 0),
      ],
    ),
    // 4: KAS → KAŞ → BAŞ → BOŞ → BOR
    CrossclimbLevel(
      id: 'cc_kas_bor',
      startWord: 'KAS',
      endWord: 'BOR',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KAŞ', clue: 'Gözün üstündeki kıllı yay biçimi', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'BAŞ', clue: 'Gövdenin üst kısmı, kafa', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'BOŞ', clue: 'Dolunun zıttı, içinde bir şey olmayan', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'BOR', clue: 'Türkiye\'nin zengin olduğu maden elementi', changedIndex: 2),
      ],
    ),
    // 5: BAL → DAL → DAM → ÇAM → ÇAY
    CrossclimbLevel(
      id: 'cc_bal_cay',
      startWord: 'BAL',
      endWord: 'ÇAY',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'DAL', clue: 'Ağacın gövdesinden ayrılan kolları', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'DAM', clue: 'Evin çatısı, örtüsü', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'ÇAM', clue: 'İğne yapraklı orman ağacı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'ÇAY', clue: 'Demlenerek içilen geleneksel sıcak içecek', changedIndex: 2),
      ],
    ),
    // 6: KOR → KOY → SOY → SON → SEN
    CrossclimbLevel(
      id: 'cc_kor_sen',
      startWord: 'KOR',
      endWord: 'SEN',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KOY', clue: 'Küçük körfez, denizin karaya girdiği girinti', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'SOY', clue: 'Bir atadan gelenlerin oluşturduğu sülale', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'SON', clue: 'İlk veya başlangıcın zıttı', changedIndex: 2),
        CrossclimbStep(index: 3, targetWord: 'SEN', clue: 'İkinci tekil şahıs zamiri', changedIndex: 1),
      ],
    ),
    // 7: KAN → KAT → KOT → BOT → BOŞ
    CrossclimbLevel(
      id: 'cc_kan_bos',
      startWord: 'KAN',
      endWord: 'BOŞ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KAT', clue: 'Bir yapının tabanları arasındaki bölüm', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'KOT', clue: 'Dayanıklı pamuklu kumaş veya pantolon', changedIndex: 1),
        CrossclimbStep(index: 2, targetWord: 'BOT', clue: 'Küçük deniz taşıtı veya kalın kışlık ayakkabı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'BOŞ', clue: 'İçinde hiçbir şey bulunmayan', changedIndex: 2),
      ],
    ),
    // 8: MAT → MAL → NAL → NAR → NUR
    CrossclimbLevel(
      id: 'cc_mat_nur',
      startWord: 'MAT',
      endWord: 'NUR',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'MAL', clue: 'Mülk, eşya veya ticari değeri olan ürün', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'NAL', clue: 'Atların tırnağına çakılan koruyucu demir', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'NAR', clue: 'İçi kırmızı tanelerle dolu bereketli meyve', changedIndex: 2),
        CrossclimbStep(index: 3, targetWord: 'NUR', clue: 'İlahi ışık, aydınlık', changedIndex: 1),
      ],
    ),
    // 9: YOL → YEL → KEL → KİL → DİL
    CrossclimbLevel(
      id: 'cc_yol_dil',
      startWord: 'YOL',
      endWord: 'DİL',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'YEL', clue: 'Hafif esen tatlı rüzgar', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'KEL', clue: 'Saçı dökülmüş, saçsız baş', changedIndex: 0),
        CrossclimbStep(index: 2, targetWord: 'KİL', clue: 'Çömlek ve seramik yapılan sarımsı toprak', changedIndex: 1),
        CrossclimbStep(index: 3, targetWord: 'DİL', clue: 'Ağızdaki tat alma organı veya lisan', changedIndex: 0),
      ],
    ),
    // 10: CAM → ÇAM → ÇAY → PAY → PAK
    CrossclimbLevel(
      id: 'cc_cam_pak',
      startWord: 'CAM',
      endWord: 'PAK',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'ÇAM', clue: 'Kışın yaprak dökmeyen iğne yapraklı ağaç', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'ÇAY', clue: 'Geleneksel olarak demlenen sıcak içecek', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'PAY', clue: 'Bölüşülen bir bütünden düşen hisse', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'PAK', clue: 'Tertemiz, arı, lekesiz', changedIndex: 2),
      ],
    ),
    // 11: KAŞ → YAŞ → YAĞ → DAĞ → BAĞ
    CrossclimbLevel(
      id: 'cc_kas_bag',
      startWord: 'KAŞ',
      endWord: 'BAĞ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'YAŞ', clue: 'Islak, nemli veya insanın ömür yılı', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'YAĞ', clue: 'Zeytinyağı veya tereyağı gibi besin maddesi', changedIndex: 2),
        CrossclimbStep(index: 2, targetWord: 'DAĞ', clue: 'Yerkabuğunun yüksek tepe ve dorukları', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'BAĞ', clue: 'Üzüm bahçesi veya iki şey arasındaki bağ', changedIndex: 0),
      ],
    ),
    // 12: GÖL → GÖZ → GÜZ → YÜZ → YAZ
    CrossclimbLevel(
      id: 'cc_gol_yaz',
      startWord: 'GÖL',
      endWord: 'YAZ',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'GÖZ', clue: 'Görme duyusu organı', changedIndex: 2),
        CrossclimbStep(index: 1, targetWord: 'GÜZ', clue: 'Yaprak dökümü mevsimi, sonbahar', changedIndex: 1),
        CrossclimbStep(index: 2, targetWord: 'YÜZ', clue: 'İnsan çehresi veya 100 sayısı', changedIndex: 0),
        CrossclimbStep(index: 3, targetWord: 'YAZ', clue: 'En sıcak mevsim veya kalemle kağıda dökmek', changedIndex: 1),
      ],
    ),
    // 13: TEST → TOST → DOST
    CrossclimbLevel(
      id: 'cc_test_dost',
      startWord: 'TEST',
      endWord: 'DOST',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'TOST', clue: 'İki dilim ekmek arasına peynir koyup basılan yiyecek', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'DOST', clue: 'Güvenilen en yakın arkadaş, yoldaş', changedIndex: 0),
      ],
    ),
    // 14: KALE → LALE → LAME
    CrossclimbLevel(
      id: 'cc_kale_lame',
      startWord: 'KALE',
      endWord: 'LAME',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'LALE', clue: 'İlkbaharda açan soğanlı meşhur çiçek', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'LAME', clue: 'Altın veya gümüş renginde parlak kumaş', changedIndex: 2),
      ],
    ),
    // 15: KART → KURT → YURT
    CrossclimbLevel(
      id: 'cc_kart_yurt',
      startWord: 'KART',
      endWord: 'YURT',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'KURT', clue: 'Ormanda yaşayan yırtıcı hayvan veya böcek lavrası', changedIndex: 1),
        CrossclimbStep(index: 1, targetWord: 'YURT', clue: 'Vatan veya öğrencilerin kaldığı pansiyon', changedIndex: 0),
      ],
    ),
    // 16: ÇATI → BATI → BARI
    CrossclimbLevel(
      id: 'cc_cati_bari',
      startWord: 'ÇATI',
      endWord: 'BARI',
      steps: [
        CrossclimbStep(index: 0, targetWord: 'BATI', clue: 'Güneşin battığı ana yön', changedIndex: 0),
        CrossclimbStep(index: 1, targetWord: 'BARI', clue: 'Hiç olmazsa, en azından anlamında söz', changedIndex: 2),
      ],
    ),
  ];
}
