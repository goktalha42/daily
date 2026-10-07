import '../../core/puzzle/puzzle_seed.dart';
import 'pinpoint_logic.dart';
import 'pinpoint_models.dart';

/// Pinpoint (Kelime İzleri) günlük bulmacalarını tohumdan deterministik olarak seçer ve üretir.
class PinpointGenerator {
  const PinpointGenerator._();

  static final DateTime _epoch = DateTime.utc(2026, 1, 1);

  static PinpointLevel generate({required String levelId}) {
    DateTime date;
    try {
      date = DateTime.parse(levelId);
    } catch (_) {
      date = DateTime.now();
    }
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final days = normalizedDate.difference(_epoch).inDays.abs();

    // Günlük tohum ile havuzdan deterministik ve dengeli seçim
    final seed = PuzzleSeed.toInt(PuzzleSeed.derive('pinpoint-daily', '$days'));
    final index = seed % _pool.length;
    final item = _pool[index];

    final level = PinpointLevel(
      id: levelId,
      categoryHint: item.categoryHint,
      targetWord: PinpointLogic.normalize(item.targetWord),
      clues: item.clues,
      alternativeAnswers: item.alternativeAnswers,
    );

    assert(PinpointLogic.validateLevel(level), 'Geçersiz Pinpoint seviyesi: ${level.targetWord}');
    return level;
  }

  static List<PinpointLevel> get pool => List.unmodifiable(_pool);

