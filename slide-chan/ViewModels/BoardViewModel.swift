import Foundation
import Combine
import SwiftUI

struct BookmarkedThread: Codable, Identifiable, Hashable {
    let id: String // board_threadId
    let board: String
    let threadId: Int
    let subject: String?
    let previewText: String?
    let timestamp: Date
}

@MainActor
class BoardViewModel: ObservableObject {
    static let shared = BoardViewModel() // Singleton for easier access across views
    
    @Published var boards: [Board] = []
    @Published var favoriteBoardIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Bookmark Logic
    @Published var bookmarks: [BookmarkedThread] = []
    private let bookmarksKey = "bookmarked_threads_final"

    /// Filtro opcional para mostrar solo tablones SFW (Safe For Work)
    @Published var showOnlySFW: Bool = false {
        didSet {
            filterBoards()
        }
    }

    private var allBoards: [Board] = []
    private let apiService = APIService.shared
    private let favoritesKey = "favorite_boards_ids"

    init() {
        loadFavorites()
        loadBookmarks()
    }

    // MARK: - Bookmarks Logic

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

    func isBookmarked(board: String, threadId: Int) -> Bool {
        let id = "\(board)_\(threadId)"
        return bookmarks.contains(where: { $0.id == id })
    }

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: bookmarksKey)
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([BookmarkedThread].self, from: data) {
            self.bookmarks = decoded
        }
    }

    // MARK: - Boards Logic

    /// Obtiene la lista completa de tablones usando el APIService
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

    private func filterBoards() {
        if showOnlySFW {
            self.boards = allBoards.filter { $0.isWorkSafe }
        } else {
            self.boards = allBoards
        }
    }

    // MARK: - Favorites Logic

    var favoriteBoards: [Board] {
        allBoards.filter { favoriteBoardIDs.contains($0.board) }
    }

    func isFavorite(_ board: Board) -> Bool {
        favoriteBoardIDs.contains(board.board)
    }

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

    private func saveFavorites() {
        let array = Array(favoriteBoardIDs)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            self.favoriteBoardIDs = Set(array)
        }
    }
}
