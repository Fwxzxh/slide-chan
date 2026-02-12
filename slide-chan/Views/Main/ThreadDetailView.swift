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
                    headerArea
                } else {
                    Color.clear.frame(height: 10)
                }
                
                contentArea
                repliesArea
            }
        }
        .navigationTitle(depth == 0 ? (rootNode.post.sub?.decodedHTML ?? "Thread #\(String(rootNode.id))") : "[\(depth)] Replies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleBookmark(board: board, threadId: rootNode.post.no, subject: rootNode.post.sub?.decodedHTML, previewText: rootNode.post.cleanComment)
                } label: {
                    Image(systemName: viewModel.isBookmarked(board: board, threadId: rootNode.post.no) ? "bookmark.fill" : "bookmark")
                }
            }
            
            if let onRefresh = onRefresh {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await onRefresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ThreadGalleryView(nodes: getAllNodesInThread(), board: board)) {
                    Image(systemName: "square.grid.2x2")
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

    private var headerArea: some View {
        ZStack {
            Color.black
            MediaView(post: rootNode.post, board: board)
                .contentShape(Rectangle())
                .onTapGesture { openSlideshow(at: 0) }
        }
        .frame(minHeight: 300, maxHeight: 500)
    }
    
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            postMetadataView
            if let subject = rootNode.post.sub, !subject.isEmpty {
                Text(subject.decodedHTML).font(.system(size: 24, weight: .black, design: .rounded))
            }
            SmartText(text: rootNode.post.cleanComment, lineLimit: isAbbreviated ? 12 : nil)
                .font(.system(.body, design: .serif)).lineSpacing(6)
            if rootNode.post.cleanComment.components(separatedBy: "\n").count > 12 {
                readMoreButton
            }
        }
        .padding(24).background(Color(UIColor.systemBackground))
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
                    .buttonStyle(PlainButtonStyle()).padding(.vertical, 8)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground)).offset(y: rootNode.post.hasFile ? -20 : 0)
    }

    private var postMetadataView: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rootNode.post.name ?? "Anonymous")
                    .font(.system(size: 13, weight: .black)).foregroundColor(.blue)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.blue.opacity(0.1)).cornerRadius(6)
                Text(rootNode.post.now ?? "").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).padding(.leading, 4)
            }
            Spacer()
            Text("#\(String(rootNode.post.no))")
                .font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(.orange)
                .padding(.horizontal, 10).padding(.vertical, 5).background(Color.orange.opacity(0.15)).cornerRadius(8)
        }
    }

    private var readMoreButton: some View {
        Button { withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) { isAbbreviated.toggle() } } label: {
            Text(isAbbreviated ? "READ MORE" : "SHOW LESS").font(.system(size: 12, weight: .black))
                .padding(.vertical, 8).padding(.horizontal, 16).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(8)
        }
    }

    private var repliesHeader: some View {
        Text("Replies (\(rootNode.replies.count))").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
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

struct ReplyStackCard: View {
    let node: ThreadNode
    let board: String
    @State private var showFullScreen = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.post.name ?? "Anonymous").font(.caption.bold()).foregroundColor(.primary)
                Spacer()
                if !node.replies.isEmpty { Text("\(node.replies.count) »").font(.caption2.bold()).foregroundColor(.blue) }
            }
            HStack(alignment: .top, spacing: 12) {
                if node.post.hasFile {
                    MediaView(post: node.post, board: board)
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
