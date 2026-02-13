import Foundation

/// Centralized 4chan API constants and URL generators.
struct APIConstants {
    /// Base URL for the JSON API.
    static let baseURL = "https://a.4cdn.org"
    /// Base URL for images and thumbnails.
    static let imageBaseURL = "https://i.4cdn.org"
    /// Base URL for static assets.
    static let staticBaseURL = "https://s.4cdn.org"
    
    /// Returns the URL for the boards list.
    static func boards() -> String {
        return "\(baseURL)/boards.json"
    }
    
    /// Returns the URL for a board's catalog.
    static func catalog(board: String) -> String {
        return "\(baseURL)/\(board)/catalog.json"
    }
    
    /// Returns the URL for a specific thread's posts.
    static func thread(board: String, threadId: Int) -> String {
        return "\(baseURL)/\(board)/thread/\(threadId).json"
    }
    
    /// Generates the URL for an original image.
    static func imageUrl(board: String, tim: Int64, ext: String) -> URL? {
        return URL(string: "\(imageBaseURL)/\(board)/\(String(tim))\(ext)")
    }
    
    /// Generates the URL for an image thumbnail.
    static func thumbnailUrl(board: String, tim: Int64) -> URL? {
        return URL(string: "\(imageBaseURL)/\(board)/\(String(tim))s.jpg")
    }
    
    /// The default placeholder URL for spoiler images.
    static let spoilerThumbnailURL = URL(string: "\(staticBaseURL)/image/spoiler.png")!
}
