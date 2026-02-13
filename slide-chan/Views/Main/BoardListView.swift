import SwiftUI

/// Main view displaying the list of all available boards.
struct BoardListView: View {
    @StateObject private var viewModel = BoardViewModel.shared
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false

    /// Filtered boards based on search text and favorites.
    var filteredBoards: [Board] {
        let boards = viewModel.boards
        
        // If searching, show all matches mixed to simplify discovery
        if !searchText.isEmpty {
            return boards.filter {
                $0.board.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // If not searching, return boards that are NOT favorites for the main section
        return boards.filter { !viewModel.isFavorite($0) }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.boards.isEmpty {
                    ProgressView("Loading boards...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.fetchBoards()
                        }
                    }
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
            .animation(.default, value: viewModel.favoriteBoardIDs) // Animate favorite changes
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - View Components

    /// The list containing bookmarks, favorites, and all boards.
    private var boardsList: some View {
        List {
            // Bookmarked Threads
            if !viewModel.bookmarks.isEmpty && searchText.isEmpty {
                    Section(header: Text("Bookmarked Threads")) {
                        ForEach(viewModel.bookmarks) { bookmark in
                            BookmarkRow(bookmark: bookmark) {
                                viewModel.toggleBookmark(board: bookmark.board, threadId: bookmark.threadId, subject: nil, previewText: nil)
                            }
                        }
                    }
            }

            // Favorites Section
            if !viewModel.favoriteBoards.isEmpty && searchText.isEmpty {
                Section(header: Text("Favorites")) {
                    ForEach(viewModel.favoriteBoards) { board in
                        navigationLink(for: board)
                    }
                }
            }

            // All Boards Section
            Section(header: Text(searchText.isEmpty ? "All Boards" : "Results")) {
                ForEach(filteredBoards) { board in
                    navigationLink(for: board)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Generates a navigation link for a given board.
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

    /// Toolbar item for toggling dark mode.
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

    /// Toolbar item for filtering boards (e.g., SFW only).
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
