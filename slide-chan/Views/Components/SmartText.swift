import SwiftUI

struct SmartText: View {
    let text: String

    var body: some View {
        let lines = text.components(separatedBy: "\n")

        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<lines.count, id: \.self) { index in
                let line = lines[index]
                if line.starts(with: ">") && !line.starts(with: ">>") {
                    Text(line)
                        .foregroundColor(.green)
                } else if line.starts(with: ">>") {
                    Text(line)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                } else {
                    Text(line)
                        .foregroundColor(.primary)
                }
            }
        }
        .font(.subheadline)
    }
}
