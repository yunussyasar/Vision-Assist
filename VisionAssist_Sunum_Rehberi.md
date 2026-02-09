# VisionAssist Sunum Anlatım Rehberi 🎤

> Bu döküman sunumda **nasıl anlatacağınızı** ve **hangi kodları göstereceğinizi** içeriyor.
> Her kod parçası için **dosya adı** ve **satır numaraları** belirtilmiştir.

---

# BÖLÜM 1: GİRİŞ VE PROBLEM TANIMI (2-3 dakika)

## Söylenecekler:

> "Merhaba, bugün size VisionAssist uygulamasını anlatacağım. Bu uygulama görme engelli bireylerin günlük hayatlarında karşılaştıkları önemli bir problemi çözmeyi hedefliyor."

### Problem:
> "Görme engelli bireyler çevrelerindeki nesneleri tespit etmekte zorlanıyor. Örneğin:
> - Telefonumu nereye koydum?
> - Masada su şişesi var mı?
> - Sandalye nerede?
> 
> Bu basit sorular görme engelli bireyler için ciddi günlük zorluklar oluşturuyor."

### Çözüm:
> "VisionAssist bu problemi çözmek için geliştirdiğimiz bir iOS uygulaması. Uygulama:
> 1. Kamera ile gerçek zamanlı nesne tespiti yapıyor
> 2. Sesli komutlarla belirli nesneleri arayabiliyor
> 3. Nesnenin konumunu ve mesafesini sesli olarak bildiriyor
> 4. Titreşimle geri bildirim veriyor"

### Önemli Vurgu:
> "Bu projede ben **uygulama geliştirme** kısmından sorumluyum. Görüntü işleme ve ML model eğitimi kısmını ekip arkadaşım anlatacak."

---

# BÖLÜM 2: KULLANILAN TEKNOLOJİLER (3-4 dakika)

## Söylenecekler:

> "Şimdi uygulamada kullandığımız teknolojileri ve neden bu tercihleri yaptığımızı açıklayacağım."

---

## 2.1 Platform: iOS

> "Uygulamamızı **iOS platformu** için geliştirdik."

### Neden iOS?

| Özellik | Açıklama |
|---------|----------|
| **VoiceOver** | iOS'un yerleşik ekran okuyucu teknolojisi |
| **Erişilebilirlik API'leri** | Kapsamlı accessibility desteği |
| **Neural Engine** | Özel ML işlemcisi, düşük güç tüketimi |
| **Tutarlı Donanım** | Test kolaylığı |

---

## 2.2 Programlama Dili: Swift 5

> "Geliştirme dili olarak **Swift** kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `ObjectDetector.swift`  
**Satırlar:** 32-37

```swift
class ObjectDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isTargetFound: Bool = false
    @Published var confidenceThreshold: Float = 0.4
```

> "Swift'in tip güvenliği ve modern sözdizimi ile okunabilir, bakımı kolay kod yazdık."

---

## 2.3 UI Framework: SwiftUI

> "Kullanıcı arayüzü için **SwiftUI** framework'ünü tercih ettik."

### 📂 Gösterilecek Kod:
**Dosya:** `ContentView.swift`  
**Satırlar:** 3-8

```swift
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var objectDetector = ObjectDetector()
    @StateObject private var voiceCommandManager = VoiceCommandManager()
    
    var body: some View {
```

> "SwiftUI'ın `@StateObject` ile bileşenler oluşturuyoruz. Veri değişince UI otomatik güncelleniyor."

---

## 2.4 Kamera: AVFoundation

> "Kamera erişimi için **AVFoundation** framework'ünü kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `CameraManager.swift`  
**Satırlar:** 35-38

```swift
func configureSession() {
    guard permissionGranted else { return }
    session.beginConfiguration()
    session.sessionPreset = .vga640x480 // Good balance for ML
```

> "VGA çözünürlük (640x480) seçtik. ML modeli zaten görüntüyü küçültüyor, yüksek çözünürlük gereksiz işlem gücü harcar."

### 📂 Gösterilecek Kod:
**Dosya:** `CameraManager.swift`  
**Satırlar:** 47-52

```swift
// Configure frame rate to 30 FPS
do {
    try videoDevice.lockForConfiguration()
    videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
    videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
    videoDevice.unlockForConfiguration()
```

