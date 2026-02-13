import Foundation

/// Represents a single page in a board's catalog.
///
/// The 4chan API returns the catalog as an array of these pages.
struct BoardPage: Codable {
    let page: Int?
    let threads: [Post]?
}
