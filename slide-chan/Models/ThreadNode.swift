import Foundation

/// Represents a node in a thread's tree structure.
class ThreadNode: Identifiable {
    /// Unique post number.
    let id: Int
    /// The actual post data.
    let post: Post
    /// Posts that explicitly reply to this node.
    var replies: [ThreadNode]
    /// Posts that this node is quoting/replying to.
    var quotes: [ThreadNode]

    init(post: Post, replies: [ThreadNode] = [], quotes: [ThreadNode] = []) {
        self.id = post.no
        self.post = post
        self.replies = replies
        self.quotes = quotes
    }
}