> "30 FPS seçtik. 60 FPS gereksiz güç tüketir, 30 FPS yeterli."

---

## 2.5 Nesne Tespiti: Vision Framework + CoreML

> "Nesne tespiti için **Vision Framework** ve **CoreML** kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `ObjectDetector.swift`  
**Satırlar:** 80-93

```swift
// MARK: - Model Setup (One-time load)
private func setupModel() {
    let config = MLModelConfiguration()
    // Use Neural Engine for power efficiency
    config.computeUnits = .cpuAndNeuralEngine
    
    guard let coreMLModel = try? best(configuration: config),
          let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
        print("Failed to load model")
        return
    }
    
    cachedVisionModel = visionModel
    print("Model cached successfully with Neural Engine")
}
```

> "Önemli noktalar:
> 1. `computeUnits = .cpuAndNeuralEngine` - Neural Engine kullanarak güç tasarrufu
> 2. `best(configuration: config)` - Ekip arkadaşımın eğittiği YOLO modeli
> 3. Model bir kez yüklenip cache'leniyor"

---

## 2.6 Konuşma Tanıma: Speech Framework

> "Sesli komutlar için **Speech Framework** kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `VoiceCommandManager.swift`  
**Satırlar:** 19-22

```swift
private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
private var recognitionTask: SFSpeechRecognitionTask?
private let audioEngine = AVAudioEngine()
```

> "`tr-TR` locale ile Türkçe konuşma tanıma yapıyoruz. iOS 15'ten itibaren cihaz üzerinde çalışıyor, internet gerektirmiyor."

---

## 2.7 Sesli Geri Bildirim: AVSpeechSynthesizer

> "Sesli geri bildirim için **AVSpeechSynthesizer** kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `AudioFeedbackManager.swift`  
**Satırlar:** 233-250

```swift
let utterance = AVSpeechUtterance(string: text)

// Use a specific voice - try different voices
// Try to get a high-quality voice
let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "tr") }
if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
    utterance.voice = enhancedVoice
    print("🎤 Using enhanced Turkish voice: \(enhancedVoice.name)")
} else if let defaultVoice = AVSpeechSynthesisVoice(language: "tr-TR") {
    utterance.voice = defaultVoice
    print("🎤 Using default tr-TR voice")
}

utterance.rate = 0.5  // Slightly slower for clarity
utterance.pitchMultiplier = 1.0
utterance.volume = 1.0  // Maximum volume
```

> "Türkçe sesi seçiyoruz. `rate = 0.5` ile biraz yavaş konuşturuyoruz, görme engelli kullanıcılar için netlik önemli."

---

## 2.8 Titreşim: UIFeedbackGenerator

> "Dokunsal geri bildirim için **UIFeedbackGenerator** kullandık."

### 📂 Gösterilecek Kod:
**Dosya:** `HapticFeedbackManager.swift`  
**Satırlar:** 5-13

```swift
class HapticFeedbackManager {
    
    // MARK: - Singleton
    static let shared = HapticFeedbackManager()
    
    // MARK: - Feedback Generators
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGenerator = UISelectionFeedbackGenerator()
```

> "Singleton pattern ile tek instance kullanıyoruz. Üç farklı titreşim tipi: notification, impact, selection."

---

## 2.9 Teknoloji Stack Özeti

```
┌─────────────────────────────────────────────────────────────────┐
│                    VisionAssist Tech Stack                       │
├─────────────────────────────────────────────────────────────────┤
│  Platform      │  iOS 15+                                       │
│  Dil           │  Swift 5                                        │
│  UI            │  SwiftUI                                        │
│  Kamera        │  AVFoundation                                   │
│  ML            │  CoreML + Vision Framework                      │
│  Model         │  YOLO (best.mlpackage)                         │
│  Konuşma       │  Speech Framework                               │
│  Ses Çıkışı    │  AVSpeechSynthesizer                           │
│  Titreşim      │  UIFeedbackGenerator                           │
└─────────────────────────────────────────────────────────────────┘
```

---

# BÖLÜM 3: UYGULAMA MİMARİSİ (3-4 dakika)

## 3.1 Genel Mimari

> "Uygulamamız **katmanlı mimari** ile tasarlandı."

