import SwiftUI

struct ThreadRow: View {
    let post: Post
    let board: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Miniatura
            if let thumbUrl = post.thumbnailUrl(board: board) {
                AsyncImage(url: thumbUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Color.gray.opacity(0.2)
                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Text("No Image")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    )
            }

            // Contenido
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let sub = post.sub, !sub.isEmpty {
                        Text(sub)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("#\(post.no)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                SmartText(text: post.cleanComment)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                // Estadísticas
                HStack(spacing: 12) {
                    Label("\(post.replies ?? 0)", systemImage: "bubble.left")
                    Label("\(post.images ?? 0)", systemImage: "photo")
                    Spacer()
                    Text(post.now)
                        .font(.system(size: 10))
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            }
        }
        .padding(10)
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
                images: 5
            ),
            board: "v"
        )
    }
    .listStyle(.plain)
}
