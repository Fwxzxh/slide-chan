import Foundation
import Combine
import SwiftUI

/// Represents a thread bookmarked by the user.
struct BookmarkedThread: Codable, Identifiable, Hashable {
    /// Unique identifier: board_threadId.
    let id: String
    /// The short ID of the board.
    let board: String
    /// The thread ID.
    let threadId: Int
    /// Optional thread subject.
    let subject: String?
    /// Preview text from the OP comment.
    let previewText: String?
    /// When the bookmark was created.
    let timestamp: Date
}

/// ViewModel for managing boards, favorites, and bookmarks.
@MainActor
class BoardViewModel: ObservableObject {
    /// Singleton instance for shared access.
    static let shared = BoardViewModel(apiService: APIService.shared)
    
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
    private let bookmarksKey = "bookmarked_threads_final"

    /// Filter to only show Safe For Work (SFW) boards.
    @Published var showOnlySFW: Bool = false {
        didSet {
            filterBoards()
        }
    }

    private var allBoards: [Board] = []
    private let apiService: APIServiceProtocol
    private let favoritesKey = "favorite_boards_ids"

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
        loadFavorites()
        loadBookmarks()
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
        saveBookmarks()
    }

    /// Checks if a thread is bookmarked.
    func isBookmarked(board: String, threadId: Int) -> Bool {
        let id = "\(board)_\(threadId)"
        return bookmarks.contains(where: { $0.id == id })
    }

    /// Persists the current list of bookmarks to UserDefaults.
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: bookmarksKey)
        }
    }

    /// Loads bookmarked threads from UserDefaults during initialization.
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([BookmarkedThread].self, from: data) {
            self.bookmarks = decoded
        }
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
        saveFavorites()
    }

    /// Persists favorite board IDs to UserDefaults.
    private func saveFavorites() {
        let array = Array(favoriteBoardIDs)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    /// Loads favorite board IDs from UserDefaults during initialization.
    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            self.favoriteBoardIDs = Set(array)
        }
    }
}
