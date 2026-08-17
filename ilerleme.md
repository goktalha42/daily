# Günlük Oyunlar (LinkedIn Stili) - Proje İlerleme ve Mimari Dokümanı

Bu doküman, LinkedIn Oyunları konseptine benzeyen **Günlük Zeka Oyunları** Flutter projesinin mimarisini, özelliklerini, teknik detaylarını ve aşamalı geliştirme planını içermektedir.

---

## 🎯 1. Proje Amacı ve Vizyonu

Kullanıcıların her gün girip 5 farklı zeka/bulmaca oyununu oynayabileceği, her gün gece yarısı yeni seviyelerin yayınlandığı, tüm oyuncuların performanslarına göre (süre, hamle sayısı vb.) sıralandığı, yüksek performanslı, cam efektli (Glassmorphic) ve üst düzey görsel estetiğe sahip modüler bir Flutter uygulaması geliştirmek.

---

## 📌 2. Temel Özellikler ve Kurallar

1. **İnternet Bağlantı Zorunluluğu (Online Only):**
   - Oyunlar **sadece internet bağlantısı aktifken** oynanabilir.
   - İnternet kesildiğinde veya çevrimdışıyken oyun duraklatılır ve `OnlineGuardWidget` uyarı ekranı gösterilir.
   - Hile yapılmasını engellemek için skorlar doğrudan sunucuya doğrulama ile gönderilir.

2. **İlk Aşamada 5 Farklı Günlük Oyun:**
   - **Vezirler (Queens):** Her satır, sütun ve renk bölgesine birbirine temas etmeyecek şekilde 1 vezir yerleştirme bulmacası.
   - **Kelime İzleri (Pinpoint / Wordle Stili):** Gizli anahtar kelimeleri ve kelime bağlantılarını tahmin etme.
   - **Kelime Tırmanışı (Crossclimb):** İpuçlarından yola çıkarak harf harf değiştirip hedef kelimeye ulaşma.
   - **Güneş & Ay (Tango / Binary Grid):** Izgaraya eşit sayıda Güneş ve Ay simgesi yerleştirme, 3 aynı simgenin yan yana gelmesini engelleme.
   - **Sayı Yolu (Zip / Path Link):** Sayıları sırasıyla yolları kesiştirmeden ızgara üzerinde birleştirme.

3. **Günlük Seviye ve Yenilenme Mantığı:**
   - Her gün (UTC 00:00 / Yerel gece yarısı) tüm oyunlar için **1 yeni seviye** aktifleşir.
   - Kullanıcılar günün seviyesini tamamladığında istatistikleri ve tamamlanma süreleri kaydedilir.

4. **Detaylı Sıralama ve Skor Tablosu (Leaderboard):**
   - **Oyun Bazlı Sıralama:** Her oyunun kendi özel sıralama listesi bulunur.
   - **Zaman Dilimleri:**
     - 📅 **Haftalık Sıralama**
     - 🗓️ **Aylık Sıralama**
     - 🏆 **Genel (Tüm Zamanlar) Sıralama**
   - **Sıralama Kriterleri:** En hızlı bitirme süresi, en az hamle/hata sayısı ve seri (streak) puanı.

5. **Genişletilebilir Modüler Oyun Mimarisi:**
   - İlerleyen süreçte kolayca 6., 7. oyunların eklenebilmesi için `BaseGame` ve `GameModule` soyutlamaları kullanılır.

---

## 🛠️ 3. Teknoloji Yığını ve Mimari

- **Framework:** Flutter (Dart) - Cross-platform (Android, iOS, Web, Desktop)
- **State Management:** `flutter_riverpod` (Modüler, test edilebilir ve güvenli durum yönetimi)
- **Network / Connectivity:** `connectivity_plus` (Bağlantı durumunu anlık izleme)
- **Tasarım & Animasyon:** `GlassCard` (Bulanık yarı saydam cam efekti), `flutter_animate`, Google Fonts (Outfit & Inter), Neons, Ambient Glow Blobs, Floating Glass Navigation Bar.

---

## 📁 4. Proje Dizin Yapısı (Modüler Mimari)

