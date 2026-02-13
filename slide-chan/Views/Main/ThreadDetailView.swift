import SwiftUI

/// Detailed view for a single thread, displaying the OP and its replies in a hierarchical or list format.
struct ThreadDetailView: View {
    /// The short ID of the board.
    let board: String
    /// The root node of the thread (OP).
    let rootNode: ThreadNode
    /// Current recursion depth (used when nesting replies).
    let depth: Int
    /// Optional refresh action.
    var onRefresh: (() async -> Void)? = nil

    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BoardViewModel.shared
    @State private var isAbbreviated: Bool = true
    @State private var selectedIndex: Int = 0
    @State private var showSlideshow: Bool = false
    
    // Memoized lists to avoid re-calculating on every body evaluation
    @State private var allThreadNodes: [ThreadNode] = []
    @State private var allMediaPosts: [Post] = []

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
                NavigationLink(destination: ThreadGalleryView(nodes: allThreadNodes, board: board)) {
                    Image(systemName: "square.grid.2x2")
                }
            }
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            FullScreenMediaView(
                allMediaPosts: allMediaPosts,
                board: board,
                currentIndex: $selectedIndex
            )
        }
        .onAppear {
            prepareThreadData()
        }
    }

    /// Prepares flattened lists of nodes and media for gallery and slideshow features.
    private func prepareThreadData() {
        let nodes = getAllNodesInThread()
        self.allThreadNodes = nodes
        self.allMediaPosts = nodes.map { $0.post }.filter { $0.hasFile }
    }

    /// Hero area for the thread, typically showing OP media.
    private var headerArea: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let imageHeight = min(screenWidth / rootNode.post.aspectRatio, 500)
            
            ZStack(alignment: .bottom) {
                // 1. Background Layer (Blurred)
                // Uses GeometryReader to fill the parent size defined by the main image
                GeometryReader { proxy in
                    if let thumbUrl = rootNode.post.thumbnailUrl(board: board) {
                        AsyncImage(url: thumbUrl) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 30)
                                .overlay(Color.black.opacity(0.3))
                        } placeholder: {
                            Color.black
                        }
                        // Extend upwards by 200pt
                        .frame(width: proxy.size.width, height: proxy.size.height + 200)
                        // Position center shifted up by 100pt, so bottom edge matches parent bottom edge
                        .position(x: proxy.size.width / 2, y: (proxy.size.height / 2) - 100)
                    }
                }
                .allowsHitTesting(false)
                // Allow this background to extend behind safe area
                .ignoresSafeArea(edges: .top)
                
                // 2. Main Image Layer
                MediaView(post: rootNode.post, board: board)
                    .onTapGesture { openSlideshow(at: 0) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: screenWidth, height: imageHeight)
            // Removed clipped() to allow the top blur to bleed into the safe area
        }
        .aspectRatio(rootNode.post.aspectRatio, contentMode: .fit)
        .frame(maxHeight: 500)
        .ignoresSafeArea(edges: .top)
    }
    
    /// Main content area for the post body and metadata.
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            postMetadataView
            if let subject = rootNode.post.sub, !subject.isEmpty {
                Text(subject.decodedHTML)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(3)
            }
            SmartText(text: rootNode.post.cleanComment, lineLimit: isAbbreviated ? 12 : nil)
                .font(.system(.body, design: .serif)).lineSpacing(4)
            if rootNode.post.cleanComment.components(separatedBy: "\n").count > 12 {
                readMoreButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(UIColor.systemBackground))
    }
    
    /// Area displaying the list of replies to the current post.
    private var repliesArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !rootNode.replies.isEmpty {
                repliesHeader
                ForEach(rootNode.replies) { childNode in
                    NavigationLink(destination: ThreadDetailView(board: board, rootNode: childNode, depth: depth + 1, onRefresh: onRefresh)) {
                        ReplyStackCard(node: childNode, board: board)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 2)
                }
                // Add some bottom padding to the whole list
                Color.clear.frame(height: 20)
            }
        }
        .background(Color.mainBackground)
    }

    /// Horizontal view displaying poster information and post number.
    private var postMetadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                // Name & Date group
                HStack(spacing: 6) {
                    Text(rootNode.post.name ?? "Anonymous")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.blue)
                    
                    Text("•")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(rootNode.post.now ?? "")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Post ID
                Text("#\(String(rootNode.post.no))")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Filename details
            if rootNode.post.hasFile, let filename = rootNode.post.filename, let ext = rootNode.post.ext {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 10))
                    Text("\(filename)\(ext)")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }

    /// Button to toggle the abbreviation of long comments.
    private var readMoreButton: some View {
        Button { withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) { isAbbreviated.toggle() } } label: {
            Text(isAbbreviated ? "READ MORE" : "SHOW LESS").font(.system(size: 12, weight: .black))
                .padding(.vertical, 8).padding(.horizontal, 16).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(8)
        }
    }

    /// Section header for the replies list.
    private var repliesHeader: some View {
        HStack {
            Text("Replies")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(rootNode.replies.count)")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    /// Recursively collects all nodes in the thread tree.
    private func getAllNodesInThread() -> [ThreadNode] {
        var all = [rootNode]
        func collect(node: ThreadNode) { for reply in node.replies { all.append(reply); collect(node: reply) } }
        collect(node: rootNode)
        return all
    }

    /// Opens the full-screen media slideshow.
    private func openSlideshow(at index: Int) {
        self.selectedIndex = index
        self.showSlideshow = true
    }
}

/// Shape that allows rounding specific corners of a rectangle.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    /// Applies a corner radius to specific corners of the view.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
