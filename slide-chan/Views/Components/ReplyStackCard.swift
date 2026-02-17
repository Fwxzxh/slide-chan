import SwiftUI

/// A specialized card view for displaying a single reply in a thread.
/// It features a compact layout with metadata at the top and content below.
struct ReplyStackCard: View {
    // MARK: - Properties
    
    /// The thread node data containing the post and any nested replies.
    let node: ThreadNode
    /// The short board ID (needed for image URLs).
    let board: String
    
    /// Controls whether to show the attached media in full screen.
    @State private var showFullScreen = false
    
    var body: some View {
        // VStack (Vertical Stack) groups the header, filename, and body vertically.
        VStack(alignment: .leading, spacing: 8) {
            
            // 1. Metadata Header: Name • Date [RepliesCount] #ID
            HStack(alignment: .center, spacing: 6) {
                // Author name (usually Anonymous)
                Text(node.post.name ?? "Anonymous")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                // Bullet separator
                Text("•")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Human-readable date string
                Text(node.post.now ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer() // Pushes the stats and ID to the right
                
                // Replies count badge: only visible if this post has replies.
                if !node.replies.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left.fill") // "Reply" icon
                            .font(.system(size: 8))
                        Text("\(node.replies.count)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(Theme.radiusXS)
                }
                
                // Unique 4chan post number (styled with a code font)
                PostIDBadge(postNumber: node.post.no)
            }
            
            // 2. Attachment Filename (optional)
            if node.post.hasFile, let filename = node.post.filename, let ext = node.post.ext {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 9))
                    Text("\(filename)\(ext)")
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, -4) // Brings it closer to the header
            }
            
            // 3. Post Body: Thumbnail (left) + Comment text (right)
            HStack(alignment: .top, spacing: 12) {
                if node.post.hasFile {
                    // Small square preview of the image/video
                    MediaThumbnailView(post: node.post, board: board, size: 64)
                        .cornerRadius(Theme.radiusSmall)
                }
                
                // The actual comment text (renders HTML and green text)
                VStack(alignment: .leading, spacing: 6) {
                    SmartText(text: node.post.cleanComment)
                        .font(.system(size: 14))
                        .lineLimit(8) // Limit vertical height of long replies
                }
            }
        }
        .padding(12) // Inner spacing of the card
        .background(Color.cardBackground) // Background defined in Theme.swift
        .cornerRadius(Theme.radiusMedium)
        .padding(.horizontal, 10) // Outer spacing from the screen edges
        .fullScreenCover(isPresented: $showFullScreen) {
            // Full screen media modal
            FullScreenMediaView(allMediaPosts: [node.post], board: board, currentIndex: .constant(0))
                .presentationBackground(.clear)
        }
    }
}

#Preview {
    NavigationView {
        ScrollView {
            VStack(spacing: 4) {
                // 1. Standard with Image
                ReplyStackCard(node: .mock, board: "v")
                
                // 2. Greentext / No Image
                ReplyStackCard(node: .mockGreentext, board: "v")
                
                // 3. Long Filename / Small Image
                ReplyStackCard(node: .mockLongFile, board: "v")
                
                // 4. Short / Single word reply
                ReplyStackCard(node: .mockShort, board: "v")
            }
            .padding(.vertical)
        }
        .background(Color.mainBackground)
        .navigationTitle("Thread Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}
