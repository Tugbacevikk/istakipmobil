# 📱 İş Takip Sistemi - Mobil Uygulama (Flutter)

Yapay zeka tabanlı fabrika İş Takip ve Saha İzleme Sistemi için geliştirilmiş Flutter mobil uygulaması. 
Bu uygulama; fabrikanın canlı kamera yayınlarını, çalışan devam/durum takibini, saha ihlal ve alarmlarını, patron/yönetici üyelik onaylarını ve PDF raporlama fonksiyonlarını mobil cihazlar üzerinden anlık takip etmeyi sağlar.

---

## 🚀 Öne Çıkan Özellikler

- **📊 Canlı Saha Dashboard'u**:
  - Aktif çalışan, duruştaki, kaynak yapan işçi metrikleri.
  - Canlı çalışan kameralar ve aktif okunmamış alarmlar özeti.
- **🎥 Canlı Kamera Yayını (Live Stream & Proxy Feed)**:
  - MJPEG / WebRTC kamera yayınları.
  - Sekme değişse de yayını koparmayan `AutomaticKeepAliveClientMixin` altyapısı.
  - Canlı yayın yeniden bağlama (reconnect retry) mekanizması.
- **📩 PDF Raporu & E-Posta Gönderimi**:
  - Filtrelere özel (Tarih, İstasyon, İşçi) hazırlanan PDF raporlarını sunucu üzerinden patron ve yönetici hesaplarına gönderme.
  - Web paneli ile birebir uyumlu 3 Sekmeli (`Herkese Gönder`, `Kişi Seç`, `Elle Yaz`) e-posta arayüzü.
- **👥 Üye & Patron Onay Yönetimi**:
  - Yeni kaydolan patron ve operatör hesaplarını onaylama veya reddetme.
  - Onay esnasında yetkili istasyon seçimi zorunluluğu.
- **🌙 Temalar & Sunucu IP Yapılandırması**:
  - Koyu (Dark) ve Aydınlık (Light) tema desteği.
  - Sunucu IP adresi ve Port numarasını uygulama içinden anlık değiştirebilme ve bağlantı testi.

---

## 🛠️ Kurulum ve Çalıştırma

### Gereksinimler
- **Flutter SDK**: 3.22+
- **Dart SDK**: 3.4+
- **Backend Sunucusu**: `Is_Takip_Sistemi` Flask backend (`http://localhost:5000` veya yerel ağ IP'si `http://192.168.x.x:5000`)

### Adımlar

1. **Bağımlılıkları Yükleyin**:
   ```bash
   flutter pub get
   ```

2. **Birim Testleri Çalıştırın**:
   ```bash
   flutter test
   ```

3. **Uygulamayı Çalıştırın**:
   - **Masaüstü / Web Sürümü (Hızlı Release Modunda)**:
     ```bash
     flutter build web --release
     python -m http.server 8080 --directory build/web
     ```
   - **Android / iOS Derlemesi**:
     ```bash
     flutter run
     ```

---

## 🔒 Üretim (Release) ve Ağ Güvenlik Yapılandırması

Uygulamanın Android 9+ ve iOS release derlemelerinde yerel HTTP sunucularına (`http://192.168.x.x:5000`) sorunsuz bağlanabilmesi için aşağıdaki izinler tanımlanmıştır:

- **Android (`AndroidManifest.xml`)**:
  - `android.permission.INTERNET` & `android.permission.ACCESS_NETWORK_STATE`
  - `android:usesCleartextTraffic="true"` (Yerel HTTP bağlantı izni)
- **iOS (`Info.plist`)**:
  - `NSAppTransportSecurity` / `NSAllowsArbitraryLoads = true`

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
