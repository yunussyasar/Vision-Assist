import Foundation
import SwiftUI
import Combine

/// Centralized settings manager for VisionAssist
/// Persists user preferences using UserDefaults
class SettingsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SettingsManager()
    
    // MARK: - UserDefaults
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let audioEnabled = "audioEnabled"
        static let speechRate = "speechRate"
        static let speechPitch = "speechPitch"
        static let hapticEnabled = "hapticEnabled"
        static let hapticIntensity = "hapticIntensity"
        static let confidenceThreshold = "confidenceThreshold"
        static let debounceInterval = "debounceInterval"
        static let interfaceLanguage = "interfaceLanguage"
        static let feedbackLanguage = "feedbackLanguage"
        static let showObjectCards = "showObjectCards"
        static let darkMode = "darkMode"
    }
    
    // MARK: - Audio Settings
    
    /// Whether audio feedback is enabled
    @Published var audioEnabled: Bool {
        didSet { defaults.set(audioEnabled, forKey: Keys.audioEnabled) }
    }
    
    /// Speech rate (0.3 - 0.7, default 0.52)
    @Published var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Keys.speechRate) }
    }
    
    /// Speech pitch (0.8 - 1.2, default 1.0)
    @Published var speechPitch: Double {
        didSet { defaults.set(speechPitch, forKey: Keys.speechPitch) }
    }
    
    // MARK: - Haptic Settings
    
    /// Whether haptic feedback is enabled
    @Published var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: Keys.hapticEnabled) }
    }
    
    /// Haptic intensity: 0 = Light, 1 = Medium, 2 = Heavy
    @Published var hapticIntensity: Int {
        didSet { defaults.set(hapticIntensity, forKey: Keys.hapticIntensity) }
    }
    
    // MARK: - Detection Settings
    
    /// Confidence threshold for object detection (0.3 - 0.9)
    @Published var confidenceThreshold: Double {
        didSet { defaults.set(confidenceThreshold, forKey: Keys.confidenceThreshold) }
    }
    
    /// Debounce interval for announcements in seconds (1.0 - 5.0)
    @Published var debounceInterval: Double {
        didSet { defaults.set(debounceInterval, forKey: Keys.debounceInterval) }
    }
    
    // MARK: - Language Settings
    
    /// Interface language: "tr" or "en"
    @Published var interfaceLanguage: String {
        didSet { defaults.set(interfaceLanguage, forKey: Keys.interfaceLanguage) }
    }
    
    /// Audio feedback language: "tr" or "en"
    @Published var feedbackLanguage: String {
        didSet { defaults.set(feedbackLanguage, forKey: Keys.feedbackLanguage) }
    }
    
    // MARK: - Visual Settings
    
    /// Whether to show detected object cards
    @Published var showObjectCards: Bool {
        didSet { defaults.set(showObjectCards, forKey: Keys.showObjectCards) }
    }
    
    /// Dark mode preference: 0 = System, 1 = Light, 2 = Dark
    @Published var darkMode: Int {
        didSet { defaults.set(darkMode, forKey: Keys.darkMode) }
    }
    
    // MARK: - Computed Properties
    
    /// Returns UIImpactFeedbackGenerator.FeedbackStyle based on hapticIntensity
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch hapticIntensity {
        case 0: return .light
        case 2: return .heavy
        default: return .medium
        }
    }
    
    /// Returns the speech locale based on feedbackLanguage
    var speechLocale: Locale {
        return Locale(identifier: feedbackLanguage == "tr" ? "tr-TR" : "en-US")
    }
    
    /// Returns ColorScheme for SwiftUI
    var colorScheme: ColorScheme? {
        switch darkMode {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load saved values or use defaults
        self.audioEnabled = defaults.object(forKey: Keys.audioEnabled) as? Bool ?? true
        self.speechRate = defaults.object(forKey: Keys.speechRate) as? Double ?? 0.52
        self.speechPitch = defaults.object(forKey: Keys.speechPitch) as? Double ?? 1.0
        self.hapticEnabled = defaults.object(forKey: Keys.hapticEnabled) as? Bool ?? true
        self.hapticIntensity = defaults.object(forKey: Keys.hapticIntensity) as? Int ?? 1
        self.confidenceThreshold = defaults.object(forKey: Keys.confidenceThreshold) as? Double ?? 0.4
        self.debounceInterval = defaults.object(forKey: Keys.debounceInterval) as? Double ?? 3.0
        self.interfaceLanguage = defaults.object(forKey: Keys.interfaceLanguage) as? String ?? "tr"
        self.feedbackLanguage = defaults.object(forKey: Keys.feedbackLanguage) as? String ?? "tr"
        self.showObjectCards = defaults.object(forKey: Keys.showObjectCards) as? Bool ?? true
        self.darkMode = defaults.object(forKey: Keys.darkMode) as? Int ?? 0
    }
    
    // MARK: - Reset
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        audioEnabled = true
        speechRate = 0.52
        speechPitch = 1.0
        hapticEnabled = true
        hapticIntensity = 1
        confidenceThreshold = 0.4
        debounceInterval = 3.0
        interfaceLanguage = "tr"
        feedbackLanguage = "tr"
        showObjectCards = true
        darkMode = 0
    }
}
