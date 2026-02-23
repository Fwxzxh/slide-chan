import Foundation

/// Represents a thread bookmarked by the user.
struct BookmarkedThread: Codable, Identifiable, Hashable {
    /// Unique identifier: board_threadId.
    let id: String
    /// The short ID of the board.
    let board: String
    /// The thread ID.
    let threadId: Int
    /// Optional thread subject.
    let subject: String?
    /// Preview text from the OP comment.
    let previewText: String?
    /// When the bookmark was created.
    let timestamp: Date
}
