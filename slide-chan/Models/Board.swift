import Foundation

/// Represents a 4chan board.
struct Board: Codable, Identifiable {
    /// The short ID of the board (e.g., "v", "a", "jp").
    let board: String
    var id: String { board }

    /// The full name of the board (e.g., "Video Games").
    let title: String

    /// Whether the board is "Work Safe" (1) or not (0).
    let ws_board: Int?
    
    /// How many threads are on a single index page.
    let per_page: Int?

    /// How many index pages does the board have.
    let pages: Int?

    /// SEO meta description content for a board.
    let meta_description: String?

    /// Maximum file size allowed for non .webm attachments (in KB).
    let max_filesize: Int?

    /// Maximum number of characters allowed in a post comment.
    let max_comment_chars: Int?
    
    /// Maximum number of image replies per thread before image replies are discarded.
    let image_limit: Int?

    /// Cooldown settings for the board.
    let cooldowns: Cooldowns?

    // MARK: - Computed Properties

    /// Returns true if the board is safe for work.
    var isWorkSafe: Bool {
        return ws_board == 1
    }

    /// Formatted name for display in lists (e.g., /v/ - Video Games).
    var displayName: String {
        return "/\(board)/ - \(title)".decodedHTML
    }

    /// Cleaned meta description for display.
    var cleanDescription: String {
        return (meta_description ?? "").decodedHTML
    }
}

/// Represents the cooldown settings for a board.
struct Cooldowns: Codable {
    let threads: Int
    let replies: Int
    let images: Int
}

/// Root structure for decoding the boards list from https://a.4cdn.org/boards.json.
struct BoardsResponse: Codable {
    let boards: [Board]
}
