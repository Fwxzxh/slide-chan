import SwiftUI

struct BoardListView: View {
    @StateObject private var viewModel = BoardViewModel.shared
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false

    var filteredBoards: [Board] {
        let boards = viewModel.boards
        
        // Si estamos buscando, mostramos todo mezclado para facilitar la búsqueda
        if !searchText.isEmpty {
            return boards.filter {
                $0.board.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Si no buscamos, solo devolvemos los que NO son favoritos para la sección principal
        return boards.filter { !viewModel.isFavorite($0) }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.boards.isEmpty {
                    ProgressView("Loading boards...")
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else {
                    boardsList
                }
            }
            .navigationTitle("Boards")
            .searchable(text: $searchText, prompt: "Search boards...")
            .toolbar {
                darkModeToolbarItem
                filterToolbarItem
            }
            .task {
                if viewModel.boards.isEmpty {
                    await viewModel.fetchBoards()
                }
            }
            .refreshable {
                await viewModel.fetchBoards()
            }
            .animation(.default, value: viewModel.favoriteBoardIDs) // Anima cambios en favoritos
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - View Components

    private var boardsList: some View {
        List {
            // Bookmarked Threads
            if !viewModel.bookmarks.isEmpty && searchText.isEmpty {
                Section(header: Text("Bookmarked Threads")) {
                    ForEach(viewModel.bookmarks) { bookmark in
                        NavigationLink(destination: ThreadLoadingView(board: bookmark.board, threadId: bookmark.threadId)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("/\(bookmark.board)/")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .cornerRadius(4)
                                    
                                    if let subject = bookmark.subject, !subject.isEmpty {
                                        Text(subject)
                                            .font(.subheadline.bold())
                                            .lineLimit(1)
                                    } else {
                                        Text("Thread #\(String(bookmark.threadId))")
                                            .font(.subheadline.bold())
                                    }
                                }
                                
                                if let preview = bookmark.previewText, !preview.isEmpty {
                                    Text(preview)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.toggleBookmark(board: bookmark.board, threadId: bookmark.threadId, subject: nil, previewText: nil)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Sección de Favoritos
            if !viewModel.favoriteBoards.isEmpty && searchText.isEmpty {
                Section(header: Text("Favorites")) {
                    ForEach(viewModel.favoriteBoards) { board in
                        navigationLink(for: board)
                    }
                }
            }

            // Sección de Todos los Tablones
            Section(header: Text(searchText.isEmpty ? "All Boards" : "Results")) {
                ForEach(filteredBoards) { board in
                    navigationLink(for: board)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func navigationLink(for board: Board) -> some View {
        NavigationLink(destination: BoardIndexView(board: board.board)) {
            BoardRow(
                board: board,
                isFavorite: viewModel.isFavorite(board),
                toggleFavorite: {
                    viewModel.toggleFavorite(board)
                }
            )
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.fetchBoards()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var darkModeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isDarkMode.toggle()
            } label: {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(isDarkMode ? .yellow : .orange)
            }
        }
    }

    private var filterToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Toggle(isOn: $viewModel.showOnlySFW) {
                    Label("SFW Only", systemImage: "shield.fill")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }
}

#Preview {
    BoardListView()
}
