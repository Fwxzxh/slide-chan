import UIKit

/// A simple utility to trigger haptic feedback throughout the app.
enum HapticManager {
    /// Triggers a physical impact feedback (e.g., light, medium, heavy).
    /// - Parameter style: The intensity of the impact.
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers a notification feedback (e.g., success, warning, error).
    /// - Parameter type: The type of notification to signal.
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Triggers a light feedback suitable for selection changes.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
