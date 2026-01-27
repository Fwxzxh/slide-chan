import SwiftUI

struct BoardListView: View {
    @StateObject private var viewModel = BoardViewModel()
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false

    var filteredBoards: [Board] {
        if searchText.isEmpty {
            return viewModel.boards
        } else {
            return viewModel.boards.filter {
                $0.board.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.boards.isEmpty {
                    ProgressView("Cargando tablones...")
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else {
                    boardsList
                }
            }
            .navigationTitle("Tablones")
            .searchable(text: $searchText, prompt: "Buscar tablón...")
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
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - View Components

    private var boardsList: some View {
        List {
            // Sección de Favoritos
            if !viewModel.favoriteBoards.isEmpty && searchText.isEmpty {
                Section(header: Text("Favoritos")) {
                    ForEach(viewModel.favoriteBoards) { board in
                        navigationLink(for: board)
                    }
                }
            }

            // Sección de Todos los Tablones
            Section(header: Text(searchText.isEmpty ? "Todos los tablones" : "Resultados")) {
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
            Button("Reintentar") {
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
                    Label("Solo SFW", systemImage: "shield.fill")
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