```
┌─────────────────────────────────────────────────────────────────┐
│                       GİRDİ KATMANI                              │
│         ┌──────────────┐        ┌──────────────┐                 │
│         │  📹 Kamera    │        │  🎤 Mikrofon  │                 │
│         └──────┬───────┘        └──────┬───────┘                 │
└────────────────┼───────────────────────┼─────────────────────────┘
                 │                       │
                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      İŞLEME KATMANI                              │
│    ┌────────────────┐        ┌─────────────────────┐             │
│    │ CameraManager   │        │ VoiceCommandManager │             │
│    └───────┬────────┘        └──────────┬──────────┘             │
│            └──────────┬─────────────────┘                        │
│                       ▼                                          │
│             ┌─────────────────┐                                  │
│             │  ObjectDetector  │                                  │
│             └────────┬────────┘                                  │
└──────────────────────┼───────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ÇIKTI KATMANI                               │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐    │
│  │ AudioFeedback     │  │ HapticFeedback    │  │ ContentView   │    │
│  └──────────────────┘  └──────────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3.2 Bileşenler ve Veri Akışı

> "Şimdi her bir dosyayı detaylı olarak inceleyeceğiz. Her dosyanın **ne işe yaradığını** açıklayıp, **kritik kod parçalarını** göstereceğim."

---

# BÖLÜM 4: DOSYA VE KOD DETAYLARI (8-10 dakika)

---

## 4.1 📂 CameraManager.swift (74 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | iPhone kamerasını yönetir ve her kareyi ObjectDetector'a iletir |
| **Giriş** | Kullanıcının kamera izni, cihaz kamerası |
| **Çıkış** | Ham görüntü kareleri (CVPixelBuffer) |
| **Bağımlılıklar** | AVFoundation framework |

> "Bu dosya kameranın açılması, yapılandırılması ve her karenin yakalanmasından sorumlu. Bir köprü gibi düşünün - kameradan gelen görüntüyü alıp ML modeline iletiyor."

---

### 📍 Kod: İzin Kontrolü (Satır 20-33)

```swift
func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        permissionGranted = true
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
        }
    default:
        permissionGranted = false
    }
}
```

> "iOS'ta kamera için kullanıcı izni zorunlu. Bu method mevcut izni kontrol ediyor, yoksa kullanıcıya soruyor."

---

### 📍 Kod: Kare Yakalama (Satır 68-73)

```swift
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrameCaptured?(pixelBuffer)
    }
}
```

> "Her kare yakalandığında bu method çağrılıyor. `pixelBuffer` ham görüntü verisi, `onFrameCaptured` callback ile ObjectDetector'a gönderiyoruz."

---

## 4.2 📂 ObjectDetector.swift (256 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | ML modeli ile gerçek zamanlı nesne tespiti yapar |
| **Giriş** | Kameradan gelen görüntü kareleri (CVPixelBuffer) |
| **Çıkış** | Tespit edilen nesneler listesi (DetectedObject[]), hedef bulundu bildirimi |
| **Bağımlılıklar** | CoreML, Vision framework, best.mlpackage modeli |

> "Uygulamanın beyni burası. Kameradan gelen her kareyi alıp ML modeline veriyor, sonuçları işliyor ve hedef nesne varsa geri bildirim tetikliyor."

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│ CameraManager │ --> │ ObjectDetector │ --> │ Geri Bildirim │
│  (Kare gönder)│     │  (ML çalıştır)  │     │ (Ses/Titreşim)│
└──────────────┘     └────────────────┘     └───────────────┘
```

---

### 📍 Kod: Termal Durum Yönetimi (Satır 111-128)
```swift
private func updateFrameSkipForThermalState(_ state: ProcessInfo.ThermalState) {
    switch state {
    case .nominal:
        adaptiveFrameSkip = 5  // ~6 FPS - Normal operation
        print("Thermal: Nominal - Frame skip: 5")
    case .fair:
        adaptiveFrameSkip = 8  // ~4 FPS - Slightly warm
        print("Thermal: Fair - Frame skip: 8")
    case .serious:
        adaptiveFrameSkip = 12 // ~2.5 FPS - Getting hot
        print("Thermal: Serious - Frame skip: 12")
    case .critical:
        adaptiveFrameSkip = 20 // ~1.5 FPS - Very hot, minimal processing
        print("Thermal: Critical - Frame skip: 20")
    @unknown default:
        adaptiveFrameSkip = 10
    }
}
```

