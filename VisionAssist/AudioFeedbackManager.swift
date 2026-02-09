import AVFoundation
import UIKit

/// Audio feedback manager for VisionAssist
/// Provides voice announcements for detected objects and their positions
class AudioFeedbackManager: NSObject, AVSpeechSynthesizerDelegate {
    
    // MARK: - Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var lastAnnouncementTimes: [String: Date] = [:]
    private var settings: SettingsManager { SettingsManager.shared }
    
    /// Computed debounce interval from settings
    private var debounceInterval: TimeInterval {
        settings.debounceInterval
    }
    
    /// Flag to track if we've announced finding the target
    private var hasAnnouncedTargetFound = false
    
    /// The current target being searched for
    private var currentTarget: String?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Use playAndRecord to allow both mic input and speaker output
            // .defaultToSpeaker ensures audio goes to speaker not earpiece
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voicePrompt,  // Optimized for voice prompts
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            
            // Force output to speaker
            try audioSession.overrideOutputAudioPort(.speaker)
            
            // Activate the session
            try audioSession.setActive(true)
            
            print("✅ Audio session configured - Output: \(audioSession.currentRoute.outputs)")
            
            // Log the current route
            for output in audioSession.currentRoute.outputs {
                print("🔈 Audio output port: \(output.portType.rawValue) - \(output.portName)")
            }
            
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    /// Force audio to speaker before speaking
    private func forceAudioToSpeaker() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to force speaker: \(error)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 Started speaking: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("🔊 Finished speaking: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🔊 Cancelled speaking")
    }
    
    // MARK: - Target Announcements
    
    /// Announces when target object is found with detailed position
    func announceTargetFound(object: DetectedObject, isFirstFind: Bool = false) {
        print("📢 announceTargetFound called - isFirstFind: \(isFirstFind), label: \(object.label)")
        
        // Only announce first find or significant position changes
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
    
    /// Announces that target object is no longer visible
    func announceTargetLost(objectLabel: String) {
        let now = Date()
        
        // Debounce lost announcements
        if let lastTime = lastAnnouncementTimes["lost_\(objectLabel)"], now.timeIntervalSince(lastTime) < 5.0 {
            return
        }
        
        speak(text: "\(objectLabel) artık görünmüyor. Bulmak için kameranızı hareket ettirin.")
        lastAnnouncementTimes["lost_\(objectLabel)"] = now
    }
    
    /// Standard object announcement (for non-target objects)
    func announce(object: DetectedObject) {
        let now = Date()
        if let lastTime = lastAnnouncementTimes[object.label], now.timeIntervalSince(lastTime) < debounceInterval {
            return
        }
        
        let position = getDetailedPosition(boundingBox: object.boundingBox)
        let text = "\(object.label), \(position)"
        
        speak(text: text)
        lastAnnouncementTimes[object.label] = now
    }
    
    // MARK: - Position Helpers
    
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
        
        var vertical: String
        if midY < 0.33 {
            vertical = "alt kısımda"
        } else if midY > 0.67 {
            vertical = "üst kısımda"
        } else {
            vertical = ""
        }
        
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
        
        var parts: [String] = []
        parts.append(horizontal)
        if !vertical.isEmpty && horizontal != "önünüzde" {
            parts.append(vertical)
        }
        if !distance.isEmpty {
            parts.append(distance)
        }
        
        return parts.joined(separator: ", ")
    }
    
    private func shouldAnnouncePositionUpdate(for object: DetectedObject) -> Bool {
        let now = Date()
        
        if let lastTime = lastAnnouncementTimes[object.label], now.timeIntervalSince(lastTime) < 5.0 {
            return false
        }
        
        return true
    }
    
    // MARK: - Search State
    
    func setSearchTarget(_ target: String?) {
        currentTarget = target
        hasAnnouncedTargetFound = false
        
        if let target = target {
            speak(text: "\(target) aranıyor")
        } else {
            speak(text: "Arama temizlendi")
        }
    }
    
    func markTargetAnnounced() {
        hasAnnouncedTargetFound = true
    }
    
    var hasAnnouncedTarget: Bool {
        return hasAnnouncedTargetFound
    }
    
    func resetAnnouncements() {
        lastAnnouncementTimes.removeAll()
        hasAnnouncedTargetFound = false
    }
    
    // MARK: - Speech
    
    private func speak(text: String) {
        // Check if audio is enabled in settings
        guard settings.audioEnabled else {
            print("🔇 Audio disabled in settings, skipping speech")
            return
        }
        
        print("🎤 Attempting to speak: \(text)")
        
        // Force audio to speaker before speaking
        forceAudioToSpeaker()
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Get language from settings
        let languageCode = settings.feedbackLanguage == "tr" ? "tr-TR" : "en-US"
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: settings.feedbackLanguage) }
        if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
            utterance.voice = enhancedVoice
            print("🎤 Using enhanced voice: \(enhancedVoice.name)")
        } else if let defaultVoice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = defaultVoice
            print("🎤 Using default \(languageCode) voice")
        }
        
        // Use settings for rate and pitch
        utterance.rate = Float(settings.speechRate)
        utterance.pitchMultiplier = Float(settings.speechPitch)
        utterance.volume = 1.0  // Maximum volume
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        // Print audio route info
        let route = AVAudioSession.sharedInstance().currentRoute
        print("🔈 Current audio route outputs: \(route.outputs.map { $0.portType.rawValue })")
        
        // Speak on main thread
        DispatchQueue.main.async { [weak self] in
            self?.synthesizer.speak(utterance)
            print("🎤 Speech queued")
        }
    }
    
    /// Test method to verify audio is working
    func testSpeak() {
        speak(text: "Ses testi. Bu sesi duyuyorsanız, ses çalışıyor.")
    }
}
