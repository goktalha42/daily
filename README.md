# Zühtü

> Günde bir kez, herkes için aynı, her gün eşsiz mini zeka oyunları.
> Flutter (Android / Google Play) · Laravel + MySQL + Redis (VDS) · FCM

Bu dosya projenin **tek yol haritasıdır**. Yeni özellik, ekran veya oyun eklemeden önce burası okunur; iş bitince burası güncellenir.

## İçindekiler
1. [Vizyon ve Temel İlkeler](#1-vizyon-ve-temel-ilkeler)
2. [Tasarım Dili (EN ÖNEMLİ BÖLÜM)](#2-tasarım-dili-en-önemli-bölüm)
3. [Oyun Listesi](#3-oyun-listesi)
4. [Günlük Eşsiz Bulmaca Üretimi](#4-günlük-eşsiz-bulmaca-üretimi)
5. [Mimari](#5-mimari)
6. [Klasör Yapısı](#6-klasör-yapısı)
7. [Zaman Yönetimi (UTC ve Clock Drift)](#7-zaman-yönetimi-utc-ve-clock-drift)
8. [Hile Koruması, Oturum ve Sıralama](#8-hile-koruması-oturum-ve-sıralama)
9. [Bildirimler (FCM)](#9-bildirimler-fcm)
10. [Yol Haritası](#10-yol-haritası)
11. [Geliştirme Kuralları (Definition of Done)](#11-geliştirme-kuralları-definition-of-done)

---

## 1. Vizyon ve Temel İlkeler

- **Oyunun adı: Zühtü.**
- Her oyun günde **tek seviye** sunar; seviye tüm dünyada aynıdır.
- Seviyeler **şablondan değil, her gün yeniden üretilir** ve hiçbir zaman tekrar etmez (bkz. Bölüm 4).
- Çözüm anahtarı **asla istemciye gönderilmez**.
- Güvenilir zaman **sunucu zamanıdır**; cihaz saati güvenilmez.
- Tüm arayüz tek bir tasarım dilinde olur (bkz. Bölüm 2).
- Geliştirme önce **yerel bilgisayarda** yapılır; sunucu sonra bağlanır (bkz. Bölüm 5).

---

## 2. Tasarım Dili (EN ÖNEMLİ BÖLÜM)

> **Kural:** Yeni eklenen her ekran, widget, diyalog, oyun tahtası ve ikon bu bölümdeki kurallara uyar. Bu bölüme uymayan kod birleştirilmez.

### 2.1 Konsept: "Kara Kalem Eskiz Defteri"
Uygulama, kareli bir eskiz defterine kalemle çizilmiş gibi görünür. Ana sayfalar (Oyunlar, Sıralama, Profil) bu dilin **referans uygulamasıdır**.

Kimliği oluşturan 5 öğe:
1. **Kağıt zemin:** krem rengi, hafif kareli, sol kırmızı marjin çizgisi, köşelerde silik karalamalar.
2. **Kalın siyah kontur:** her kart ve butonda kurşun kalem siyahı kenarlık.
3. **Sert (blur'suz) gölge:** gölge çizilmiş gibi durur, yumuşak değildir.
4. **Fosforlu kalem renkleri:** zemin sade, vurgu parlak fosfor tonlarıdır.
5. **El yazısı font:** Patrick Hand.

### 2.2 Renkler
Tek kaynak: [`lib/core/theme/app_colors.dart`](lib/core/theme/app_colors.dart). Koda sabit renk kodu (`Color(0xFF...)`) yazılmaz, `AppColors` kullanılır.

| Rol | Token | Değer |
|---|---|---|
| Sayfa zemini | `backgroundLight` | `#FBF9F4` |
| Kart / yüzey | `surfaceLight` | `#FFFFFF` |
| İkincil yüzey | `surfaceSecondaryLight` | `#F3EFE6` |
| Kontur ve ana metin | `pencilBlack` | `#1C1917` |
| İkincil metin | `pencilGraphite` | `#44403C` |
| Soluk metin | `pencilGray` | `#78716C` |
| Taslak çizgi | `pencilLight` | `#A8A29E` |
| Sarı fosfor (seçili/vurgu) | `highlighterYellow` | `#FFDE59` |
| Turkuaz fosfor | `highlighterCyan` | `#70E0D8` |
| Turuncu fosfor | `highlighterOrange` | `#FF9F68` |
| Pembe fosfor | `highlighterPink` | `#FF85A1` |
| Yeşil fosfor | `highlighterGreen` | `#86EFAC` |
| Mor fosfor | `highlighterPurple` | `#C4B5FD` |
| Hata | `error` | `#EF4444` |

**Oyun renkleri** (kartlarda, başlıklarda, tahta vurgularında): Queens → pembe, Pinpoint → turkuaz, Crossclimb → mor, Tango → turuncu, Zip → yeşil. Yeni oyun eklenince **kalan fosfor tonlarından biri** atanır, `AppColors.<oyun>Game` olarak tanımlanır.

### 2.3 Tipografi
Tek kaynak: [`app_text_styles.dart`](lib/core/theme/app_text_styles.dart). Font: **Patrick Hand** (`google_fonts`). Başka font kullanılmaz.

| Stil | Boyut | Ağırlık |
|---|---|---|
| `displayLarge` | 44 | 700 |
| `headlineLarge` | 32 | 700 |
| `headlineMedium` | 26 | 700 |
| `titleLarge` | 22 | 700 |
| `titleMedium` | 18 | 700 |
| `bodyLarge` | 17 | 600 |
| `bodyMedium` | 15 | 500 |
| `labelLarge` | 16 | 700 |

### 2.4 Kontur, Gölge, Köşe
| Öğe | Kenarlık | Gölge | Köşe |
|---|---|---|---|
| Büyük kart / nav çubuğu | 2.5 px `pencilBlack` | `Offset(4,4)`, blur **0**, `pencilBlack` | 16 |
| Seçili küçük öğe | 2.0 px `pencilBlack` | `Offset(2,2)`, blur **0** | 10 |
| Buton | 2–2.5 px `pencilBlack` | `Offset(3,3)`, blur **0** | 12–16 |

- Seçili / aktif durumun arka planı `highlighterYellow` olur.
- Basılma animasyonu: gölge küçülür ve öğe gölge yönünde kayar (basılmış kalem hissi).
- Boşluklar `AppSpacing` (`xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`) ile verilir. Köşe yarıçapları `AppSpacing.borderRadius*` ile.

### 2.5 Yasaklar
- **Yok:** yumuşak/bulanık gölge, cam efekti (glassmorphism), gradyan zemin, koyu neon temalar.
- **Yok:** Material varsayılan renkleri, Roboto/Inter gibi başka fontlar.
- **Yok:** ince (1 px altı) veya gri kontur.
- Gradyan yalnızca oyun kartı logolarında, açık tonlu ve küçük alanda kullanılabilir.

### 2.6 Hareket ve Dokunuş
- Kısa, canlı animasyonlar (150–300 ms, `flutter_animate`). Yavaş geçiş yok.
- Seçimde `HapticFeedback.selectionClick()`, başarıda daha güçlü titreşim.
- Hata: `ScreenShake`. Zafer: `GeniusWinDialog`.

### 2.7 Ortak Bileşenler (yeni iş bunları kullanır)
| Bileşen | Dosya |
|---|---|
| Kağıt zemin | `core/widgets/sketch_decorations.dart` → `SketchPaperBackground` |
| Kart | `core/theme/widgets/app_card.dart` |
| Buton | `core/theme/widgets/app_button.dart` |
| Oyun logoları | `core/widgets/game_card_logos.dart` |
| Zafer diyaloğu | `core/widgets/genius_win_dialog.dart` |
| Ekran sarsıntısı | `core/widgets/screen_shake.dart` |
| Oyun ekranı iskeleti | `games/common/neo_game_layout.dart` |

Yeni ekran **önce** bu bileşenlerle denenir; eksikse bileşen buraya eklenir, ekran içinde tek seferlik stil yazılmaz.

### 2.8 Tasarım Uyum Borcu (düzeltilecekler)
- [x] `GameType.color` artık `AppColors.*Game` (fosfor) tonlarını kullanıyor.
- [x] `glass_card.dart` silindi. `NeoGameLayout` blur'suz, kalın konturlu skeç iskeletine çevrildi.
- [x] `AppColors` içindeki koyu mod ve `glassGradient*` tanımları temizlendi.
- [x] Kalan "Dahi" etiketleri (`Saf Dahi`, `Global Dahi`, `Dahi #8492`, `DAHİ SEVİYESİ`) Zühtü kimliğiyle yeniden adlandırıldı (`ZuhtuWinDialog` aliası bağlandı).
- [x] Oyun ekranlarının içi (Pinpoint, Crossclimb, Tango, Zip, Patches, Queens) için dil denetimi tamamlandı: yumuşak gölgeler kaldırıldı (blur: 0), sabit renk kodları `AppColors` standartlarına (`errorBgLight`, `successDark`, `highlighter*`) bağlandı.

---

## 3. Oyun Listesi

Hedef: aşağıdaki **6 oyunun tamamı** yapılacak.

| # | Oyun | Türkçe ad | Durum | Renk |
|---|---|---|---|---|
| 1 | Queens | Vezirler | Mevcut | Pembe |
| 2 | Tango | Güneş & Ay | Mevcut | Turuncu |
| 3 | Zip | Sayı Yolu | Mevcut | Yeşil |
| 4 | Pinpoint | Kelime İzleri | Mevcut | Turkuaz |
| 5 | Crossclimb | Kelime Tırmanışı | Mevcut | Mor |
| 6 | Patches (Shikaku) | Alan Bölme | Mevcut | Sarı |

Her oyun şu üç parçayı içerir: **`Models`** (tahta durumu), **`Logic`** (hamle işleme, durum), **`Validator`** (çözüm ve kural doğrulama) ve ayrıca **`Generator`** (bkz. Bölüm 4).

### 3.1 Queens (Vezirler)
- N×N ızgara, N farklı renk bölgesi.
- Her satırda, her sütunda ve her renk bölgesinde **tam 1** vezir.
- İki vezir 8 yönde komşu olamaz.

### 3.2 Tango (Güneş & Ay)
- Çift sayılı kare ızgara (örn. 6×6); hücreler Güneş veya Ay.
- Her satır/sütunda eşit sayıda Güneş ve Ay.
- Yan yana veya alt alta 3 aynı sembol olamaz.
- Hücreler arası `=` (aynı) ve `×` (farklı) kuralları.

### 3.3 Zip (Sayı Yolu)
- N×M ızgara, sıralı kontrol noktaları (1…K) ve duvarlar.
- 1'den başlayıp noktalar sırayla tek çizgiyle bağlanır, yalnızca ortogonal hareket.
- Çizgi tüm erişilebilir boş kareleri **tam bir kez** geçer.

### 3.4 Pinpoint (Kelime İzleri)
- Verilen ipuçlarından gizli anahtar kelime/kategori tahmin edilir.
- İpuçları kademeli açılır; ne kadar az ipucuyla bilinirse puan o kadar yüksek.

### 3.5 Crossclimb (Kelime Tırmanışı)
- İpuçlarından kelimeler bulunur; kelimeler arası geçişte tek harf değişir.
- Sıralama doğru kurulunca zirve kelimesi açılır.

### 3.6 Patches (Alan Bölme / Shikaku)
- Izgarada bazı hücrelerde alan sayısı yazar.
- Izgara, her biri tam bir sayı içeren ve alanı o sayıya eşit **dikdörtgenlere** bölünür.
- Dikdörtgenler çakışamaz, boş hücre kalamaz.

> Her oyunun kural değişikliği önce bu bölümde güncellenir, sonra kodlanır.

---

## 4. Günlük Eşsiz Bulmaca Üretimi

### 4.1 Hedef
Yayın gününden **3 yıl** (hatta 30 yıl) sonra üretilen bölüm, ilk günkü bölümle ve aradaki tüm bölümlerle **aynı olmamalı**. Sabit seviye listesi, şablon veya döngüsel tekrar yoktur.

### 4.2 Yöntem
1. **Tohum (seed):** `seed = HMAC_SHA256(SERVER_SECRET, "<oyun_id>|<YYYY-MM-DD>")`. Tohum tahmin edilemez ve her gün/oyun için farklıdır. Tarih bazlı sabit `Random(202608)` gibi tohumlar **kullanılmaz**.
2. **Jeneratör:** Her oyun, tohumdan başlayan deterministik bir PRNG ile **sıfırdan** tahta üretir:
   - Queens: rastgele geçerli yerleşim → bölgeleri bu yerleşimin etrafında büyüt.
   - Tango: rastgele tam çözüm → ipuçlarını (`=`, `×`, hazır hücreler) çıkar.
   - Zip: rastgele Hamilton yolu → kontrol noktaları ve duvarlar yoldan türetilir.
   - Patches: ızgarayı rastgele dikdörtgenlere böl → her dikdörtgene bir sayı yerleştir.
   - Pinpoint / Crossclimb: büyük kelime ve ipucu havuzundan + kombinasyonlarla (kelime hazinesi sürekli büyür).
3. **Tek çözüm garantisi:** Üretilen tahta bir **çözücüden** geçer; birden fazla çözüm varsa reddedilip yeni tahta üretilir.
4. **Zorluk dalgası:** Zorluk (kolay→zor) takvime göre değişir, ancak tahta içeriği zorluğa bağlı sabit şablon değildir.
5. **Benzersizlik kontrolü:** Üretilen tahtanın **parmak izi** (`SHA-256(kanonik tahta)`) veritabanındaki `puzzle_fingerprints` tablosunda aranır. Çakışma varsa yeni üretim yapılır.
6. **Önceden üretim:** Cron her gece, ertesi **N gün** için bulmaca üretip Redis ve MySQL'e yazar (varsayılan 7 gün).

### 4.3 Mevcut Durum
Tüm 6 oyun (Queens, Tango, Zip, Patches, Pinpoint, Crossclimb) artık bu yönteme geçti: [`queens_generator.dart`](lib/games/queens/queens_generator.dart), [`tango_generator.dart`](lib/games/tango/tango_generator.dart), [`zip_generator.dart`](lib/games/zip_path/zip_generator.dart), [`patches_generator.dart`](lib/games/patches/patches_generator.dart), [`pinpoint_generator.dart`](lib/games/pinpoint/pinpoint_generator.dart) ve [`crossclimb_generator.dart`](lib/games/crossclimb/crossclimb_generator.dart) tohumdan tahta/seviye üretir veya seçer; tohum yardımcıları `core/puzzle/puzzle_seed.dart` içindedir. Zorluk takvimleri ve depolar da tohumludur (`*DifficultyScheduler`, `Local*PuzzleRepository`). Faz 1 böylece tüm oyunlarıyla tamamlanmıştır.



---

## 5. Mimari

### 5.1 İki aşamalı geliştirme

| Aşama | Bulmaca kaynağı | Sıralama / stats | Zaman |
|---|---|---|---|
| **A – Yerel (şimdi)** | Cihazdaki `Generator` (geliştirme tohumu ile) | `shared_preferences` | Cihaz saati (kısıtlı) |
| **B – VDS (sonra)** | Sunucudaki `Generator` → Redis/MySQL → API | Redis Sorted Set | Sunucu saati |

İstemci, bulmacayı bir **`PuzzleRepository`** arayüzü üzerinden alır:
```
abstract class PuzzleRepository {
  Future<Puzzle> getDaily(GameType game, DateTime utcDay);
}
```
- `LocalPuzzleRepository` → Aşama A (yerel jeneratör).
- `RemotePuzzleRepository` → Aşama B (REST API).

Arayüz sabit kaldığı için A'dan B'ye geçişte oyun ekranları değişmez.

### 5.2 Teknoloji yığını
- **İstemci:** Flutter, `flutter_riverpod`, `google_fonts`, `flutter_animate`, `shared_preferences`, `connectivity_plus`.
- **Sunucu (VDS):** Ubuntu, 2 çekirdek, 3 GB RAM, 30 GB SSD.
- **Servisler:** Nginx + PHP/Laravel REST API + MySQL + Redis.
- **Bildirim:** Firebase Cloud Messaging (HTTP v1), VDS cron ile tetiklenir.

### 5.3 Veri akışı (Aşama B)
```
Cron (gece) ─► Generator ─► tek-çözüm doğrulama ─► fingerprint kontrol
                                   │
                                   ▼
                         MySQL (kalıcı) + Redis (önbellek)
                                   ▲
Flutter ──► /api/v1/game/start ────┘   (yalnızca başlangıç tahtası)
Flutter ──► /api/v1/game/submit ──► sunucuda doğrulama + süre hesabı ──► Redis leaderboard
```

### 5.4 Temel veri tabloları (taslak)
- `puzzles(id, game_id, date, difficulty, board_json, solution_json, fingerprint)`
- `puzzle_fingerprints(fingerprint UNIQUE)`
- `users(id, name, device_id, fcm_token, created_at)`
- `results(id, user_id, game_id, date, duration_ms, moves, hints, flagged)`

`solution_json` yalnızca sunucuda tutulur ve istemciye hiçbir yanıtta dönmez.

---

## 6. Klasör Yapısı

```
lib/
├─ main.dart
├─ core/
│  ├─ theme/            # app_colors, app_text_styles, app_spacing, app_theme
│  │  └─ widgets/       # app_button, app_card
│  ├─ widgets/          # sketch_decorations, game_card_logos, genius_win_dialog ...
│  ├─ services/         # game_stats_service, (yeni) time_sync_service
│  ├─ network/          # network_checker, (yeni) api_client
│  └─ utils/            # date_utils
├─ features/
│  ├─ home/             # Oyunlar sekmesi + alt navigasyon
│  ├─ leaderboard/      # Sıralama
│  └─ profile/          # Profil
└─ games/
   ├─ common/           # base_game, neo_game_layout, PuzzleRepository arayüzü
   ├─ queens/           # models, logic, validator, generator, screen
   ├─ tango/
   ├─ zip_path/
   ├─ pinpoint/
   ├─ crossclimb/
   └─ patches/          # (yeni)
```
Her oyun klasörü: `*_models.dart`, `*_logic.dart`, `*_validator.dart`, `*_generator.dart`, `*_screen.dart`.

Sunucu ayrı bir depoda tutulacak (`zuhtu-backend`, Laravel).

---

## 7. Zaman Yönetimi (UTC ve Clock Drift)

1. **UTC pivot:** Günlük sıfırlama **UTC 00:00:00** bazlıdır.
2. **`TimeSyncService`:** İlk açılışta sunucudan `server_time_utc` alınır.
   `clockDrift = serverTimeUtc - (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000)`
3. `getTrustedServerTime()` = `DateTime.now().toUtc() + clockDrift`.
4. **Kalan süre:** `next_reset_utc - trustedNow` hesaplanır, gösterim için `.toLocal()` kullanılır.
5. Aşama A'da servis aynı arayüzle sahte (cihaz saati) olarak çalışır; Aşama B'de gerçek sunucu zamanı kullanılır.

---

## 8. Hile Koruması, Oturum ve Sıralama

### 8.1 Oturum (`/api/v1/game/start`, `/api/v1/game/submit`)
- Oyuna girerken istemci `session_token` (HMAC/JWT) alır. İçinde: `user_id`, `game_id`, `date`, `server_start_timestamp`.
- Sunucu yalnızca **başlangıç tahtasını** döner, çözümü asla göndermez.
- Bitişte istemci token, hamle listesi ve ipucu sayısını gönderir.
- **Süre sunucuda hesaplanır:** `elapsed = now_server - server_start_timestamp`.
- İnsan sınırının altındaki süreler `flagged` işaretlenir; hamle listesi sunucuda yeniden oynatılıp doğrulanır.

### 8.2 Redis Sıralaması
- Anahtar: `leaderboard:<oyun>:<YYYY-MM-DD>` (örn. `leaderboard:queens:2026-10-06`), tip **Sorted Set**.
- Komutlar: `ZADD`, `ZREVRANK`, `ZRANGE`.
- Skor: daha az süre ve daha az ipucu = daha yüksek skor.
- Tek API çağrısı: ilk 5 oyuncu (`ZRANGE 0 4`) + isteyen kullanıcının sırası (`ZREVRANK`).
- Haftalık/aylık/genel sıralamalar ayrı anahtarlarda toplanır. 3 GB RAM için eski günlük anahtarlara TTL verilir, kalıcı veri MySQL'dedir.

---

## 9. Bildirimler (FCM)
- Her gün sıfırlanmada VDS cron'u Laravel komutunu çalıştırır.
- FCM HTTP v1 üzerinden kayıtlı tüm cihazlara "Günün yeni bulmacaları hazır!" bildirimi gider.
- Büyük kitleler için token'lar gruplanarak (batch) gönderilir; geçersiz token'lar temizlenir.

---

## 10. Yol Haritası

Durum: ✅ bitti · 🟡 kısmen · ⬜ başlamadı

### Faz 0 – Dokümantasyon ve Temel
- ✅ README'nin proje dokümanına dönüştürülmesi
- 🟡 Tasarım uyum borcunun kapatılması (Bölüm 2.8): `GameType.color`, `NeoGameLayout`, `glass_card` ve "Dahi Profil" etiketi düzeltildi; kalanlar 2.8'de
- 🟡 "Zühtü" adının uygulamaya yansıtılması: başlık, Android etiketi ve web dosyaları tamam; ikon ve `pubspec`/paket adı kaldı

### Faz 1 – Oyun Motorları (yerel)
- ✅ Queens (Vezirler): Tohumlu `QueensGenerator` (tek çözüm garantisi, 3 yıl tekrarsızlık), `LocalQueensPuzzleRepository`, birim testleri, skeç defteri temasına uygun tahta (`QueensBoardPainter`), skeç ekran tasarımı (`QueensScreen`) ve skeç zafer diyaloğu (`GeniusWinDialog`) her şeyiyle tamamlandı.
- ✅ Tango (Güneş & Ay): Tohumlu `TangoGenerator` (deterministik, tek çözüm garantisi, insan mantığı ile tahminsiz çözülebilirlik), `TangoDifficultyScheduler`, `LocalTangoPuzzleRepository` ve birim testleri tamamlandı.
- ✅ Zip (Sayı Yolu): Modeller, duvar desteği (`walls`), tohumlu `ZipGenerator` (ortogonal yürüyüş, tek çözüm garantisi), `ZipDifficultyScheduler`, `LocalZipPuzzleRepository`, skeç ekranına duvar entegrasyonu ve birim testleri tamamlandı.
- ✅ Patches (Alan Bölme / Shikaku): Model, logic, tohumlu `PatchesGenerator` (rastgele dikdörtgen bölme, tek çözüm garantisi), `PatchesDifficultyScheduler`, `LocalPatchesPuzzleRepository`, skeç ekranı entegrasyonu ve birim testleri tamamlandı.
- ✅ Pinpoint (Kelime İzleri): Model, `PinpointLogic` (normalizasyon, alternatif cevaplar, puanlama formülü), tohumlu `PinpointGenerator`, `LocalPinpointPuzzleRepository` ve birim testleri tamamlandı.
- ✅ Crossclimb (Kelime Tırmanışı): Model, `CrossclimbLogic` (Hamming mesafesi = 1, zincir doğrulama, puanlama), tohumlu `CrossclimbGenerator`, `LocalCrossclimbPuzzleRepository` ve birim testleri tamamlandı.
- ✅ Her oyun için **tek çözüm / kural doğrulayıcısı** ve birim testleri (6 oyunun tamamı)
- ✅ `PuzzleRepository` arayüzü hazır (`core/puzzle/`); 6 oyunun tamamı için `Local*PuzzleRepository` bağlandı
- ✅ Sabit tohumlu seviye havuzları kaldırıldı ve tohumlu jeneratör mimarisine bağlandı (6 oyunun tamamı)



### Faz 2 – Zaman ve Oyun Akışı
- ✅ `TimeSyncService`: UTC pivot (00:00:00 UTC), clock drift önlemi, yerel simülasyon ve güvenilir zaman sağlayıcısı tamamlandı.
- ✅ Kalan süre sayacı UI'ı: `SketchCountdownTimer` (reaktif stream provider, fosforlu kara kalem defter stili) ve ana sayfa Hero kartı entegrasyonu tamamlandı.
- ✅ Günlük bir kez oynama kuralı: `DailyPlayService`, `DailyPlayNotifier`, SharedPreferences kalıcılığı, 6 oyun ekranında zafer anında kayıt, ana sayfada tamamlanan oyunlar için kilitli modal (`_showCompletedDialog`) ve yeşil `BİTTİ • [Skor]P` rozetleri tamamlandı.
- ✅ Birim testleri: `test/time_sync_test.dart` (7 test) ve `test/daily_play_test.dart` (5 test) ile doğrulandı (toplam 64/64 test geçiyor).

### Faz 3 – Backend (VDS)
- ⬜ Laravel iskeleti, MySQL şeması, Redis kurulumu
- ⬜ Jeneratörlerin sunucuya taşınması (PHP) veya ayrı üretim servisi
- ⬜ `/game/start`, `/game/submit`, `/time` endpoint'leri
- ⬜ Redis leaderboard
- ⬜ `RemotePuzzleRepository` ve istemci entegrasyonu

### Faz 4 – Bildirim ve Yayın
- ⬜ FCM entegrasyonu + cron
- ⬜ Google Play hazırlıkları (ikon, ekran görüntüleri, gizlilik politikası)

---

## 11. Geliştirme Kuralları (Definition of Done)

Bir iş şu şartlar sağlanınca biter:
1. **Tasarım:** Bölüm 2'ye uyar; sabit renk/font/gölge yok.
2. **Mantık UI'dan ayrıdır:** `models`, `logic`, `validator`, `generator` dosyalarında; ekran sadece görüntüler.
3. **Test:** Validator ve generator için birim testi vardır (yeni oyunlarda tek çözüm testi dahil).
4. **Eşsizlik:** Bulmaca şablon/sabit liste değil, jeneratörden gelir.
5. **Güvenlik:** İstemciye çözüm anahtarı gönderilmez.
6. **README güncel:** Yol haritası durumu ve ilgili bölüm güncellenir.