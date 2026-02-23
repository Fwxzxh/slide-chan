import SwiftUI

/// A vertically scrolling feed that displays all images and videos found in a specific thread.
/// It provides context for each file, such as the post ID and the number of replies.
struct ThreadGalleryView: View {
    // MARK: - Properties
    
    /// The flattened tree of all nodes in the thread.
    let nodes: [ThreadNode]
    /// The ID of the original post (thread starter).
    let rootId: Int
    /// Short board ID (e.g., "v").
    let board: String
    
    @Environment(\.dismiss) private var dismiss
    
    /// Logic for infinite scrolling: how many items are currently rendered.
    @State private var visibleItemsCount = 15
    /// Tracking for the modal full-screen slideshow.
    @State private var selectedIndex = 0
    @State private var showSlideshow = false
    
    /// Filter: Only show direct replies to the OP.
    @State private var onlyDirectReplies = false
    
    /// Tracks scroll position to conditionally show toolbar title
    @State private var scrollOffset: CGFloat = 0
    
    /// Computes a flat list of unique posts that actually contain media.
    private var mediaNodes: [ThreadNode] {
        var seen = Set<Int>()
        var unique: [ThreadNode] = []
        
        // Find the root node in our nodes array to identify its direct children
        let rootNode = nodes.first { $0.post.no == rootId }
        let directChildIds = Set(rootNode?.replies.map { $0.post.no } ?? [])
        
        for node in nodes {
            if onlyDirectReplies {
                // We include the post if it IS the rootId OR if it is a DIRECT child of rootNode
                guard node.post.no == rootId || directChildIds.contains(node.post.no) else { continue }
            }
            
            if node.post.hasFile && !seen.contains(node.post.no) {
                seen.insert(node.post.no)
                unique.append(node)
            }
        }
        return unique
    }
    
    var body: some View {
        ScrollView {
            // Invisible detector for scroll position
            GeometryReader { proxy in
                let minY = proxy.frame(in: .named("galleryScroll")).minY
                Color.clear
                    .onChange(of: minY) { _, newValue in
                        scrollOffset = newValue
                    }
            }
            .frame(height: 0)

            // LazyVStack only renders items as they are scrolled into view, saving memory.
            LazyVStack(spacing: 24) {
                // Header with total count as a subtitle
                VStack(spacing: 4) {
                    Text("Gallery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(mediaNodes.count) media files")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // The main feed of media items
                contentStream
                
                // Show a spinner at the bottom if there are more items to load
                if visibleItemsCount < mediaNodes.count {
                    ProgressView()
                        .padding(.vertical, 30)
                }
            }
            .padding(.bottom, 60)
        }
        .coordinateSpace(name: "galleryScroll")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Gallery")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(mediaNodes.count) files")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .opacity(scrollOffset < -60 ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: scrollOffset)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onlyDirectReplies.toggle()
                        visibleItemsCount = 15 // Reset scroll on filter change
                    }
                } label: {
                    // List indent icon for the whole tree, Arrow down-right for direct replies
                    Image(systemName: onlyDirectReplies ? "arrow.turn.down.right" : "list.bullet.indent")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(onlyDirectReplies ? .blue : .primary)
                }
            }
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            // Reuses the same FullScreenMediaView as the thread detail.
            FullScreenMediaView(
                allMediaPosts: mediaNodes.map { $0.post },
                board: board,
                currentIndex: $selectedIndex
            )
            .presentationBackground(.clear)
        }
    }
    
    // MARK: - View Components

    /// Iterates through the media list and builds the UI for each item.
    private var contentStream: some View {
        ForEach(Array(mediaNodes.prefix(visibleItemsCount).enumerated()), id: \.element.post.no) { index, node in
            VStack(alignment: .leading, spacing: 10) {
                
                // 1. Large Media Preview
                MediaView(post: node.post, board: board)
                    .cornerRadius(Theme.radiusMedium)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tapping the image opens the slideshow at the correct index.
                        self.selectedIndex = index
                        self.showSlideshow = true
                    }
                
                // 2. File and Context Metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Display filename (e.g., sample.jpg)
                        if let filename = node.post.filename {
                            Text(filename + (node.post.ext ?? ""))
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        
                        // Badge showing how many people replied to this specific post.
                        if node.replies.count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                Text("\(node.replies.count)")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.teal.opacity(0.15))
                            .cornerRadius(Theme.radiusSmall)
                        }
                    }
                    
                    // 3. Navigation Link to view the post in its original thread location.
                    HStack(spacing: 12) {
                        NavigationLink(destination: ThreadDetailView(board: board, rootNode: node, opID: rootId, parentID: rootId, depth: 1, onRefresh: nil)) {
                            Label("View Context", systemImage: "arrow.right.circle")
                                .font(.caption.bold())
                        }
                        
                        PostIDBadge(postNumber: node.post.no)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .onAppear {
                // When the last visible item appears, load the next batch of 15.
                if index == visibleItemsCount - 1 {
                    loadMore()
                }
            }
        }
    }
    
    // MARK: - Logic

    /// Increases the number of visible items (infinite scroll implementation).
    private func loadMore() {
        if visibleItemsCount < mediaNodes.count {
            visibleItemsCount += 15
        }
    }
}

#Preview {
    NavigationStack {
        ThreadGalleryView(
            nodes: [
                .mock,
                ThreadNode(post: .mockNoSubject),
                ThreadNode(post: .mockManyStats),
                .mockLong,
                .mockLongFile
            ],
            rootId: Post.mock.no,
            board: "preview"
        )
    }
}
