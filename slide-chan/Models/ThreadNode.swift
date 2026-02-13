import Foundation

/// Represents a node in a thread's tree structure.
///
/// Defined as a class (Reference Type) to allow efficient tree construction
/// and avoid "overlapping access" errors during mutation.
class ThreadNode: Identifiable {
    let id: Int
    let post: Post
    var replies: [ThreadNode]

    init(post: Post, replies: [ThreadNode] = []) {
        self.id = post.no
        self.post = post
        self.replies = replies
    }
}
