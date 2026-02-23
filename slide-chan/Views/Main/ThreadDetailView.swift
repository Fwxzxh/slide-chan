import SwiftUI

/// Detailed view for a single thread, displaying the Original Post (OP) and its replies.
/// It uses a recursive structure to allow navigating into reply chains.
struct ThreadDetailView: View {
    // MARK: - Properties
    
    /// The short ID of the board (e.g., "g").
    let board: String
    /// The thread node representing the current post and its nested replies.
    let rootNode: ThreadNode
    /// The ID of the Original Poster (OP) post.
    let opID: Int
    /// The ID of the post we are coming from (for highlighting context).
    let parentID: Int?
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
    
    /// Dynamic top inset to account for Safe Area + Navigation Bar.
    @State private var topInset: CGFloat = 100 // Default safe start to prevent overlap before measurement
    /// Tracking for pull-to-view-media
    @State private var hasTriggeredPullMedia = false

    var body: some View {
        ZStack {
            // 1. Invisible Measurement Layer
            // This GeometryReader respects the safe area (because ZStack does by default).
            // Its global minY gives us the exact bottom position of the Navigation Bar / Safe Area.
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        let y = proxy.frame(in: .global).minY
                        if y > 0 { topInset = y }
                    }
                    .onChange(of: proxy.frame(in: .global).minY) { _, newValue in
                        if newValue > 0 { topInset = newValue }
                    }
            }
            .allowsHitTesting(false)
            
            // 2. Main ScrollView
            // Ignores safe area to allow the blurred background to fill the screen top.
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Pull trigger detector
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .named("scroll")).minY
                        Color.clear
                            .onChange(of: minY) { _, newValue in
                                handlePullToMedia(offset: newValue)
                            }
                    }
                    .frame(height: 0)

                    // Header Section: Shows the image or video of the OP.
                    if rootNode.post.hasFile {
                        headerArea(topPadding: topInset)
                    } else {
                        // Ensure content starts below the navigation area when no media is present.
                        Color.clear.frame(height: topInset)
                    }
                    
                    // Content Section: Metadata, Title (Subject), and Comment.
                    contentArea
                    
                    // Replies Section: Lists all posts that replied to this one.
                    repliesArea
                }
                .containerRelativeFrame(.horizontal)
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
        }
        .background(Color(UIColor.systemBackground))
        // Dynamic navigation title showing either the subject or the thread ID.
        .navigationTitle(depth == 0 ? (rootNode.post.sub?.decodedHTML ?? "Thread #\(String(rootNode.id))") : "[\(depth)] Replies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                    NavigationLink(destination: ThreadGalleryView(nodes: allThreadNodes, rootId: rootNode.post.no, board: board)) {
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
                .presentationBackground(.clear)
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
    private func headerArea(topPadding: CGFloat) -> some View {
        // The MediaView dictates the height of the header area.
        MediaView(post: rootNode.post, board: board)
            .onTapGesture { openSlideshow(at: 0) }
            .aspectRatio(rootNode.post.aspectRatio, contentMode: .fit)
            // Add top padding to respect the safe area / nav bar visually
            .padding(.top, topPadding)
            // Limit the maximum height (including padding)
            .frame(maxHeight: 500 + topPadding)
            // Expand to full width so the background covers the screen horizontally
            .frame(maxWidth: .infinity)
            .background {
                // Immersive blurred background
                if let thumbUrl = rootNode.post.thumbnailUrl(board: board) {
                    CachedImage(url: thumbUrl, contentMode: .fill) {
                        Color.black
                    }
                    .scaleEffect(1.5)
                    .blur(radius: 40)
                    .overlay(Color.black.opacity(0.4))
                    // Ensure the background fills the available space
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped() // Clip any background overflow
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
            SmartText(text: rootNode.post.cleanComment, opID: opID, activeID: parentID)
                .lineLimit(isAbbreviated ? 20 : nil)
                .lineSpacing(4)
            
            // "Read More" button appears if the comment is too long.
            // Thresholds synced to 20 lines to match the lineLimit.
            if rootNode.post.cleanComment.count > 1000 || rootNode.post.cleanComment.components(separatedBy: "\n").count > 20 {
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
                    NavigationLink(destination: ThreadDetailView(board: board, rootNode: childNode, opID: opID, parentID: rootNode.id, depth: depth + 1, onRefresh: onRefresh)) {
                        ReplyStackCard(node: childNode, board: board, opID: opID, activeID: rootNode.id)
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
                PostIDBadge(postNumber: rootNode.post.no)
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

    /// Handles the "Pull Down to View Media" logic.
    private func handlePullToMedia(offset: CGFloat) {
        // Only trigger if we are pulling down significantly (e.g. > 100px)
        // and only if the current post actually has media.
        guard rootNode.post.hasFile, !showSlideshow, !hasTriggeredPullMedia else {
            if offset < 20 { hasTriggeredPullMedia = false }
            return
        }

        if offset > 120 {
            hasTriggeredPullMedia = true
            HapticManager.notification(type: .success)
            openSlideshow(at: 0)
        }
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
        ThreadDetailView(board: "preview", rootNode: .mockLong, opID: ThreadNode.mockLong.id, parentID: nil, depth: 0)
    }
}
