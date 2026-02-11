import SwiftUI

struct SmartText: View {
    let text: String
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

    /// Crea un AttributedString con estilos y detección de enlaces
    private func attributedString(for line: String) -> AttributedString {
        var attrString = AttributedString(line)
        attrString.foregroundColor = .primary

        // 1. Estilo de cita (Greentext) - Suele ser toda la línea
        if line.starts(with: ">") && !line.starts(with: ">>") {
            attrString.foregroundColor = .green
        }

        // 2. Detección de menciones (>>12345) en cualquier parte del texto
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

        // 3. Detección de enlaces URL
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
