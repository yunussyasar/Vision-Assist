# VisionAssist 👁️

Görme engelli kullanıcılar için **gerçek zamanlı nesne tespiti** ve **sesli konumsal geri bildirim** sağlayan iOS erişilebilirlik uygulaması.

![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Lisans](https://img.shields.io/badge/Lisans-MIT-green)

## 📱 Genel Bakış

VisionAssist, görme engelli kullanıcıların çevrelerindeki nesneleri kamera aracılığıyla tespit ederek sesli geri bildirim sağlar. Kullanıcılar sesli komutlarla belirli nesneleri arayabilir ve uygulama nesnenin konumunu ve mesafesini doğal konuşma ile duyurur.

### Demo

| Özellik | Açıklama |
|---------|----------|
| 🎤 Sesli Arama | "Telefonumu bul" veya "Bilgisayar nerede" deyin |
| 🔊 Sesli Geri Bildirim | "Bilgisayar bulundu. Solunuzda, yakında" |
| 📳 Titreşim Geri Bildirimi | Hedef nesne tespit edildiğinde titreşim |
| 👁️ Gerçek Zamanlı Tespit | Kamera görüntüsünden sürekli nesne tanıma |

## ✨ Özellikler

- **Gerçek Zamanlı Nesne Tespiti** - Apple Vision Framework kullanarak sürekli nesne tanıma
- **Sesli Komutlar** - Eller serbest nesne arama için doğal dil desteği
- **Konumsal Ses Geri Bildirimi** - Nesne konumu (sol/sağ/merkez) ve mesafe duyurusu
- **Dokunsal Geri Bildirim** - Nesne bulunduğunda titreşim bildirimi
- **Erişilebilir Arayüz** - Tam VoiceOver desteği
- **Tespit Yumuşatma** - Akıllı kare işleme ile UI titremesini önleme

## 🛠️ Teknolojiler

| Teknoloji | Kullanım Amacı |
|-----------|----------------|
| **Swift & SwiftUI** | UI ve uygulama mantığı |
| **Apple Vision Framework** | Nesne sınıflandırma (VNClassifyImageRequest) |
| **AVFoundation** | Kamera yakalama ve ses oturumu yönetimi |
| **Speech Framework** | Sesli komut tanıma (SFSpeechRecognizer) |
| **AVSpeechSynthesizer** | Sesli geri bildirim için metin-konuşma dönüşümü |
| **CoreML** | Makine öğrenimi modeli entegrasyonuna hazır |

## 📋 Gereksinimler

- iOS 15.0+
- Xcode 14.0+
- Fiziksel iOS cihazı (kamera gerekli)

## 🚀 Kurulum

1. **Depoyu klonlayın**
   ```bash
   git clone https://github.com/yunussyasar/VisionAssist.git
   cd VisionAssist
   ```

2. **Xcode'da açın**
   ```bash
   open VisionAssist.xcodeproj
   ```

3. **İmzalamayı yapılandırın**
   - Xcode'da projeyi seçin
   - "Signing & Capabilities" bölümüne gidin
   - Geliştirme takımınızı seçin

4. **Derleyin ve çalıştırın**
   - iOS cihazınızı bağlayın
   - Cihazınızı hedef olarak seçin
   - `Cmd + R` ile derleyip çalıştırın

## 📖 Kullanım

### Temel Kullanım

1. **Uygulamayı başlatın** - İstendiğinde kamera ve mikrofon izinlerini verin
2. **Tespitleri görüntüleyin** - Nesneler otomatik olarak tespit edilir ve ekranda gösterilir
3. **Nesne arayın** - Mikrofon butonuna dokunun ve söyleyin:
   - "Find [nesne adı]" (örn: "Find my keys")
   - "Where is [nesne]" (örn: "Where is the laptop")
   - "Look for [nesne]" (örn: "Look for a chair")

### Sesli Komutlar

| Komut | Örnek |
|-------|-------|
| Find | "Find my phone" |
| Search | "Search for a bottle" |
| Look for | "Look for the remote" |
| Where is | "Where is my wallet" |
| Locate | "Locate the door" |
| Clear | "Clear" veya "Cancel" aramayı durdurmak için |

### Sesli Geri Bildirim Örnekleri

- **Nesne bulundu:** *"Found Phone. It is on your left, nearby. 85 percent confident."*
- **Nesne kayboldu:** *"Phone is no longer visible. Move your camera around to find it."*
- **Konum güncellemesi:** *"Phone is now on your right"*

## 🏗️ Mimari

```
VisionAssist/
├── VisionAssistApp.swift      # Uygulama giriş noktası
├── ContentView.swift          # Kamera önizlemeli ana UI
├── ObjectDetector.swift       # Vision framework entegrasyonu
├── CameraManager.swift        # AVFoundation kamera yönetimi
├── CameraPreview.swift        # SwiftUI kamera görünümü
├── VoiceCommandManager.swift  # Konuşma tanıma
├── AudioFeedbackManager.swift # Metin-konuşma çevirisi
├── HapticFeedbackManager.swift# Dokunsal bildirimler
└── Info.plist                 # Uygulama izinleri
```

### Ana Bileşenler

#### ObjectDetector
Apple Vision framework kullanarak gerçek zamanlı nesne tespiti yapar:
- Performans için kare atlama (her 3 kareden birini işler)
- Tespit geçmişi yumuşatma (5 kare üzerinde %60 tutarlılık gerektirir)
- Durum yönetimi ile otomatik hedef takibi

#### VoiceCommandManager
Eller serbest kullanım için konuşma tanımayı yönetir:
- Birden fazla tetikleyici ifadeyi destekler
- Doğal dilden nesne adlarını çıkarır
- Kayıt ve oynatma arasında ses oturumu geçişini yönetir

#### AudioFeedbackManager
AVSpeechSynthesizer kullanarak sesli geri bildirim sağlar:
- Detaylı konum duyuruları (sol/sağ, üst/alt, mesafe)
- Tekrarlamayı önlemek için geciktirilmiş duyurular
- Zorla hoparlör çıkışı yönlendirmesi

## 🔒 Gizlilik ve İzinler

Uygulama aşağıdaki izinleri gerektirir (Info.plist'te yapılandırılmış):

| İzin | Sebep |
|------|-------|
| Kamera | Canlı kamera görüntüsünden nesne tespiti |
| Mikrofon | Sesli komut tanıma |
| Konuşma Tanıma | Komutlar için konuşmayı metne çevirme |

## 🎯 Gelecek İyileştirmeler

- [ ] Daha iyi nesne tespiti için özel YOLO modeli entegrasyonu
- [ ] Cihaz üzerinde ML modelleri ile çevrimdışı mod
- [ ] Derinlik sensörü kullanarak nesne mesafesi tahmini
- [ ] Çoklu dil desteği (Türkçe, Almanca vb.)
- [ ] Hızlı arama için kayıtlı nesne önayarları
- [ ] Nesne konumlarını gösteren AR katmanı

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen Pull Request göndermekten çekinmeyin.

1. Depoyu fork'layın
2. Feature branch'inizi oluşturun (`git checkout -b feature/HarikaOzellik`)
3. Değişikliklerinizi commit'leyin (`git commit -m 'Harika bir özellik eklendi'`)
4. Branch'e push'layın (`git push origin feature/HarikaOzellik`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👨‍💻 Geliştirici

**Yunus Emre**

- GitHub: [@yunussyasar](https://github.com/yunussyasar)

## 🙏 Teşekkürler

- Apple Vision Framework dokümantasyonu
- SwiftUI erişilebilirlik rehberleri
- Erişilebilirlik için iOS Human Interface Guidelines

---

<p align="center">
  Erişilebilirlik için ❤️ ile yapıldı
</p>
