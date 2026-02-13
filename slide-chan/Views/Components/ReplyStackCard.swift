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
            HStack {
                Text(node.post.name ?? "Anonymous")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                
                if node.post.hasFile, let filename = node.post.filename, let ext = node.post.ext {
                    HStack(spacing: 2) {
                        Image(systemName: "paperclip")
                        Text("\(filename)\(ext)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                if !node.replies.isEmpty {
                    Text("\(node.replies.count) »")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                }
            }
            HStack(alignment: .top, spacing: 12) {
                if node.post.hasFile {
                    MediaThumbnailView(post: node.post, board: board)
                        .onTapGesture { showFullScreen = true }
                }
                SmartText(text: node.post.cleanComment)
                    .font(.subheadline)
                    .lineLimit(4)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
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
