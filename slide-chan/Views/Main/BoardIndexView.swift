import SwiftUI

/// Displays the catalog of threads for a specific board (e.g., /v/, /a/, /g/).
/// It fetches and shows a list of the most recent "Original Posts" (OPs).
struct BoardIndexView: View {
    // MARK: - Properties
    
    /// The short ID of the board (e.g., "v").
    let board: String
    /// Manages the state and network calls for the board's catalog.
    @StateObject private var viewModel: BoardIndexViewModel
    /// Accesses the global theme preference.
    @AppStorage("isDarkMode") private var isDarkMode = false

    /// Custom initializer to pass the board ID to the ViewModel.
    init(board: String) {
        self.board = board
        // Initialize StateObject manually to inject the board dependency.
        _viewModel = StateObject(wrappedValue: BoardIndexViewModel(board: board))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.threads.isEmpty {
                // Initial loading state
                ProgressView("Loading catalog...")
            } else if let errorMessage = viewModel.errorMessage {
                // Centralized error handling
                errorView(errorMessage)
            } else {
                // The actual scrollable list of threads
                threadsList
            }
        }
        .navigationTitle("/\(board)/")
        .navigationBarTitleDisplayMode(.inline) // Compact nav bar title
        .toolbar {
            // Dark Mode toggle in the nav bar
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { isDarkMode.toggle() } label: {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(isDarkMode ? .yellow : .orange)
                }
            }
            // Manual refresh button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await viewModel.fetchCatalog() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading) // Prevent multiple simultaneous refreshes
            }
        }
        .task { 
            // Automatically fetch data when the view is mounted
            if viewModel.threads.isEmpty { await viewModel.fetchCatalog() } 
        }
        .refreshable { 
            // Support for native pull-to-refresh
            await viewModel.fetchCatalog() 
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - View Components

    /// Constructs the main List of thread rows.
    private var threadsList: some View {
        List(viewModel.threads) { thread in
            // NavigationLink handles transition to the thread details.
            // We use ThreadLoadingView as an intermediate "buffer" to fetch the full thread JSON.
            NavigationLink(destination: ThreadLoadingView(board: board, threadId: thread.no)) {
                ThreadRow(post: thread, board: board)
            }
            .listRowInsets(EdgeInsets()) // Removes default row padding for a custom edge-to-edge look
        }
        .listStyle(.plain) // Simple list style without backgrounds/rounded corners
    }

    /// A simple UI for displaying error states with a retry button.
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.secondary)
            Text(message).multilineTextAlignment(.center).foregroundColor(.secondary)
            Button("Retry") { Task { await viewModel.fetchCatalog() } }.buttonStyle(.borderedProminent)
        }.padding()
    }
}

/// A "middle-man" view that fetches the complete thread data (replies, etc.)
/// before displaying the final ThreadDetailView.
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
        // ZStack allows us to overlay content or backgrounds
        ZStack {
            Color(UIColor.secondarySystemBackground).ignoresSafeArea()
            
            if let rootNode = viewModel.rootNode {
                // Once data is available, transition to the actual detail view
                ThreadDetailView(board: board, rootNode: rootNode, depth: 0, onRefresh: { await viewModel.fetchThread() })
            } else if let error = viewModel.errorMessage {
                // Error state for thread loading
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.icloud").font(.largeTitle).foregroundColor(.secondary)
                    Text(error).font(.subheadline).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.fetchThread() } }.buttonStyle(.bordered)
                }.padding()
            } else {
                // Loading spinner while fetching JSON
                VStack(spacing: 20) { 
                    ProgressView()
                    Text("Loading thread...").font(.caption).foregroundColor(.secondary) 
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { 
            // Trigger fetch only if not already loaded
            if viewModel.rootNode == nil { await viewModel.fetchThread() } 
        }
    }
}
