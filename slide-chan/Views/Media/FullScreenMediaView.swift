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
                    MediaView(post: allMediaPosts[index], board: board)
                        .tag(index)
                        .onTapGesture {
                            withAnimation { showControls.toggle() }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            if showControls {
                VStack {
                    // Top Controls
                    HStack(spacing: 0) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.4))
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if let filename = allMediaPosts[currentIndex].filename {
                            Text(filename + (allMediaPosts[currentIndex].ext ?? ""))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 10)
                        }

                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                copyImageLink()
                            } label: {
                                Image(systemName: "link")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.4))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                shareMedia()
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.4))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Index Indicator
                    Text("\(currentIndex + 1) / \(allMediaPosts.count)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                        .padding(.bottom, 20)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
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
