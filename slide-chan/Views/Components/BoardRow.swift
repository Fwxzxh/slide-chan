import SwiftUI

struct BoardRow: View {
    let board: Board
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(board.displayName)
                    .font(.headline)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            if board.meta_description != nil {
                SmartText(text: board.cleanDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleFavorite()
            } label: {
                Label(
                    isFavorite ? "Quitar" : "Favorito",
                    systemImage: isFavorite ? "star.slash.fill" : "star.fill"
                )
            }
            .tint(.yellow)
        }
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
