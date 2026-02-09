import UIKit

/// Centralized haptic feedback manager for VisionAssist
/// Provides different types of haptic feedback for various app events
class HapticFeedbackManager {
    
    // MARK: - Singleton
    static let shared = HapticFeedbackManager()
    
    // MARK: - Feedback Generators
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Settings
    private var settings: SettingsManager { SettingsManager.shared }
    
    // MARK: - Debouncing
    private var lastSuccessTime: Date?
    private let debounceInterval: TimeInterval = 1.5  // Prevent continuous vibration
    
    // MARK: - Initialization
    private init() {
        prepareGenerators()
    }
    
    /// Pre-warm the haptic engines for instant response
    func prepareGenerators() {
        notificationGenerator.prepare()
        impactGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Feedback Methods
    
    /// Trigger success haptic when target object is found
    /// Includes debouncing to prevent continuous vibration
    func triggerSuccessFeedback() {
        guard settings.hapticEnabled else { return }
        
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
    
    /// Trigger warning haptic (e.g., object at edge of frame)
    func triggerWarningFeedback() {
        guard settings.hapticEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Trigger error haptic (e.g., voice command not recognized)
    func triggerErrorFeedback() {
        guard settings.hapticEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// Trigger impact feedback for button presses
    func triggerImpactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard settings.hapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: settings.hapticStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger selection feedback for UI element changes
    func triggerSelectionFeedback() {
        guard settings.hapticEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    /// Reset the debounce timer (e.g., when search target changes)
    func resetDebounce() {
        lastSuccessTime = nil
    }
}
