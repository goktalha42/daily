# 🏆 Günlük Zeka Oyunları - Kapsamlı Rozet Kataloğu (`rozetler.md`)

Bu doküman, uygulamada yer alan tüm rozetlerin, süreli şampiyonluk kemerlerinin ve seri unvanlarının tam listesini, kazanılma ve kaybedilme koşullarını içermektedir.

---

## 📌 Rozet Kategorileri Özeti

| Kategori | Tür | Toplam Rozet Sayısı | Açıklama |
| :--- | :--- | :---: | :--- |
| **👑 Süreli Rozetler & Şampiyonluk Kemerleri** | Süreli / Dinamik | **10** | Şart sağlandığı sürece taşınır; şart bozulduğunda veya süre bittiğinde otomatik düşer. |
| **🔥 Seri Rozetleri (Oyun Bazlı & Genel)** | Kalıcı Koleksiyon | **91** | 6 oyun + Genel seri x 13 aşama. 1 kere kazanılınca ömür boyu kalır. |
| **🎮 Oyun Ustalığı Rozetleri** | Kalıcı Koleksiyon | **6** | Her oyun için özel ustalık ve galibiyet unvanları. |
| **🧠 Zekâ & Özel Başarı Rozetleri** | Kalıcı Koleksiyon | **6** | IQ kilometre taşları, hız rekorları ve maraton başarıları. |
| **TOPLAM** | - | **113 Rozet** | - |

---

## 👑 1. Süreli Rozetler & Şampiyonluk Kemerleri (Dinamik / Süreli)

Bu rozetler oyuncunun **aktif performansına** bağlıdır. Koşul bozulduğunda ya da süresi dolduğunda kaybedilir.

| Rozet ID | Rozet Adı | Simge | Geçerlilik Süresi | Kazanılma Koşulu | Düşme / Kaybedilme Koşulu | Özel Gösterim |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `belt_einstein` | **Einstein Zekâ Rozeti** | 🧠 | **Koşula Bağlı Dinamik** | Genel Zekâ Endeksinde **130+ IQ** seviyesine ulaşmak. | Zekâ endeksi **130 IQ altına düştüğü an** anında silinir. | **Profil kartının sol üst köşesinde parıldayan prestij rozeti olarak herkesçe görülür.** |
| `belt_grandmaster` | **Büyük Usta Rozeti** | 💡 | **Koşula Bağlı Dinamik** | Genel Zekâ Endeksinde **120+ IQ** seviyesine ulaşmak. | Zekâ endeksi **120 IQ altına düştüğü an** silinir. | Profilde statü göstergesi. |
| `belt_daily_champion` | **Zirve Hükümdarı Kemeri** | 👑 | **1 Gün** | Herhangi bir oyunun günün liderlik tablosunda **#1 sıraya** yerleşmek. | Gece yarısı gün yenilendiğinde tekrar kazanılmalıdır. | Altın şampiyonluk kemeri vitrini. |
| `belt_weekly_podium` | **Podyum Lideri Kemeri** | 🏆 | **7 Gün** | Liderlik tablosunda **ilk 3 dereceye (Kürsü)** girmek. | 7 gün boyunca ilk 3'e tekrar girilmezse düşer. | Podyum madalyası vitrini. |
| `belt_lightning` | **Günün Şimşeği Kemeri** | ⚡ | **3 Gün** | Herhangi bir bulmacayı **35 saniyenin altında** ışık hızında çözmek. | 3 gün içinde tekrar 35 sn altı skor alınmazsa düşer. | Neon şimşek etiketi. |
| `belt_queens_master` | **Vezirler Şampiyonluk Kemeri** | ♟️ | **7 Gün** | Vezirler oyununda **Master (9x9, 2 Vezir)** seviyesini çözmek. | 7 gün içinde Master seviye tekrar çözülmezse düşer. | Vezirler tacı kemeri. |
| `belt_night_owl` | **Gece Baykuşu Rozeti** | 🦉 | **1 Gün** | Gece yarısı **00:00 - 04:00** saatleri arasında günün yeni bulmacasını çözmek. | 24 saat sonra düşer. | Gece modu baykuş amblemi. |
| `belt_early_bird` | **Erken Kalkan Deha** | 🌅 | **1 Gün** | Sabah **05:00 - 08:30** saatleri arasında zihin antrenmanını tamamlamak. | 24 saat sonra düşer. | Şafak güneşi amblemi. |
| `belt_clean_sweep` | **Günün 6'da 6 Fatihi** | 🎖️ | **1 Gün** | Aynı gün içinde 6 oyunun tamamını (**6/6**) eksiksiz çözmek. | Gün bitiminde süresi dolar. | Altın çelenk kemeri. |
| `belt_flawless` | **Kusursuz Sezon Kemeri** | 🎯 | **3 Gün** | Herhangi bir oyunu sıfır hata veya geri alma ile bitirmek. | 3 gün sonra düşer. | Hedef tahtası rozeti. |

