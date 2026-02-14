import SwiftUI

/// A list row representing a saved (bookmarked) thread.
/// It displays the board name, the thread subject, and a short text preview.
struct BookmarkRow: View {
    // MARK: - Properties
    
    /// The persistent model data for the bookmark.
    let bookmark: BookmarkedThread
    /// Callback triggered when the user performs a swipe-to-delete action.
    let onDelete: () -> Void
    
    var body: some View {
        // NavigationLink makes the entire row tappable, pushing a new view to the stack.
        NavigationLink(destination: ThreadLoadingView(board: bookmark.board, threadId: bookmark.threadId)) {
            VStack(alignment: .leading, spacing: 4) {
                
                // Top Line: Board tag and Subject
                HStack {
                    // Small blue badge showing the board ID (e.g., /v/)
                    Text("/\(bookmark.board)/")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(Theme.radiusXS)
                    
                    // The subject of the thread.
                    if let subject = bookmark.subject, !subject.isEmpty {
                        Text(subject)
                            .font(.subheadline.bold())
                            .lineLimit(2) // Allows wrapping for longer titles
                    } else {
                        // Fallback text if no subject exists.
                        Text("Thread #\(String(bookmark.threadId))")
                            .font(.subheadline.bold())
                    }
                }
                
                // Bottom Line: Post preview text
                if let preview = bookmark.previewText, !preview.isEmpty {
                    Text(preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2) // Truncates long previews
                }
            }
            .padding(.vertical, 4)
        }
        // swipeActions adds a trailing "Delete" button when the user swipes left.
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    List {
        BookmarkRow(bookmark: .mock, onDelete: {})
    }
}
