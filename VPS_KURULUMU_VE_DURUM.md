# 🚀 Daily Games (Zühtü) - Devir Teslim & VPS Geçiş Kılavuzu

> **🤖 EVDEKİ ANTIGRAVITY AI DİKKATİNE:**  
> Bu belge, kullanıcının ofis/laptop ortamından evdeki ana bilgisayarına geçtiğinde kaldığı yeri, kurulan backend mimarisini ve VPS entegrasyonu adımlarını **sıfır bağlam kaybıyla** devam ettirebilmeniz için hazırlanmıştır. Lütfen bu dosyayı dikkatlice oku ve kullanıcının kaldığı yerden kusursuz şekilde devam etmesini sağla.

---

## 📌 1. Projenin Genel Durumu ve Yapılanlar

1. **Flutter Mobil Uygulaması (`daily`):**
   - 6 oyunun tamamı (Vezirler, Pinpoint, Crossclimb, Tango, Zip Path, Patches) ve jeneratörleri aktif çalışıyor.
   - 10 kademeli Duolingo tarzı Haftalık Lig Sistemi ve Steam tarzı Rozet/Kemer vitrini hazır.
   - **83 testin tamamı (`flutter test`) ve `flutter analyze` 0 hata ile eksiksiz geçiyor.**
   - Dark Theme desteği skeç teması bozulmadan tüm ekranlarda mevcut.
   - `http` paketi eklendi; yerel veya uzak API ile haberleşen `ApiClient` (`lib/core/network/api_client.dart`) yazıldı.
   - Sıralama ekranında (`leaderboard_screen.dart`) canlı sunucu rozeti (`CANLI SUNUCU • ÇEVRİMİÇİ`) ve aşağı çekip yenileme (Pull-to-Refresh) mekanizması hazır.

2. **Backend API (`server/` klasörü - Laravel 11):**
   - Proje kök dizininde `server/` adında bağımsız bir Laravel 11 API projesi kuruldu.
   - **Veritabanı:** `database/database.sqlite` (Geliştirme için tak-çalıştır SQLite; VPS'te istenirse tek satırla MySQL yapılabilir).
   - **Modeller:** `Player` (Cihaz/oyuncu bilgisi, Sanctum token) ve `GameScore` (Skorlar, süre, hamle).
   - **Bot Havuzu:** `RealisticBotSeeder.php` ile 150 gerçekçi bot oyuncu ve geçmiş/günlük skorları veritabanına hazır yüklendi.
   - **Uç Noktalar (Endpoints):**
     * `POST /api/v1/auth/guest` -> Cihaz UUID ile anonim oturum ve API token üretir.
     * `GET  /api/v1/time` -> UTC sunucu zamanını döner (`TimeSyncService` saat hilelerini engeller).
     * `POST /api/v1/games/submit` -> Oyuncu oyun bitirince skoru ve süreyi kaydeder/günceller.
     * `GET  /api/v1/leaderboard` -> Canlı sıralamayı döner (Vezirler toplam puanı kuralı dahil).
   - `server/tests/Feature/ApiTest.php` testleri yazıldı ve 17 assertion ile başarıyla geçti.
   - Kolay başlatma için `server/start_server.bat` oluşturuldu.

---

## 🎯 2. Kullanıcının Hedefi ve Vizyonu

- Bu oyun bir web sitesi **değildir**; Google Play Store (Android) ve App Store (iOS) üzerinden indirilecek bir **mobil oyundur**.
- Kullanıcı ucuz bir VPS (Hetzner, DigitalOcean, Ubuntu sunucu vb.) alarak `server/` klasörünü oraya kuracak.
- Böylece:
  * Kullanıcının evdeki bilgisayarının açık kalmasına gerek kalmayacak.
  * Farklı şehirlerdeki/evlerdeki arkadaşları (collaborator'lar) APK'yı yükleyip aynı sabit VPS sunucusuna bağlanacak.
  * Herkes canlı olarak birbirinin skorlarını görebilecek ve yarışabilecek.

---

## 🛠️ 3. Evdeki Bilgisayarda İlk Yapılacaklar (Git & Başlangıç)

Evdeki ana bilgisayara geçtiğinizde:

1. **Git Güncellemesi:**
   ```bash
   git pull origin main
   ```
2. **Flutter Paketlerini Alın:**
   ```bash
   flutter pub get
   ```
3. **Backend Bağımlılıklarını Kurun:**
   ```bash
   cd server
   composer install
   php artisan migrate --seed
   ```
4. **Testleri Doğrulayın:**
   ```bash
   flutter test   # 83 testin tümü geçmeli
   php artisan test --filter=ApiTest  # 3 backend testi geçmeli
   ```

---

## 🌐 4. Canlı VPS Sunucu Durumu (AKTİF & ÇALIŞIYOR)

Sunucu başarıyla kiralandı, kuruldu ve API tüm dünyaya açıldı!

- **Sunucu IP:** `2.56.109.165`
- **Konum / Donanım:** TR4 Paketi (3 CORE Platinum, 4 GB RAM, 50 GB SSD - Ubuntu 24.04 LTS)
- **Web & Backend:** Nginx (Port 80) + PHP 8.4-FPM + SQLite
- **API Base URL:** `http://2.56.109.165/api/v1`
- **Sunucu Dizin Yolu:** `/var/www/daily/server`
- **Veritabanı Durumu:** Migrasyonlar tamamlandı; 150 gerçekçi bot oyuncu ve skorları yüklendi (`RealisticBotSeeder`).
- **Flutter İstemci:** [`lib/core/network/api_client.dart`](file:///c:/Users/Talha/Desktop/projeler/daily/lib/core/network/api_client.dart) içerisindeki varsayılan adres canlı VPS IP'sine güncellendi (`http://2.56.109.165/api/v1`).

### İleride Backend Güncellendiğinde VPS'i Güncelleme Komutu:
Bilgisayarınızdan GitHub'a kod push'ladıktan sonra VPS'e bağlanıp:
```bash
ssh root@2.56.109.165
cd /var/www/daily && git pull origin main
cd server && php artisan optimize:clear && php artisan config:cache && php artisan route:cache
```

---

## 📋 5. Sırada Bekleyen Diğer Geliştirme Maddeleri (`oyun_hatalari.md`)

VPS bağlandıktan sonra veya paralelinde devam edilecek açık konular:
1. **Sıralama Sayfası:** İnce el çizimi kart rötuşları (gerekirse).
2. **Ana Sayfa:** Not alınmış boş başlık (yeni kartlar, günlük özet vb.).
3. **Oyun İçi Mantık & Puanlama:** 6 oyunda mantıksız bulunan yerlerin kontrolü.
4. **Rozetler & Kemerler:** Başarıların sunucuyla senkronizasyonu.
