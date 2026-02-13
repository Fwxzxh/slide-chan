import SwiftUI

/// View displaying the catalog of threads for a specific board.
struct BoardIndexView: View {
    /// The short ID of the board.
    let board: String
    @StateObject private var viewModel: BoardIndexViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false

    init(board: String) {
        self.board = board
        _viewModel = StateObject(wrappedValue: BoardIndexViewModel(board: board))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView("Loading catalog...")
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                threadsList
            }
        }
        .navigationTitle("/\(board)/")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { isDarkMode.toggle() } label: {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(isDarkMode ? .yellow : .orange)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await viewModel.fetchCatalog() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task { if viewModel.threads.isEmpty { await viewModel.fetchCatalog() } }
        .refreshable { await viewModel.fetchCatalog() }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    /// List of threads in the board.
    private var threadsList: some View {
        List(viewModel.threads) { thread in
            NavigationLink(destination: ThreadLoadingView(board: board, threadId: thread.no)) {
                ThreadRow(post: thread, board: board)
            }
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
    }

    /// Inline error view for catalog loading failures.
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.secondary)
            Text(message).multilineTextAlignment(.center).foregroundColor(.secondary)
            Button("Retry") { Task { await viewModel.fetchCatalog() } }.buttonStyle(.borderedProminent)
        }.padding()
    }
}

/// Container view that handles loading a thread before displaying its detail.
struct ThreadLoadingView: View {
    let board: String
    let threadId: Int
    @StateObject private var viewModel: ThreadViewModel
    
    init(board: String, threadId: Int) {
        self.board = board
        self.threadId = threadId
        self._viewModel = StateObject(wrappedValue: ThreadViewModel(board: board, threadId: threadId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground).ignoresSafeArea()
            if let rootNode = viewModel.rootNode {
                ThreadDetailView(board: board, rootNode: rootNode, depth: 0, onRefresh: { await viewModel.fetchThread() })
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.icloud").font(.largeTitle).foregroundColor(.secondary)
                    Text(error).font(.subheadline).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.fetchThread() } }.buttonStyle(.bordered)
                }.padding()
            } else {
                VStack(spacing: 20) { 
                    ProgressView()
                    Text("Loading thread...").font(.caption).foregroundColor(.secondary) 
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { if viewModel.rootNode == nil { await viewModel.fetchThread() } }
    }
}