> "iPhone ML çalıştırınca ısınır. Bu sistem termal durumu dinliyor. Cihaz ısındıkça daha az kare işliyoruz:
> - Normal: 6 FPS
> - Sıcak: 2.5 FPS  
> - Kritik: 1.5 FPS"

---

### 📍 Kod: Kare Atlama (Satır 131-144)

```swift
func processFrame(_ pixelBuffer: CVPixelBuffer) {
    frameCounter += 1
    guard frameCounter >= adaptiveFrameSkip else { return }
    frameCounter = 0
    
    guard !isProcessing else { return }
    guard cachedVisionModel != nil else { return }
    
    isProcessing = true
    
    processingQueue.async { [weak self] in
        self?.detectObjects(in: pixelBuffer)
    }
}
```

> "`adaptiveFrameSkip = 5` demek her 5 karede birini işle demek. `isProcessing` flag'i ile aynı anda birden fazla tespit engelleniyor."

---

### 📍 Kod: Konumsal Pozisyon Hesaplama (Satır 224-244)

```swift
private func calculateSpatialPosition(boundingBox: CGRect) -> String {
    let centerX = boundingBox.midX
    let centerY = boundingBox.midY
    
    var horizontal: String
    var vertical: String
    
    // Vision coordinates: 0.0 left/bottom, 1.0 right/top
    if centerX < 0.35 { horizontal = "sol" }
    else if centerX > 0.65 { horizontal = "sağ" }
    else { horizontal = "orta" }
    
    if centerY < 0.35 { vertical = "alt" }
    else if centerY > 0.65 { vertical = "üst" }
    else { vertical = "orta" }
    
    if horizontal == "orta" && vertical == "orta" { return "ortada" }
    else if horizontal == "orta" { return vertical }
    else if vertical == "orta" { return horizontal }
    else { return "\(vertical) \(horizontal)" }
}
```

> "Bounding box koordinatları 0-1 arası. Ekranı 3x3 grid gibi böldük: sol/orta/sağ, alt/orta/üst."

---

### 📍 Kod: Hedef Nesne Kontrolü (Satır 199-221)

```swift
private func checkForTargetObject() {
    guard let target = targetObject else {
        isTargetFound = false
        return
    }
    
    let matchingObject = detectedObjects.first { object in
        object.label.lowercased().contains(target.lowercased())
    }
    
    let found = matchingObject != nil
    let wasFound = isTargetFound
    isTargetFound = found
    
    if found && !wasFound {
        if let object = matchingObject {
            audioManager.announceTargetFound(object: object, isFirstFind: true)
            hapticManager.triggerSuccessFeedback()
        }
    } else if !found && wasFound {
        audioManager.announceTargetLost(objectLabel: target)
    }
}
```

> "Durum makinesi mantığı:
> - `found && !wasFound` → İlk kez bulundu → Sesli duyuru + Titreşim
> - `!found && wasFound` → Kayboldu → Kayıp duyurusu"

---

## 4.3 📂 VoiceCommandManager.swift (317 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | Kullanıcının sesli komutlarını tanır ve işler |
| **Giriş** | Mikrofon sesi |
| **Çıkış** | Aranacak hedef nesne adı (İngilizce) |
| **Bağımlılıklar** | Speech framework, AVFoundation |

> "Bu dosya konuşma tanıma işini yapıyor. Kullanıcı 'telefon bul' dediğinde bunu anlayıp, 'cell phone' olarak ObjectDetector'a iletiyor."

```
┌─────────────┐     ┌─────────────────────┐     ┌──────────────┐
│ Mikrofon     │ --> │ VoiceCommandManager │ --> │ targetObject │
│ "telefon bul"│     │ (Tanı + Çevir)       │     │ "cell phone"  │
└─────────────┘     └─────────────────────┘     └──────────────┘
```

---

### 📍 Kod: Tetikleyici İfadeler (Satır 25-29)

```swift
/// Command phrases that trigger object search (Turkish)
private let searchTriggerPhrases = ["bul", "ara", "nerede", "göster", "find", "search"]

/// Command phrases that clear the current search (Turkish)
private let clearTriggerPhrases = ["temizle", "iptal", "vazgeç", "sıfırla", "dur", "clear", "cancel"]
```

