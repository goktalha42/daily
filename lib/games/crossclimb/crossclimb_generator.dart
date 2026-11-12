import '../../core/puzzle/puzzle_seed.dart';
import 'crossclimb_logic.dart';
import 'crossclimb_models.dart';

/// Crossclimb (Kelime Tırmanışı) günlük seviyelerini tohumdan deterministik olarak üretir / seçer.
class CrossclimbGenerator {
  const CrossclimbGenerator._();

  static final DateTime _epoch = DateTime.utc(2026, 1, 1);
  static final Map<int, List<int>> _cycleOrders = {};

  static CrossclimbLevel generate({required String levelId}) {
    DateTime date;
    try {
      date = DateTime.parse(levelId);
    } catch (_) {
      date = DateTime.now();
    }
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final days = normalizedDate.difference(_epoch).inDays.abs();

    final count = _pool.length;
    final cycle = days ~/ count;
    final posInCycle = days % count;
    final order = _orderForCycle(cycle, count);
    final item = _pool[order[posInCycle]];

    final level = CrossclimbLevel(
      id: levelId,
      startWord: CrossclimbLogic.normalize(item.startWord),
      endWord: CrossclimbLogic.normalize(item.endWord),
      steps: item.steps,
    );

    assert(CrossclimbLogic.validateLevel(level), 'Geçersiz Crossclimb zinciri: ${level.id}');
    return level;
  }

  static List<int> _orderForCycle(int cycle, int count) {
    if (_cycleOrders.containsKey(cycle)) {
      return _cycleOrders[cycle]!;
    }
    // Döngü sınırında ardışık tekrar olmaması için gerekirse önceki döngüleri iteratif hazırla.
    for (int c = 0; c <= cycle; c++) {
      if (_cycleOrders.containsKey(c)) continue;
      final order = List<int>.generate(count, (i) => i);
      for (int i = count - 1; i > 0; i--) {
        final seed = PuzzleSeed.toInt(PuzzleSeed.derive('crossclimb-cycle-$c', '$i'));
        final j = seed % (i + 1);
        final tmp = order[i];
        order[i] = order[j];
        order[j] = tmp;
      }
      if (c > 0 && count > 1) {
        final prevLast = _cycleOrders[c - 1]!.last;
        if (order.first == prevLast) {
          final swapSeed = PuzzleSeed.toInt(PuzzleSeed.derive('crossclimb-boundary', '$c'));
          final swapIdx = 1 + (swapSeed % (count - 1));
          final tmp = order[0];
          order[0] = order[swapIdx];
          order[swapIdx] = tmp;
        }
      }
      _cycleOrders[c] = order;
    }
    return _cycleOrders[cycle]!;
  }

  static List<CrossclimbLevel> get pool => List.unmodifiable(_pool);

  static CrossclimbLevel _chain(String id, List<String> words, List<String> clues) {
    assert(words.length >= 2 && clues.length == words.length - 1, 'Geçersiz zincir uzunluğu: $id');
    final normalized = words.map(CrossclimbLogic.normalize).toList();
    final steps = <CrossclimbStep>[];
    for (int i = 1; i < normalized.length; i++) {
      final changedIdx = CrossclimbLogic.findChangedIndex(normalized[i - 1], normalized[i]);
      assert(changedIdx != -1, 'Zincir adımı 1 harf farkı kuralını ihlal ediyor: $id (${normalized[i - 1]} -> ${normalized[i]})');
      steps.add(
        CrossclimbStep(
          index: i - 1,
          targetWord: normalized[i],
          clue: clues[i - 1],
          changedIndex: changedIdx,
        ),
      );
    }
    return CrossclimbLevel(
      id: id,
      startWord: normalized.first,
      endWord: normalized.last,
      steps: steps,
    );
  }

