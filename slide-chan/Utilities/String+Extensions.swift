import Foundation

/// General string manipulations and utility helpers.
extension String {
    /// Decodes common HTML entities used by the 4chan API.
    var decodedHTML: String {
        guard self.contains("&") else { return self }
        
        var decoded = self
        let entities = [
            "&quot;": "\"",
            "&amp;": "&",
            "&#039;": "'",
            "&apos;": "'",
            "&gt;": ">",
            "&lt;": "<",
            "&nbsp;": " ",
            "&trade;": "™",
            "&copy;": "©",
            "&reg;": "®"
        ]
        
        for (entity, replacement) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: replacement)
        }
        
        return decoded
    }
}
