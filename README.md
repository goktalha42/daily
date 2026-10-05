Sen kıdemli bir Full-Stack Mobil Yazılım Mimarı ve Oyun Motoru Geliştiricisisin.

Flutter ile geliştirdiğim, günlük tek seviyeli (daily single-puzzle), hile korumalı, küresel saat senkronizasyonlu ve LinkedIn tarzı mini mantık oyunlarını içeren projem için hem istemci (Flutter) hem de sunucu (Backend) mimarisini kuracaksın.

### ALTYAPI VE TEKNOLOJİ YIĞINI
- **Mobil İstemci:** Flutter (Android / Google Play odaklı)
- **Sunucu Donanımı:** Bağımsız VDS (Ubuntu Linux, 2 Core CPU, 3 GB RAM, 30 GB SSD)
- **Backend Servisleri:** Nginx + PHP/Laravel REST API + MySQL + Redis
- **Bildirimler:** Firebase Cloud Messaging (FCM) entegrasyonu (VDS üzerindeki Cron Job ile tetiklenecek)

---

### GÖREV 1: VDS BACKEND VE HİLE KORUMASI MİMARİSİ (SESSION & LEADERBOARD)

1. **Oturum ve Token Yönetimi (`/api/v1/game/start` & `/api/v1/game/submit`):**
   - İstemci oyuna girerken sunucudan bir `session_token` (HMAC/JWT tabanlı) alır. Token içinde `user_id`, `game_id`, `date` ve sunucunun o anki UTC timestamp'i (`server_start_timestamp`) saklanır.
   - Sunucu istemciye yalnızca oyun tahtasının başlangıç durumunu döner; **asla çözüm anahtarını istemciye göndermez**.
   - Oyun bittiğinde istemci token'ı, yapılan hamle listesini ve ipucu sayısını gönderir.
   - **Doğrulama:** Süre istemcinin beyanına göre değil, `elapsed_time = current_server_timestamp - server_start_timestamp` formülüyle sunucuda hesaplanır. İnsan sınırının altındaki süreler otomatik şüpheli (flagged) işaretlenir.

2. **Redis Tabanlı Yüksek Performanslı Leaderboard:**
   - 3 GB RAM'li VDS'i yormamak için sıralamalar doğrudan MySQL'den değil, **Redis Sorted Sets (ZADD, ZREVRANK, ZRANGE)** üzerinden yönetilecektir.
   - Her oyun ve gün için bir anahtar tutulur (Örn: `leaderboard:queens:2026-10-06`).
   - Skorlama kuralı: En az süre + en az ipucu en yüksek skoru alır.
   - API tek bir çağrıda hem ilk 5 oyuncuyu (`ZRANGE 0 4`) hem de istek atan kullanıcının kendi sırasını (`ZREVRANK`) anlık getirecek şekilde tasarlanmalıdır.

3. **Gece Bildirimi (FCM Cron Trigger):**
   - VDS üzerinde her gün sıfırlanma saatinde (veya belirlenen saatte) çalışacak bir cron komutu için FCM HTTP v1 üzerinden tüm kayıtlı cihaz token'larına "Günün yeni bulmacaları hazır!" bildirimi basan PHP/Laravel servis yapısını hazırla.

---

### GÖREV 2: FLUTTER SAAT DİLİMİ VE GÜN SIFIRLAMA YÖNETİMİ (TIMEZONE & CLOCK DRIFT)

Kullanıcının cihaz saatini ileri/geri alarak sistemi aldatmasını engellemek için:
1. **UTC Pivot:** Tüm oyun seviyeleri ve günlük sıfırlama **UTC 00:00:00** bazlı çalışır.
2. **Clock Drift Servisi (`TimeSyncService`):**
   - Flutter ilk açılışta sunucudan `server_time_utc` değerini alır:
     `clockDrift = serverTimeUtc - (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000)`
   - Cihaz saati değiştirilse dahi uygulama içindeki güvenilir zaman `getTrustedServerTime()` fonksiyonu üzerinden (`DateTime.now().toUtc() + clockDrift`) hesaplanır.
3. **Kalan Süre Sayacı:** Bir sonraki seviyeye kalan süre `next_reset_utc - currentTrustedTime` farkı ile hesaplanır ve UI'da yerel saate (`.toLocal()`) çevrilerek gösterilir.

---

### GÖREV 3: BEŞ TEMEL MİNİ OYUNUN MOTOR VE KURAL SETİ (GAME ENGINES)

Aşağıdaki 5 oyunun her biri için veri modellerini (`BoardState`), durum yönetimini (`State`) ve kesin hamle/çözüm doğrulama mantığını (`Validator`) hatasız oluştur:

1. **Queens (Vezirler):**
   - $N \times N$ ızgara ve $N$ farklı renk bölgesi.
   - Her satırda, her sütunda ve her renk bölgesinde tam olarak 1 vezir bulunmalıdır.
   - İki vezir yatay, dikey veya çapraz komşu olamaz (çevrelerindeki 8 kare boş olmalıdır).

2. **Tango (İkili Denge):**
   - Çift sayılı kare ızgara (ör. $6 \times 6$). Hücreler Güneş (`S`) veya Ay (`M`) alır.
   - Her satır/sütunda eşit sayıda Güneş ve Ay olmalıdır.
   - Yan yana veya alt alta 3 aynı sembol (`SSS` veya `MMM`) gelemez.
   - Hücreler arası `=` (aynı sembol) ve `×` (farklı sembol) kenar kurallarına uyulmalıdır.

3. **Zip (Hamiltonian Yolu):**
   - $N \times M$ ızgara, sıralı kontrol noktaları (1, 2, ... $K$) ve engel duvarları.
   - 1'den başlayıp sırasıyla tüm kontrol noktaları tek bir çizgiyle bağlanmalıdır.
   - Yalnızca ortogonal (yukarı/aşağı/sağ/sol) hareket edilebilir.
   - Çizgi tahtadaki **tüm erişilebilir boş karelerin üzerinden tam olarak bir kez** geçmelidir.

4. **Patches (Alan Bölme / Shikaku):**
   - Izgara üzerinde alan sayı