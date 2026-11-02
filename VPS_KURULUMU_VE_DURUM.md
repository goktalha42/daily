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

## 🌐 4. VPS Alındığında Kurulum Adımları (Adım Adım)

Kullanıcı ucuz bir VPS aldığında (Örn. Ubuntu 22.04 / 24.04):

### Adım 4.1: VPS Sunucusunu Hazırlama
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y php8.3-cli php8.3-fpm php8.3-sqlite3 php8.3-curl php8.3-xml php8.3-mbstring php8.3-zip composer nginx git
```

### Adım 4.2: Kodları VPS'e Yükleme
- GitHub reposunu VPS'e klonlayın veya `server/` klasörünü `/var/www/zuhtu-api` dizinine atın.
- İzinleri ayarlayın:
  ```bash
  sudo chown -R www-data:www-data /var/www/zuhtu-api/storage /var/www/zuhtu-api/database
  sudo chmod -R 775 /var/www/zuhtu-api/storage /var/www/zuhtu-api/database
  ```
- `.env` dosyasını oluşturun ve veritabanını kurun:
  ```bash
  composer install --no-dev --optimize-autoloader
  php artisan key:generate
  touch database/database.sqlite
  php artisan migrate --force --seed
  ```

### Adım 4.3: Hızlı Çalıştırma (Test Aşaması)
En basit test için Nginx ile uğraşmadan direkt:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
veya Nginx sanal host (VirtualHost) eklenip `systemd` ile kalıcı servis yapılabilir.

### Adım 4.4: Flutter'ı VPS Adresine Bağlama
Flutter projesindeki [`lib/core/network/api_client.dart`](file:///c:/Users/Talha/Desktop/projeler/daily/lib/core/network/api_client.dart) dosyasına gidin:
```dart
// Satır 24 civarı:
static const String _defaultLanUrl = 'http://VPS_IP_ADRESI:8000/api/v1';
// veya alan adı bağlandıysa:
// static const String _defaultLanUrl = 'https://api.oyununuz.com/api/v1';
```
Bu adresi yazdıktan sonra APK derleyip (`flutter build apk`) uzaktaki tüm arkadaşlarınıza gönderdiğinizde, herkes o VPS'e bağlanıp tek bir liderlik tablosunda yarışacaktır!

---

## 📋 5. Sırada Bekleyen Diğer Geliştirme Maddeleri (`oyun_hatalari.md`)

VPS bağlandıktan sonra veya paralelinde devam edilecek açık konular:
1. **Sıralama Sayfası:** İnce el çizimi kart rötuşları (gerekirse).
2. **Ana Sayfa:** Not alınmış boş başlık (yeni kartlar, günlük özet vb.).
3. **Oyun İçi Mantık & Puanlama:** 6 oyunda mantıksız bulunan yerlerin kontrolü.
4. **Rozetler & Kemerler:** Başarıların sunucuyla senkronizasyonu.
