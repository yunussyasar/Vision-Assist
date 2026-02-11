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
    /// Trigger success haptic (double heavy impact)
    /// Used when target object is found
    func triggerSuccessFeedback() {
        guard settings.hapticEnabled else { return }
        
        let now = Date()
        
        // Debounce: only trigger if enough time has passed since last success
        if let lastTime = lastSuccessTime, now.timeIntervalSince(lastTime) < debounceInterval {
            return
        }
        
        // Pattern: Heavy impact, short pause, heavy impact
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred()
        }
        
        lastSuccessTime = now
    }
    
    /// Trigger warning haptic (triple light impact)
    /// Used for obstacles or edge detection
    func triggerWarningFeedback() {
        guard settings.hapticEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.impactOccurred()
        }
    }
    
    /// Trigger error haptic (long distinct vibration)
    /// Used when command is not recognized or operation fails
    func triggerErrorFeedback() {
        guard settings.hapticEnabled else { return }
        // UINotificationFeedbackGenerator.error is distinct enough (3 pulses)
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
    
    /// Trigger distance-based feedback
    /// Intensity increases as object gets closer (larger bounding box area)
    func triggerDistanceFeedback(intensity: Float) {
        guard settings.hapticEnabled else { return }
        
        // Map 0.0-1.0 intensity to feedback styles
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        if intensity > 0.8 {
            style = .heavy
        } else if intensity > 0.4 {
            style = .medium
        } else {
            style = .light
        }
        
        let generator = UIImpactFeedbackGenerator(style: style)
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
