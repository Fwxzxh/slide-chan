import Foundation
import UIKit

/// Represents a 4chan post.
struct Post: Codable, Identifiable {
    /// The unique ID of the post ('no' in the API).
    let no: Int

    var id: Int { no }

    /// For replies: the ID of the thread being replied to. For OP: this value is zero.
    let resto: Int?

    /// UNIX timestamp the post was created.
    let time: Int?
    
    /// Date string: MM/DD/YY(Day)HH:MM (:SS on some boards), EST/EDT timezone.
    let now: String?
    
    /// Name the user posted with. Defaults to "Anonymous".
    let name: String?

    /// OP Subject text.
    let sub: String?
    
    /// Comment text (HTML escaped).
    let com: String?
    
    /// Filename as it appeared on the poster's device.
    let filename: String?
    
    /// File extension (e.g., .jpg, .png, .webm).
    let ext: String?
    
    /// Unix timestamp + microtime that an image was uploaded.
    let tim: Int64?
    
    /// Image width dimension.
    let w: Int?
    
    /// Image height dimension.
    let h: Int?
    
    /// Thumbnail image width dimension.
    let tn_w: Int?
    
    /// Thumbnail image height dimension.
    let tn_h: Int?
    
    /// Total number of replies to a thread (OP only).
    let replies: Int?
    
    /// Total number of image replies to a thread (OP only).
    let images: Int?

    /// Calculated aspect ratio for the media attachment.
    var aspectRatio: CGFloat {
        guard let w = w, let h = h, w > 0, h > 0 else { return 1.5 }
        return CGFloat(w) / CGFloat(h)
    }

    let sticky: Int?
    let closed: Int?
    let archived: Int?
    let trip: String?
    let capcode: String?
    let country: String?
    let country_name: String?
    let filedeleted: Int?
    let spoiler: Int?
    let custom_spoiler: Int?

    // MARK: - Helper Properties

    /// Indicates if the post has a valid media attachment.
    var hasFile: Bool {
        return tim != nil && filedeleted != 1
    }

    /// Indicates if the attachment is marked as a spoiler.
    var isSpoiler: Bool {
        return spoiler == 1
    }

    /// Cleans the HTML comment, handling line breaks, tags, and entities.
    var cleanComment: String {
        guard var text = com else { return "" }

        // 1. Handle HTML line breaks
        text = text.replacingOccurrences(of: "<br>", with: "\n")

        // 2. Clean HTML tags (e.g., <span class="quote">)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // 3. Decode HTML entities
        return text.decodedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extracts IDs of posts cited in this comment (e.g., >>12345).
    func replyIds() -> [Int] {
        guard let text = com else { return [] }
        // Detects both >> and &gt;&gt; followed by numbers
        let pattern = "(?:>>|&gt;&gt;)([0-9]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = text as NSString
        let results = regex?.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        return results?.compactMap { Int(nsString.substring(with: $0.range(at: 1))) } ?? []
    }

    /// Generates the URL for the original image.
    func imageUrl(board: String) -> URL? {
        // Special case for previews/testing to show functional images
        if board == "preview" {
            let seed = (tim ?? Int64(no)) % 1000
            return URL(string: "https://picsum.photos/seed/\(seed)/1200/1600")
        }
        guard let tim = tim, let ext = ext else { return nil }
        return APIConstants.imageUrl(board: board, tim: tim, ext: ext)
    }

    /// Generates the URL for the thumbnail image.
    func thumbnailUrl(board: String) -> URL? {
        if board == "preview" {
            let seed = (tim ?? Int64(no)) % 1000
            return URL(string: "https://picsum.photos/seed/\(seed)/200/200")
        }
        if isSpoiler {
            return APIConstants.spoilerThumbnailURL
        }
        guard let tim = tim else { return nil }
        return APIConstants.thumbnailUrl(board: board, tim: tim)
    }

    /// Identifies the media type based on the file extension.
    var mediaType: MediaType {
        guard let ext = ext?.lowercased() else { return .none }
        switch ext {
        case ".jpg", ".jpeg", ".png", ".heic":
            return .image
        case ".gif":
            return .gif
        case ".webm", ".mp4":
            return .video
        case ".pdf":
            return .pdf
        default:
            return .unknown
        }
    }

    /// Supported media types.
    enum MediaType {
        case image
        case gif
        case video
        case pdf
        case none
        case unknown
    }
}

/// Root structure for decoding a thread response.
struct ThreadResponse: Codable {
    let posts: [Post]
}
