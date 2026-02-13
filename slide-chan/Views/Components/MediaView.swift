import SwiftUI
import WebKit

/// A view that handles the display of different media types (images, videos, gifs).
struct MediaView: View {
    /// The post containing the media metadata.
    let post: Post
    /// The short ID of the board.
    let board: String
    /// Whether the media is being displayed in full-screen mode.
    var isFullScreen: Bool = false
    
    @State private var loadError = false
    @State private var retryID = UUID()
    
    var body: some View {
        Group {
            if loadError {
                errorPlaceholder
            } else {
                contentView
            }
        }
        .id(retryID)
    }

    /// Primary content view logic based on media type and display mode.
    @ViewBuilder
    private var contentView: some View {
        let ext = post.ext?.lowercased() ?? ""
        
        if post.mediaType == .image && ext != ".gif" {
            if isFullScreen {
                // Zoomable view for full-screen images
                if let url = post.imageUrl(board: board) {
                    ZoomableImageView(url: url)
                }
            } else {
                standardImage
            }
        } else {
            if let url = post.imageUrl(board: board) {
                SimpleWebPlayer(url: url, isFullScreen: isFullScreen)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// Standard non-interactive image view.
    private var standardImage: some View {
        AsyncImage(url: post.imageUrl(board: board)) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .onAppear { loadError = false }
            case .failure(_):
                Color.clear.onAppear { loadError = true }
            case .empty:
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

    /// UI placeholder for media loading failures.
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
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Button {
                loadError = false
                retryID = UUID()
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
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(post.aspectRatio, contentMode: .fit)
    }
}

/// A lightweight web view wrapper for playing videos and GIFs.
struct SimpleWebPlayer: UIViewRepresentable {
    /// The URL of the media file.
    let url: URL
    /// Whether interactive controls should be enabled.
    let isFullScreen: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = isFullScreen
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let isGif = url.pathExtension.lowercased() == "gif"
        let videoAttrs = isFullScreen ? "playsinline loop autoplay controls" : "playsinline loop autoplay muted"
        
        let mediaTag = isGif ? 
            "<img src=\"\(url.absoluteString)\" style=\"width:100%;height:100%;object-fit:contain;\">" :
            "<video \(videoAttrs) style=\"width:100%;height:100%;object-fit:contain;\"><source src=\"\(url.absoluteString)\"></video>"
            
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
