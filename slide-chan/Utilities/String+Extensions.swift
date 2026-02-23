import Foundation

/// General string manipulations and utility helpers.
extension String {
    /// Decodes common HTML entities used by the 4chan API.
    var decodedHTML: String {
        guard self.contains("&") else { return self }
        
        // Dictionary of entities and their replacements
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
        
        var decoded = self
        for (entity, replacement) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Handle numeric entities like &#123;
        return decoded.decodeNumericEntities()
    }

    /// Decodes numeric HTML entities (e.g., &#10004;)
    private func decodeNumericEntities() -> String {
        var result = self
        let pattern = "&#([0-9]+);"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.utf16.count))
        
        for match in matches.reversed() {
            if let range = Range(match.range(at: 1), in: self),
               let code = Int(self[range]),
               let scalar = UnicodeScalar(code) {
                let replacementRange = Range(match.range, in: self)!
                result.replaceSubrange(replacementRange, with: String(scalar))
            }
        }
        
        return result
    }
}