> "Kullanıcı 'telefon bul', 'telefonu ara', 'telefon nerede' diyebilir. Hepsi çalışıyor."

---

### 📍 Kod: Türkçe-İngilizce Çeviri Sözlüğü (Satır 32-79)

```swift
private let turkishToEnglish: [String: String] = [
    // Common objects - Yaygın nesneler
    "bilgisayar": "computer", "laptop": "laptop", "dizüstü": "laptop",
    "telefon": "cell phone", "cep telefonu": "cell phone", "mobil": "cell phone",
    "tablet": "tablet", "klavye": "keyboard", "fare": "mouse",
    "monitör": "monitor", "ekran": "monitor", "televizyon": "tv", "tv": "tv",
    
    // Furniture - Mobilya
    "sandalye": "chair", "koltuk": "couch", "kanepe": "couch", "masa": "dining table",
    
    // Kitchen - Mutfak
    "bardak": "cup", "fincan": "cup", "şişe": "bottle",
    
    // Animals - Hayvanlar
    "kedi": "cat", "köpek": "dog", "kuş": "bird",
    
    // ... 60+ çeviri
]
```

> "ML modeli İngilizce etiketler üretiyor (COCO dataset). Kullanıcı Türkçe konuşuyor. Bu sözlük ile eşleştirme yapıyoruz."

---

### 📍 Kod: Komut Ayrıştırma (Satır 224-242)

```swift
private func parseCommand(from text: String) {
    let lowercased = text.lowercased()
    
    // Check for clear commands first
    for clearPhrase in clearTriggerPhrases {
        if lowercased.contains(clearPhrase) {
            clearSearch()
            return
        }
    }
    
    // Check for search commands
    for searchPhrase in searchTriggerPhrases {
        if lowercased.contains(searchPhrase) {
            extractTargetObject(from: lowercased, triggerPhrase: searchPhrase)
            return
        }
    }
}
```

> "Tanınan metinde tetikleyici ifadeleri arıyoruz. Önce temizleme, sonra arama komutları kontrol ediliyor."

---

### 📍 Kod: Hedef Çıkarma - Türkçe Dil Mantığı (Satır 245-294)

```swift
private func extractTargetObject(from text: String, triggerPhrase: String) {
    let components = text.components(separatedBy: triggerPhrase)
    
    var target = ""
    
    // Turkish word order: object usually comes BEFORE the verb
    // "bilgisayar bul" -> ["bilgisayar ", ""]
    // English word order: object comes AFTER the verb
    // "find computer" -> ["", " computer"]
    
    if let afterPhrase = components.last, !afterPhrase.trimmingCharacters(in: .whitespaces).isEmpty {
        target = afterPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
    } else if let beforePhrase = components.first, !beforePhrase.trimmingCharacters(in: .whitespaces).isEmpty {
        target = beforePhrase.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // ...temizlik ve çeviri...
    
    let englishTarget = translateToEnglish(target)
    self.targetObject = englishTarget
}
```

> "Türkçe'de nesne fiilden önce: '**Telefon** bul'. İngilizce'de sonra: 'Find **phone**'. İkisini de destekliyoruz."

---

## 4.4 📂 AudioFeedbackManager.swift (268 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | Kullanıcıya Türkçe sesli geri bildirim verir |
| **Giriş** | Tespit edilen nesne bilgisi, konum ve güven oranı |
| **Çıkış** | Türkçe sesli duyuru |
| **Bağımlılıklar** | AVSpeechSynthesizer |

> "Görme engelli kullanıcı için en kritik çıktı. Nesne bulunduğunda, kaybolduğunda veya konumu değiştiğinde kullanıcıyı Türkçe olarak bilgilendiriyor."

```
┌───────────────┐     ┌──────────────────────┐     ┌──────────────┐
│ ObjectDetector │ --> │ AudioFeedbackManager │ --> │ 🔊 Hoparlör   │
│ (Nesne bulundu)│     │ (Duyuru oluştur)      │     │ "Telefon      │
│                │     │                       │     │  solunuzda"   │
└───────────────┘     └──────────────────────┘     └──────────────┘
```

---

### 📍 Kod: Detaylı Konum Hesaplama (Satır 138-182)

