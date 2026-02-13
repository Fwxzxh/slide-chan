import SwiftUI

/// A view that renders text with support for Greentext and link detection.
struct SmartText: View {
    /// The raw text to display.
    let text: String
    /// Maximum number of lines to display.
    var lineLimit: Int? = nil

    var body: some View {
        let allLines = text.components(separatedBy: "\n")
        let displayLines = lineLimit != nil ? Array(allLines.prefix(lineLimit!)) : allLines

        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<displayLines.count, id: \.self) { index in
                Text(attributedString(for: displayLines[index]))
            }
            
            if let limit = lineLimit, allLines.count > limit {
                Text("...")
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
    }

    /// Creates an AttributedString with styles and link detection.
    private func attributedString(for line: String) -> AttributedString {
        var attrString = AttributedString(line)
        attrString.foregroundColor = .primary

        // 1. Greentext style - Typically an entire line starting with '>'
        if line.starts(with: ">") && !line.starts(with: ">>") {
            attrString.foregroundColor = .green
        }

        // 2. Mention detection (>>12345) anywhere in the text
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

        // 3. URL detection
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
        SmartText(text: ">Greentext example\nRegular text with >>12345 reference.\nhttps://google.com link")
        
        SmartText(text: "Line 1\nLine 2\nLine 3 (Hidden)", lineLimit: 2)
    }
    .padding()
}