  /// Zengin Türkçe kavram ve 5 aşamalı ipucu havuzu
  static final List<PinpointLevel> _pool = [
    PinpointLevel(
      id: 'pp_kahve',
      categoryHint: 'İçecek & Günlük Yaşam',
      targetWord: 'KAHVE',
      clues: ['Espresso', 'Kolombiya', 'Çekirdek', 'Fincan', 'Sabah'],
      alternativeAnswers: ['TÜRK KAHVESİ'],
    ),
    PinpointLevel(
      id: 'pp_gezegen',
      categoryHint: 'Doğa ve Uzay',
      targetWord: 'GEZEGEN',
      clues: ['Yörünge', 'Yerçekimi', 'Jüpiter', 'Kutup', 'Atmosfer'],
    ),
    PinpointLevel(
      id: 'pp_gitar',
      categoryHint: 'Müzik ve Sanat',
      targetWord: 'GİTAR',
      clues: ['Akort', 'Tel', 'Pena', 'Solo', 'Melodi'],
      alternativeAnswers: ['KLASİK GİTAR', 'ELEKTRO GİTAR'],
    ),
    PinpointLevel(
      id: 'pp_sinema',
      categoryHint: 'Kültür & Eğlence',
      targetWord: 'SİNEMA',
      clues: ['Koltuk', 'Kamera', 'Patlamış Mısır', 'Perde', 'Yönetmen'],
      alternativeAnswers: ['FİLM'],
    ),
    PinpointLevel(
      id: 'pp_kaptan',
      categoryHint: 'Denizcilik & Macera',
      targetWord: 'KAPTAN',
      clues: ['Pusula', 'Dümen', 'Liman', 'Güverte', 'Dalga'],
      alternativeAnswers: ['GEMİ KAPTANI'],
    ),
    PinpointLevel(
      id: 'pp_mutfak',
      categoryHint: 'Gastronomi & Ev',
      targetWord: 'MUTFAK',
      clues: ['Önlük', 'Tencere', 'Baharat', 'Bıçak', 'Yemek'],
    ),
    PinpointLevel(
      id: 'pp_futbol',
      categoryHint: 'Spor & Rekabet',
      targetWord: 'FUTBOL',
      clues: ['Düdük', 'Krampon', 'Kale', 'Penaltı', 'Taraftar'],
      alternativeAnswers: ['FUTBOL MAÇI'],
    ),
    PinpointLevel(
      id: 'pp_kitap',
      categoryHint: 'Edebiyat & Bilgi',
      targetWord: 'KİTAP',
      clues: ['Sayfa', 'Cilt', 'Yazar', 'Ayraç', 'Raf'],
      alternativeAnswers: ['ROMAN'],
    ),
    PinpointLevel(
      id: 'pp_piyano',
      categoryHint: 'Enstrüman & Klasik',
      targetWord: 'PİYANO',
      clues: ['Tuş', 'Pedal', 'Kuyruk', 'Konser', 'Nota'],
    ),
    PinpointLevel(
      id: 'pp_doktor',
      categoryHint: 'Tıp & Sağlık',
      targetWord: 'DOKTOR',
      clues: ['Stetoskop', 'Beyaz Önlük', 'Reçete', 'Muayene', 'Şifa'],
      alternativeAnswers: ['HEKİM', 'TABİP'],
    ),
    PinpointLevel(
      id: 'pp_astronot',
      categoryHint: 'Bilim & Kozmos',
      targetWord: 'ASTRONOT',
      clues: ['Kask', 'Yerçekimsiz', 'Uzay İstasyonu', 'Ay', 'Roket'],
      alternativeAnswers: ['KOZMONOT'],
    ),
    PinpointLevel(
      id: 'pp_kamp',
      categoryHint: 'Doğa & Macera',
      targetWord: 'KAMP',
      clues: ['Çadır', 'Uyku Tulumu', 'Ateş', 'Matara', 'Yıldızlar'],
    ),
    PinpointLevel(
      id: 'pp_dedektif',
      categoryHint: 'Gizem & Suç',
      targetWord: 'DEDEKTİF',
      clues: ['Büyüteç', 'İpucu', 'Parmak İzi', 'Şüpheli', 'Gizem'],
      alternativeAnswers: ['MÜFETTİŞ'],
    ),
    PinpointLevel(
      id: 'pp_saat',
      categoryHint: 'Zaman & Günlük',
      targetWord: 'SAAT',
      clues: ['Yelkovan', 'Akrep', 'Tik Tak', 'Alarm', 'Zaman'],
      alternativeAnswers: ['KOL SAATİ', 'DUVAR SAATİ'],
    ),
    PinpointLevel(
      id: 'pp_ucak',
      categoryHint: 'Havacılık & Seyahat',
      targetWord: 'UÇAK',
      clues: ['Kanat', 'Kokpit', 'Hostes', 'İniş Pisti', 'Bulutlar'],
      alternativeAnswers: ['TAYYARE'],
    ),
    PinpointLevel(
      id: 'pp_ressam',
      categoryHint: 'Görsel Sanatlar',
      targetWord: 'RESSAM',
      clues: ['Tuval', 'Şövale', 'Fırça', 'Palet', 'Boya'],
    ),
    PinpointLevel(
      id: 'pp_deprem',
      categoryHint: 'Coğrafya & Doğa Olayı',
      targetWord: 'DEPREM',
      clues: ['Fay Hattı', 'Richter', 'Sarsıntı', 'Sismograf', 'Artçı'],
      alternativeAnswers: ['ZELZELE'],
    ),
    PinpointLevel(
      id: 'pp_tiyatro',
      categoryHint: 'Sahne Sanatları',
      targetWord: 'TİYATRO',
      clues: ['Sahne', 'Kostüm', 'Alkış', 'Replik', 'Perde'],
      alternativeAnswers: ['OYUN'],
    ),
    PinpointLevel(
      id: 'pp_volkan',
      categoryHint: 'Jeoloji & Doğa',
      targetWord: 'VOLKAN',
      clues: ['Lav', 'Magma', 'Krater', 'Kül', 'Püskürme'],
      alternativeAnswers: ['YANARDAĞ'],
    ),
    PinpointLevel(
      id: 'pp_ari',
      categoryHint: 'Biyoloji & Canlılar',
      targetWord: 'ARI',
      clues: ['Kovan', 'Polen', 'Petek', 'Kraliçe', 'Bal'],
      alternativeAnswers: ['BAL ARISI'],
    ),
    PinpointLevel(
      id: 'pp_satranc',
      categoryHint: 'Strateji & Zeka',
      targetWord: 'SATRANÇ',
      clues: ['Şah', 'Mat', 'Piyon', 'Rok', 'Kare'],
    ),
    PinpointLevel(
      id: 'pp_piramit',
      categoryHint: 'Tarih & Mimari',
      targetWord: 'PİRAMİT',
      clues: ['Firavun', 'Mumya', 'Nil', 'Kum', 'Anıt'],
    ),
    PinpointLevel(
      id: 'pp_selale',
      categoryHint: 'Coğrafya & Manzara',
      targetWord: 'ŞELALE',
      clues: ['Kanyon', 'Debi', 'Köpük', 'Akıntı', 'Çağlayan'],
      alternativeAnswers: ['ÇAĞLAYAN'],
    ),
    PinpointLevel(
      id: 'pp_denizalti',
      categoryHint: 'Deniz & Savunma',
      targetWord: 'DENİZALTI',
      clues: ['Periskop', 'Sonar', 'Torpidolar', 'Derinlik', 'Basınç'],
    ),
    PinpointLevel(
      id: 'pp_teleskop',
      categoryHint: 'Astronomi & Gözlem',
      targetWord: 'TELESKOP',
      clues: ['Mercek', 'Galaksi', 'Gözlemevi', 'Yıldız', 'Odak'],
    ),
    PinpointLevel(
      id: 'pp_buzul',
      categoryHint: 'İklim & Kutup',
      targetWord: 'BUZUL',
      clues: ['Antarktika', 'İklim', 'Eriyen', 'Buzdağı', 'Soğuk'],
      alternativeAnswers: ['GLASYER'],
    ),
    PinpointLevel(
      id: 'pp_olimpiyat',
      categoryHint: 'Uluslararası Spor',
      targetWord: 'OLİMPİYAT',
      clues: ['Meşale', 'Madalya', 'Halka', 'Maraton', 'Kürsü'],
      alternativeAnswers: ['OLİMPİYATLAR'],
    ),
    PinpointLevel(
      id: 'pp_ekmek',
      categoryHint: 'Geleneksel Mutfak',
      targetWord: 'EKMEK',
      clues: ['Fırın', 'Hamur', 'Maya', 'Buğday', 'Kabuk'],
    ),
    PinpointLevel(
      id: 'pp_dagcilik',
      categoryHint: 'Ekstrem Spor',
      targetWord: 'DAĞCILIK',
      clues: ['Zirve', 'Halat', 'Krampon', 'Oksijen', 'Tırmanış'],
    ),
    PinpointLevel(
      id: 'pp_tren',
      categoryHint: 'Ulaşım & Demiryolu',
      targetWord: 'TREN',
      clues: ['Ray', 'Lokomotif', 'Vagon', 'İstasyon', 'Kondüktör'],
      alternativeAnswers: ['ŞİMENDİFER'],
    ),
  ];
}