---

## 🔥 2. Seri Rozetleri (Kalıcı Koleksiyon - 91 Adet)

Oyuncuların her gün aralıksız oynama disiplinini ödüllendirir. **1 kez kazanıldıktan sonra oyuncunun koleksiyonunda ömür boyu kalır.**

Tüm oyunlar için geçerli olan **13 Seri Eşiği**:
`3`, `5`, `10`, `15`, `30`, `50`, `75`, `100`, `150`, `200`, `250`, `300`, `365 (1 Yıl!)` Gün

### A) Oyun Bazlı Seri Rozetleri (6 Oyun x 13 Seviye = 78 Rozet)

#### 1. Vezirler (Queens) Serisi
- `streak_queens_3`: Vezirler: 3 Günlük Başlangıç Serisi (🔥)
- `streak_queens_5`: Vezirler: 5 Günlük Seri (🔥)
- `streak_queens_10`: Vezirler: 10 Günlük Seri (🔥)
- `streak_queens_15`: Vezirler: Odak Ustası Serisi (15 Gün) (🎯)
- `streak_queens_30`: Vezirler: Aylık İstikrar Serisi (30 Gün) (🌟)
- `streak_queens_50`: Vezirler: Demir İrade Serisi (50 Gün) (⚡)
- `streak_queens_75`: Vezirler: 75 Günlük Seri (⚡)
- `streak_queens_100`: Vezirler: Yüzyıl Kulübü Serisi (100 Gün) (🎖️)
- `streak_queens_150`: Vezirler: Yarım Yıl Zihin Serisi (150 Gün) (💎)
- `streak_queens_200`: Vezirler: 200 Günlük Seri (💎)
- `streak_queens_250`: Vezirler: Büyük Üstat Serisi (250 Gün) (🏆)
- `streak_queens_300`: Vezirler: 300 Günlük Seri (🏆)
- `streak_queens_365`: Vezirler: Efsanevi Yıllık Seri (1 Yıl!) (👑)

#### 2. Kelime İzleri (Pinpoint) Serisi
- `streak_pinpoint_3` ... `streak_pinpoint_365` (13 Seviye)

#### 3. Kelime Tırmanışı (Crossclimb) Serisi
- `streak_crossclimb_3` ... `streak_crossclimb_365` (13 Seviye)

#### 4. Güneş & Ay (Tango) Serisi
- `streak_tango_3` ... `streak_tango_365` (13 Seviye)

#### 5. Sayı Yolu (Zip Path) Serisi
- `streak_zip_path_3` ... `streak_zip_path_365` (13 Seviye)

#### 6. Alan Bölme (Patches) Serisi
- `streak_patches_3` ... `streak_patches_365` (13 Seviye)

---

