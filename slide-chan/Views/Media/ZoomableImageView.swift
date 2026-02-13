import SwiftUI

/// A view that provides pinch-to-zoom and drag functionality for an image.
struct ZoomableImageView: View {
    /// The URL of the image to display.
    let url: URL
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        // Pinch Gesture (Magnification)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    // Limit zoom scale
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale <= 1.0 {
                                        resetImageState()
                                    }
                                }
                        )
                        // Drag Gesture (Only if zoomed)
                        .gesture(
                            scale > 1.0 ? 
                            DragGesture()
                                .onChanged { value in
                                    let newWidth = lastOffset.width + value.translation.width
                                    let newHeight = lastOffset.height + value.translation.height
                                    offset = CGSize(width: newWidth, height: newHeight)
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    validateBoundaries(size: geometry.size)
                                }
                            : nil
                        )
                        // Double Tap Gesture to toggle zoom
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                if scale > 1.0 {
                                    resetImageState()
                                } else {
                                    scale = 3.0
                                }
                            }
                        }
                case .failure(_):
                    Color.clear
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    /// Resets the image to its original scale and position.
    private func resetImageState() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    /// Validates and adjusts the image position within boundaries.
    private func validateBoundaries(size: CGSize) {
        // If scale is 1, always reset to center
        if scale <= 1.0 {
            resetImageState()
        }
    }
}
