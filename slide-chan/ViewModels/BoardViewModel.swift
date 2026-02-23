import Foundation
import Combine
import SwiftUI

@MainActor
class BoardViewModel: ObservableObject {
    /// Singleton instance for shared access.
    static let shared = BoardViewModel(apiService: APIService.shared, persistenceService: PersistenceService.shared)
    
    /// List of all available boards.
    @Published var boards: [Board] = []
    /// Set of favorite board short IDs.
    @Published var favoriteBoardIDs: Set<String> = []
    /// Indicates if a network request is in progress.
    @Published var isLoading: Bool = false
    /// Holds the error message if the last request failed.
    @Published var errorMessage: String?
    
    /// List of user bookmarks.
    @Published var bookmarks: [BookmarkedThread] = []

    /// Filter to only show Safe For Work (SFW) boards.
    @Published var showOnlySFW: Bool = false {
        didSet {
            filterBoards()
        }
    }

    private var allBoards: [Board] = []
    private let apiService: APIServiceProtocol
    private let persistenceService: PersistenceService

    init(apiService: APIServiceProtocol, persistenceService: PersistenceService) {
        self.apiService = apiService
        self.persistenceService = persistenceService
        self.favoriteBoardIDs = persistenceService.loadFavorites()
        self.bookmarks = persistenceService.loadBookmarks()
    }

    // MARK: - Bookmarks Logic

    /// Toggles a thread's bookmark status.
    func toggleBookmark(board: String, threadId: Int, subject: String?, previewText: String?) {
        let id = "\(board)_\(threadId)"
        if let index = bookmarks.firstIndex(where: { $0.id == id }) {
            bookmarks.remove(at: index)
        } else {
            let newBookmark = BookmarkedThread(
                id: id,
                board: board,
                threadId: threadId,
                subject: subject,
                previewText: previewText,
                timestamp: Date()
            )
            bookmarks.insert(newBookmark, at: 0)
        }
        persistenceService.saveBookmarks(bookmarks)
    }

    /// Checks if a thread is bookmarked.
    func isBookmarked(board: String, threadId: Int) -> Bool {
        let id = "\(board)_\(threadId)"
        return bookmarks.contains(where: { $0.id == id })
    }

    // MARK: - Boards Logic

    /// Fetches the full list of boards from the API.
    func fetchBoards() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedBoards = try await apiService.fetchBoards()
            self.allBoards = fetchedBoards
            filterBoards()
            self.isLoading = false
        } catch {
            self.errorMessage = "Error loading boards: \(error.localizedDescription)"
            self.isLoading = false
            print("Error in BoardViewModel: \(error)")
        }
    }

    /// Synchronizes the `boards` property with the filtered subset based on user preferences.
    private func filterBoards() {
        if showOnlySFW {
            self.boards = allBoards.filter { $0.isWorkSafe }
        } else {
            self.boards = allBoards
        }
    }

    // MARK: - Favorites Logic

    /// Returns the subset of favorite boards.
    var favoriteBoards: [Board] {
        allBoards.filter { favoriteBoardIDs.contains($0.board) }
    }

    /// Checks if a board is marked as favorite.
    func isFavorite(_ board: Board) -> Bool {
        favoriteBoardIDs.contains(board.board)
    }

    /// Toggles a board's favorite status and persists the change.
    func toggleFavorite(_ board: Board) {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
            if favoriteBoardIDs.contains(board.board) {
                favoriteBoardIDs.remove(board.board)
            } else {
                favoriteBoardIDs.insert(board.board)
            }
        }
        persistenceService.saveFavorites(favoriteBoardIDs)
    }
}
