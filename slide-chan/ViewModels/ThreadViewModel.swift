import Foundation
import Combine

/// ViewModel for a single thread, managing its posts and hierarchical structure.
@MainActor
class ThreadViewModel: ObservableObject {
    /// The flat list of posts in the thread.
    @Published var posts: [Post] = []
    /// The root node of the thread's comment tree.
    @Published var rootNode: ThreadNode?
    /// Indicates if a network request is in progress.
    @Published var isLoading: Bool = false
    /// Holds the error message if the last request failed.
    @Published var errorMessage: String?

    private let board: String
    private let threadId: Int
    private let apiService: APIServiceProtocol

    init(board: String, threadId: Int, apiService: APIServiceProtocol = APIService.shared) {
        self.board = board
        self.threadId = threadId
        self.apiService = apiService
    }

    /// Fetches all posts from a specific thread and builds the hierarchical tree.
    func fetchThread() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedPosts = try await apiService.fetchThread(board: board, threadId: threadId)
            self.posts = fetchedPosts
            buildTree(from: fetchedPosts)
            self.isLoading = false
        } catch {
            self.errorMessage = "Error loading thread: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    /// Converts the flat list of 4chan posts into a tree structure.
    private func buildTree(from allPosts: [Post]) {
        guard let op = allPosts.first else {
            self.rootNode = nil
            return
        }

        // 1. Create a dictionary of all posts wrapped in nodes for fast access
        let nodes = allPosts.reduce(into: [Int: ThreadNode]()) { dict, post in
            dict[post.no] = ThreadNode(post: post)
        }

        // 2. Relate each post with its parents and children
        for post in allPosts {
            guard let currentNode = nodes[post.no] else { continue }
            let quotedIds = Set(post.replyIds())

            // Track who this post is quoting
            for qId in quotedIds {
                if let quotedNode = nodes[qId], qId != post.no {
                    currentNode.quotes.append(quotedNode)
                }
            }

            // Determine the "Primary Parent" for the visual tree hierarchy
            // Priority: The highest quoted ID that exists in this thread, or the OP
            let validQuotes = quotedIds.filter { nodes[$0] != nil && $0 != post.no }
            let primaryParentId = validQuotes.max() ?? op.no
            
            if post.no != op.no {
                nodes[primaryParentId]?.replies.append(currentNode)
            }
        }

        // 3. Assign the root node
        self.rootNode = nodes[op.no]
    }

    /// Refreshes the thread's posts.
    func refresh() async {
        await fetchThread()
    }
}
