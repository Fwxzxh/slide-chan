import SwiftUI

struct ThreadDetailView: View {
    let board: String
    let rootNode: ThreadNode
    let depth: Int
    var onRefresh: (() async -> Void)? = nil // Callback para refrescar desde la raíz

    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. Post "Raíz" actual
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(rootNode.post.name)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text(rootNode.post.now)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("#\(rootNode.post.no)")
                            .font(.caption2)
                            .monospaced()
                    }

                    if let fullImageURL = rootNode.post.imageUrl(board: board) {
                        AsyncImage(url: fullImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(8)
                            case .failure(_):
                                Color.gray.opacity(0.2)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                            case .empty:
                                ProgressView()
                                    .frame(height: 100)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    SmartText(text: rootNode.post.cleanComment)
                        .font(.body)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: false)
                }
                .padding()
                .background(Color(UIColor.systemBackground))

                Divider()

                // 2. Lista de respuestas directas
                VStack(alignment: .leading, spacing: 0) {
                    if rootNode.replies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No hay respuestas a este post")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        Text("Respuestas (\(rootNode.replies.count))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        ForEach(rootNode.replies) { childNode in
                            // Pasamos el onRefresh hacia abajo para que el botón esté disponible en cualquier nivel
                            NavigationLink(destination: ThreadDetailView(board: board, rootNode: childNode, depth: depth + 1, onRefresh: onRefresh)) {
                                ReplyStackCard(node: childNode, board: board)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle(depth == 0 ? "Hilo #\(rootNode.id)" : "[\(depth)] Respuestas")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
        .toolbar {
            if let onRefresh = onRefresh {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await onRefresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Subvistas

struct ReplyStackCard: View {
    let node: ThreadNode
    let board: String

    var body: some View {
        ZStack(alignment: .bottom) {
            if !node.replies.isEmpty {
                ForEach(1...min(node.replies.count, 2), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .offset(y: CGFloat(i * 6))
                        .padding(.horizontal, CGFloat(i * 8))
                        .opacity(0.4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(node.post.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    if !node.replies.isEmpty {
                        HStack(spacing: 4) {
                            Text("\(node.replies.count)")
                            Image(systemName: "chevron.right.2")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    if let thumbUrl = node.post.thumbnailUrl(board: board) {
                        AsyncImage(url: thumbUrl) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.1)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)
                        .clipped()
                    }

                    Text(node.post.cleanComment)
                        .font(.subheadline)
                        .lineLimit(4)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.bottom, CGFloat(min(node.replies.count, 2) * 6))
    }
}

#Preview {
    NavigationView {
        ThreadDetailView(
            board: "v",
            rootNode: ThreadNode(
                post: Post(
                    no: 1, resto: 0, time: 0, now: "Ahora", name: "OP",
                    sub: "Thread Title", com: "Hello World", filename: nil,
                    ext: nil, tim: nil, w: nil, h: nil, tn_w: nil, tn_h: nil,
                    replies: 0, images: 0
                ),
                replies: [
                    ThreadNode(post: Post(
                        no: 2, resto: 1, time: 0, now: "Ahora", name: "Anon",
                        sub: nil, com: ">>285607335\n>>285607292\nYou did mention it. I rushed my post again.", filename: nil,
                        ext: nil, tim: nil, w: nil, h: nil, tn_w: nil, tn_h: nil,
                        replies: 0, images: 0
                    ))
                ]
            ),
            depth: 0,
            onRefresh: {}
        )
    }
}
