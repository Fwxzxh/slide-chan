import SwiftUI

@main
struct slide_chanApp: App {
    init() {
        setupCache()
    }

    var body: some Scene {
        WindowGroup {
            BoardListView()
        }
    }
    
    /// Configures a large, persistent URL cache for images and API responses.
    private func setupCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 500 * 1024 * 1024 // 500 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "image_cache")
        URLCache.shared = cache
    }
}
