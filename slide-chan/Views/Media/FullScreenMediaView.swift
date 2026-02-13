import SwiftUI
import UIKit

/// A view for displaying media in a full-screen paging interface.
struct FullScreenMediaView: View {
    /// List of posts containing media to display.
    let allMediaPosts: [Post]
    /// The short ID of the board.
    let board: String
    /// Binding to the currently selected media index.
    @Binding var currentIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(allMediaPosts.indices, id: \.self) { index in
                    MediaView(post: allMediaPosts[index], board: board, isFullScreen: true)
                        .tag(index)
                        .onTapGesture {
                            withAnimation { showControls.toggle() }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            if showControls {
                // Top Toolbar
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                        
                        Spacer()
                        
                        if let filename = allMediaPosts[currentIndex].filename {
                            Text(filename + (allMediaPosts[currentIndex].ext ?? ""))
                                .font(.caption.bold())
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button(action: copyImageLink) {
                                Image(systemName: "link")
                            }
                            Button(action: shareMedia) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    Spacer()
                    
                    // Page Indicator
                    Text("\(currentIndex + 1) / \(allMediaPosts.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    /// Copies the original image URL to the clipboard.
    private func copyImageLink() {
        if let url = allMediaPosts[currentIndex].imageUrl(board: board) {
            UIPasteboard.general.url = url
        }
    }
    
    /// Opens the native share sheet for the current media.
    private func shareMedia() {
        guard let url = allMediaPosts[currentIndex].imageUrl(board: board) else { return }
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            if let popoverController = av.popoverPresentationController {
                popoverController.sourceView = rootVC.view
            }
            rootVC.present(av, animated: true)
        }
    }
}
