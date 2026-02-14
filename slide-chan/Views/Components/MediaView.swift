import SwiftUI
import WebKit

/// The central media player component for Slide-chan.
/// It intelligently decides whether to use a native image view or a web-based video player
/// based on the file extension (JPG, PNG, GIF, WEBM, MP4).
struct MediaView: View {
    // MARK: - Properties
    
    /// The post containing the media details (URL, dimensions, etc).
    let post: Post
    /// Short board ID (e.g., "a").
    let board: String
    /// When true, enables zooming for images and controls for videos.
    var isFullScreen: Bool = false
    
    /// Internal state to track if a download failed.
    @State private var loadError = false
    /// Used to force a view refresh when retrying a connection.
    @State private var retryID = UUID()
    
    var body: some View {
        Group {
            if loadError {
                // UI shown when media fails to load.
                errorPlaceholder
            } else {
                // The actual media content.
                contentView
            }
        }
        .id(retryID) // Changing this ID forces SwiftUI to re-create the view.
        .ignoresSafeArea(isFullScreen ? .all : [])
    }

    // MARK: - Content Logic

    /// Main logic for choosing the right sub-view for the media type.
    @ViewBuilder
    private var contentView: some View {
        let ext = post.ext?.lowercased() ?? ""
        let url = post.imageUrl(board: board)
        
        // Strategy: 
        // 1. Static Images (JPG, PNG) use native SwiftUI AsyncImage.
        // 2. Animated/Complex Media (GIF, WEBM, MP4) use a WKWebView wrapper.
        
        if post.mediaType == .image && ext != ".gif" {
            if isFullScreen {
                // Custom zoomable view implementation.
                if let url = url {
                    ZoomableImageView(url: url)
                }
            } else {
                standardImage(url: url)
            }
        } else {
            // Video/GIF path:
            if let url = url {
                ZStack {
                    // SimpleWebPlayer uses a hidden web view to render 4chan's webm/gifs.
                    SimpleWebPlayer(url: url, isFullScreen: isFullScreen)
                        .aspectRatio(post.aspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    
                    // If not full screen, we place a transparent layer on top to catch taps.
                    // This is necessary because WKWebView often "steals" touch events.
                    if !isFullScreen {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    // MARK: - Sub-Components

    /// Native image component with loading and failure handling.
    private func standardImage(url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .onAppear { loadError = false }
            case .failure(_):
                // Trigger the error UI if download fails.
                Color.clear.onAppear { loadError = true }
            case .empty:
                // Loading state.
                ZStack {
                    Color.secondary.opacity(0.05)
                    ProgressView()
                }
                .aspectRatio(post.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
            @unknown default:
                EmptyView()
            }
        }
    }

    /// Error UI with a retry button for failed connections.
    private var errorPlaceholder: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Failed to load")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(Theme.radiusMedium)
            .padding(.horizontal, 20)
            
            Button {
                loadError = false
                retryID = UUID() // Triggers re-render.
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Connection")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(Theme.radiusLarge)
                .shadow(color: .blue.opacity(0.3), radius: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(post.aspectRatio, contentMode: .fit)
    }
}

// MARK: - WKWebView Wrapper

/// A wrapper that makes UIKit's WKWebView compatible with SwiftUI.
/// Used for rendering webm and mp4 files natively since SwiftUI's VideoPlayer
/// has limited support for certain web formats.
struct SimpleWebPlayer: UIViewRepresentable {
    let url: URL
    let isFullScreen: Bool
    
    /// Creates the actual UIKit view.
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true // Plays inside the view, not full screen by default.
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false // Prevent accidental scrolling inside the player.
        webView.isUserInteractionEnabled = isFullScreen // Only allow controls in full screen.
        return webView
    }
    
    /// Updates the view whenever the state changes.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let isGif = url.pathExtension.lowercased() == "gif"
        // HTML video attributes: loop, autoplay, and muted (muted is required for autoplay in web views).
        let videoAttrs = isFullScreen ? "playsinline loop autoplay controls" : "playsinline loop autoplay muted"
        
        let mediaTag = isGif ? 
            "<img src=\"\(url.absoluteString)\" style=\"width:100%;height:100%;object-fit:contain;\">" :
            "<video \(videoAttrs) style=\"width:100%;height:100%;object-fit:contain;\"><source src=\"\(url.absoluteString)\"></video>"
            
        // Inject a simple HTML wrapper to ensure the media is centered and covers the view.
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin:0; padding:0; background-color:black; display:flex; align-items:center; justify-content:center; height:100vh; overflow:hidden; }
            </style>
        </head>
        <body>\(mediaTag)</body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: url)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Standard Image")
            MediaView(
                post: .mock,
                board: "preview"
            )
            .frame(height: 300)
            
            Text("Full Screen Mode")
            MediaView(
                post: .mock,
                board: "preview",
                isFullScreen: true
            )
            .frame(height: 300)
            
            Text("GIF/Video (Simulated)")
            MediaView(
                post: Post(no: 1, resto: 0, time: 0, now: "", name: "", sub: "", com: "", filename: "test", ext: ".gif", tim: 1, w: 500, h: 500, tn_w: 100, tn_h: 100, replies: 0, images: 0, sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil, country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil),
                board: "v" // This will still use 4chan logic but Giphy might work if timed right, though board="preview" is better for picsum
            )
            .frame(height: 300)
        }
    }
}
