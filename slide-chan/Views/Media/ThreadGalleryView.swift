import SwiftUI

struct ThreadGalleryView: View {
    let nodes: [ThreadNode]
    let board: String
    @Environment(\.dismiss) private var dismiss
    @State private var visibleItemsCount = 15
    @State private var selectedIndex = 0
    @State private var showSlideshow = false
    
    // Garantiza que cada post de media aparezca solo una vez
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 40) {
                    headerView(proxy: proxy)
                    
                    contentStream
                    
                    if visibleItemsCount < mediaNodes.count {
                        ProgressView()
                            .padding(.vertical, 40)
                    }
                }
                .padding(.bottom, 60)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.container, edges: .top)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            FullScreenMediaView(
                allMediaPosts: mediaNodes.map { $0.post },
                board: board,
                currentIndex: $selectedIndex
            )
        }
    }
    
    // MARK: - Subviews
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private func headerView(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gallery")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .id("top")
            
            Text("\(mediaNodes.count) media files in this thread")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 110)
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
    
    private var contentStream: some View {
        ForEach(Array(mediaNodes.prefix(visibleItemsCount).enumerated()), id: \.element.post.no) { index, node in
            VStack(alignment: .leading, spacing: 16) {
                MediaView(post: node.post, board: board)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .onTapGesture {
                        self.selectedIndex = index
                        self.showSlideshow = true
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let filename = node.post.filename {
                            Text(filename + (node.post.ext ?? ""))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        
                        if let replies = node.post.replies, replies > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                Text("\(replies)")
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
                            HStack {
                                Text("View Context")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Text("#\(String(node.post.no))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)
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