```swift
private func getDetailedPosition(boundingBox: CGRect) -> String {
    let midX = boundingBox.midX
    let midY = boundingBox.midY
    
    var horizontal: String
    if midX < 0.33 {
        horizontal = "solunuzda"
    } else if midX > 0.67 {
        horizontal = "sağınızda"
    } else {
        horizontal = "önünüzde"
    }
    
    // Mesafe tahmini (bounding box boyutuna göre)
    let size = boundingBox.width * boundingBox.height
    var distance: String
    if size > 0.25 {
        distance = "çok yakın"
    } else if size > 0.1 {
        distance = "yakın"
    } else if size > 0.02 {
        distance = ""
    } else {
        distance = "uzakta"
    }
    
    return parts.joined(separator: ", ")  // "solunuzda, yakın"
}
```

> "Mesafe tahmini bounding box boyutundan yapılıyor. Nesne büyük görünüyorsa yakın demektir."

---

### 📍 Kod: Hedef Bulundu Duyurusu (Satır 86-107)

```swift
func announceTargetFound(object: DetectedObject, isFirstFind: Bool = false) {
    print("📢 announceTargetFound called - isFirstFind: \(isFirstFind), label: \(object.label)")
    
    guard isFirstFind || shouldAnnouncePositionUpdate(for: object) else {
        print("📢 Skipping announcement (debounce)")
        return
    }
    
    let position = getDetailedPosition(boundingBox: object.boundingBox)
    let confidence = Int(object.confidence * 100)
    
    var announcement: String
    if isFirstFind {
        announcement = "\(object.label) bulundu. \(position). Yüzde \(confidence) güven oranı."
    } else {
        announcement = "\(object.label) şimdi \(position)"
    }
    
    speak(text: announcement)
    lastAnnouncementTimes[object.label] = Date()
}
```

> "İlk bulunduğunda: 'Telefon bulundu. Solunuzda, yakın. Yüzde 85 güven oranı.'  
> Sonraki güncellemeler: 'Telefon şimdi sağınızda'"

---

### 📍 Kod: Debouncing (Satır 184-192)

```swift
private func shouldAnnouncePositionUpdate(for object: DetectedObject) -> Bool {
    let now = Date()
    
    if let lastTime = lastAnnouncementTimes[object.label], now.timeIntervalSince(lastTime) < 5.0 {
        return false
    }
    
    return true
}
```

> "Son 5 saniyede duyuru yapıldıysa tekrar yapmıyoruz. Kullanıcıyı rahatsız etmemek için."

---

## 4.5 📂 HapticFeedbackManager.swift (80 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | Kullanıcıya titreşim ile dokunsal geri bildirim verir |
| **Giriş** | Başarı/uyarı olayları |
| **Çıkış** | iPhone titreşimi |
| **Bağımlılıklar** | UIFeedbackGenerator |

> "Sessiz modda veya gürültülü ortamda bile kullanıcı nesnenin bulunduğunu titreşimle anlayabiliyor. Erişilebilirlik için önemli bir kanal."

---

### 📍 Kod: Singleton Pattern (Satır 5-8)

```swift
class HapticFeedbackManager {
    
    // MARK: - Singleton
    static let shared = HapticFeedbackManager()
```

> "Singleton pattern ile tüm uygulama boyunca tek instance. Donanım kaynaklarını verimli kullanıyoruz."

---

### 📍 Kod: Success Feedback + Debouncing (Satır 35-48)

```swift
func triggerSuccessFeedback() {
    let now = Date()
    
    // Debounce: only trigger if enough time has passed since last success
    if let lastTime = lastSuccessTime, now.timeIntervalSince(lastTime) < debounceInterval {
        return
    }
    
    notificationGenerator.notificationOccurred(.success)
    lastSuccessTime = now
    
    // Prepare for next use
    notificationGenerator.prepare()
}
```

> "1.5 saniye debounce süresi. Nesne sürekli görünürken sürekli titreşim olmasın."

---

## 4.6 📂 ContentView.swift (338 satır)

> **Bu Dosya Ne İşe Yarar?**

| Özellik | Açıklama |
|---------|----------|
| **Temel Görevi** | Tüm bileşenleri birleştirir ve kullanıcı arayüzünü oluşturur |
| **Giriş** | Tüm manager'lardan gelen veriler |
| **Çıkış** | Görsel arayüz (kamera önizleme, butonlar, nesne kartları) |
| **Bağımlılıklar** | SwiftUI, diğer tüm manager'lar |

