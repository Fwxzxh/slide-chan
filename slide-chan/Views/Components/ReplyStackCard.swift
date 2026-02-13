import SwiftUI

/// A card view representing a reply in the thread list.
struct ReplyStackCard: View {
    /// The thread node representing the post and its replies.
    let node: ThreadNode
    /// The short ID of the board.
    let board: String
    
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Metadata header: Name, Date, Stats, Post No
            HStack(alignment: .center, spacing: 6) {
                // Author Name
                Text(node.post.name ?? "Anonymous")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Text("•")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Post Date
                Text(node.post.now ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Replies count badge (Fixed position in header)
                if !node.replies.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 8))
                        Text("\(node.replies.count)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // Post ID
                Text("#\(String(node.post.no))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Filename (if applicable)
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
                .padding(.top, -4)
            }
            
            // Body: Thumbnail + Comment
            HStack(alignment: .top, spacing: 12) {
                if node.post.hasFile {
                    MediaThumbnailView(post: node.post, board: board, size: 64)
                        .cornerRadius(6)
                        .onTapGesture { showFullScreen = true }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    SmartText(text: node.post.cleanComment)
                        .font(.system(size: 14))
                        .lineLimit(8)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal, 12)
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenMediaView(allMediaPosts: [node.post], board: board, currentIndex: .constant(0))
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ReplyStackCard(node: .mock, board: "v")
    }
}
