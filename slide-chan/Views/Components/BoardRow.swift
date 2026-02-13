import SwiftUI

/// A row view representing a single 4chan board.
struct BoardRow: View {
    let board: Board
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(board.displayName)
                        .font(.headline)
                    
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.appAccent)
                    }

                    if !board.isWorkSafe {
                        Text("NSFW")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                if board.meta_description != nil {
                    SmartText(text: board.cleanDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        BoardRow(
            board: Board(
                board: "v",
                title: "Video Games",
                ws_board: 1,
                per_page: 15,
                pages: 10,
                meta_description: "Video Games channel",
                max_filesize: 4096,
                max_comment_chars: 2000,
                image_limit: 150,
                cooldowns: nil
            ),
            isFavorite: true,
            toggleFavorite: {}
        )
    }
}
