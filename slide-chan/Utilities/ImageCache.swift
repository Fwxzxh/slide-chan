import SwiftUI
import Combine

/// A custom image loader that utilizes the shared URLCache for persistent storage.
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private static let cache = URLCache.shared
    private var cancellable: AnyCancellable?
    
    /// Loads an image from the cache or network.
    /// - Parameter url: The remote URL of the image.
    func load(from url: URL) {
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
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                self?.image = loadedImage
                self?.isLoading = false
            }
    }
    
    /// Cancels the ongoing loading task.
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
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
                    .onAppear {
                        if let url = url {
                            loader.load(from: url)
                        }
                    }
            }
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
