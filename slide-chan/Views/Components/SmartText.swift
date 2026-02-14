import SwiftUI

/// A specialized text component that parses and styles 4chan-specific syntax.
/// It automatically detects "Greentext" (quotes), post mentions (>>12345), and URLs.
struct SmartText: View {
    // MARK: - Properties
    
    /// The original HTML-decoded comment string.
    let text: String

    var body: some View {
        // We use a single Text view with a concatenated AttributedString to ensure
        // standard SwiftUI lineLimit and truncation (...) work correctly across all lines.
        Text(fullAttributedString())
            .font(.subheadline)
    }

    // MARK: - Parser Logic

    /// Concatenates all lines into a single AttributedString with proper formatting.
    private func fullAttributedString() -> AttributedString {
        var result = AttributedString("")
        let lines = text.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            let attrLine = attributedString(for: line)
            result.append(attrLine)
            
            // Re-insert newlines between segments
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return result
    }

    /// Converts a single line of string into an AttributedString with multiple styles.
    private func attributedString(for line: String) -> AttributedString {
        var attrString = AttributedString(line)
        attrString.foregroundColor = .primary

        // 1. Greentext detection
        if line.starts(with: ">") && !line.starts(with: ">>") {
            attrString.foregroundColor = .green
        }

        // 2. Post Mention detection (e.g., >>123456789)
        let mentionPattern = ">>([0-9]+)"
        if let regex = try? NSRegularExpression(pattern: mentionPattern) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            
            for match in matches {
                if let range = Range(match.range, in: line),
                   let attrRange = Range(range, in: attrString) {
                    attrString[attrRange].foregroundColor = .red
                    attrString[attrRange].font = .subheadline.bold()
                }
            }
        }

        // 3. Web URL detection
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: line),
               let attrRange = Range(range, in: attrString) {
                attrString[attrRange].foregroundColor = .blue
                attrString[attrRange].underlineStyle = .single
                attrString[attrRange].link = match.url
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
