import SwiftUI

struct ThreadDetailView: View {
    let board: String
    let rootNode: ThreadNode
    let depth: Int
    var onRefresh: (() async -> Void)? = nil

    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BoardViewModel.shared
    @State private var isAbbreviated: Bool = true
    @State private var selectedIndex: Int = 0
    @State private var showSlideshow: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if rootNode.post.hasFile {
                    // Header Area Simple
                    ZStack {
                        Color.black // Fondo neutro para evitar saturación
                        
                        MediaView(post: rootNode.post, board: board)
                            .padding(.top, 50)
                            .padding(.bottom, 20)
                            .onTapGesture { openSlideshow(at: 0) }
                    }
                    .frame(minHeight: 300)
                } else {
                    Color.clear.frame(height: 100)
                }
                
                contentArea
                
                repliesArea
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                customBackButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    bookmarkButton
                    if let onRefresh = onRefresh {
                        customRefreshButton(onRefresh)
                    }
                    galleryButton
                }
            }
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            FullScreenMediaView(
                allMediaPosts: getAllNodesInThread().map { $0.post }.filter { $0.hasFile },
                board: board,
                currentIndex: $selectedIndex
            )
        }
    }

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            postMetadataView
            
            if let subject = rootNode.post.sub, !subject.isEmpty {
                Text(subject.decodedHTML)
                    .font(.title2.bold())
            }

            SmartText(text: rootNode.post.cleanComment, lineLimit: isAbbreviated ? 12 : nil)
                .font(.system(.body, design: .serif))
                .lineSpacing(6)
            
            if rootNode.post.cleanComment.components(separatedBy: "\n").count > 12 {
                readMoreButton
            }
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .offset(y: rootNode.post.hasFile ? -20 : 0)
    }
    
    private var repliesArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !rootNode.replies.isEmpty {
                repliesHeader
                ForEach(rootNode.replies) { childNode in
                    NavigationLink(destination: ThreadDetailView(board: board, rootNode: childNode, depth: depth + 1, onRefresh: onRefresh)) {
                        ReplyStackCard(node: childNode, board: board)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .offset(y: rootNode.post.hasFile ? -20 : 0)
    }

    // MARK: - Components (Simplificados)
    
    private var bookmarkButton: some View {
        Button {
            viewModel.toggleBookmark(board: board, threadId: rootNode.post.no, subject: rootNode.post.sub?.decodedHTML, previewText: rootNode.post.cleanComment)
        } label: {
            Image(systemName: viewModel.isBookmarked(board: board, threadId: rootNode.post.no) ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.ultraThinMaterial).clipShape(Circle())
        }
    }
    
    private var galleryButton: some View {
        NavigationLink(destination: ThreadGalleryView(nodes: getAllNodesInThread(), board: board)) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.ultraThinMaterial).clipShape(Circle())
        }
    }

    private var readMoreButton: some View {
        Button { withAnimation { isAbbreviated.toggle() } } label: {
            Text(isAbbreviated ? "READ MORE" : "SHOW LESS").font(.caption.bold())
                .padding(8).background(Color.blue.opacity(0.1)).cornerRadius(8)
        }
    }

    private var postMetadataView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rootNode.post.name ?? "Anonymous").font(.subheadline.bold()).foregroundColor(.blue)
                Text(rootNode.post.now ?? "").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("#\(String(rootNode.post.no))").font(.caption.monospaced()).foregroundColor(.orange)
        }
    }

    private var customBackButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.ultraThinMaterial).clipShape(Circle())
        }
    }

    private func customRefreshButton(_ action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
            Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.ultraThinMaterial).clipShape(Circle())
        }
    }

    private var repliesHeader: some View {
        Text("Replies (\(rootNode.replies.count))")
            .font(.caption.bold()).foregroundColor(.secondary)
            .padding(.horizontal, 24).padding(.top, 32).padding(.bottom, 12)
    }

    private func getAllNodesInThread() -> [ThreadNode] {
        var all = [rootNode]
        func collect(node: ThreadNode) { for reply in node.replies { all.append(reply); collect(node: reply) } }
        collect(node: rootNode)
        return all
    }

    private func openSlideshow(at index: Int) {
        self.selectedIndex = index
        self.showSlideshow = true
    }
}

// MARK: - Subviews

struct ReplyStackCard: View {
    let node: ThreadNode
    let board: String
    @State private var showFullScreen = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.post.name ?? "Anonymous").font(.caption.bold()).foregroundColor(.primary)
                Spacer()
                if !node.replies.isEmpty {
                    Text("\(node.replies.count) »").font(.caption2.bold()).foregroundColor(.blue)
                }
            }
            HStack(alignment: .top, spacing: 12) {
                if let thumbUrl = node.post.thumbnailUrl(board: board) {
                    AsyncImage(url: thumbUrl) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Color.gray.opacity(0.1) }
                    .frame(width: 50, height: 50).cornerRadius(8).clipped()
                    .onTapGesture { showFullScreen = true }
                }
                SmartText(text: node.post.cleanComment).font(.subheadline).lineLimit(4)
            }
        }
        .padding().background(Color(UIColor.systemBackground)).cornerRadius(12).padding(.horizontal)
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenMediaView(allMediaPosts: [node.post], board: board, currentIndex: .constant(0))
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
