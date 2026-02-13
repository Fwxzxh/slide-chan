import SwiftUI

/// Centralized color palette and design tokens for the application.
extension Color {
    /// Primary accent color for buttons and highlights.
    static let appAccent = Color.blue
    /// Secondary accent color for labels and tags.
    static let appSecondary = Color.orange
    /// Background color for cards and elevated elements.
    static let cardBackground = Color(UIColor.systemBackground)
    /// Background color for the main content area.
    static let mainBackground = Color(UIColor.secondarySystemBackground)
}

/// Shared UI constants for consistent spacing and styling.
struct Theme {
    /// Standard corner radius for cards and containers.
    static let cornerRadius: CGFloat = 12
    /// Large corner radius for hero elements and modals.
    static let largeCornerRadius: CGFloat = 20
    /// Standard horizontal padding for views.
    static let horizontalPadding: CGFloat = 24
}
