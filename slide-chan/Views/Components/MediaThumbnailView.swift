import SwiftUI

/// A small, square preview view used in lists (like thread rows or reply cards).
/// It shows a thumbnail of the post's attachment and a small icon if it's a video.
struct MediaThumbnailView: View {
    // MARK: - Properties
    
    /// The post whose media thumbnail we want to display.
    let post: Post
    /// Short board ID (e.g., "v").
    let board: String
    /// The width and height of the square thumbnail.
    var size: CGFloat = 50
    
    var body: some View {
        // ZStack layers the image and the optional media icon.
        ZStack(alignment: .bottomTrailing) {
            
            // 1. Thumbnail Image
            AsyncImage(url: post.thumbnailUrl(board: board)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill) // Fills the square without distorting
                case .failure(_):
                    // Error state icon
                    Color.gray.opacity(0.2)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                case .empty:
                    // Grey background while loading
                    Color.secondary.opacity(0.05)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: size, height: size)
            .clipped() // Ensures parts of the image that spill out of the square are hidden
            
            // 2. Media Type Icon (e.g., Play button for videos)
            if post.mediaType != .image {
                Image(systemName: mediaIcon)
                    .font(.system(size: 8, weight: .bold))
                    .padding(2)
                    .background(.ultraThinMaterial) // Blurry glass effect background
                    .cornerRadius(Theme.radiusXS / 2)
                    .padding(2)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(Theme.radiusXS)
    }
    
    // MARK: - Helpers

    /// Decides which SF Symbol icon to show based on the file type.
    private var mediaIcon: String {
        switch post.mediaType {
        case .video: return "play.fill"
        case .gif: return "gif"
        case .pdf: return "doc.fill"
        default: return ""
        }
    }
}

#Preview {
    HStack {
        MediaThumbnailView(post: .mock, board: "v")
        MediaThumbnailView(post: .mock, board: "v", size: 100)
    }
    .padding()
}
