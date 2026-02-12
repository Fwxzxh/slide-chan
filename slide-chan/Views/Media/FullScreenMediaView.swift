import SwiftUI
import UIKit

struct FullScreenMediaView: View {
    let allMediaPosts: [Post]
    let board: String
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
                // Toolbar Superior Nativa
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
                    
                    // Indicador Inferior Nativo
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
    
    private func copyImageLink() {
        if let url = allMediaPosts[currentIndex].imageUrl(board: board) {
            UIPasteboard.general.url = url
        }
    }
    
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
