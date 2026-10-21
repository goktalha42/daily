# Günlük Zeka Oyunları - Proje İlerleme ve Mimari Dokümanı

Bu doküman, günlük zeka oyunları konseptindeki **Daily Games (Zühtü)** Flutter projesinin mimarisini, özelliklerini, teknik detaylarını ve aşamalı geliştirme durumunu içermektedir.

---

## 🎯 1. Proje Amacı ve Vizyonu

Kullanıcıların her gün girip 6 farklı zeka/bulmaca oyununu oynayabileceği, her gün gece yarısı yeni seviyelerin yayınlandığı, tüm oyuncuların performanslarına göre (süre, hamle sayısı vb.) sıralandığı, sıcak el çizimi skeç estetiğine (Organic Sketch Paper & Hatching) sahip, IQ endeksi ve rozet sistemiyle zenginleştirilmiş modüler bir Flutter uygulaması.

---

## 📌 2. Temel Özellikler ve Kurallar

1. **İnternet Bağlantı Zorunluluğu (Online Only):**
   - Oyunlar **sadece internet bağlantısı aktifken** oynanabilir.
   - İnternet kesildiğinde veya çevrimdışıyken oyun duraklatılır ve `OnlineGuardWidget` uyarı ekranı gösterilir.
   - Hile yapılmasını engellemek için skorlar sunucuya doğrulama ile senkronize edilir.

2. **6 Farklı Günlük Oyun:**
   - **Vezirler (Queens):** Satır, sütun ve renk bölgesine birbirine temas etmeyecek şekilde vezir yerleştirme (Kolay, Zor ve 9x9 çift vezirli Master seviyesi).
   - **Kelime İzleri (Pinpoint):** Gizli anahtar kelimeleri ve kelime bağlantılarını aşamalı ipuçlarıyla tahmin etme.
   - **Kelime Tırmanışı (Crossclimb):** Merdiven basamakları içinde doğrudan ipucuna göre tek harf değiştirerek zirveye tırmanma.
   - **Güneş & Ay (Tango):** Izgaraya eşit sayıda Güneş ve Ay simgesi yerleştirme, 3 aynı simgenin yan yana gelmesini engelleme.
   - **Sayı Yolu (Zip Path):** Sayıları sırasıyla yolları kesiştirmeden ızgara üzerinde birleştirme.
   - **Alan Bölme (Patches):** Sayı değerlerine göre ızgarayı çakışmayan dikdörtgen ve kare alanlara bölme.

