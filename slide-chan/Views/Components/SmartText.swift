import SwiftUI

/// A specialized text component that parses and styles 4chan-specific syntax.
/// It automatically detects "Greentext" (quotes), post mentions (>>12345), and URLs.
struct SmartText: View {
    // MARK: - Properties
    
    /// The original HTML-decoded comment string.
    let text: String
    
    /// The ID of the Original Poster (OP) of the thread.
    var opID: Int? = nil
    /// The ID of the post currently being viewed as the main context.
    var activeID: Int? = nil

    var body: some View {
        // We use a single Text view with a concatenated AttributedString to ensure
        // standard SwiftUI lineLimit and truncation (...) work correctly across all lines.
        Text(fullAttributedString())
            .font(.subheadline)
    }

    // MARK: - Parser Logic

    private static let mentionRegex = try? NSRegularExpression(pattern: ">>([0-9]+)")
    private static let urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    /// Concatenates all lines into a single AttributedString with proper formatting.
    private func fullAttributedString() -> AttributedString {
        var attrString = AttributedString(text)
        attrString.foregroundColor = .primary
        
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        // 1. Greentext detection (Line by line)
        nsText.enumerateSubstrings(in: fullRange, options: .byLines) { substring, substringRange, _, _ in
            if let line = substring, line.starts(with: ">") && !line.starts(with: ">>") {
                if let range = Range(substringRange, in: self.text),
                   let attrRange = Range(range, in: attrString) {
                    attrString[attrRange].foregroundColor = .green
                }
            }
        }
        
        // 2. Web URL detection
        if let detector = Self.urlDetector {
            let matches = detector.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if let range = Range(match.range, in: self.text),
                   let attrRange = Range(range, in: attrString) {
                    attrString[attrRange].foregroundColor = .blue
                    attrString[attrRange].underlineStyle = .single
                    attrString[attrRange].link = match.url
                }
            }
        }
        
        // 3. Post Mention detection (e.g., >>123456789)
        if let regex = Self.mentionRegex {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            let uniqueIds = Set(matches.compactMap { Int(nsText.substring(with: $0.range(at: 1))) })
            let totalUniqueMentions = uniqueIds.count
            
            // Process matches in reverse to safely insert "(OP)" labels
            for match in matches.reversed() {
                if let range = Range(match.range, in: self.text),
                   let attrRange = Range(range, in: attrString) {
                    
                    let mentionContent = nsText.substring(with: match.range(at: 1))
                    let mentionedId = Int(mentionContent)
                    
                    if let mentionedId = mentionedId {
                        let isOP = mentionedId == opID
                        let isActive = mentionedId == activeID
                        
                        if isActive && !isOP && totalUniqueMentions > 1 {
                            attrString[attrRange].foregroundColor = .orange
                            attrString[attrRange].backgroundColor = .orange.opacity(0.1)
                            attrString[attrRange].font = .subheadline.bold()
                        } else {
                            attrString[attrRange].foregroundColor = .red
                            attrString[attrRange].font = .subheadline.bold()
                        }
                        
                        if isOP {
                            var opLabel = AttributedString(" (OP)")
                            opLabel.font = .system(size: 10, weight: .black)
                            opLabel.foregroundColor = .secondary
                            attrString.insert(opLabel, at: attrRange.upperBound)
                        }
                    }
                }
            }
        }
        
        return attrString
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        SmartText(text: ">Greentext example\nRegular text with >>12345 reference.\nCheck out https://4chan.org")
        
        SmartText(text: "Line 1\nLine 2\nLine 3 (Hidden)")
            .lineLimit(2)
    }
    .padding()
}
