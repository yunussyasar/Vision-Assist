import Speech
import AVFoundation
import SwiftUI
import Combine

/// Voice command manager for VisionAssist
/// Handles speech recognition and command parsing for hands-free object search
class VoiceCommandManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var targetObject: String? = nil
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let hapticManager = HapticFeedbackManager.shared
    
    /// Command phrases that trigger object search (Turkish)
    private let searchTriggerPhrases = ["bul", "ara", "nerede", "göster", "find", "search"]
    
    /// Command phrases that clear the current search (Turkish)
    private let clearTriggerPhrases = ["temizle", "iptal", "vazgeç", "sıfırla", "dur", "clear", "cancel"]
    
    /// Turkish to English object translation dictionary
    private let turkishToEnglish: [String: String] = [
        // Common objects - Yaygın nesneler
        "bilgisayar": "computer", "laptop": "laptop", "dizüstü": "laptop",
        "telefon": "cell phone", "cep telefonu": "cell phone", "mobil": "cell phone",
        "tablet": "tablet", "klavye": "keyboard", "fare": "mouse",
        "monitör": "monitor", "ekran": "monitor", "televizyon": "tv", "tv": "tv",
        
        // Furniture - Mobilya
        "sandalye": "chair", "koltuk": "couch", "kanepe": "couch", "masa": "dining table",
        "yatak": "bed", "dolap": "cabinet", "kitaplık": "bookshelf",
        
        // Kitchen - Mutfak
        "bardak": "cup", "fincan": "cup", "şişe": "bottle", "çatal": "fork",
        "bıçak": "knife", "kaşık": "spoon", "tabak": "bowl", "kase": "bowl",
        "buzdolabı": "refrigerator", "fırın": "oven", "mikrodalga": "microwave",
        
        // Personal items - Kişisel eşyalar  
        "çanta": "handbag", "sırt çantası": "backpack", "valiz": "suitcase",
        "şemsiye": "umbrella", "gözlük": "glasses", "saat": "clock",
        "anahtar": "keys", "cüzdan": "wallet",
        
        // Transportation - Ulaşım
        "araba": "car", "otomobil": "car", "otobüs": "bus", "kamyon": "truck",
        "motorsiklet": "motorcycle", "bisiklet": "bicycle", "uçak": "airplane",
        "tren": "train", "tekne": "boat", "gemi": "boat",
        
        // Animals - Hayvanlar
        "kedi": "cat", "köpek": "dog", "kuş": "bird", "at": "horse",
        "inek": "cow", "koyun": "sheep", "fil": "elephant", "ayı": "bear",
        "zürafa": "giraffe", "zebra": "zebra",
        
        // People - İnsanlar
        "kişi": "person", "insan": "person", "adam": "person", "kadın": "person",
        
        // Sports - Spor
        "top": "sports ball", "futbol topu": "sports ball", "tenis raketi": "tennis racket",
        "kayak": "skis", "sörf tahtası": "surfboard",
        
        // Food - Yiyecek
        "elma": "apple", "muz": "banana", "portakal": "orange", "sandviç": "sandwich",
        "pizza": "pizza", "kek": "cake", "pasta": "cake", "havuç": "carrot",
        "brokoli": "broccoli", "sosisli": "hot dog",
        
        // Other - Diğer
        "kitap": "book", "lamba": "lamp", "vazo": "vase", "makas": "scissors",
        "oyuncak": "teddy bear", "diş fırçası": "toothbrush", "saksı": "potted plant",
        "bitki": "potted plant", "çiçek": "potted plant", "kapı": "door", "pencere": "window"
    ]
    
    // MARK: - Initialization
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - Authorization
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.authorizationStatus = authStatus
                switch authStatus {
                case .authorized:
                    self?.errorMessage = nil
                case .denied:
                    self?.errorMessage = "Speech recognition access denied. Please enable in Settings."
                case .restricted:
                    self?.errorMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self?.errorMessage = "Speech recognition authorization pending."
                @unknown default:
                    self?.errorMessage = "Unknown authorization status."
                }
            }
        }
    }
    
    /// Check if speech recognition is available
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false && authorizationStatus == .authorized
    }
    
    // MARK: - Recording Control
    func startRecording() {
        // Check availability first
        guard isAvailable else {
            errorMessage = "Speech recognition is not available."
            hapticManager.triggerErrorFeedback()
            return
        }
        
        // Cancel any existing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session."
            hapticManager.triggerErrorFeedback()
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Failed to create recognition request."
            hapticManager.triggerErrorFeedback()
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        isProcessing = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.parseCommand(from: result.bestTranscription.formattedString)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.isProcessing = false
                }
            }
        }
        
        // Install audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            errorMessage = nil
            hapticManager.triggerImpactFeedback(style: .light)
        } catch {
            errorMessage = "Failed to start audio engine."
            hapticManager.triggerErrorFeedback()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        isProcessing = false
        hapticManager.triggerImpactFeedback(style: .light)
        
        // Restore audio session for playback (text-to-speech)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
                try audioSession.setActive(true)
                print("✅ Audio session restored for playback")
            } catch {
                print("❌ Failed to restore audio session: \(error)")
            }
        }
    }
    
    /// Clear the current search target
    func clearSearch() {
        targetObject = nil
        recognizedText = ""
        hapticManager.resetDebounce()
        hapticManager.triggerSelectionFeedback()
    }
    
    // MARK: - Command Parsing
    
    /// Parse the recognized text for commands
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
    
    /// Extract the target object from the recognized text
    private func extractTargetObject(from text: String, triggerPhrase: String) {
        let components = text.components(separatedBy: triggerPhrase)
        
        var target = ""
        
        // Turkish word order: object usually comes BEFORE the verb
        // "bilgisayar bul" -> ["bilgisayar ", ""]
        // English word order: object comes AFTER the verb
        // "find computer" -> ["", " computer"]
        
        if let afterPhrase = components.last, !afterPhrase.trimmingCharacters(in: .whitespaces).isEmpty {
            // English style: "find computer" or "bul bilgisayar"
            target = afterPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let beforePhrase = components.first, !beforePhrase.trimmingCharacters(in: .whitespaces).isEmpty {
            // Turkish style: "bilgisayar bul"
            target = beforePhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        print("🎯 extractTargetObject - text: '\(text)', trigger: '\(triggerPhrase)', target: '\(target)'")
        
        // Remove common Turkish articles and filler words
        let articles = ["bir ", "bu ", "şu ", "o ", "benim ", "the ", "a ", "an ", "my ", "bana ", "bunu ", "şunu "]
        for article in articles {
            if target.hasPrefix(article) {
                target = String(target.dropFirst(article.count))
            }
        }
        
        // Also remove trailing filler words
        let suffixes = [" bul", " ara", " göster", " nerede"]
        for suffix in suffixes {
            if target.hasSuffix(suffix) {
                target = String(target.dropLast(suffix.count))
            }
        }
        
        // Clean up any trailing punctuation or filler words
        target = target.trimmingCharacters(in: .punctuationCharacters)
        target = target.trimmingCharacters(in: .whitespaces)
        
        print("🎯 After cleanup - target: '\(target)'")
        
        if !target.isEmpty {
            // Translate Turkish to English if needed
            let englishTarget = translateToEnglish(target)
            print("🎯 Translated to English: '\(englishTarget)'")
            self.targetObject = englishTarget
            hapticManager.resetDebounce()
            hapticManager.triggerSelectionFeedback()
            
            // Automatically stop recording after object is recognized
            stopRecording()
        }
    }
    
    /// Translate Turkish object name to English for model matching
    private func translateToEnglish(_ turkishText: String) -> String {
        let lowercased = turkishText.lowercased()
        
        // Direct match
        if let translation = turkishToEnglish[lowercased] {
            return translation
        }
        
        // Partial match - check if any Turkish word is in the text
        for (turkish, english) in turkishToEnglish {
            if lowercased.contains(turkish) {
                return english
            }
        }
        
        // No translation found, return original (might be English already)
        return turkishText
    }
}
