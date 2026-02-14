import SwiftUI

/// A component that represents a single 4chan board in the main directory.
/// It displays the board name, a favorite star, an NSFW indicator, and a short description.
struct BoardRow: View {
    // MARK: - Properties
    
    /// The model data for the specific board.
    let board: Board
    /// Whether the user has marked this board as a favorite.
    let isFavorite: Bool
    /// Action to trigger when the favorite status is toggled.
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Main Content: Name and Description
            VStack(alignment: .leading, spacing: 4) {
                
                // Top Line: Display Name + Status Icons
                HStack {
                    // e.g., "v - Video Games"
                    Text(board.displayName)
                        .font(.headline)
                    
                    // Star icon if board is favorited.
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.appAccent)
                    }

                    // Red badge if the board is Not-Work-Safe (NSFW).
                    if !board.isWorkSafe {
                        Text("NSFW")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(Theme.radiusXS)
                    }
                }

                // Metadata description (channel purpose)
                if board.meta_description != nil {
                    SmartText(text: board.cleanDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer() // Ensures the row takes up the full width of the List.
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        BoardRow(board: .mock, isFavorite: true, toggleFavorite: {})
        BoardRow(board: .mock, isFavorite: false, toggleFavorite: {})
    }
}
