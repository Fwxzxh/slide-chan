import SwiftUI

/// Detailed view for a single thread, displaying the Original Post (OP) and its replies.
/// It uses a recursive structure to allow navigating into reply chains.
struct ThreadDetailView: View {
    // MARK: - Properties
    
    /// The short ID of the board (e.g., "g").
    let board: String
    /// The thread node representing the current post and its nested replies.
    let rootNode: ThreadNode
    /// The current level in the reply tree (0 for OP, 1 for first-level replies, etc.).
    let depth: Int
    /// Action to refresh the thread data.
    var onRefresh: (() async -> Void)? = nil

    // MARK: - Local State
    
    /// User's dark/light mode preference.
    @AppStorage("isDarkMode") private var isDarkMode = false
    /// Allows dismissing the view programmatically.
    @Environment(\.dismiss) private var dismiss
    /// Shared ViewModel for managing bookmarks and favorites.
    @StateObject private var viewModel = BoardViewModel.shared
    /// Controls whether long comments are truncated or fully shown.
    @State private var isAbbreviated: Bool = true
    /// Tracking for the media slideshow.
    @State private var selectedIndex: Int = 0
    @State private var showSlideshow: Bool = false
    
    // MARK: - Memoized Data
    
    /// Flat list of all nodes in this specific branch (used for gallery).
    @State private var allThreadNodes: [ThreadNode] = []
    /// Flat list of all posts containing media in this branch.
    @State private var allMediaPosts: [Post] = []

    var body: some View {
        // ScrollView allows vertical scrolling of the post content and replies.
        ScrollView {
            // VStack (Vertical Stack) stacks elements one on top of another.
            VStack(spacing: 0) {
                // 1. Header Section: Shows the image or video of the OP.
                if rootNode.post.hasFile {
                    headerArea
                } else {
                    // Small spacer if there's no media.
                    Color.clear.frame(height: 10)
                }
                
                // 2. Content Section: Metadata, Title (Subject), and Comment.
                contentArea
                
                // 3. Replies Section: Lists all posts that replied to this one.
                repliesArea
            }
        }
        // Dynamic navigation title showing either the subject or the thread ID.
        .navigationTitle(depth == 0 ? (rootNode.post.sub?.decodedHTML ?? "Thread #\(String(rootNode.id))") : "[\(depth)] Replies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Toolbar Items: Bookmark, Refresh, and Gallery buttons.
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
        // Presents the slideshow as a full-screen overlay.
        .fullScreenCover(isPresented: $showSlideshow) {
            FullScreenMediaView(
                allMediaPosts: allMediaPosts,
                board: board,
                currentIndex: $selectedIndex
            )
        }
        .onAppear {
            // Pre-calculate flat lists when the view appears.
            prepareThreadData()
        }
    }

    // MARK: - Logic Helpers

    /// Prepares flattened lists of nodes and media for gallery and slideshow features.
    private func prepareThreadData() {
        let nodes = getAllNodesInThread()
        self.allThreadNodes = nodes
        self.allMediaPosts = nodes.map { $0.post }.filter { $0.hasFile }
    }

    // MARK: - View Components

    /// Immersive header area showing the OP media with a blurred background.
    private var headerArea: some View {
        // GeometryReader gives us access to the size of the parent container.
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            // Calculate a height that respects aspect ratio but doesn't exceed 500pt.
            let imageHeight = min(screenWidth / rootNode.post.aspectRatio, 500)
            
            // ZStack (Depth Stack) layers views on top of each other.
            ZStack(alignment: .bottom) {
                // Layer 1: Blurred Background (Immersive effect)
                GeometryReader { proxy in
                    if let thumbUrl = rootNode.post.thumbnailUrl(board: board) {
                        AsyncImage(url: thumbUrl) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 30) // Soft blur
                                .overlay(Color.black.opacity(0.3)) // Slight darken
                        } placeholder: {
                            Color.black
                        }
                        // Oversized background to cover safe areas during scroll bounce.
                        .frame(width: proxy.size.width, height: proxy.size.height + 200)
                        .position(x: proxy.size.width / 2, y: (proxy.size.height / 2) - 100)
                    }
                }
                .allowsHitTesting(false) // Clicks pass through to the main image
                .ignoresSafeArea(edges: .top) // Extends behind the notch/status bar
                
                // Layer 2: Main Media (High resolution image or video)
                MediaView(post: rootNode.post, board: board)
                    .onTapGesture { openSlideshow(at: 0) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // Explicitly set the frame of the stack to the calculated height.
            .frame(width: screenWidth, height: imageHeight)
        }
        // Use aspect ratio to ensure the GeometryReader itself takes up the right amount of space.
        .aspectRatio(rootNode.post.aspectRatio, contentMode: .fit)
        .frame(maxHeight: 500)
        .ignoresSafeArea(edges: .top)
    }
    
