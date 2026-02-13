import SwiftUI

/// A small thumbnail view for post attachments.
struct MediaThumbnailView: View {
    /// The post containing the media.
    let post: Post
    /// The short ID of the board.
    let board: String
    /// The square dimension of the thumbnail.
    var size: CGFloat = 50
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: post.thumbnailUrl(board: board)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Color.gray.opacity(0.2)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                case .empty:
                    Color.secondary.opacity(0.05)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: size, height: size)
            .clipped()
            
            // Icon to indicate type of media if it's not a plain image
            if post.mediaType != .image {
                Image(systemName: mediaIcon)
                    .font(.system(size: 8, weight: .bold))
                    .padding(2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(2)
                    .padding(2)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(4)
    }
    
    /// System icon name for the specific media type.
    private var mediaIcon: String {
        switch post.mediaType {
        case .video: return "play.fill"
        case .gif: return "gif"
        case .pdf: return "doc.fill"
        default: return ""
        }
    }
}
