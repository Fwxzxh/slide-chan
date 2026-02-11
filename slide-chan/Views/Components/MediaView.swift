import SwiftUI
import WebKit

struct MediaView: View {
    let post: Post
    let board: String
    @State private var loadError = false
    
    var body: some View {
        Group {
            if loadError {
                errorPlaceholder
            } else {
                contentView
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        let ext = post.ext?.lowercased() ?? ""
        
        if post.mediaType == .image && ext != ".gif" {
            standardImage
        } else {
            // GIF, WebM, MP4
            if let url = post.imageUrl(board: board) {
                SimpleWebPlayer(url: url)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var standardImage: some View {
        AsyncImage(url: post.imageUrl(board: board)) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            case .failure(_):
                Color.clear.onAppear { loadError = true }
            case .empty:
                // Placeholder con dimensiones reales para evitar que se "aplane"
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

    private var errorPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text("Failed to load").font(.caption2).bold()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(post.aspectRatio, contentMode: .fit)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SimpleWebPlayer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let isGif = url.pathExtension.lowercased() == "gif"
        let mediaTag = isGif ? 
            "<img src=\"\(url.absoluteString)\" style=\"width:100%;height:100%;object-fit:contain;\">" :
            "<video playsinline loop autoplay muted style=\"width:100%;height:100%;object-fit:contain;\"><source src=\"\(url.absoluteString)\"></video>"
            
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin:0; padding:0; background-color:black; display:flex; align-items:center; justify-content:center; height:100vh; overflow:hidden; }
            </style>
        </head>
        <body>
            \(mediaTag)
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: url)
    }
}
