import SwiftUI

/// A gallery view displaying all media files within a thread.
struct ThreadGalleryView: View {
    /// List of all nodes in the thread.
    let nodes: [ThreadNode]
    /// The short ID of the board.
    let board: String
    @Environment(\.dismiss) private var dismiss
    @State private var visibleItemsCount = 15
    @State private var selectedIndex = 0
    @State private var showSlideshow = false
    
    /// Filters nodes to only include unique posts with file attachments.
    private var mediaNodes: [ThreadNode] {
        var seen = Set<Int>()
        var unique: [ThreadNode] = []
        for node in nodes {
            if node.post.hasFile && !seen.contains(node.post.no) {
                seen.insert(node.post.no)
                unique.append(node)
            }
        }
        return unique
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                Text("\(mediaNodes.count) media files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)

                contentStream
                
                if visibleItemsCount < mediaNodes.count {
                    ProgressView()
                        .padding(.vertical, 40)
                }
            }
            .padding(.bottom, 60)
        }
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showSlideshow) {
            FullScreenMediaView(
                allMediaPosts: mediaNodes.map { $0.post },
                board: board,
                currentIndex: $selectedIndex
            )
        }
    }
    
    /// Stream of media views with context metadata.
    private var contentStream: some View {
        ForEach(Array(mediaNodes.prefix(visibleItemsCount).enumerated()), id: \.element.post.no) { index, node in
            VStack(alignment: .leading, spacing: 16) {
                MediaView(post: node.post, board: board)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedIndex = index
                        self.showSlideshow = true
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let filename = node.post.filename {
                            Text(filename + (node.post.ext ?? ""))
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        
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
                            .cornerRadius(6)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: ThreadDetailView(board: board, rootNode: node, depth: 1, onRefresh: nil)) {
                            Label("View Context", systemImage: "arrow.right.circle")
                                .font(.caption.bold())
                        }
                        
                        Text("#\(String(node.post.no))")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .onAppear {
                if index == visibleItemsCount - 1 {
                    loadMore()
                }
            }
        }
    }
    
    /// Increases the number of visible items (infinite scroll).
    private func loadMore() {
        if visibleItemsCount < mediaNodes.count {
            visibleItemsCount += 15
        }
    }
}