```text
lib/
├── core/
│   ├── network/            # İnternet bağlantı kontrolü ve network guard
│   ├── theme/              # Renk paletleri, tipografi, tema ayarları
│   ├── utils/              # Zaman hesaplama, tarih formatlama, yardımcılar
│   └── widgets/            # GlassCard, OnlineGuardWidget
├── features/
│   ├── home/               # Ana sayfa (Glassmorphism Hero Banner, Oyun kartları, Floating Nav Bar)
│   ├── leaderboard/        # Haftalık, Aylık, Genel sıralama ekranları (Podium UI)
│   └── profile/            # Kullanıcı profili, başarılar, istatistikler
├── games/                  # Oyun Modülleri (Her oyun bağımsız modüldür)
│   ├── common/             # BaseGame, GameResult, LeaderboardEntry modelleri
│   ├── queens/             # Vezirler Oyunu (Logic, Grid UI, Level Generator)
│   ├── pinpoint/           # Kelime İzleri Oyunu
│   ├── crossclimb/         # Kelime Tırmanışı Oyunu
│   ├── tango/              # Güneş & Ay Oyunu
│   └── zip_path/           # Sayı Yolu Oyunu
└── main.dart
```

---

## 📋 5. Geliştirme Yol Haritası ve İlerleme Durumu

### 🟢 Aşama 1: Proje Kurulumu ve Temel Mimari
- [x] `flutter create` ile projenin oluşturulması
- [x] Gerekli paketlerin eklenmesi (`flutter_riverpod`, `connectivity_plus`, `google_fonts`, `flutter_animate`, `uuid`, `intl` vb.)
- [x] Dizin yapısının kurulması
- [x] Temel tema (Dark Mode) ve renk sisteminin oluşturulması (`app_theme.dart`)

### 🟢 Aşama 2: Çevrimiçi Kontrolü (Online-Only Guard)
- [x] `NetworkChecker` servisi ile internet bağlantısının anlık izlenmesi
- [x] `OnlineGuardWidget` ile internet kesildiğinde oyunun kilitlenmesi ve uyarı verilmesi

### 🟢 Aşama 3: Oyun Modülü Altyapısı ve İlk 5 Oyun
- [x] `BaseGame`, `GameResult` ve `LeaderboardEntry` modellerinin yazılması
- [x] **Oyun 1: Vezirler (Queens):** Izgara, çakışma kontrolü ve kazanma dialogu
- [x] **Oyun 2: Kelime İzleri (Pinpoint):** Aşamalı ipucu açma ve kelime tahmin mekanizması
- [x] **Oyun 3: Kelime Tırmanışı (Crossclimb):** Merdiven kelime değişimi ve tırmanış mantığı
- [x] **Oyun 4: Güneş & Ay (Tango):** ☀️/🌙 ızgarası, 3 yan yana simge engeli ve doğrulama motoru
- [x] **Oyun 5: Sayı Yolu (Zip Path):** Kesişmeyen sayı takip yolu çizim motoru

### 🟢 Aşama 4: Günlük Seviye & Zaman Yönetimi
- [x] Tarih bazlı seviye üreticileri (`QueensLevelRepository`, `PinpointLevelRepository` vb.)
- [x] Gece yarısına kalan canlı geri sayım sayacı (`DateUtils`)

### 🟢 Aşama 5: Sıralama & Skor Sistemi (Leaderboard)
- [x] Her oyun için ayrı sıralama sekmesi (Queens, Pinpoint, Crossclimb, Tango, Zip)
- [x] **Haftalık**, **Aylık** ve **Genel** sıralama filtreleri
- [x] İlk 3 derece için Kürsü (Podium 🥇🥈🥉) görünümü

### 🟢 Aşama 6: Ultra-Modern UI/UX Cilalama ve Testler
- [x] `GlassCard` yarı saydam cam efekti ve ışıltılı kenarlıklar
- [x] Süzülen yuvarlatılmış yönlendirme çubuğu (Floating Glass Bottom Navigation Bar)
- [x] Ambient Glow arka plan ışımaları ve mikro-animasyonlar
- [x] Oyun mantık motorları için birim testleri (`test/game_logic_test.dart`)

---
*Son Güncelleme: 17 Ağustos 2026*
