import SwiftUI
import Combine

/// A custom image loader that utilizes the shared URLCache for persistent storage.
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private static let cache = URLCache.shared
    
    /// Loads an image from the cache or network.
    /// - Parameter url: The remote URL of the image.
    func load(from url: URL) async {
        // 1. Check if we already have the image in memory or are loading
        guard image == nil && !isLoading else { return }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        // 2. Try to get data from cache synchronously first
        if let cachedResponse = Self.cache.cachedResponse(for: request) {
            self.image = UIImage(data: cachedResponse.data)
            return
        }
        
        // 3. If not in cache, load from network
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            self.image = UIImage(data: data)
        } catch {
            print("Failed to load image from \(url): \(error)")
            self.image = nil
        }
    }
    
    /// Cancels the ongoing loading task.
    func cancel() {
        // In async/await, cancellation is handled by the task context
        isLoading = false
    }
}

/// A SwiftUI view that displays an image from a URL with persistent caching support.
struct CachedImage<Placeholder: View>: View {
    @StateObject private var loader = ImageLoader()
    let url: URL?
    let placeholder: Placeholder
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fill, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .task(id: url) {
            if let url = url {
                await loader.load(from: url)
            }
        }
    }
}
