### GÖREV: "Vezirler (Queens)" Oyun Motorunu ve UI'ını Sıfırdan LinkedIn Standartlarında Yeniden Yaz

Şu anki Vezirler oyunu rastgele tahtalar ürettiği için saf insan mantığıyla adım adım çözülemiyor (tahmin/deneme-yanılma gerektiriyor) ve UI olarak bölgeler birbirinden ayrışmıyor. Bu oyunu LinkedIn Queens kalitesinde, garantili tek çözümlü (Unique Solution) ve saf mantıksal çıkarımlarla çözülebilir hale getireceğiz.

---

### 1. Kurallar ve Çözülebilirlik Garantisi (Deductive Logic Engine)
- **Temel Kurallar:**
  - $N \times N$ ızgarada tam $N$ adet renk bölgesi vardır.
  - Her satırda tam 1 vezir, her sütunda tam 1 vezir ve her renk bölgesinde tam 1 vezir bulunmalıdır.
  - Hiçbir iki vezir yatay, dikey veya ÇAPRAZ olarak birbirine temas edemez (çapraz bitişik kareler yasaktır).
- **Mantık Doğrulama (Deduction Verifier):**
  - Üretilen her seviye, kullanıcının tahmin yapmasına gerek kalmadan sadece mantıksal elemelerle (satır/sütun/bölge sıkışması, 2x2 kuralı vb.) çözülebilir **TEK BİR ÇÖZÜME (Unique Solution)** sahip olmak ZORUNDADIR.
  - Seviye üretiminde Backtracking ve Constraint Satisfaction doğrulaması çalıştır: Eğer tahta saf mantık adımlarıyla tek yanıta indirgenemiyorsa tahta çöpe atılıp yenisi üretilsin.

---

### 2. 3 Farklı Zorluk Seviyesi
Kullanıcının seçebileceği veya günün mücadelesinde yer alacak 3 zorluk modu ekle:
1. **Kolay (Easy):** $6 \times 6$ ızgara, 6 bölge, daha açık ve net mantık blokları.
2. **Orta (Medium):** $8 \times 8$ ızgara, 8 bölge, dengeli kısıtlar.
3. **Zor (Hard):** $9 \times 9$ veya $10 \times 10$ ızgara, 9-10 bölge, iç içe geçmiş girintili bölgeler.

---

### 3. UI & UX Görsel Standartları (LinkedIn Birebir)
- **Kalın Bölge Sınırları (Thick Outer Borders):** Farklı renkteki komşu bölgelerin arasına belirgin, koyu/kontrastlı sınır çizgileri (`Border`) çizdir. Aynı renk hücrelerinin arasındaki iç çizgiler ise çok ince veya görünmez olsun.
- **Hücre İçi Görseller:**
  - Tek dokunuş: Hücre merkezine şık, minimalist bir `X` veya gri nokta (nokta işareti) koyarak o hücreyi eleme imkanı ver.
  - Çift dokunuş (veya bas-çek): Şık, modern siyah bir Taç/Vezir (`Crown`) ikonu yerleştir.
  - Vezir yerleştirildiğinde aynı satır, sütun ve komşu hücreleri otomatik olarak soluklaştır/işaretlemeyi kolaylaştır (opsiyonel toggle).
- **Hata Bildirimi:** Kural ihlali yapan (aynı satır/sütun/bölgede çakışan veya çapraz değen) vezirlerin arka planı hafif kırmızı parlasın.
- **Header & Mod Seçici:** Üst kısımda Kolay / Orta / Zor geçiş sekmeleri (Segmented Control), süre sayacı ve hamle sayısı yer alsın.

---

### 4. Kodlama Mimarisi
- `QueensGameController` (State & Seviye Üretici + Validator)
- `QueensBoardPainter` veya `QueensGridWidget` (Thick Border hesaplayıcı CustomPainter/Container mantığı)
- `QueensLevelGenerator` (Garantili tek çözümlü generator)

Lütfen bu mimariyi mevcut hatalı kodların yerine tam ve hatasız bir şekilde entegre et.