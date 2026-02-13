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

        // 1. Create a dictionary of all posts wrapped in nodes (classes) for fast access
        let nodes = allPosts.reduce(into: [Int: ThreadNode]()) { dict, post in
            dict[post.no] = ThreadNode(post: post)
        }

        // 2. Relate each post with its parents (those it cites)
        for post in allPosts {
            guard let currentNode = nodes[post.no] else { continue }
            let quotedIds = post.replyIds()

            // In 4chan, if a post doesn't cite anyone specifically, it is considered a reply to the OP
            if quotedIds.isEmpty && post.no != op.no {
                nodes[op.no]?.replies.append(currentNode)
            } else {
                // Use a Set to avoid duplicates if a post cites the same post multiple times
                for pId in Set(quotedIds) {
                    // Avoid self-citations and verify the cited post exists in this thread
                    if pId != post.no, let parentNode = nodes[pId] {
                        parentNode.replies.append(currentNode)
                    }
                }
            }
        }

        // 3. Assign the root node
        if let opNode = nodes[op.no] {
            self.rootNode = opNode
        }
    }

    /// Refreshes the thread's posts.
    func refresh() async {
        await fetchThread()
    }
}
