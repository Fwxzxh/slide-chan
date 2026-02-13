import SwiftUI

/// A row view representing a bookmarked thread.
struct BookmarkRow: View {
    /// The bookmark data.
    let bookmark: BookmarkedThread
    /// Action to perform when deleting the bookmark.
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: ThreadLoadingView(board: bookmark.board, threadId: bookmark.threadId)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("/\(bookmark.board)/")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                    
                    if let subject = bookmark.subject, !subject.isEmpty {
                        Text(subject)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                    } else {
                        Text("Thread #\(String(bookmark.threadId))")
                            .font(.subheadline.bold())
                    }
                }
                
                if let preview = bookmark.previewText, !preview.isEmpty {
                    Text(preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
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
