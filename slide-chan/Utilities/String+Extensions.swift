import Foundation

/// General string manipulations and utility helpers.
extension String {
    /// Decodes common HTML entities used by the 4chan API.
    var decodedHTML: String {
        return self.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