  /// Geniş Türkçe kelime merdiveni (1 harf değişim zinciri) havuzu — 120+ özgün seviye
  static final List<CrossclimbLevel> _pool = [
    // --- 3 HARFLİ KELİME MERDİVENLERİ ---
    _chain('cc_kar_ton', ['KAR', 'TAR', 'TAS', 'TOS', 'TON'], [
      'Tarihi telli bir Türk çalgısı',
      'Hamam veya su kabı',
      'Bebek veya küçük çocuğa sevgiyle söylenir',
      '1000 kilogram ağırlık birimi',
    ]),
    _chain('cc_sal_kut', ['SAL', 'SOL', 'KOL', 'KUL', 'KUT'], [
      'Sağın karşıtı olan yön',
      'Vücudun omuzdan parmaklara uzanan uzvu',
      'Yaratıcıya bağlı olan insan',
      'Eski Türklerde ilahi uğur, kutsal güç',
    ]),
    _chain('cc_ari_ada', ['ARI', 'ARA', 'ORA', 'ODA', 'ADA'], [
      'İki şey arasındaki mesafe veya mola',
      '"Burası" kelimesinin karşıtı olan yer',
      'Evin bölümlerinden her biri',
      'Dört tarafı sularla çevrili kara parçası',
    ]),
    _chain('cc_kas_bor', ['KAS', 'KAŞ', 'BAŞ', 'BOŞ', 'BOR'], [
      'Gözün üstündeki kıllı yay biçimi',
      'Gövdenin üst kısmı, kafa',
      'Dolunun zıttı, içinde bir şey olmayan',
      'Türkiye\'nin zengin olduğu maden elementi',
    ]),
    _chain('cc_bal_cay', ['BAL', 'DAL', 'DAM', 'ÇAM', 'ÇAY'], [
      'Ağacın gövdesinden ayrılan kolları',
      'Evin çatısı, örtüsü',
      'İğne yapraklı orman ağacı',
      'Demlenerek içilen geleneksel sıcak içecek',
    ]),
    _chain('cc_kor_sen', ['KOR', 'KOY', 'SOY', 'SON', 'SEN'], [
      'Küçük körfez, denizin karaya girdiği girinti',
      'Bir atadan gelenlerin oluşturduğu sülale',
      'İlk veya başlangıcın zıttı',
      'İkinci tekil şahıs zamiri',
    ]),
    _chain('cc_kan_bos', ['KAN', 'KAT', 'KOT', 'BOT', 'BOŞ'], [
      'Bir yapının tabanları arasındaki bölüm',
      'Dayanıklı pamuklu kumaş veya pantolon',
      'Küçük deniz taşıtı veya kalın kışlık ayakkabı',
      'İçinde hiçbir şey bulunmayan',
    ]),
    _chain('cc_mat_nur', ['MAT', 'MAL', 'NAL', 'NAR', 'NUR'], [
      'Mülk, eşya veya ticari değeri olan ürün',
      'Atların tırnağına çakılan koruyucu demir',
      'İçi kırmızı tanelerle dolu meyve',
      'İlahi ışık, aydınlık',
    ]),
    _chain('cc_yol_dil', ['YOL', 'YEL', 'KEL', 'KİL', 'DİL'], [
      'Hafif esen tatlı rüzgar',
      'Saçı dökülmüş, saçsız baş',
      'Çömlek ve seramik yapılan toprak',
      'Ağızdaki tat alma organı veya lisan',
    ]),
    _chain('cc_cam_pak', ['CAM', 'ÇAM', 'ÇAY', 'PAY', 'PAK'], [
      'Kışın yaprak dökmeyen iğne yapraklı ağaç',
      'Demlenerek içilen geleneksel sıcak içecek',
      'Bölüşülen bir bütünden düşen hisse',
      'Tertemiz, arı, lekesiz',
    ]),
    _chain('cc_kas_bag', ['KAŞ', 'YAŞ', 'YAĞ', 'DAĞ', 'BAĞ'], [
      'Islak, nemli veya insanın ömür yılı',
      'Zeytin veya tereyağından elde edilen besin',
      'Yerkabuğunun yüksek tepe ve dorukları',
      'Üzüm bahçesi veya iki şey arasındaki ilişki',
    ]),
    _chain('cc_gol_yaz', ['GÖL', 'GÖZ', 'GÜZ', 'YÜZ', 'YAZ'], [
      'Görme duyusu organı',
      'Yaprak dökümü mevsimi, sonbahar',
      'İnsan çehresi veya 100 sayısı',
      'En sıcak mevsim',
    ]),
    _chain('cc_kat_bal', ['KAT', 'KAY', 'PAY', 'BAY', 'BAL'], [
      'Buz üzerinde dengede duramayıp gitmek',
      'Ortaklıktan düşen hisse',
      'Erkeklere saygı için kullanılan ünvan',
      'Arıların çiçek özünden yaptığı tatlı besin',
    ]),
    _chain('cc_gul_bir', ['GÜL', 'KÜL', 'KİL', 'KİR', 'BİR'], [
      'Ateşten arta kalan toz',
      'Seramik yapımında kullanılan yumuşak toprak',
      'Bulaşan toz veya leke',
      'Teklik bildiren ilk sayı',
    ]),
    _chain('cc_sut_tup', ['SÜT', 'SÜS', 'KÜS', 'KÜP', 'TÜP'], [
      'Bezek, dekoratif eşya',
      'Dargın, konuşmayan',
      'Altı yüzü kare olan geometrik cisim',
      'İçinde gaz veya krem saklanan silindirik kap',
    ]),
    _chain('cc_kis_tuz', ['KIŞ', 'KUŞ', 'DUŞ', 'TUŞ', 'TUZ'], [
      'Kanatlı, tüylü, uçabilen hayvan',
      'Ayakta yapılan hızlı banyo',
      'Klavye veya piyanoda basılan parça',
      'Yemeklere lezzet katan beyaz kristal',
    ]),
    _chain('cc_dis_bin', ['DİŞ', 'FİŞ', 'FİL', 'BİL', 'BİN'], [
      'Elektrik prizine takılan uç veya alışveriş kağıdı',
      'Hortumlu, iri kulaklı dev kara hayvanı',
      'Bilgi sahibi olmak, tanımak',
      'Yüzün on katı olan sayı',
    ]),
    _chain('cc_gun_giz', ['GÜN', 'DÜN', 'DİN', 'DİZ', 'GİZ'], [
      'Bugünden bir önceki gün',
      'İnanç sistemi',
      'Bacağın ortasındaki eklem yeri',
      'Saklı tutulan şey, sır',
    ]),
    _chain('cc_ten_sel', ['TEN', 'TER', 'YER', 'YEL', 'SEL'], [
      'Sıcak veya efor sonucu deriden çıkan sıvı',
      'Üzerinde yaşadığımız gezegen veya mekan',
      'Hafif esen rüzgar',
      'Şiddetli yağışla oluşan taşkın su',
    ]),
    _chain('cc_sac_ham', ['SAÇ', 'TAÇ', 'TAT', 'TAM', 'HAM'], [
      'Hükümdarların başına giydiği süslü başlık',
      'Dilin algıladığı lezzet',
      'Eksiksiz, bütün, kusursuz',
      'Olgunlaşmamış veya işlenmemiş',
    ]),
    _chain('cc_gaz_bol', ['GAZ', 'KAZ', 'KAL', 'BAL', 'BOL'], [
      'Perde ayaklı iri su kuşu',
      'Bir yerde bulunmaya devam etmek',
      'Arıların ürettiği tatlı gıda',
      'Miktarı çok olan, dar olmayan',
    ]),
    _chain('cc_gok_kil', ['GÖK', 'KÖK', 'KÖR', 'KİR', 'KİL'], [
      'Bitkinin toprağa tutunan bölümü',
      'Görme yetisinden yoksun',
      'Temizlenmesi gereken leke',
      'Çömlekçilikte kullanılan toprak türü',
    ]),
    _chain('cc_can_zam', ['CAN', 'ÇAN', 'ÇAM', 'CAM', 'ZAM'], [
      'Vurulunca ses çıkaran metal araç',
      'Her mevsim yeşil kalan iğne yapraklı ağaç',
      'Pencerelere takılan saydam madde',
      'Fiyat veya maaş artışı',
    ]),
    _chain('cc_hiz_soz', ['HIZ', 'KIZ', 'KAZ', 'SAZ', 'SÖZ'], [
      'Genç kadın, dişi çocuk',
      'Toprağı çukurlaştırmak veya kümes hayvanı',
      'Tezeneli halk müziği çalgısı',
      'Ağızdan çıkan anlamlı cümle veya vaat',
    ]),
    _chain('cc_bir_ses', ['BİR', 'PİR', 'PİS', 'SİS', 'SES'], [
      'Alanında çok usta, ulu kimse',
      'Kirli, temiz olmayan',
      'Görüşü azaltan yoğun yer bulutu',
      'Kulağın işittiği titreşim',
    ]),
    _chain('cc_tuy_col', ['TÜY', 'TÜL', 'GÜL', 'GÖL', 'ÇÖL'], [
      'İnce, seyrek dokulu perde kumaşı',
      'Dikenli dalda açan kokulu çiçek',
      'Karalarla çevrili durgun su birikintisi',
      'Kumlarla kaplı kurak alan',
    ]),
    _chain('cc_col_diz', ['ÇÖL', 'ÇÖZ', 'SÖZ', 'SİZ', 'DİZ'], [
      'Düğümü açmak veya sonuca ulaşmak',
      'Verilen vaat, kelam',
      'İkinci çoğul şahıs zamiri',
      'Bacağın bükülen eklem yeri',
    ]),
    _chain('cc_duz_bit', ['DÜZ', 'DİZ', 'DİN', 'BİN', 'BİT'], [
      'Sıra halinde yan yana getirmek',
      'İbadet ve inanç bütünü',
      '1000 sayısı',
      'Saçta veya bitkide yaşayabilen minik parazit',
    ]),
    _chain('cc_koy_sal', ['KÖY', 'KOY', 'SOY', 'SOL', 'SAL'], [
      'Denizin karaya doğru küçük girintisi',
      'Aynı atadan gelen topluluk',
      'Kalbin bulunduğu taraf, yön',
      'Kütüklerden yapılan basit su aracı',
    ]),
    _chain('cc_bas_kaz', ['BAŞ', 'TAŞ', 'YAŞ', 'YAZ', 'KAZ'], [
      'Sert mineral kütlesi, kaya parçası',
      'Islak veya insanın doğumundan geçen yıl',
      'Sıcaklığın en yüksek olduğu mevsim',
      'Uzun boyunlu perde ayaklı kuş',
    ]),
    _chain('cc_toz_naz', ['TOZ', 'POZ', 'BOZ', 'BAZ', 'NAZ'], [
      'Fotoğraf çekilirken verilen duruş',
      'Kül rengi, griye çalan renk',
      'Temel, esas veya asidin karşıtı madde',
      'İstekli görünmeme, cilve',
    ]),
    _chain('cc_mor_var', ['MOR', 'ZOR', 'KOR', 'KAR', 'VAR'], [
      'Kolay olmayan, güç',
      'Ateşin sönmeye yakın kızıl hali',
      'Kışın yağan beyaz kristaller',
      'Mevcut olan, yokun karşıtı',
    ]),
    _chain('cc_hal_tok', ['HAL', 'HAK', 'PAK', 'TAK', 'TOK'], [
      'Adalet, hukuk veya doğrunun payı',
      'Temiz, lekesiz',
      'Küçük süslü kemer veya bir şeyi yerine geçirmek',
      'Karnı doymuş, aç olmayan',
    ]),
    _chain('cc_tok_kup', ['TOK', 'TOP', 'TİP', 'KİP', 'KÜP'], [
      'Oyunlarda kullanılan küre biçimli nesne',
      'Tür, çeşit veya karakter yapısı',
      'Dilbilgisinde fiil çekim biçimi',
      'Büyük toprak testi veya 6 yüzlü şekil',
    ]),
    _chain('cc_top_goz', ['TOP', 'TOZ', 'KOZ', 'KÖZ', 'GÖZ'], [
      'İnce zerrecikler halinde toprak veya kir',
      'Ceviz veya çam kozalağı; elde tutulan güçlü kart',
      'Ateşin alevsiz kızgın kömürü',
      'Görme organı',
    ]),
    _chain('cc_bel_cil', ['BEL', 'TEL', 'KEL', 'KİL', 'ÇİL'], [
      'İnce uzun metal veya gitar parçası',
      'Saçsız baş',
      'Çömlek yapımında kullanılan toprak',
      'Yüzde oluşan küçük kahverengi benek',
    ]),
    _chain('cc_cil_dil', ['ÇİL', 'ÇİP', 'DİP', 'DİK', 'DİL'], [
      'Elektronik devrelerdeki mikro yonga',
      'Bir kabın veya denizin en alt noktası',
      'Eğri olmayan, dikey',
      'Konuşma ve tat alma organı',
    ]),
    _chain('cc_dik_kek', ['DİK', 'TİK', 'TEK', 'PEK', 'KEK'], [
      'İstem dışı tekrarlanan ani kas hareketi',
      'Çift olmayan, yalnız bir',
      'Çok, hayli veya sert',
      'Fırında pişirilen tatlı hamur işi',
    ]),
    _chain('cc_kek_dem', ['KEK', 'KEL', 'KEM', 'NEM', 'DEM'], [
      'Saçı dökülmüş kimse',
      'Kötü, fena (kem göz)',
      'Havadaki su buharı, rutubet',
      'Çayın lezzetini alması veya an, zaman',
    ]),
    _chain('cc_dem_cap', ['DEM', 'GEM', 'GAM', 'ÇAM', 'ÇAP'], [
      'Atın ağzına takılan demir parça',
      'Keder, tasa veya müzikte ses dizisi',
      'Kozalaklı orman ağacı',
      'Dairenin merkezinden geçen en uzun doğru',
    ]),
    _chain('cc_cap_boy', ['ÇAP', 'KAP', 'KOP', 'KOY', 'BOY'], [
      'İçine sıvı veya eşya konulan gereç',
      'İpin veya bağın birden ayrılması',
      'Deniz girintisi, küçük körfez',
      'Uzunluk ölçüsü veya insanın dikey uzunluğu',
    ]),
    _chain('cc_boy_kil', ['BOY', 'BOL', 'YOL', 'YIL', 'KIL'], [
      'Dar olmayan, geniş ve bereketli',
      'Üzerinde gidilen şerit, güzergah',
      '12 aylık zaman dilimi, sene',
      'Deride çıkan ince ipliksi uzantı',
    ]),
    _chain('cc_kil_tur', ['KIL', 'KIR', 'SIR', 'SUR', 'TUR'], [
      'Kent dışındaki açık, yeşil alan',
      'Kimseye söylenmeyen gizli bilgi',
      'Şehirleri çevreleyen yüksek savunma duvarı',
      'Gezi veya yarışmada bir tam dönüş',
    ]),
    _chain('cc_tur_yuz', ['TUR', 'TUZ', 'BUZ', 'BÜZ', 'YÜZ'], [
      'Yemeklere katılan mineral madde',
      'Donmuş su kütlesi',
      'Kumaşı büküp daraltmak',
      'Çehre, surat veya 100 sayısı',
    ]),
    _chain('cc_yaz_zar', ['YAZ', 'YAR', 'VAR', 'DAR', 'ZAR'], [
      'Uçurum veya gönülden sevilen kimse',
      'Mevcut, bulunan',
      'Geniş olmayan, sıkışık',
      'Tavla oyununda atılan küp veya ince örtü',
    ]),
    _chain('cc_zar_bar', ['ZAR', 'FAR', 'KAR', 'GAR', 'BAR'], [
      'Aracın önündeki aydınlatma lambası',
      'Kışın yağan beyaz yağış',
      'Büyük tren istasyonu',
      'İçecek servis edilen mekan veya basınç birimi',
    ]),
    _chain('cc_bar_cat', ['BAR', 'BAK', 'YAK', 'YAT', 'ÇAT'], [
      'Gözünü bir yöne çevirmek',
      'Ateşle tutuşturmak',
      'Özel gezi teknesi',
      'İki tahtayı veya parçayı birbirine eklemek',
    ]),
    _chain('cc_cat_say', ['ÇAT', 'ÇAY', 'PAY', 'RAY', 'SAY'], [
      'Küçük akarsu veya sıcak içecek',
      'Bölümden düşen hisse',
      'Tren tekerleklerinin üzerinde gittiği demir yol',
      'Rakamları sırayla söylemek, adet bulmak',
    ]),
    _chain('cc_say_tac', ['SAY', 'SAT', 'SAÇ', 'MAÇ', 'TAÇ'], [
      'Para karşılığı bir malı vermek',
      'Başta uzayan kıllar',
      'Spor karşılaşması, müsabaka',
      'Kral veya kraliçenin başına taktığı simge',
    ]),
    _chain('cc_kup_goc', ['KÜP', 'KÜL', 'GÜL', 'GÜÇ', 'GÖÇ'], [
      'Yanmadan sonra kalan gri toz',
      'Hoş kokulu dikenli çiçek',
      'Kuvvet, enerji, zor',
      'Başka bir yere taşınma, hicret',
    ]),
    _chain('cc_koc_mum', ['KOÇ', 'KOR', 'KUR', 'KUM', 'MUM'], [
      'Sönmemiş kızgın ateş parçası',
      'Döviz değeri veya bina inşa etmek',
      'Deniz kıyısındaki ince taneli toprak',
      'Fitilli balmumu aydınlatma aracı',
    ]),
    _chain('cc_kum_boz', ['KUM', 'MUM', 'MUZ', 'BUZ', 'BOZ'], [
      'Fitilli aydınlatma aracı',
      'Sarı kabuklu tropikal meyve',
      'Katı haldeki su',
      'Griye çalan soluk renk',
    ]),
    _chain('cc_boz_gol', ['BOZ', 'BOR', 'SOR', 'SOL', 'GOL'], [
      'Temizlik ve cam sanayinde kullanılan element',
      'Bilgi almak için sual yöneltmek',
      'Sağ yönünün tersi',
      'Futbolda topun kaleye girmesi',
    ]),
    _chain('cc_gol_sal', ['GOL', 'BOL', 'BAL', 'DAL', 'ŞAL'], [
      'Geniş, ferah veya çok sayıda',
      'Çiçek nektarından üretilen tatlı besin',
      'Ağacın gövdeden çıkan uzantısı',
      'Omuza atılan ince dokuma örtü',
    ]),
    _chain('cc_sal_kan', ['ŞAL', 'ÇAL', 'ÇAN', 'HAN', 'KAN'], [
      'Müzik aletini seslendirmek',
      'Okul veya kilisede ses çıkaran metal araç',
      'Eskiden yolcuların konakladığı yapı',
      'Damarlarda dolaşan kırmızı sıvı',
    ]),
    _chain('cc_han_dil', ['HAN', 'HAM', 'DAM', 'DAL', 'DİL'], [
      'İşlenmemiş veya olgunlaşmamış',
      'Çatı veya köy evi üstü',
      'Ağaç kolu',
      'İletişim aracı lisan',
    ]),
    _chain('cc_dil_pil', ['DİL', 'SİL', 'SİS', 'PİS', 'PİL'], [
      'Yazıyı veya lekeyi yok etmek',
      'Yoğun pus tabakası',
      'Kirli, düzensiz',
      'Cihazlara enerji veren batarya',
    ]),
    _chain('cc_pil_cin', ['PİL', 'KİL', 'KİP', 'ÇİP', 'ÇİN'], [
      'Heykel ve seramik yapılan toprak',
      'Vücuda tam oturan, dar kalıp',
      'Elektronik mikro devre',
      'Asya\'nın en kalabalık ülkesi',
    ]),
    _chain('cc_cin_fil', ['ÇİN', 'DİN', 'BİN', 'BİL', 'FİL'], [
      'Manevi inanç sistemi',
      'Üç sıfırlı bin sayısı',
      'Öğrenip akılda tutmak',
      'Dünyanın en iri kara memelisi',
    ]),
    _chain('cc_sel_yer', ['SEL', 'BEL', 'TEL', 'TER', 'YER'], [
      'Vücudun göğüs ile kalça arasındaki dar kısmı',
      'İnce metal iplik',
      'Çaba harcarken vücuttan çıkan su',
      'Mekan, konum veya toprak',
    ]),
    _chain('cc_yer_dev', ['YER', 'YEM', 'CEM', 'DEM', 'DEV'], [
      'Hayvanların yediği kuru gıda',
      'Topluluk veya bir araya gelme',
      'Vakit, çağ veya çay kıvamı',
      'Masallarda geçen çok iri yaratık',
    ]),
    _chain('cc_dev_tav', ['DEV', 'SEV', 'SAV', 'LAV', 'TAV'], [
      'Gönül bağı kurmak, hoşlanmak',
      'İleri sürülen fikir, tez',
      'Yanardağdan çıkan erimiş kaya',
      'Demirin dövülmek için ısıtıldığı kıvam',
    ]),
    _chain('cc_tav_has', ['TAV', 'TAS', 'PAS', 'FAS', 'HAS'], [
      'Metal veya plastik yuvarlak kap',
      'Demir üzerindeki kızıl oksit tabakası',
      'Kuzey Afrika ülkesi',
      'Katkısız, saf, özgü',
    ]),
    _chain('cc_has_bay', ['HAS', 'HAT', 'KAT', 'KAY', 'BAY'], [
      'Çizgi, yol veya güzel yazı sanatı',
      'Apartman dairesi seviyesi',
      'Kaygan zeminde ilerlemek',
      'Erkek hitap sözü',
    ]),
    _chain('cc_biz_koz', ['BİZ', 'GİZ', 'GÖZ', 'SÖZ', 'KÖZ'], [
      'Saklı gerçek, sır',
      'Bakma ve görme organı',
      'Kelime veya vaat',
      'Kızıl kor ateş parçası',
    ]),
    _chain('cc_sut_tul', ['SÜT', 'SÜS', 'KÜS', 'KÜL', 'TÜL'], [
      'Süsleme amacıyla takılan eşya',
      'Kırgın, darılmış',
      'Odunun yanmasından kalan toz',
      'Gelinlik ve perdede kullanılan ince kumaş',
    ]),
    _chain('cc_tul_kur', ['TÜL', 'TÜR', 'HÜR', 'GÜR', 'KÜR'], [
      'Çeşit, cins, kategori',
      'Özgür, bağımsız',
      'Bol, sık ve gürbüz',
      'Tedavi amaçlı uygulanan kür programı',
    ]),
    _chain('cc_kur_dip', ['KÜR', 'KÜP', 'TÜP', 'TİP', 'DİP'], [
      'Büyük toprak saklama kabı',
      'Laboratuvarda kullanılan ince cam silindir',
      'Görünüş, model',
      'En alt kısım, taban',
    ]),
    _chain('cc_dip_zil', ['DİP', 'DİL', 'MİL', 'SİL', 'ZİL'], [
      'Tat alma organı',
      'Deniz veya kara uzunluk ölçüsü / çamur',
      'Tahtadaki yazıyı temizlemek',
      'Kapıya basıldığında çalan uyarı aracı',
    ]),
    _chain('cc_zil_sis', ['ZİL', 'MİL', 'MİM', 'SİM', 'SİS'], [
      'Dönme ekseni veya ölçü birimi',
      'İşaret, nokta veya dudaksıl harf',
      'Parlak gümüşi tel veya cep telefonu kartı',
      'Görüşü kapatan dumanımsı hava olayı',
    ]),
    _chain('cc_sis_kes', ['SİS', 'SES', 'FES', 'PES', 'KES'], [
      'Kulağın duyduğu akustik dalga',
      'Püsküllü geleneksel başlık',
      'Alçak ton veya vazgeçmek',
      'Makasla ayırmak',
    ]),
    _chain('cc_kes_bas', ['KES', 'KEŞ', 'LEŞ', 'BEŞ', 'BAŞ'], [
      'Kurumuş çökelek peyniri',
      'Bozulmuş hayvan ölüsü',
      '4 ile 6 arasındaki sayı',
      'Vücudun en üst bölümü, kafa',
    ]),
    _chain('cc_bas_kiz', ['BAŞ', 'KAŞ', 'KUŞ', 'KIŞ', 'KIZ'], [
      'Göz üstündeki kıl şeridi',
      'Uçabilen tüylü canlı',
      'Kar yağışlı soğuk mevsim',
      'Dişi çocuk',
    ]),
    _chain('cc_kiz_yaz', ['KIZ', 'KAZ', 'GAZ', 'SAZ', 'YAZ'], [
      'Büyük beyaz su kuşu',
      'Yanıcı yakıt veya maddenin akışkan hali',
      'Bataklık kamışı veya telli çalgı',
      'Sıcak tatil mevsimi',
    ]),
    _chain('cc_yat_bot', ['YAT', 'KAT', 'KOT', 'NOT', 'BOT'], [
      'Çok katmanlı yapının her düzeyi',
      'Mavi dayanıklı kumaş pantolon',
      'Kısa yazılı hatırlatma veya okul puanı',
      'Bileği saran kışlık ayakkabı',
    ]),
    _chain('cc_bot_mor', ['BOT', 'POT', 'KOT', 'KOR', 'MOR'], [
      'Kumaşta oluşan kırışıklık veya gafta bulunmak',
      'Dayanıklı pamuklu dokuma',
      'Kızgın ateş közü',
      'Kırmızı ile mavinin karışımı renk',
    ]),
    _chain('cc_put_sur', ['PUT', 'KUT', 'KUR', 'TUR', 'SUR'], [
      'Uğur, bereket, saadet',
      'Yabancı para değişim değeri',
      'Yarış veya gezi döngüsü',
      'Kaleyi çevreleyen taş duvar',
    ]),
    _chain('cc_sur_cul', ['SUR', 'KUR', 'KUL', 'PUL', 'ÇUL'], [
      'Kurmak eylemi veya değer oranı',
      'İbadet eden kimse',
      'Mektuba yapıştırılan küçük kağıt veya balık zırhı',
      'Kaba yün dokuma örtü',
    ]),
    _chain('cc_cul_kol', ['ÇUL', 'BUL', 'DUL', 'KUL', 'KOL'], [
      'Aranan bir şeyi ele geçirmek',
      'Eşini kaybetmiş kimse',
      'Yaratıcıya inanan insan',
      'Omuzdan ele uzanan organ',
    ]),
    _chain('cc_kol_boy', ['KOL', 'KOV', 'KOY', 'TOY', 'BOY'], [
      'Bir kimseyi veya hayvanı uzaklaştırmak',
      'Denizin karaya girdiği küçük körfez',
      'Deneyimsiz, acemi',
      'Akrabalık topluluğu veya uzunluk',
    ]),
    _chain('cc_toy_ton', ['TOY', 'SOY', 'SON', 'DON', 'TON'], [
      'Aile kökeni, nesil',
      'Bitiş, nihayet',
      'Sıfırın altındaki soğuk veya iç giysi',
      'Renk derecesi veya ağırlık birimi',
    ]),
    _chain('cc_don_kor', ['DON', 'FON', 'SON', 'SOR', 'KOR'], [
      'Arka plan rengi veya birikmiş para kaynağı',
      'En arkadaki, bitim noktası',
      'Merak ettiğini yöneltmek',
      'Sıcaklığını koruyan ateş közü',
    ]),
    _chain('cc_guc_buz', ['GÜÇ', 'GÜZ', 'DÜZ', 'BÜZ', 'BUZ'], [
      'Sonbahar mevsimi',
      'Eğimi ve çıkıntısı olmayan',
      'İple çekip büzmek',
      'Soğuktan katılaşmış su',
    ]),
    _chain('cc_sis_zil', ['ŞİŞ', 'FİŞ', 'FİL', 'BİL', 'ZİL'], [
      'Priz girişi veya alışveriş belgesi',
      'Büyük hortumlu memeli',
      'Bilgiye sahip olmak',
      'Çalınarak ses veren zil aracı',
    ]),
    _chain('cc_bit_biz', ['BİT', 'KİT', 'KİR', 'BİR', 'BİZ'], [
      'Tamir veya deney seti takımı',
      'Leke, pas, toz birikintisi',
      'En küçük pozitif tam sayı',
      'Birinci çoğul şahıs zamiri',
    ]),
    _chain('cc_biz_pil', ['BİZ', 'DİZ', 'DİK', 'PİK', 'PİL'], [
      'Bacak eklemi',
      'Yere 90 derece açıyla duran',
      'İskambil oyununda maça veya en yüksek nokta',
      'Taşınabilir elektrik kaynağı',
    ]),
    _chain('cc_cit_sit', ['ÇİN', 'ÇİP', 'ÇİT', 'BİT', 'SİT'], [
      'Silikon mikroişlemci yongası',
      'Bahçeyi çevreleyen tahta veya tel örgü',
      'Küçük asalak böcek',
      'Koruma altına alınmış tarihi alan',
    ]),
    _chain('cc_cit_din', ['ÇİT', 'ÇİL', 'KİL', 'KİN', 'DİN'], [
      'Güneşle yüzde beliren küçük nokta',
      'Yumuşak seramik toprağı',
      'İçte beslenen öfke ve düşmanlık',
      'İnanç ve ibadet bütünü',
    ]),
    _chain('cc_kin_mis', ['KİN', 'PİN', 'PİS', 'SİS', 'MİS'], [
      'Güvenlik şifresi veya yaka iğnesi',
      'Temiz olmayan, kirli',
      'Görüşü engelleyen yoğun dumanımsı hava',
      'Çok hoş ve güzel koku',
    ]),
    _chain('cc_mis_fil', ['MİS', 'PİS', 'PİL', 'ÇİL', 'FİL'], [
      'Kötü, kirli',
      'Enerji depolayan hücre',
      'Benek, küçük nokta',
      'Uzun hortumlu büyük hayvan',
    ]),
    _chain('cc_oda_ani', ['ODA', 'ADA', 'ALA', 'ANA', 'ANİ'], [
      'Suyla çevrili kara parçası',
      'Alacalı veya güzel göz rengi',
      'Temel, esas veya anne',
      'Birdenbire olan, beklenmedik',
    ]),
    _chain('cc_ana_aci', ['ANA', 'ATA', 'ARA', 'ARI', 'ACI'], [
      'Soyun geldiği büyük, ced',
      'Boşluk veya teneffüs',
      'Bal yapan kanatlı böcek',
      'Biber tadı veya üzüntü duygusu',
    ]),
    _chain('cc_asi_irk', ['ASI', 'AŞI', 'AŞK', 'ARK', 'IRK'], [
      'Hastalıklara karşı koruyucu tıbbi uygulama',
      'Derin sevgi ve tutku duygusu',
      'Tarlalara su taşıyan küçük kanal',
      'Biyolojik köken topluluğu',
    ]),
    _chain('cc_irk_ora', ['IRK', 'ARK', 'ARZ', 'ARA', 'ORA'], [
      'Su akıtılan dar hendek',
      'Sunma, talep veya yeryüzü',
      'İki nokta arası mesafe',
      'İşaret edilen uzak yer',
    ]),
    _chain('cc_zil_dil', ['ZİL', 'ÇİL', 'FİL', 'BİL', 'DİL'], [
      'Ciltteki küçük kahverengi benek',
      'Büyük hortumlu memeli',
      'Doğrusunu kavramak',
      'Konuşma ve tat alma organı',
    ]),
    _chain('cc_guz_suz', ['GÜZ', 'BÜZ', 'DÜZ', 'YÜZ', 'SÜZ'], [
      'İple çekip daraltmak',
      'Pürüzsüz ve engebesiz',
      'Suda kulaç atmak veya insan çehresi',
      'Sıvıyı süzgeçten geçirmek',
    ]),
    _chain('cc_suz_coz', ['SÜZ', 'SÖZ', 'KÖZ', 'GÖZ', 'ÇÖZ'], [
      'Verilen söz veya cümle',
      'Ateşin sönmemiş koru',
      'Işığı algılayan görme organı',
      'Bilmeceyi veya düğümü açmak',
    ]),
    _chain('cc_cam_ham', ['ÇAM', 'CAM', 'ZAM', 'GAM', 'HAM'], [
      'Şeffaf pencere malzemesi',
      'Fiyat artışı',
      'Üzüntü, keder',
      'Olgunlaşmamış meyve',
    ]),
    _chain('cc_ham_san', ['HAM', 'HAN', 'KAN', 'YAN', 'ŞAN'], [
      'Kervanların konakladığı eski bina',
      'Kırmızı yaşam sıvısı',
      'Bir şeyin sağ veya sol tarafı',
      'Ün, şöhret, şeref',
    ]),
    _chain('cc_san_tan', ['ŞAN', 'VAN', 'CAN', 'ÇAN', 'TAN'], [
      'Doğu Anadolu\'daki büyük göl ili',
      'Yaşam, ruh',
      'Okul zili veya büyük metal çan',
      'Güneş doğmadan önceki alacakaranlık',
    ]),
    _chain('cc_tan_bas', ['TAN', 'TAS', 'PAS', 'YAS', 'BAS'], [
      'Bakır veya metal su kabı',
      'Demirde oluşan kızıl tabaka',
      'Ölüm veya kayıp sonrası duyulan üzüntü',
      'Aşağı doğru kuvvet uygulamak',
    ]),
    _chain('cc_baz_koz', ['BAZ', 'BOZ', 'TOZ', 'POZ', 'KOZ'], [
      'Soluk gri-kahverengi ton',
      'İnce toprak zerresi',
      'Kamera karşısındaki duruş',
      'Oyunda üstünlük sağlayan güçlü kart',
    ]),
    _chain('cc_koz_gok', ['KOZ', 'KÖZ', 'KÖR', 'KÖK', 'GÖK'], [
      'Kızgın kömür ateşi',
      'Görmeyen, ama veya keskin olmayan',
      'Ağacın toprak altındaki kısmı',
      'Mavi gökyüzü, sema',
    ]),
    _chain('cc_lav_mac', ['LAV', 'SAV', 'SAÇ', 'TAÇ', 'MAÇ'], [
      'Ortaya atılan iddia, tez',
      'Baş derisindeki kıllar',
      'Kral tacı',
      'Spor müsabakası',
    ]),
    _chain('cc_pak_dal', ['PAK', 'HAK', 'HAL', 'ŞAL', 'DAL'], [
      'Doğruluk ve adalet payı',
      'Durum, vaziyet veya meyve sebze pazarı',
      'Omuz örtüsü',
      'Ağaç kolu',
    ]),
    _chain('cc_dal_yar', ['DAL', 'MAL', 'NAL', 'NAR', 'YAR'], [
      'Ticari eşya, servet',
      'At toynağına takılan demir',
      'Kırmızı taneli kış meyvesi',
      'Uçurum veya sevgili',
    ]),
    _chain('cc_nar_sur', ['NAR', 'NUR', 'KUR', 'TUR', 'SUR'], [
      'Kutsal ışık, parlaklık',
      'Para birimi oranı',
      'Gezinti veya pist dönüşü',
      'Kale duvarı',
    ]),
    _chain('cc_sur_yil', ['SUR', 'SIR', 'KIR', 'KIL', 'YIL'], [
      'Gizli tutulan bilgi',
      'Kırsal alan veya beyazlaşmış saç',
      'İnce tel gibi vücut tüyü',
      '365 günlük dönem',
    ]),
    _chain('cc_yil_ton', ['YIL', 'YOL', 'SOL', 'SON', 'TON'], [
      'Ulaşım şeridi',
      'Sağın zıttı yön',
      'Bitiş noktası',
      'Ses yüksekliği veya 1000 kilo',
    ]),
    _chain('cc_ton_koy', ['TON', 'SON', 'SOY', 'KOY', 'KÖY'], [
      'Nihayet, bitiş',
      'Atadan gelen sülale',
      'Küçük deniz girintisi',
      'Şehirden küçük yerleşim yeri',
    ]),
    _chain('cc_tuz_kum', ['TUZ', 'BUZ', 'MUZ', 'MUM', 'KUM'], [
      'Donmuş su',
      'Uzun sarı meyve',
      'Balmumundan ışık kaynağı',
      'Plajdaki ince taneler',
    ]),
    _chain('cc_kum_gur', ['KUM', 'KUR', 'KÜR', 'HÜR', 'GÜR'], [
      'Döviz kuru',
      'Bakım ve sağlık uygulaması',
      'Bağımsız, özgür',
      'Yoğun, bol ve kuvvetli',
    ]),
    _chain('cc_gur_kul', ['GÜR', 'TÜR', 'TÜL', 'GÜL', 'KÜL'], [
      'Çeşit, sınıf',
      'İnce saydam perde kumaşı',
      'Güzel kokulu dikenli çiçek',
      'Ateşten kalan toz',
    ]),
    _chain('cc_tip_dil', ['TİP', 'DİP', 'ÇİP', 'ÇİL', 'DİL'], [
      'En alt taban noktası',
      'Mikro elektronik devre',
      'Yüzdeki minik leke',
      'Konuşulan lisan',
    ]),
    _chain('cc_dil_dis', ['DİL', 'KİL', 'FİL', 'FİŞ', 'DİŞ'], [
      'Seramik hamuru toprağı',
      'Büyük hortumlu memeli',
      'Kasa makbuzu veya elektrik fişi',
      'Çiğnemeye yarayan sert organ',
    ]),
    _chain('cc_dis_pin', ['DİŞ', 'DİN', 'BİN', 'ÇİN', 'PİN'], [
      'İnanç yolu',
      '1000 sayısı',
      'Uzak Doğu ülkesi',
      'Kart güvenlik kodu',
    ]),

    // --- 4 HARFLİ KELİME MERDİVENLERİ ---
    _chain('cc_kale_balo', ['KALE', 'LALE', 'BALE', 'BALO'], [
      'İlkbaharda açan soğanlı meşhur çiçek',
      'Parmak ucunda yapılan klasik sahne dansı',
      'Resmi giysili büyük danslı gece davetiyesi',
    ]),
    _chain('cc_mart_yurt', ['MART', 'KART', 'KURT', 'YURT'], [
      'Dikdörtgen sert kağıt veya ödeme aracı',
      'Ormanda yaşayan yırtıcı hayvan',
      'Vatan veya öğrencilerin kaldığı yer',
    ]),
    _chain('cc_cati_sari', ['ÇATI', 'KATI', 'BATI', 'BARI', 'SARI'], [
      'Sert, sıvı olmayan veya acımasız',
      'Güneşin battığı ana yön',
      'Hiç olmazsa, en azından',
      'Limon ve güneşin rengi',
    ]),
    _chain('cc_test_dost', ['MEST', 'TEST', 'TOST', 'DOST'], [
      'Bilgi veya dayanıklılık ölçme sınavı',
      'İki ekmek arasına peynir konup basılan yiyecek',
      'Güvenilen en yakın arkadaş',
    ]),
    _chain('cc_balo_kaba', ['BALO', 'BALA', 'BABA', 'SABA', 'KABA'], [
      'Küçük çocuk, yavru (halk ağzında)',
      'Ailenin erkek ebeveyni',
      'Klasik Türk müziğinde hüzünlü bir makam',
      'İnce ve kibar olmayan, pürüzlü',
    ]),
    _chain('cc_kaba_pasa', ['KABA', 'KASA', 'MASA', 'MAŞA', 'PAŞA'], [
      'Para ve değerli eşya saklanan çelik dolap',
      'Üzerinde yemek yenilen veya çalışılan mobilya',
      'Köz veya kömür tutmaya yarayan kıskaç',
      'Osmanlı ve Cumhuriyet dönemi general rütbesi',
    ]),
    _chain('cc_pasa_taka', ['PAŞA', 'YAŞA', 'YAKA', 'ŞAKA', 'TAKA'], [
      'Alkış ve tezahürat ünlemi',
      'Gömleğin boynu saran kısmı',
      'Güldürmek için söylenen söz veya eylem',
      'Karadeniz\'e özgü küçük ahşap tekne',
    ]),
    _chain('cc_taka_deva', ['TAKA', 'TAVA', 'HAVA', 'DAVA', 'DEVA'], [
      'İçinde yemek kızartılan saplı mutfak gereci',
      'Soluduğumuz gaz karışımı veya gökyüzü',
      'Mahkemeye taşınan hukuki uyuşmazlık',
      'Hastalığı iyileştiren çare, ilaç',
    ]),
    _chain('cc_deva_maya', ['DEVA', 'DAVA', 'DAYA', 'KAYA', 'MAYA'], [
      'Yargı sürecine konu olan mesele',
      'Bir şeyi bir yere yaslamak, destek vermek',
      'Büyük ve sert taş kütlesi',
      'Hamuru kabartan veya yoğurt tutan canlı kültür',
    ]),
    _chain('cc_maya_para', ['MAYA', 'KAYA', 'KARA', 'YARA', 'PARA'], [
      'Sert dağ taşı kütlesi',
      'Siyah renk veya deniz dışındaki toprak parçası',
      'Deride açılan kesik veya sıyrık',
      'Alışverişte kullanılan ödeme aracı',
    ]),
    _chain('cc_para_sari', ['PARA', 'DARA', 'DARI', 'BARI', 'SARI'], [
      'Tartılan kabın kendi ağırlığı',
      'Mısır veya kuş yemi olarak bilinen tahıl',
      'Hiç olmazsa anlamında bağlaç',
      'Altın ve ayçiçeğinin rengi',
    ]),
    _chain('cc_sari_yaki', ['SARI', 'KARI', 'KAPI', 'YAPI', 'YAKI'], [
      'Bembeyaz kar örtüsü (belirtme hali) / eş',
      'Odaya veya binaya giriş çıkış bölümü',
      'İnşa edilmiş bina, eser',
      'Ağrıyan bölgeye yapıştırılan ısıtıcı bant',
    ]),
    _chain('cc_yaki_taka', ['YAKI', 'YAPI', 'TAPI', 'TAKI', 'TAKA'], [
      'Mimari eser, bina',
      'Tapınma veya tapu ile ilgili',
      'Küpe, bilezik, kolye gibi süs eşyası',
      'Küçük ahşap deniz motoru',
    ]),
    _chain('cc_kara_kita', ['KART', 'KARA', 'KASA', 'KISA', 'KITA'], [
      'Kömür rengi veya toprak parçası',
      'Paraların konulduğu kilitli bölüm',
      'Uzunun karşıtı',
      'Yeryüzündeki büyük kara parçası (Asya, Avrupa vb.)',
    ]),
    _chain('cc_kita_mana', ['KITA', 'KINA', 'KANA', 'DANA', 'MANA'], [
      'Ellerin süslenmesinde kullanılan kırmızı bitkisel toz',
      'İçmeye doymak (kana kana)',
      'Bir yaşından küçük sığır yavrusu',
      'Sözcüğün taşıdığı anlam',
    ]),
    _chain('cc_boru_kuyu', ['BORU', 'KORU', 'KURU', 'KUTU', 'KUYU'], [
      'Küçük ağaçlık, ormanlık alan',
      'Islak olmayan, nemini kaybetmiş',
      'Eşya koymaya yarayan kapaklı kap',
      'Su çıkarmak için kazılan derin çukur',
    ]),
    _chain('cc_kuyu_bora', ['KUYU', 'KOYU', 'KOYA', 'BOYA', 'BORA'], [
      'Açık rengin karşıtı, yoğun kıvamlı',
      'Bir kabın içine bırakmak (koya)',
      'Duvar veya resim renklendirme maddesi',
      'Şiddetli fırtına ve yağışlı rüzgar',
    ]),
    _chain('cc_bora_kota', ['BORA', 'BOTA', 'ROTA', 'NOTA', 'KOTA'], [
      'Ayakkabının su geçirmeyen bot hali (yönelme)',
      'Gemi veya uçağın izlediği yol',
      'Müzik sesini gösteren işaret',
      'Belirlenen üst sınır veya kontenjan',
    ]),
    _chain('cc_kota_soda', ['KOTA', 'KOLA', 'MOLA', 'MODA', 'SODA'], [
      'Koyu renkli gazlı meşrubat',
      'Yolculuk veya çalışmada verilen kısa ara',
      'Giyim ve tasarımda geçici toplumsal beğeni',
      'Maden suyu veya karbonatlı içecek',
    ]),
    _chain('cc_soda_cefa', ['SODA', 'SOFA', 'SEFA', 'VEFA', 'CEFA'], [
      'Eski evlerde odaların açıldığı geniş salon',
      'Gönül rahatlığı, huzur ve keyif',
      'Sevgi ve dostlukta bağlılık, sadakat',
      'Sıkıntı, eziyet, üzüntü',
    ]),
    _chain('cc_cefa_sema', ['CEFA', 'SEFA', 'SEMA', 'TEMA', 'ŞEMA'], [
      'Keyif ve rahatlık içinde yaşama',
      'Gökyüzü veya Mevlevi dönme ayini',
      'Bir eserde işlenen ana konu',
      'Bir sistemin ana hatlarını gösteren çizim',
    ]),
    _chain('cc_bela_bala', ['BELA', 'SELA', 'SALA', 'HALA', 'BALA'], [
      'Camide okunan çağrı veya selam',
      'Büyük misafir salonu veya salma',
      'Babanın kız kardeşi',
      'Yavru, küçük çocuk',
    ]),
    _chain('cc_hala_yapi', ['HALA', 'HALI', 'ÇALI', 'YALI', 'YAPI'], [
      'Yere serilen dokuma ev eşyası',
      'Kısa boylu dikenli veya dallı bitki',
      'Deniz kıyısındaki görkemli köşk',
      'Bina, mimari kuruluş',
    ]),
    _chain('cc_taki_kati', ['TAKI', 'YAKI', 'ÇAKI', 'ÇATI', 'KATI'], [
      'Isı vererek ağrı azaltan tıbbi flaster',
      'Katlanabilen küçük cep bıçağı',
      'Binaların en üst örtü bölümü',
      'Sert, katılaşmış madde',
    ]),
    _chain('cc_kale_masa', ['KALE', 'KASE', 'KASA', 'MASA', 'MAŞA'], [
      'Çorba veya yoğurt konulan derin çanak',
      'Para kutusu veya kamyon arka bölümü',
      'Dört ayaklı yemek veya çalışma mobilyası',
      'Ateşten köz tutmaya yarayan maşa',
    ]),
    _chain('cc_kale_care', ['KALE', 'PALE', 'PARE', 'FARE', 'ÇARE'], [
      'Kürek veya pervane kanadı',
      'Parça, kısım',
      'Kemirgen küçük hayvan veya bilgisayar donanımı',
      'Çözüm yolu, derman',
    ]),
    _chain('cc_care_dara', ['ÇARE', 'FARE', 'YARE', 'YARA', 'DARA'], [
      'Bilgisayar imlecini hareket ettiren cihaz',
      'Sevgiliye sesleniş',
      'Ciltteki kesik veya bere',
      'Kabın boş ağırlığı',
    ]),
    _chain('cc_dert_kart', ['DERT', 'MERT', 'MART', 'ŞART', 'KART'], [
      'Sözünün eri, yiğit, dürüst',
      'Yılın üçüncü ayı',
      'Koşul, gereklilik',
      'Tebrik kağıdı veya plastik ödeme kartı',
    ]),
    _chain('cc_bant_bent', ['BANT', 'RANT', 'KANT', 'KENT', 'BENT'], [
      'Emek harcanmadan elde edilen gelir',
      'Ünlü Alman filozof',
      'Büyük yerleşim yeri, şehir',
      'Suyu tutmak için yapılan set veya madde',
    ]),
    _chain('cc_dost_pest', ['DOST', 'POST', 'TOST', 'TEST', 'PEST'], [
      'Hayvan kürkü veya makam koltuğu',
      'Kızartılmış peynirli sandviç',
      'Deneme sınavı',
      'Alçak, yavaş (müzikte pes / pest perde)',
    ]),
    _chain('cc_kole_pece', ['KÖLE', 'KÖSE', 'KESE', 'KEÇE', 'PEÇE'], [
      'Sakalı ve bıyığı çıkmayan erkek',
      'Banyo kesesi veya küçük kumaş torba',
      'Yünün dövülmesiyle yapılan kalın kumaş',
      'Yüzün alt kısmını örten ince tül',
    ]),
    _chain('cc_pece_tefe', ['PEÇE', 'KEÇE', 'KEFE', 'TEFE'], [
      'Dövme yünden yapılan kalın örtü',
      'Terazinin iki gözünden her biri',
      'Dokuma tezgahında iplik sıkıştıran parça',
    ]),
    _chain('cc_kupe_ture', ['KÜPE', 'KÜME', 'KÜRE', 'SÜRE', 'TÜRE'], [
      'Elemanlar topluluğu veya birikim',
      'Dünya gibi yuvarlak üç boyutlu şekil',
      'Geçen zaman aralığı, müddet',
      'Doğmak, ortaya çıkmak veya hukuk kuralı',
    ]),
    _chain('cc_sure_care', ['SÜRE', 'KÜRE', 'KARE', 'FARE', 'ÇARE'], [
      'Yuvarlak top biçimindeki geometrik cisim',
      'Dört kenarı eşit dik açılı dörtgen',
      'Kemirgen küçük hayvan',
      'Çözüm yolu, deva',
    ]),
    _chain('cc_kare_baro', ['KARE', 'KALE', 'BALE', 'BALO', 'BARO'], [
      'Savunma amaçlı surlarla çevrili yapı',
      'Müzik eşliğinde yapılan klasik dans sanatı',
      'Şık kıyafetlerle katılınan danslı davet',
      'Avukatların bağlı olduğu meslek birliği',
    ]),
    _chain('cc_baro_mala', ['BARO', 'BALO', 'BALA', 'PALA', 'MALA'], [
      'Büyük resmi dans gecesi',
      'Yavru, küçük çocuk',
      'Geniş bıçaklı eğri kılıç',
      'Sıva yaparken harç sürmeye yarayan alet',
    ]),
    _chain('cc_deri_seri', ['DERİ', 'GERİ', 'VERİ', 'BERİ', 'SERİ'], [
      'Önün veya ilerinin karşıtı',
      'Bilgi parçası, data',
      'Öteden beri, yakın taraf',
      'Art arda sıralanan, hızlı',
    ]),
    _chain('cc_seri_deli', ['SERİ', 'PERİ', 'VERİ', 'DERİ', 'DELİ'], [
      'Masallarda geçen kanatlı hayali varlık',
      'İşlenmek üzere toplanan bilgi',
      'Vücudu saran dış tabaka',
      'Aklî dengesi bozuk veya çok coşkulu',
    ]),
    _chain('cc_kapi_bazi', ['KAPI', 'YAPI', 'YAZI', 'RAZI', 'BAZI'], [
      'İnşa edilmiş bina',
      'Harflerle kağıda dökülen anlatım',
      'Kabul etmiş, gönlü olmuş',
      'Kimi, bir kısım',
    ]),
    _chain('cc_otak_ayaz', ['OTAK', 'ATAK', 'AYAK', 'AYAR', 'AYAZ'], [
      'Hücum, hamle veya girişken',
      'Yürümeyi sağlayan organ',
      'Saat veya cihaz düzenlemesi',
      'Kuru ve keskin gece soğuğu',
    ]),
    _chain('cc_orak_uyak', ['ORAK', 'OTAK', 'ATAK', 'AYAK', 'UYAK'], [
      'Göçebe Türklerin büyük süslü çadırı',
      'Hızlı çıkış, girişken',
      'Uzunluk birimi veya organ',
      'Şiirde dize sonu ses benzerliği, kafiye',
    ]),
    _chain('cc_uzak_ayaz', ['UZAK', 'UYAK', 'UYAR', 'AYAR', 'AYAZ'], [
      'Şiirde kafiye',
      'Uygun düşer, denk gelir',
      'Ölçü ve denge düzeni',
      'Açık havada oluşan dondurucu soğuk',
    ]),
    _chain('cc_ilik_alin', ['İLİK', 'İLİM', 'ALİM', 'ALIM', 'ALIN'], [
      'Bilim, bilgi',
      'Çok bilgili bilgin kimse',
      'Satın alma veya çekicilik',
      'Yüzün kaşlar ile saç arasındaki bölümü',
    ]),
    _chain('cc_alin_akin', ['ALIN', 'ALIM', 'AKIM', 'AKIL', 'AKIN'], [
      'Mal veya hizmet satın alma',
      'Elektrik akımı veya sanat eğilimi',
      'Düşünme ve anlama yetisi',
      'Kalabalık halde hızlı ilerleyiş, baskın',
    ]),
    _chain('cc_akin_atik', ['AKIN', 'AKIL', 'ASIL', 'ATIL', 'ATIK'], [
      'Zihin gücü',
      'Gerçek, esas, temel',
      'Kullanılmayan, hareketsiz kalmış',
      'Çöp veya kullanılmış malzeme',
    ]),
    _chain('cc_atik_isil', ['ATIK', 'AÇIK', 'AŞIK', 'IŞIK', 'IŞIL'], [
      'Kapalı olmayan, net',
      'Gönlünü kaptırmış, sevdalı',
      'Aydınlık sağlayan enerji',
      'Parıl parıl parlayan',
    ]),
    _chain('cc_elma_arka', ['ELMA', 'ALMA', 'ASMA', 'ARMA', 'ARKA'], [
      'Elma kelimesinin eski/halk ağzı veya satın alma',
      'Üzüm yetiştirilen sarmaşık bitki',
      'Devlet veya kulüp simgesi, amblem',
      'Önün karşıtı olan yön',
    ]),
    _chain('cc_arka_arzu', ['ARKA', 'ARMA', 'ARSA', 'ARZA', 'ARZU'], [
      'Bir kurumun resmi sembolü',
      'Üzerine bina yapılabilen boş arazi',
      'Teknik aksaklık, bozulma (arıza)',
      'Şiddetli istek, dilek',
    ]),
    _chain('cc_orsa_atma', ['ORSA', 'ARSA', 'ARMA', 'ASMA', 'ATMA'], [
      'Yapılaşmaya uygun boş toprak parçası',
      'Bayrak veya rozet amblemi',
      'Üzüm bağı veya çamaşır asılan yer',
      'Fırlatma eylemi',
    ]),
    _chain('cc_atma_amca', ['ATMA', 'ASMA', 'ALMA', 'AMMA', 'AMCA'], [
      'Üzüm veren tırmanıcı ağaç',
      'Alma eylemi',
      'Fakat, ama anlamında bağlaç',
      'Babanın erkek kardeşi',
    ]),
    _chain('cc_amca_arka', ['AMCA', 'AMMA', 'ARMA', 'ARPA', 'ARKA'], [
      'Lakin, ancak',
      'Şeref işareti, nişan',
      'Bira ve yem yapımında kullanılan tahıl',
      'Geri taraf',
    ]),
    _chain('cc_mavi_cani', ['MAVİ', 'MANİ', 'FANİ', 'GANİ', 'CANİ'], [
      'Dört dizelik halk şiiri veya engel',
      'Ölümlü, geçici dünya',
      'Çok zengin, bol gönüllü',
      'Cinayet işleyen acımasız kimse',
    ]),
    _chain('cc_vali_tali', ['VALİ', 'HALİ', 'MALİ', 'TALİ'], [
      'Durumu, görünüşü',
      'Para ve bütçe ile ilgili',
      'İkinci derecede önemli, yan',
    ]),
    _chain('cc_maca_kara', ['MAÇA', 'MAŞA', 'MASA', 'KASA', 'KARA'], [
      'Mangal kömürü tutma aleti',
      'Yemek yenilen mobilya',
      'Çelik para dolabı',
      'Siyah renk veya toprak parçası',
    ]),
    _chain('cc_kara_lama', ['KARA', 'YARA', 'YAMA', 'KAMA', 'LAMA'], [
      'Ciltteki kesik',
      'Yırtık yere dikilen kumaş parçası',
      'İki ucu keskin hançer veya tahta takoz',
      'Güney Amerika\'da yaşayan hörgüçsüz devegiller hayvanı',
    ]),
    _chain('cc_kaza_kole', ['KAZA', 'KASA', 'KASE', 'KÖSE', 'KÖLE'], [
      'Para kasası',
      'Derin çorba tabağı',
      'Sakalsız erkek',
      'Özgürlüğü elinden alınmış kimse',
    ]),
    _chain('cc_kole_kuse', ['KÖLE', 'KÖŞE', 'KÖSE', 'KESE', 'KÜSE'], [
      'İki duvarın birleştiği açısal nokta',
      'Tüysüz yüz',
      'Küçük kumaş torba',
      'Darılmak (küse)',
    ]),
    _chain('cc_yazi_tazi', ['YAZI', 'KAZI', 'BAZI', 'RAZI', 'TAZI'], [
      'Arkeolojik toprak araştırma çalışması',
      'Birkaç, kimi',
      'Gönlü razı, kabul eden',
      'Çok hızlı koşan ince yapılı av köpeği',
    ]),
    _chain('cc_koyu_dolu', ['KOYU', 'SOYU', 'BOYU', 'BOLU', 'DOLU'], [
      'Nesli, kökeni',
      'Uzunluğu veya ebatı',
      'Abant Gölü ile ünlü Batı Karadeniz ili',
      'İçi tamamen dolmuş veya buz taneli yağış',
    ]),
    _chain('cc_konu_soru', ['KONU', 'KORU', 'BORU', 'DORU', 'SORU'], [
      'Küçük ağaçlık orman alanı',
      'Su veya gaz ileten silindirik hat',
      'Kızıl kahverengi at rengi',
      'Cevap bekleyen ifade, sual',
    ]),
    _chain('cc_soru_kutu', ['SORU', 'BORU', 'KORU', 'KURU', 'KUTU'], [
      'İçi boş uzun silindir',
      'Küçük koruluk',
      'Nemden arınmış',
      'Eşya saklamaya yarayan kapaklı kutu',
    ]),
    _chain('cc_sari_kati', ['SARI', 'YARI', 'YAPI', 'KAPI', 'KATI'], [
      'İki eş parçadan biri, buçuk',
      'Mimari bina',
      'Giriş çıkış kapısı',
      'Sert, yoğun',
    ]),
    _chain('cc_kati_caki', ['KATI', 'BATI', 'YATI', 'ÇATI', 'ÇAKI'], [
      'Güneşin battığı yön',
      'Gemisi veya yatı (iyelik) / yatı okulu',
      'Evin üst örtüsü',
      'Küçük katlanır cep bıçağı',
    ]),
    _chain('cc_cal_dari', ['ÇALI', 'HALI', 'SALI', 'SARI', 'DARI'], [
      'Zemine serilen dokuma örtü',
      'Pazartesiden sonraki gün',
      'Güneş rengi',
      'Mısır veya kuş yemi tahılı',
    ]),
    _chain('cc_fire_mide', ['FİRE', 'FİLE', 'FİDE', 'PİDE', 'MİDE'], [
      'Ağ dokulu torba veya spor kalesi ağı',
      'Toprağa dikilmek üzere yetiştirilen genç bitki',
      'Fırında pişen yassı hamur işi',
      'Besinlerin sindirildiği organ',
    ]),
    _chain('cc_kure_yore', ['KÜRE', 'SÜRE', 'TÜRE', 'TÖRE', 'YÖRE'], [
      'Zaman aralığı',
      'Gelenek veya türemek',
      'Toplumda uyulan geleneksel kurallar',
      'Belirli bir bölge, civar',
    ]),
    _chain('cc_yore_dere', ['YÖRE', 'TÖRE', 'TÜRE', 'TERE', 'DERE'], [
      'Toplumsal gelenek',
      'Hukuk kuralı, yasa',
      'Salatalara konan keskin kokulu yeşillik',
      'Küçük akarsu, çay',
    ]),
    _chain('cc_dere_kufe', ['DERE', 'TERE', 'KERE', 'KÜRE', 'KÜFE'], [
      'Acımsı tadı olan yeşil salata otu',
      'Defa, kez',
      'Yuvarlak top şekli',
      'Sırtla veya elle taşınan büyük örme sepet',
    ]),
    _chain('cc_zemin_temin', ['ZEMİN', 'DEMİN', 'YEMİN', 'TEMİN'], [
      'Az önce, kısa bir süre önce',
      'Kutsal değerler üzerine verilen söz, ant',
      'Sağlamak, elde etmek, güvence altına almak',
    ]),
    _chain('cc_bilge_golge', ['BİLGE', 'BELGE', 'BÖLGE', 'GÖLGE'], [
      'Resmi kanıt kağıdı, doküman',
      'Sınırları belli coğrafi alan',
      'Işığın engellenmesiyle oluşan karanlık alan',
    ]),
    _chain('cc_umut_obur', ['UMUT', 'UMUR', 'OMUR', 'OBUR'], [
      'Önemseme, kaygı, iş (umurunda olmak)',
      'Omurgayı oluşturan kemiklerden her biri',
      'Aşırı derecede yemek yiyen',
    ]),
    _chain('cc_bufe_ture', ['BÜFE', 'KÜFE', 'KÜRE', 'SÜRE', 'TÜRE'], [
      'Büyük örme taşıma sepeti',
      'Dünya gibi yuvarlak cisim',
      'Geçen zaman dilimi',
      'Türemek veya yasa',
    ]),

    // --- 5 HARFLİ KELİME MERDİVENLERİ ---
    _chain('cc_tabak_yalan', ['TABAK', 'KABAK', 'KABAN', 'YABAN', 'YALAN'], [
      'Sarı veya yeşil renkli, dolması yapılan sebze',
      'Kışın giyilen kalın palto, mont',
      'Evcil olmayan, ıssız veya yabancı',
      'Doğru olmayan söz, gerçek dışı',
    ]),
    _chain('cc_yalan_kalin', ['YALAN', 'TALAN', 'PALAN', 'KALAN', 'KALIN'], [
      'Yağma, yıkıp dağıtma',
      'Eşek veya katır semeri',
      'Bölme işleminden artan veya geriye kalan',
      'İncenin zıttı',
    ]),
    _chain('cc_kalin_yanit', ['KALIN', 'KALIP', 'KALIT', 'KANIT', 'YANIT'], [
      'Şekillendirmeye yarayan model veya sabun adedi',
      'Kalıtsal özellik veya miras',
      'Doğruluğu ispatlayan delil',
      'Sorulan soruya verilen karşılık, cevap',
    ]),
    _chain('cc_kayit_yayim', ['KAYIT', 'KAYIK', 'KAYIN', 'YAYIN', 'YAYIM'], [
      'Küçük kürekli tekne',
      'Orman ağacı türü veya eşin erkek kardeşi',
      'Radyo/TV aktarımı veya basılı eser',
      'Kitap veya derginin basılıp halka sunulması',
    ]),
    _chain('cc_yayin_bakim', ['YAYIN', 'YAKIN', 'TAKIN', 'TAKIM', 'BAKIM'], [
      'Uzağın karşıtı, mesafesi az',
      'Üzerine takmak veya takınmak',
      'Spor kulübü veya alet seti',
      'Onarım, özen gösterme',
    ]),
    _chain('cc_bakim_yarin', ['BAKIM', 'TAKIM', 'TARIM', 'YARIM', 'YARIN'], [
      'Eşya seti veya futbol ekibi',
      'Toprağı işleyip ürün alma sanatı, ziraat',
      'Bir bütünün iki eş parçasından biri',
      'Bugünden sonraki gün',
    ]),
    _chain('cc_yarin_yikik', ['YARIN', 'YAKIN', 'YAKIM', 'YIKIM', 'YIKIK'], [
      'Yakın mesafede olan',
      'Yakma işlemi veya kalorifer yakıtı',
      'Büyük tahribat, çöktürme',
      'Harap olmuş, çökmüş yapı',
    ]),
    _chain('cc_camur_mamur', ['ÇAMUR', 'HAMUR', 'SAMUR', 'MAMUR'], [
      'Un ve suyla yoğrulan ekmek özü',
      'Kürkü değerli küçük etçil hayvan',
      'Bayındır, gelişmiş, bakımlı',
    ]),
    _chain('cc_celik_belik', ['ÇELİK', 'DELİK', 'MELİK', 'BELİK'], [
      'Açılmış boşluk, oyuk',
      'Hükümdar, padişah (tarihte)',
      'Saç örgüsü',
    ]),
    _chain('cc_yazar_hazar', ['YAZAR', 'PAZAR', 'NAZAR', 'HAZAR'], [
      'Haftanın son günü veya açık alışveriş yeri',
      'Kötü bakıştan geldiğine inanılan uğursuzluk',
      'Dünyanın en büyük tuzlu gölü/denizi',
    ]),
    _chain('cc_kazik_yakit', ['KAZIK', 'YAZIK', 'YAZIM', 'YAZIT', 'YAKIT'], [
      'Acıma veya üzüntü bildiren ünlem',
      'İmla, yazma biçimi',
      'Taş üzerine kazınmış tarihi metin, kitabe',
      'Enerji üretmek için yakılan madde (benzin vb.)',
    ]),
    _chain('cc_yatak_katik', ['YATAK', 'ÇATAK', 'BATAK', 'BATIK', 'KATIK'], [
      'İki dağ yamacının birleştiği derin yer',
      'Çamurlu bataklık veya borç içinde olma',
      'Denizin dibine batmış gemi',
      'Ekmeğin yanında yenen peynir, zeytin vb.',
    ]),
    _chain('cc_katik_sanik', ['KATIK', 'ÇATIK', 'YATIK', 'YANIK', 'SANIK'], [
      'Çatılmış, kızgın görünüşlü (kaş)',
      'Eğik duran, yatmış',
      'Ateşin deride bıraktığı iz veya içli türkü',
      'Suç işlediği şüphesiyle yargılanan kimse',
    ]),
    _chain('cc_sanik_carik', ['SANIK', 'YANIK', 'TANIK', 'TARIK', 'ÇARIK'], [
      'Ateşten zarar görmüş veya yanık kokusu',
      'Bir olaya şahitlik eden kimse, şahit',
      'Sabah yıldızı (Zühre) veya yol',
      'Eskiden köylülerin giydiği deriden ayakkabı',
    ]),
    _chain('cc_sevgi_gergi', ['SEVGİ', 'SERGİ', 'VERGİ', 'DERGİ', 'GERGİ'], [
      'Sanat eserlerinin halka sunulduğu mekan',
      'Devletin vatandaşlardan aldığı mali pay',
      'Düzenli aralıklarla çıkan resimli yayın, mecmua',
      'Bir şeyi gergin tutmaya yarayan alet',
    ]),
    _chain('cc_burgu_duygu', ['BURGU', 'KURGU', 'DURGU', 'DUYGU'], [
      'Hayal gücüyle oluşturulan hikaye veya montaj',
      'Cümledeki duraklama yeri',
      'Sevgi, sevinç, hüzün gibi ruhsal his',
    ]),
    _chain('cc_dalgi_kargi', ['DALGI', 'SALGI', 'SARGI', 'YARGI', 'KARGI'], [
      'Bezlerden salgılanan hormon veya sıvı',
      'Yarayı sarmak için kullanılan tıbbi bez',
      'Mahkeme kararı veya hüküm',
      'Ucu sivri uzun mızrak veya kamış',
    ]),
    _chain('cc_melek_kelek', ['MELEK', 'FELEK', 'YELEK', 'BELEK', 'KELEK'], [
      'Talih, kader veya gökyüzü',
      'Kolsuz, önü iliklenen giysi',
      'Antalya\'nın ünlü turizm beldesi',
      'Olgunlaşmamış kavun veya kalleşlik',
    ]),
    _chain('cc_bebek_melek', ['BEBEK', 'BELEK', 'YELEK', 'FELEK', 'MELEK'], [
      'Bebeğin sarıldığı kundak bezi',
      'Takım elbisenin kolsuz parçası',
      'Kader, talih',
      'İyilik ve saflık timsali nurani varlık',
    ]),
    _chain('cc_tavan_kalan', ['TAVAN', 'YAVAN', 'YALAN', 'TALAN', 'KALAN'], [
      'Yağı, tuzu az, lezzetsiz yemek',
      'Gerçeğe aykırı söz',
      'Yağmalama, talan etme',
      'Artakalan kısım',
    ]),
    _chain('cc_yaban_kaban', ['YABAN', 'TABAN', 'TABAK', 'KABAK', 'KABAN'], [
      'Ayağın alt kısmı veya bir nesnenin altı',
      'Yemek konulan yayvan mutfak eşyası',
      'Balkabağı veya sakız kabağı',
      'Kalın kışlık ceket',
    ]),
    _chain('cc_kaban_saman', ['KABAN', 'YABAN', 'YAMAN', 'ZAMAN', 'SAMAN'], [
      'Vahşi doğa, ıssız yer',
      'Çok becerikli, çetin, güçlü',
      'Geçmiş, şimdi ve geleceği kapsayan akış',
      'Buğday saplarının ufalanmış kuru hali',
    ]),
    _chain('cc_kapan_yalan', ['KAPAN', 'SAPAN', 'TAPAN', 'YAPAN', 'YALAN'], [
      'Taş atmaya yarayan Y biçimli araç',
      'Tarlayı düzlemeye yarayan tarım aleti',
      'Bir işi gerçekleştiren',
      'Gerçek olmayan söz',
    ]),
    _chain('cc_kazan_batan', ['KAZAN', 'SAZAN', 'YAZAN', 'YATAN', 'BATAN'], [
      'Tatlı sularda yaşayan iri balık',
      'Kaleme alan, yazar',
      'Uzanmış veya yatakta uyuyan',
      'Suya gömülen veya iflas eden',
    ]),
    _chain('cc_yapim_cikik', ['YAPIM', 'YAKIM', 'YIKIM', 'YIKIK', 'ÇIKIK'], [
      'Yakıt yakma işlemi',
      'Yıkma işi, felaket',
      'Harabe, yıkılmış',
      'Eklemin yerinden oynaması veya dışarı doğru taşmış',
    ]),
    _chain('cc_kasik_yazit', ['KASIK', 'KAZIK', 'YAZIK', 'YAZIM', 'YAZIT'], [
      'Yere çakılan sivri uçlu direk',
      'Acıma veya boşa gitme durumu',
      'Kelimelerin doğru yazılma kuralı',
      'Anıtlar üzerine kazınan eski yazı',
    ]),
    _chain('cc_yazit_tarim', ['YAZIT', 'YAZIM', 'YAKIM', 'TAKIM', 'TARIM'], [
      'İmla kuralları',
      'Isıtma için yakma işi',
      'Birbiriyle uyumlu eşya grubu',
      'Çiftçilik, ziraat',
    ]),
    _chain('cc_tarim_sakin', ['TARIM', 'YARIM', 'YARIN', 'YAKIN', 'SAKIN'], [
      'Bütünün yarısı, 0.5',
      'Ertesi gün',
      'Uzak olmayan',
      'Sakın ha, aman yapma anlamında uyarı',
    ]),
    _chain('cc_sakin_yazim', ['SAKIN', 'YAKIN', 'YAYIN', 'YAYIM', 'YAZIM'], [
      'Mesafesi az, dost',
      'Medya yayını',
      'Basım ve dağıtım',
      'Harfleri doğru yazma biçimi, imla',
    ]),
    _chain('cc_yanik_kayit', ['YANIK', 'TANIK', 'KANIK', 'KAYIK', 'KAYIT'], [
      'Mahkemede gördüğünü anlatan kimse',
      'Alışmış, kanıksamış',
      'Göl veya denizde kürekle sürülen tekne',
      'Deftere veya sisteme işleme, arşivleme',
    ]),
    _chain('cc_soluk_dolak', ['SOLUK', 'SOLAK', 'ÇOLAK', 'DOLAK'], [
      'Sol elini daha ustaca kullanan',
      'Bir kolu veya eli sakat olan',
      'Eskiden bacağa sarılan kalın yün bez',
    ]),
    _chain('cc_sefer_kemer', ['SEFER', 'SEHER', 'SEMER', 'KEMER'], [
      'Tan ağarmadan önceki vakit',
      'Yük hayvanlarının sırtına konulan eyer',
      'Beli sıkmaya yarayan deri kuşak veya mimari yay',
    ]),
    _chain('cc_park_bark', ['PARK', 'FARK', 'ŞARK', 'BARK'], [
      'İki şey arasındaki ayrım',
      'Doğu yönü veya şarkı sözü kökü',
      'Ev, yuva (ev bark deyiminde)',
    ]),
    _chain('cc_saman_kalan', ['SAMAN', 'ZAMAN', 'YAMAN', 'YALAN', 'KALAN'], [
      'Saatlerle ölçülen süre',
      'Güçlü, çetin, usta',
      'Uydurma söz',
      'Geriye artan miktar',
    ]),
  ];
}