> "Bu dosya orkestra şefi gibi. Tüm bileşenleri yaratıyor, birbirine bağlıyor ve kullanıcıyla etkileşimi yönetiyor."

```
┌─────────────────────────────────────────────────────────────┐
│                     ContentView (Ana UI)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐   │
│  │ CameraManager │  │ ObjectDetector │  │ VoiceCommand    │   │
│  │ @StateObject   │  │ @StateObject   │  │ @StateObject     │   │
│  └───────────────┘  └───────────────┘  └─────────────────┘   │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   UI Elemanları                          │ │
│  │  📹 Kamera Önizleme │ 🎤 Mikrofon Butonu │ 📋 Nesne Kartları  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

### 📍 Kod: Bileşen Bağlantısı (Satır 15-19)

```swift
.onAppear {
    cameraManager.onFrameCaptured = { buffer in
        objectDetector.processFrame(buffer)
    }
}
```

> "View yüklendiğinde CameraManager'dan gelen her kareyi ObjectDetector'a yönlendiriyoruz."

---

### 📍 Kod: VoiceCommand → ObjectDetector Senkronizasyonu (Satır 20-29)

```swift
.onChange(of: voiceCommandManager.targetObject) { newTarget in
    objectDetector.targetObject = newTarget
    
    // Announce target change for accessibility
    if let target = newTarget {
        UIAccessibility.post(notification: .announcement, argument: "Now searching for \(target)")
    } else {
        UIAccessibility.post(notification: .announcement, argument: "Search cleared")
    }
}
```

> "Kullanıcı sesli komut verdiğinde `voiceCommandManager.targetObject` değişiyor. Bu değişiklik `objectDetector.targetObject`'e aktarılıyor."

---

### 📍 Kod: Erişilebilirlik - VoiceOver (Satır 56-57)

```swift
.accessibilityLabel("Clear search")
.accessibilityHint("Double tap to stop searching for \(target)")
```

> "Her UI elemanına `accessibilityLabel` ve `accessibilityHint` ekledik. VoiceOver kullanıcıları her elemanı anlayabiliyor."

---

### 📍 Kod: Tespit Edilen Nesne Kartları (Satır 95-104)

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(objectDetector.detectedObjects) { object in
            DetectedObjectCard(object: object, isTarget: isTargetObject(object))
        }
    }
    .padding(.horizontal)
}
.frame(height: 100)
```

> "Tespit edilen nesneler yatay kaydırılabilir kartlarda gösteriliyor. `ForEach` ile dinamik liste."

---

# BÖLÜM 5: ENTEGRASYON VE VERİ AKIŞI

## Tam Senaryo: "Telefon bul"

| Adım | Dosya | Satırlar | Açıklama |
|------|-------|----------|----------|
| 1 | `ContentView.swift` | 107 | Mikrofon butonuna basılır |
| 2 | `VoiceCommandManager.swift` | 114-190 | `startRecording()` - Kayıt başlar |
| 3 | `VoiceCommandManager.swift` | 152-172 | Konuşma tanınır: "telefon bul" |
| 4 | `VoiceCommandManager.swift` | 224-242 | `parseCommand()` - "bul" trigger tespit |
| 5 | `VoiceCommandManager.swift` | 245-294 | `extractTargetObject()` - "telefon" çıkarılır |
| 6 | `VoiceCommandManager.swift` | 298-314 | `translateToEnglish()` - "cell phone" çevirisi |
| 7 | `ContentView.swift` | 20-21 | `targetObject` değişikliği algılanır |
| 8 | `ObjectDetector.swift` | 38-48 | `targetObject` set edilir |
| 9 | `AudioFeedbackManager.swift` | 196-205 | "cell phone aranıyor" duyurusu |
| 10 | `CameraManager.swift` | 69-72 | Kare yakalanır, ObjectDetector'a gönderilir |
| 11 | `ObjectDetector.swift` | 131-144 | Frame skip kontrolü, ML'e gönderim |
| 12 | `ObjectDetector.swift` | 146-168 | `detectObjects()` - ML modeli çalışır |
| 13 | `ObjectDetector.swift` | 170-188 | Sonuçlar işlenir, DetectedObject'ler oluşur |
| 14 | `ObjectDetector.swift` | 199-221 | `checkForTargetObject()` - "Cell Phone" eşleşir! |
| 15 | `AudioFeedbackManager.swift` | 86-107 | "Cell Phone bulundu. Solunuzda, yakın." duyurusu |
| 16 | `HapticFeedbackManager.swift` | 35-48 | Başarı titreşimi |

