import SwiftUI
import UIKit

/// A full-screen paging container for viewing images and videos.
/// It supports swiping between multiple media items, sharing, and copying links.
struct FullScreenMediaView: View {
    // MARK: - Properties
    
    /// The collection of all media-containing posts in the current thread or branch.
    let allMediaPosts: [Post]
    /// Short board ID (e.g., "v").
    let board: String
    /// A binding to the index currently being viewed, allowing the parent to track progress.
    @Binding var currentIndex: Int
    
    /// Standard environment variable to close the view.
    @Environment(\.dismiss) private var dismiss
    /// Controls the visibility of the toolbar and page counter.
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Solid black background for cinematic viewing.
            Color.black.ignoresSafeArea()
            
            // TabView with .page style creates the "swipeable" horizontal gallery effect.
            TabView(selection: $currentIndex) {
                ForEach(allMediaPosts.indices, id: \.self) { index in
                    // Reuse MediaView with isFullScreen enabled for interactive content.
                    MediaView(post: allMediaPosts[index], board: board, isFullScreen: true)
                        .tag(index) // Necessary for TabView selection tracking.
                        .onTapGesture {
                            // Single tap toggles the UI overlay (toolbar and counter).
                            withAnimation { showControls.toggle() }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Hides native page dots.
            .ignoresSafeArea()
            
            // Floating UI Overlay (Header toolbar and Footer counter)
            if showControls {
                VStack {
                    // 1. Top Navigation Bar
                    HStack {
                        // Close button
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                        
                        Spacer()
                        
                        // Display the current file name.
                        if let filename = allMediaPosts[currentIndex].filename {
                            Text(filename + (allMediaPosts[currentIndex].ext ?? ""))
                                .font(.caption.bold())
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()
                        
                        // Action buttons: Copy link and Share.
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
                    .background(.ultraThinMaterial) // Translucent blurred background
                    
                    Spacer() // Pushes the counter to the bottom
                    
                    // 2. Page Counter (e.g., "5 / 20")
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
    
    // MARK: - Actions

    /// Copies the direct image/video URL to the device clipboard.
    private func copyImageLink() {
        if let url = allMediaPosts[currentIndex].imageUrl(board: board) {
            UIPasteboard.general.url = url
        }
    }
    
    /// Triggers the native iOS system share sheet.
    private func shareMedia() {
        guard let url = allMediaPosts[currentIndex].imageUrl(board: board) else { return }
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // UIKit bridge to find the current active window for presenting the share sheet.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            if let popoverController = av.popoverPresentationController {
                popoverController.sourceView = rootVC.view // Required for iPad compatibility.
            }
            rootVC.present(av, animated: true)
        }
    }
}
