import SwiftUI

/// A row view representing a thread preview in a board catalog.
struct ThreadRow: View {
    let post: Post
    let board: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail with subtle shadow
            ZStack(alignment: .bottomTrailing) {
                if let thumbUrl = post.thumbnailUrl(board: board) {
                    AsyncImage(url: thumbUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 85, height: 85)
                    .cornerRadius(12)
                    .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 85, height: 85)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    if let sub = post.sub, !sub.isEmpty {
                        Text(sub.decodedHTML)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    } else {
                        Text("Thread")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("#\(String(post.no))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.appSecondary.opacity(0.8))
                }

                SmartText(text: post.cleanComment, lineLimit: 2)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                // Stats and Time bar
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        statLabel(value: post.replies ?? 0, icon: "bubble.left.fill")
                        statLabel(value: post.images ?? 0, icon: "photo.fill")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)

                    Spacer()
                    
                    Text(post.now ?? "")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// Helper to create a stat label with an icon.
    private func statLabel(value: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    List {
        ThreadRow(
            post: Post(
                no: 123456,
                resto: 0,
                time: 1611710000,
                now: "01/27/21(Wed)12:00:00",
                name: "Anonymous",
                sub: "Thread Subject Example",
                com: "This is a sample comment for the thread row component testing.",
                filename: nil,
                ext: nil,
                tim: nil,
                w: nil,
                h: nil,
                tn_w: nil,
                tn_h: nil,
                replies: 42,
                images: 5,
                sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
            ),
            board: "v"
        )
    }
    .listStyle(.plain)
}
