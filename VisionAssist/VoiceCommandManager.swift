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
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let hapticManager = HapticFeedbackManager.shared
    
    /// Command phrases that trigger object search
    private let searchTriggerPhrases = ["find", "search", "look for", "where is", "locate", "show me"]
    
    /// Command phrases that clear the current search
    private let clearTriggerPhrases = ["clear", "stop searching", "cancel", "reset", "never mind"]
    
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
        guard let lastPart = components.last else { return }
        
        var target = lastPart.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common articles
        let articles = ["the ", "a ", "an ", "my ", "that "]
        for article in articles {
            if target.hasPrefix(article) {
                target = String(target.dropFirst(article.count))
            }
        }
        
        // Clean up any trailing punctuation or filler words
        target = target.trimmingCharacters(in: .punctuationCharacters)
        
        if !target.isEmpty {
            self.targetObject = target
            hapticManager.resetDebounce()
            hapticManager.triggerSelectionFeedback()
        }
    }
}