### B) Genel Zihin Serisi (Günde En Az 1 Oyun - 13 Rozet)
Her gün uygulamaya girip herhangi bir oyunu tamamlayanların kazandığı genel seri rozetleri:
- `streak_all_3` - 3 Günlük Genel Seri (🔥)
- `streak_all_5` - 5 Günlük Genel Seri (🔥)
- `streak_all_10` - 10 Günlük Genel Seri (🔥)
- `streak_all_15` - 15 Günlük Genel Odak Serisi (🎯)
- `streak_all_30` - 30 Günlük Aylık Disiplin Serisi (🌟)
- `streak_all_50` - 50 Günlük Demir Zihin Serisi (⚡)
- `streak_all_75` - 75 Günlük Genel Seri (⚡)
- `streak_all_100` - 100 Günlük Zeka Maratonu (🎖️)
- `streak_all_150` - 150 Günlük İstikrar Abidesi (💎)
- `streak_all_200` - 200 Günlük Bilge Serisi (💎)
- `streak_all_250` - 250 Günlük Üstat Serisi (🏆)
- `streak_all_300` - 300 Günlük Efsane Serisi (🏆)
- `streak_all_365` - 365 Gün: 1 Tam Yıl Kesintisiz Zeka Serisi (👑)

---

## 🎮 3. Oyun Ustalığı Rozetleri (Kalıcı Koleksiyon - 6 Adet)

Her oyunda en az **3 galibiyet** alan oyuncuların kazandığı kalıcı rozetler:

| Rozet ID | Rozet Adı | Simge | İlgili Oyun | Kazanılma Koşulu |
| :--- | :--- | :---: | :--- | :--- |
| `badge_queens_mastery` | **Vezirler Ustası** | ♟️ | Vezirler | Vezirler oyununda 3 galibiyet elde et. |
| `badge_pinpoint_mastery` | **Kelime Dedektifi** | 🔍 | Kelime İzleri | Kelime İzleri oyununda 3 galibiyet elde et. |
| `badge_crossclimb_mastery` | **Zirve Tırmanıcısı** | 🧗 | Kelime Tırmanışı | Kelime Tırmanışı oyununda 3 galibiyet elde et. |
| `badge_tango_mastery` | **Güneş & Ay Dengesi** | ☀️ | Güneş & Ay | Güneş & Ay oyununda 3 galibiyet elde et. |
| `badge_zip_mastery` | **Sayıların Efendisi** | 🔢 | Sayı Yolu | Sayı Yolu oyununda 3 galibiyet elde et. |
| `badge_patches_mastery` | **Geometri Mimarı** | 📐 | Alan Bölme | Alan Bölme oyununda 3 galibiyet elde et. |

---

## 🧠 4. Zekâ & Özel Başarı Rozetleri (Kalıcı Koleksiyon - 6 Adet)

| Rozet ID | Rozet Adı | Simge | Kategori | Kazanılma Koşulu |
| :--- | :--- | :---: | :--- | :--- |
| `badge_first_win` | **İlk Adım** | 🎓 | Genel | Herhangi bir oyunda ilk galibiyetini al. |
| `badge_genius_club` | **Dahi Kulübü (120+ IQ)** | 💡 | Zekâ | Genel zekâ endeksinde 120 IQ seviyesini gör. |
| `badge_all_rounder` | **Çok Yönlü Deha** | 🌟 | Genel | 6 farklı oyunun hepsinde en az 1 galibiyet kazan. |
| `badge_speed_demon` | **Işık Hızı Efendisi** | 🚀 | Hız | Herhangi bir oyunu 20 saniyenin altında bitir. |
| `badge_century_club` | **100'ler Kulübü** | 💯 | İstikrar | Toplam 100 oyun tamamlama kilometre taşına ulaş. |
| `badge_perfectionist` | **Mükemmeliyetçi** | ✨ | Kusursuzluk | 3 farklı oyunu tek bir hata yapmadan bitir. |

---

## 💡 Rozet Yönetim ve Doğrulama Kuralları
1. **Einstein Rozeti Dinamikliği:** IQ puanı her oyun sonucuna göre yeniden ağırlıklandırılır. Oyuncunun genel zekâ endeksi 130 veya üzerine çıktığında rozet aktive olur ve profilde sol üstte yer alır; 130'un altına gerilediğinde rozet otomatik olarak düşer.
2. **Seri Güvenliği:** Bir gün oyun oynanmadığında aktif seri bozulur ancak o güne kadar kazanılmış olan **tüm seri rozetleri oyuncunun koleksiyonunda kalıcı olarak kalır.**
3. **Kemer Yenileme:** Süreli kemerler süreleri dolmadan önce aynı başarı tekrarlandığında süreleri (örn. 7 gün) baştan sıfırlanarak yenilenir.
