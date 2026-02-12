import SwiftUI

struct ThreadGalleryView: View {
    let nodes: [ThreadNode]
    let board: String
    @Environment(\.dismiss) private var dismiss
    @State private var visibleItemsCount = 15
    @State private var selectedIndex = 0
    @State private var showSlideshow = false
    
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
                            Label("\(node.replies.count)", systemImage: "bubble.left.fill")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
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
    
    private func loadMore() {
        if visibleItemsCount < mediaNodes.count {
            visibleItemsCount += 15
        }
    }
}
