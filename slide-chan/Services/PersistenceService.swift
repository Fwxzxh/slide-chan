import Foundation
import Combine

/// Service responsible for persisting user data like favorites and bookmarks.
final class PersistenceService: Sendable {
    static let shared = PersistenceService()
    
    private let defaults = UserDefaults.standard
    private let favoritesKey = "favorite_boards_ids"
    private let bookmarksKey = "bookmarked_threads_final"
    
    private init() {}
    
    // MARK: - Favorites
    
    /// Loads favorite board IDs.
    func loadFavorites() -> Set<String> {
        if let array = defaults.stringArray(forKey: favoritesKey) {
            return Set(array)
        }
        return []
    }
    
    /// Saves favorite board IDs.
    func saveFavorites(_ favorites: Set<String>) {
        defaults.set(Array(favorites), forKey: favoritesKey)
    }
    
    // MARK: - Bookmarks
    
    /// Loads bookmarked threads.
    func loadBookmarks() -> [BookmarkedThread] {
        guard let data = defaults.data(forKey: bookmarksKey),
              let decoded = try? JSONDecoder().decode([BookmarkedThread].self, from: data) else {
            return []
        }
        return decoded
    }
    
    /// Saves bookmarked threads.
    func saveBookmarks(_ bookmarks: [BookmarkedThread]) {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            defaults.set(encoded, forKey: bookmarksKey)
        }
    }
}