---

# BÖLÜM 6: DEMO SENARYOSU

| Adım | Yapılacak | Gösterilecek Kod |
|------|-----------|------------------|
| 1 | Uygulamayı aç | - |
| 2 | Çevredeki nesneleri göster | `ContentView.swift` satır 95-104 (kartlar) |
| 3 | Mikrofon butonuna bas | `VoiceCommandManager.swift` satır 114 (`startRecording`) |
| 4 | "Bilgisayar bul" de | `VoiceCommandManager.swift` satır 32-79 (çeviri sözlüğü) |
| 5 | Bilgisayara doğrult | `ObjectDetector.swift` satır 199-221 (hedef kontrolü) |
| 6 | Sesli duyuruyu dinlet | `AudioFeedbackManager.swift` satır 86-107 |

---

# BÖLÜM 7: OLASI SORULAR

### 1. "Neden SwiftUI tercih ettiniz?"
📂 `ContentView.swift` satır 3-6 göster
> "Reaktif programlama. `@StateObject` ile veri değişince UI otomatik güncelleniyor."

### 2. "Termal yönetim nasıl çalışıyor?"
📂 `ObjectDetector.swift` satır 111-128 göster
> "Cihaz ısındıkça daha az kare işliyoruz: 6 FPS → 4 → 2.5 → 1.5 FPS"

### 3. "Türkçe-İngilizce çeviri neden gerekli?"
📂 `VoiceCommandManager.swift` satır 32-79 göster
> "Model İngilizce, kullanıcı Türkçe. Sözlük ile eşleştirme."

### 4. "Mesafe nasıl hesaplanıyor?"
📂 `AudioFeedbackManager.swift` satır 160-170 göster
> "Bounding box boyutu. Büyük = yakın, küçük = uzak."

### 5. "Model nasıl entegre ediliyor?"
📂 `ObjectDetector.swift` satır 80-93 göster
> "`best.mlpackage` dosyası Xcode tarafından Swift sınıfına çevriliyor. `best()` constructor'ı ile yüklüyoruz."

---

# HIZLI REFERANS: DOSYAlar VE ÖNEMLİ SATIRLAR

| Dosya | Önemli Satırlar | Konu |
|-------|-----------------|------|
| `CameraManager.swift` | 35-38 | VGA çözünürlük |
| `CameraManager.swift` | 47-52 | 30 FPS ayarı |
| `CameraManager.swift` | 68-72 | Kare yakalama |
| `ObjectDetector.swift` | 80-93 | Model yükleme |
| `ObjectDetector.swift` | 111-128 | Termal yönetim |
| `ObjectDetector.swift` | 131-144 | Frame skipping |
| `ObjectDetector.swift` | 199-221 | Hedef kontrolü |
| `ObjectDetector.swift` | 224-244 | Konum hesaplama |
| `VoiceCommandManager.swift` | 19 | Türkçe recognizer |
| `VoiceCommandManager.swift` | 25-29 | Trigger ifadeler |
| `VoiceCommandManager.swift` | 32-79 | Çeviri sözlüğü |
| `VoiceCommandManager.swift` | 224-242 | Komut ayrıştırma |
| `AudioFeedbackManager.swift` | 86-107 | Bulundu duyurusu |
| `AudioFeedbackManager.swift` | 138-182 | Detaylı konum |
| `AudioFeedbackManager.swift` | 233-250 | Türkçe TTS |
| `HapticFeedbackManager.swift` | 5-8 | Singleton |
| `HapticFeedbackManager.swift` | 35-48 | Success + debounce |
| `ContentView.swift` | 15-19 | Kamera bağlantısı |
| `ContentView.swift` | 20-29 | Hedef senkronizasyonu |
| `ContentView.swift` | 95-104 | Nesne kartları |

---

> 💡 **Sunum İpucu:** Bu dökümanı yanınızda tutun. Anlatırken ilgili dosyayı IDE'de açıp satır numaralarına gidin. Kod göstermek sunumu çok daha etkileyici yapar.