3. **Gerçekçi Zekâ Endeksi (IQ) ve Yüzdelik Dilim Sistemi:**
   - Gauss normal dağılımı (ortalama 100, standart sapma 15) uyarınca gerçekçi yüzdelik dilim ve IQ endeksi.
   - Kilometre Taşı (Milestone) eşikleri (100 IQ: Ortalama, 108 IQ: %70'ten iyi, 120 IQ: Büyük Usta, 130 IQ: Einstein seviyesi).
   - Kazanma ekranında dinamik yukarı yükselen animasyonlu karşılaştırma çubuğu.

4. **Kapsamlı Rozet & Şampiyonluk Kemeri Sistemi (`rozetler.md`):**
   - **Süreli Şampiyonluk Kemerleri (Dinamik):**
     - **Einstein Zekâ Rozeti (130+ IQ):** 130 IQ üzerinde olduğu sürece profilde sol üst köşede sergilenir; 130 altına düşüldüğünde otomatik silinir.
     - **Büyük Usta Rozeti (120+ IQ):** 120 IQ üzerinde korunan unvan rozeti.
     - **Zirve Hükümdarı Kemeri:** Günün liderlik tablosunda #1 olan oyuncuya 24 saatliğine verilir.
     - Podyum Lideri, Günün Şimşeği, Vezirler Master Kemeri, Gece Baykuşu, vb.
   - **Seri Rozetleri (Kalıcı Koleksiyon - 91 Adet):**
     - Her oyun için ayrı ayrı ve genel zihin serisi için 13 aşama (`3, 5, 10, 15, 30, 50, 75, 100, 150, 200, 250, 300, 365` gün).
     - 1 kez kazanıldıktan sonra oyuncunun koleksiyonunda ömür boyu kalır.
   - **Oyun Ustalığı ve Zekâ Rozetleri:** 6 oyun ustalığı ve 6 özel başarı rozeti.

5. **Detaylı Sıralama ve Skor Tablosu (Leaderboard):**
   - Oyun bazlı sıralama + Vezirler için zorluk sekmesi filtresi (`👑 Tümü`, `Kolay`, `Zor`, `Master`).
   - Zaman Dilimleri: Günlük, Haftalık, Aylık, Genel Sıralama.
   - İlk 3 derece için organik podyum (🥇🥈🥉) görünümü.

---

## 🛠️ 3. Teknoloji Yığını ve Mimari

- **Framework:** Flutter (Dart) - Cross-platform
- **State Management:** `flutter_riverpod` (Modüler ve güvenli durum yönetimi)
- **Tasarım Dili:** Kara kalem / Defter skeç estetiği (`SketchCard`, `SketchPaperBackground`, `AppColors.pencilBlack`, `GoogleFonts.patrickHand`)
- **Renk Kuralı:** `highlighterYellow` ve `highlighterGreen` kesinlikle yasaktır; `AppColors.sunYellow` ve `AppColors.success` kullanılır.
- **Kayıt / Cache:** `shared_preferences` ile günlük ilerleme, oturum durumu, istatistikler ve rozet koleksiyonu saklanır.

---

## 📁 4. Proje Dizin Yapısı

```text
lib/
├── core/
│   ├── models/             # badge_model.dart (113 rozet ve kuralları)
│   ├── network/            # network_checker.dart
│   ├── services/           # badge_service.dart, daily_play_service.dart, game_stats_service.dart, game_session_service.dart
│   ├── theme/              # app_colors.dart, app_theme.dart
│   ├── utils/              # date_utils.dart
│   └── widgets/            # sketch_decorations.dart, genius_win_dialog.dart, screen_shake.dart
├── features/
│   ├── home/               # Ana sayfa (Skeç defter arayüzü, oyun kartları)
│   ├── leaderboard/        # Liderlik tablosu (Zorluk filtreleri, dengeli bot simülasyonu)
│   └── profile/            # Profil ekranı, sol köşede Einstein rozeti, rozet vitrini
└── games/
    ├── common/             # BaseGame, GameResult modelleri
    ├── queens/             # Vezirler (Kolay, Zor, Master 9x9 2-Vezir mantığı)
    ├── pinpoint/           # Kelime İzleri
    ├── crossclimb/         # Kelime Tırmanışı (Basamak içi doğrudan giriş)
    ├── tango/              # Güneş & Ay
    ├── zip_path/           # Sayı Yolu
    └── patches/            # Alan Bölme
```

---

## 📋 5. Geliştirme Yol Haritası ve İlerleme Durumu

### 🟢 Tamamlanan Aşamalar
- [x] Temel mimari ve Riverpod durum yönetim altyapısı
- [x] Online-Only bağlantı denetleyicisi (`OnlineGuardWidget`)
- [x] 6 farklı günlük oyunun mantık motorları ve seviye jeneratörleri
- [x] Vezirler Master (9x9, 2 Vezir) çıkarımsal mantık çözücüsü ve doğru ipucu sistemi
- [x] Kelime Tırmanışı basamak içi soru/giriş tasarımı
- [x] Gerçekçi IQ endeksi, Gauss yüzdelik dilimi ve animasyonlu yükselen bar diyalogu
- [x] Vezirler Master (9x9, 2 Vezir) %100 insan aklıyla çözülebilirlik kuralı (`deductive.isSolvable`) ve çok katmanlı eğitici ipucu sistemi
- [x] Gerçekçi ve mücadeleci Liderlik Tablosu puan simülasyonu (Oyunların 2000 taban puanına tam uyumlu elit rekabet eğrisi)
- [x] `flutter analyze` 0 hata ve `flutter test` 76 testin tamamının başarıyla geçmesi
- [x] Duolingo tarzı Haftalık Lig Sistemi (`league_service.dart`, `league_screen.dart`)
  - 10 lig kademesi: Taş → Bronz → Gümüş → Altın → Safir → Yakut → Elmas → Ametist → Zümrüt → Muhteşem
  - 42 oyunculuk lig grupları (1 kullanıcı + 41 bot)
  - Haftalık toplam puan sıralaması (Pazartesi sıfırlanır, Pazar bitiş)
  - İlk 10 yükselir / Son 10 düşer kuralı
  - Yükselme / Güvenli / Düşme bölge etiketleri
  - Ana navigasyon çubuğuna "Lig" sekmesi eklendi (4 sekme)
  - Profil ekranına lig özet kartı entegre edildi
