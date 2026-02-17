import SwiftUI

/// A row component for the board catalog list.
/// Displays a preview of a thread, including its thumbnail, subject, comment snippet, and stats.
struct ThreadRow: View {
    // MARK: - Properties
    
    /// The Original Post (OP) data of the thread.
    let post: Post
    /// The board ID (e.g., "g") used to build media URLs.
    let board: String

    var body: some View {
        // HStack (Horizontal Stack) arranges the thumbnail on the left and text content on the right.
        HStack(alignment: .top, spacing: 16) {
            
            // 1. Thread Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let thumbUrl = post.thumbnailUrl(board: board) {
                    // AsyncImage loads the thumbnail from 4chan servers in the background.
                    AsyncImage(url: thumbUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill) // Fills the 85x85 square
                    } placeholder: {
                        // Background shown while the image is downloading.
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 85, height: 85)
                    .cornerRadius(Theme.radiusSmall)
                    .clipped() // Cuts any part of the image that spills out of the 85x85 frame
                } else {
                    // Placeholder shown if there's no media in the thread.
                    RoundedRectangle(cornerRadius: Theme.radiusSmall)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 85, height: 85)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                }
            }

            // 2. Thread Information (Subject, Snippet, Stats)
            // VStack (Vertical Stack) stacks the text elements vertically.
            VStack(alignment: .leading, spacing: 6) {
                
                // Top Line: Subject and Post ID
                HStack(alignment: .firstTextBaseline) {
                    if let sub = post.sub, !sub.isEmpty {
                        // The decodedHTML extension converts entities like &quot; to "
                        Text(sub.decodedHTML)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2) // Allows long titles to wrap once
                    } else {
                        // Default text if no subject is provided.
                        Text("Thread")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    Spacer() // Pushes the ID to the far right

                    // Thread ID (#12345)
                    PostIDBadge(postNumber: post.no)
                }

                // Comment Snippet (Preview of the post body)
                SmartText(text: post.cleanComment)
                    .lineLimit(2)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4) // Pushes the stats bar to the bottom of the row

                // Bottom Bar: Replies, Images, and Date
                HStack(spacing: 12) {
                    // Stat Group: [BubbleIcon RepliesCount] [PhotoIcon ImageCount]
                    HStack(spacing: 12) {
                        statLabel(value: post.replies ?? 0, icon: "bubble.left.fill")
                        statLabel(value: post.images ?? 0, icon: "photo.fill")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.08)) // Subtle background for the "pill"
                    .cornerRadius(Theme.radiusSmall)

                    Spacer()
                    
                    // The "now" string from 4chan API (e.g., "02/13/26(Fri)03:57:07")
                    Text(post.now ?? "")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helper Views

    /// Generates a consistent label for thread statistics (e.g., reply count).
    private func statLabel(value: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)
                // fixedSize ensures the text doesn't wrap or compress when the list is narrow.
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    NavigationView {
        List {
            NavigationLink(destination: Text("Detail")) {
                ThreadRow(post: .mock, board: "v")
            }
            .listRowInsets(EdgeInsets())
            
            NavigationLink(destination: Text("Detail")) {
                ThreadRow(post: .mockLongTitle, board: "v")
            }
            .listRowInsets(EdgeInsets())
            
            NavigationLink(destination: Text("Detail")) {
                ThreadRow(post: .mockManyStats, board: "v")
            }
            .listRowInsets(EdgeInsets())
            
            NavigationLink(destination: Text("Detail")) {
                ThreadRow(post: .mockNoSubject, board: "v")
            }
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .navigationTitle("/v/ - Video Games")
        .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}
