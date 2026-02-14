import SwiftUI

/// A specialized text component that parses and styles 4chan-specific syntax.
/// It automatically detects "Greentext" (quotes), post mentions (>>12345), and URLs.
struct SmartText: View {
    // MARK: - Properties
    
    /// The original HTML-decoded comment string.
    let text: String
    /// Optional limit on the number of lines shown (used in previews).
    var lineLimit: Int? = nil

    var body: some View {
        // Split the text into individual lines to apply line-by-line styling.
        let allLines = text.components(separatedBy: "\n")
        let displayLines = lineLimit != nil ? Array(allLines.prefix(lineLimit!)) : allLines

        VStack(alignment: .leading, spacing: 2) {
            // Iterate through each line and create a styled Text view.
            ForEach(0..<displayLines.count, id: \.self) { index in
                Text(attributedString(for: displayLines[index]))
            }
            
            // Show an ellipsis (...) if we are truncating the lines.
            if let limit = lineLimit, allLines.count > limit {
                Text("...")
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
    }

    // MARK: - Parser Logic

    /// Converts a single line of string into an AttributedString with multiple styles.
    /// AttributedString allows us to colorize specific parts of a single string.
    private func attributedString(for line: String) -> AttributedString {
        var attrString = AttributedString(line)
        attrString.foregroundColor = .primary

        // 1. Greentext detection
        // Lines starting with '>' (but not '>>') are colored green to indicate a quote.
        if line.starts(with: ">") && !line.starts(with: ">>") {
            attrString.foregroundColor = .green
        }

        // 2. Post Mention detection (e.g., >>123456789)
        // Uses Regular Expressions to find post number references anywhere in the line.
        let mentionPattern = ">>([0-9]+)"
        if let regex = try? NSRegularExpression(pattern: mentionPattern) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            
            for match in matches {
                // If a mention is found, we color it red and make it bold.
                if let range = Range(match.range, in: line),
                   let attrRange = Range(range, in: attrString) {
                    attrString[attrRange].foregroundColor = .red
                    attrString[attrRange].font = .subheadline.bold()
                }
            }
        }

        // 3. Web URL detection
        // Uses the system's DataDetector to find links like https://...
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: line),
               let attrRange = Range(range, in: attrString) {
                // Colorize the link blue and make it clickable.
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
        
        SmartText(text: "Line 1\nLine 2\nLine 3 (Hidden)", lineLimit: 2)
    }
    .padding()
}
