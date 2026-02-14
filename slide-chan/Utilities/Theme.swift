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
    // MARK: - Corner Radii
    
    /// Smallest radius for badges and minor tags.
    static let radiusXS: CGFloat = 4
    /// Standard radius for thumbnails and nested components.
    static let radiusSmall: CGFloat = 8
    /// Standard radius for cards, rows, and primary containers.
    static let radiusMedium: CGFloat = 12
    /// Large radius for hero sections, modals, and major surfaces.
    static let radiusLarge: CGFloat = 20
    
    // MARK: - Spacing
    
    /// Standard horizontal padding for views.
    static let horizontalPadding: CGFloat = 24
}
