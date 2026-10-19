ALTIN KURAL:
highlighterYellow
highlighterGreen Bu iki rengi öleceğini bilsen bile hiç bir yerde hiç bir şekilde kullanma. Bu iki rengi de begenmedim hatta nefret 


Seri rozetleri: Her oyun için ayrı ayrı 3 günlük seri, 5 günlük seri, 10 günlük seri, 15 günlük seri, 30 günlük seri, 50 günlük seri, 75 günlük seri, 100 günlük seri, 150 günlük seri, 200 günlük seri, 250 günlük seri, 300 günlük seri, 365 günlük seri. bu rozetler olacak ve bunlar 1 kere kazandıktan sonra kişinin koleksiyonunda hep duracak.
Süreli rozetler: örnek olarak einstein rozeti, kişi 130 iq üzerinde oldugu sürece einstein rozeti olsun. 130 iq altına dustugu an o rozet kaybolsun. ve einstein rozeti kişinin profili üstünde sol köşede gözüksün, herkes de görebilsin.
bunun gibi süreli rozetlerimiz olsun.
aklına gelen başka rozet fikirlerine de açığım.
not: kaç çeşit rozetimi var ise bunları gruplar halinde rozetler.md adında bir dosyada tut ve hepsinin açıklaması olsun. Oradan bakıp kontrol edebileyim hepsini.


Uygulamada ve oyunlarda ve puanlama sisteminde mantıga aykırı olan her şeyi kontrol et. Mantıksız veya saçma duran her şeyi düzelt. ve bana da söyle. 

---

### 1-) Vezirler (Queens):
- **Düzeltilen Mantık Hatası:** 
  - Önceki puanlamada `_moveCount * 3` cezası vardı. Kullanıcı vezir koyup hücre eledikçe puanı düşüyor ve 11.2 saniyede çözmesine rağmen 828 puana gerileyip 16.9 saniyede çözen botun altına düşüyordu. Bu ceza `excessMoves = max(0, moveCount - expectedMoves)` haline getirilerek kaldırıldı; 11.2 sn'de bitiren 876 puanla hak ettiği **#1 Zirveye** oturdu.
  - Master seviye (9x9, 18 vezir) seviyeleri tahmin gerektirmeden insan aklıyla %100 çıkarımsal çözülebilir (`deductive.isSolvable`) kılındı.
  - 4 katmanlı Türkçe eğitici ipucu motoru eklendi (Çift temas kuralı, kilitli adaylar, imkânsız eşleşmeler ve çelişki tespiti).

---

### 2-) Kelime İzleri (Pinpoint):
- **Düzeltilen UX / Tasarım:**
  - Hedef kelimenin harf kutucukları (`SketchCard`) birbirine yapışık duruyordu; aralarına ferah `horizontal: 3` padding eklenerek her harf bağımsız bir skeç kartı haline getirildi.
  - Türkçe karakter normalizasyonu (`İ/I`, `Ş/ş`, vb.) ve alternatif kabul edilen cevaplar denetlendi.
  - Skor: Her ekstra ipucu için 250 P, her yanlış tahmin için 100 P, geçen her saniye için 5 P adil ceza uygulanıyor.

---

### 3-) Kelime Tırmanışı (Crossclimb):
- **Düzeltilen Mantık Hatası:**
  - Oyuncu yanlış harf girdiğinde `_wrongAttempts` sayacı artırılmıyordu ve `calculateScore`'a gönderilmiyordu! Bu sebeple 10 defa rastgele deneyen biri ile tek denemede bilen oyuncu aynı puanı alıyordu.
  - `_wrongAttempts` sayacı duruma ve oturum kaydına eklendi. Her hatalı harf denemesi adil olarak -50 puan düşürülüyor.
  - Basamaklar arası otomatik odaklanma ve klavye akışı optimize edildi.

---

### 4-) Güneş ve Ay (Tango):
- **Düzeltilen Gecikme & Tepkisellik:**
  - 3 aynı sembol yan yana geldiğinde veya kural ihlali olduğunda hata uyarısı tam 1 saniye (`Duration(seconds: 1)`) sonra gösteriliyordu; bu da oyunu hantal hissettiriyordu.
  - Gecikme 250ms seviyesine çekilerek anlık, organik ve tepkisel hale getirildi.
  - Hamle cezası `math.max(0, moveCount - expectedMoves)` olarak adilleştirildi.

---

### 5-) Sayı Yolu (Zip Path):
- **Oyun Mekaniği & Akış:**
  - Parmak geriye sürüklendiğinde yolun otomatik olarak o noktaya kadar geri sarılması (auto-rewind) ve çit/duvar üzerinden geçişlerin engellenmesi kontrol edildi.
  - Puanlama yalnızca geçen süreye bağlı (2000 taban, her saniye için -10 puan).

---

### 6-) Alan Bölme (Patches):
- **Düzeltilen Mantık Hatası:**
  - `PatchesScreen`'de skor hesaplanırken `_userRects.length * 5` puan zorunlu olarak düşülüyordu. 8 ipuculu bir tahtada oyunu sıfır hata ile kusursuz bitiren bir oyuncudan bile sırf tahtayı tamamladı diye 8 * 5 = 40 puan haksızca kesiliyordu!
  - `_moveCount` takibi eklendi. Ceza yalnızca gerekenden fazla yapılan hamlelere (`excessMoves = math.max(0, _moveCount - clues.length)`) uygulanacak şekilde düzeltildi.
  - Sürükleme anında parmağın yanında beliren `Genişlik × Yükseklik = Alan` rozeti ve alan doğru olduğunda yeşil skeç geri bildirimi kontrol edildi.

---

### 🚀 Sıradaki Geliştirme Önerileri ve Fikirler:
1. **Oyun İçi Hızlı Geri Bildirim Toast/Banner:** Yanlış hamle yapıldığında ekran titremesine ek olarak defterin alt köşesinde el yazısıyla tatlı bir uyarı balonu (ör. "Bu vezir diğerini tehdit ediyor!").
2. **Kişisel Günlük Rekor Bildirimi:** Oyuncu kendi kişisel en iyi derecesini geliştirdiğinde veya günün liderlik tablosunda ilk 3'e yükseldiğinde konfeti eşliğinde "Yeni Zirve!" kutlaması.
3. **Günlük Zeka Defteri Özeti (Günün 6/6 Tamamlanışı):** 6 oyunun tamamı bittiğinde oyuncuya günün tüm istatistiklerini, toplam IQ değişimini ve kazanılan rozetleri tek bir skeç sertifikası olarak sunma.