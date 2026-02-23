import Foundation
import Combine

/// ViewModel for a board's thread index (catalog).
@MainActor
class BoardIndexViewModel: ObservableObject {
    /// List of threads (OP posts) in the board.
    @Published var threads: [Post] = []
    /// Indicates if a network request is in progress.
    @Published var isLoading: Bool = false
    /// Holds the error message if the last request failed.
    @Published var errorMessage: String?

    /// The short ID of the board (e.g., "v").
    let board: String
    private let apiService: APIServiceProtocol

    init(board: String, apiService: APIServiceProtocol = APIService.shared) {
        self.board = board
        self.apiService = apiService
    }

    /// Fetches the board's catalog using the APIService.
    func fetchCatalog() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedThreads = try await apiService.fetchCatalog(board: board)
            self.threads = fetchedThreads
            self.isLoading = false
        } catch where (error as NSError).code == NSURLErrorCancelled {
            // Silently ignore cancellations (common when navigating quickly)
            return
        } catch {
            self.errorMessage = "Error loading catalog: \(error.localizedDescription)"
            self.isLoading = false
            print("Error in BoardIndexViewModel: \(error)")
        }
    }

    /// Refreshes the board's catalog.
    func refresh() async {
        await fetchCatalog()
    }
}