    /// Main text section for the post: includes name, date, subject, and the comment body.
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Horizontal metadata bar (Name, Date, ID)
            postMetadataView
            
            // Post Subject (Title) - Only shown if present.
            if let subject = rootNode.post.sub, !subject.isEmpty {
                Text(subject.decodedHTML)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(3)
            }
            
            // SmartText is a custom view that handles greentext and reply links.
            SmartText(text: rootNode.post.cleanComment, lineLimit: isAbbreviated ? 12 : nil)
                .font(.system(.body, design: .serif)).lineSpacing(4)
            
            // "Read More" button appears if the comment is too long.
            if rootNode.post.cleanComment.components(separatedBy: "\n").count > 12 {
                readMoreButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(UIColor.systemBackground))
    }
    
    /// List of reply cards. Each card can be tapped to "drill down" into that reply chain.
    private var repliesArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !rootNode.replies.isEmpty {
                // Header with the total count of replies.
                repliesHeader
                
                // Loop through each reply and create a clickable card.
                ForEach(rootNode.replies) { childNode in
                    NavigationLink(destination: ThreadDetailView(board: board, rootNode: childNode, depth: depth + 1, onRefresh: onRefresh)) {
                        ReplyStackCard(node: childNode, board: board)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 4)
                }
                // Extra space at the end of the list.
                Color.clear.frame(height: 20)
            }
        }
        .background(Color.mainBackground)
    }

    /// Horizontal metadata bar containing poster name, post date, and post ID.
    private var postMetadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                // Group: Name • Date
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
                
                // Post Number (#1234567)
                Text("#\(String(rootNode.post.no))")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(Theme.radiusXS)
            }
            
            // Filename display for attachments.
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

    /// Toggles the expanded view of the comment.
    private var readMoreButton: some View {
        Button { withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) { isAbbreviated.toggle() } } label: {
            Text(isAbbreviated ? "READ MORE" : "SHOW LESS").font(.system(size: 12, weight: .black))
                .padding(.vertical, 8).padding(.horizontal, 16).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(Theme.radiusSmall)
        }
    }

    /// Visual header for the replies section with a stylized counter.
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
                .cornerRadius(Theme.radiusXS)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    /// Helper to recursively flatten the thread structure into a single array.
    private func getAllNodesInThread() -> [ThreadNode] {
        var all = [rootNode]
        func collect(node: ThreadNode) { for reply in node.replies { all.append(reply); collect(node: reply) } }
        collect(node: rootNode)
        return all
    }

    /// Prepares and triggers the slideshow for media viewing.
    private func openSlideshow(at index: Int) {
        self.selectedIndex = index
        self.showSlideshow = true
    }
}

// MARK: - Helpers

/// A reusable SwiftUI Shape that allows rounding specific corners independently.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    /// Modifier to apply a corner radius to selected corners only.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

#Preview {
    NavigationView {
        ThreadDetailView(board: "v", rootNode: .mockLong, depth: 0)
    }
}
