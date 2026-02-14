import SwiftUI

/// Main entry point view that displays a searchable list of all 4chan boards.
/// It includes sections for bookmarked threads, favorite boards, and the full directory.
struct BoardListView: View {
    // MARK: - State Properties
    
    /// The main logic controller for board data. @StateObject ensures it lives as long as the view.
    @StateObject private var viewModel = BoardViewModel.shared
    /// Holds the current string typed in the search bar.
    @State private var searchText = ""
    /// Persisted user preference for dark/light mode across app launches.
    @AppStorage("isDarkMode") private var isDarkMode = false

    /// Computes which boards to show based on search queries and favorite status.
    var filteredBoards: [Board] {
        let boards = viewModel.boards
        
        // If the user is searching, we show all matches regardless of favorites.
        if !searchText.isEmpty {
            return boards.filter {
                $0.board.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // In normal view, we only show non-favorites here (favorites have their own section).
        return boards.filter { !viewModel.isFavorite($0) }
    }

    var body: some View {
        // NavigationView provides the stack-based navigation and top navigation bar.
        NavigationView {
            // Group is used to return a single view type even if we have if/else logic inside.
            Group {
                if viewModel.isLoading && viewModel.boards.isEmpty {
                    // Loading spinner
                    ProgressView("Loading boards...")
                } else if let errorMessage = viewModel.errorMessage {
                    // Custom error component with a retry button
                    ErrorView(message: errorMessage) {
                        Task { await viewModel.fetchBoards() }
                    }
                } else {
                    // The actual list of boards
                    boardsList
                }
            }
            .navigationTitle("Boards") // Sets the text at the top of the screen
            .searchable(text: $searchText, prompt: "Search boards...") // Adds the native iOS search bar
            .toolbar {
                // UI elements placed in the navigation bar
                darkModeToolbarItem
                filterToolbarItem
            }
            .task {
                // Triggers async code when the view first appears
                if viewModel.boards.isEmpty {
                    await viewModel.fetchBoards()
                }
            }
            .refreshable {
                // Enables the "pull-to-refresh" gesture
                await viewModel.fetchBoards()
            }
            .animation(.default, value: viewModel.favoriteBoardIDs) // Animates rows when they move between sections
        }
        // Force the app theme based on the user preference
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - Sub-Views

    /// Builds the structured list using Section views for logical grouping.
    private var boardsList: some View {
        // List is the equivalent of a TableView, optimized for many rows.
        List {
            // 1. Bookmarked Threads Section
            if !viewModel.bookmarks.isEmpty && searchText.isEmpty {
                Section(header: Text("Bookmarked Threads")) {
                    ForEach(viewModel.bookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark) {
                            viewModel.toggleBookmark(board: bookmark.board, threadId: bookmark.threadId, subject: nil, previewText: nil)
                        }
                    }
                }
            }

            // 2. Favorites Section (Quick access to preferred boards)
            if !viewModel.favoriteBoards.isEmpty && searchText.isEmpty {
                Section(header: Text("Favorites")) {
                    ForEach(viewModel.favoriteBoards) { board in
                        navigationLink(for: board)
                    }
                }
            }

            // 3. Main Directory Section
            Section(header: Text(searchText.isEmpty ? "All Boards" : "Results")) {
                ForEach(filteredBoards) { board in
                    navigationLink(for: board)
                }
            }
        }
        .listStyle(.insetGrouped) // Gives the classic iOS "rounded boxes" look to the list
    }

    /// Creates a row that, when tapped, navigates to the specific board's index.
    private func navigationLink(for board: Board) -> some View {
        NavigationLink(destination: BoardIndexView(board: board.board)) {
            // BoardRow is a reusable component for the board's visual representation
            BoardRow(
                board: board,
                isFavorite: viewModel.isFavorite(board),
                toggleFavorite: {
                    viewModel.toggleFavorite(board)
                }
            )
        }
    }

    /// Button in the toolbar to switch between dark and light modes.
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

    /// Menu in the toolbar to filter content (e.g., hiding NSFW boards).
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
