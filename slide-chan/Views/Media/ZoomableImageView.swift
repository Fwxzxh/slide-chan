import SwiftUI

/// A view wrapper that adds interactive pinch-to-zoom and panning capabilities to an image.
/// It uses standard iOS gestures to allow users to inspect high-resolution media.
struct ZoomableImageView: View {
    // MARK: - Properties
    
    /// The remote URL of the image to download and display.
    let url: URL
    
    // MARK: - State Management
    
    /// The current multiplier for the image size (1.0 = normal).
    @State private var scale: CGFloat = 1.0
    /// Tracking the scale from the previous gesture update to calculate deltas.
    @State private var lastScale: CGFloat = 1.0
    /// The horizontal and vertical displacement of the image from its center.
    @State private var offset: CGSize = .zero
    /// Tracking the offset from the previous gesture update.
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    // The actual image with applied transformation effects.
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale) // Apply zoom level
                        .offset(offset)     // Apply panning position
                        
                        // 1. Pinch-to-Zoom Gesture (Magnification)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Calculate how much the pinch distance has changed.
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    // Clamp the zoom between 1x and 5x.
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    // Reset state for the next gesture.
                                    lastScale = 1.0
                                    if scale <= 1.0 {
                                        resetImageState()
                                    }
                                }
                        )
                        
                        // 2. Drag Gesture (Panning)
                        // Only enabled if the image is actually zoomed in.
                        .gesture(
                            scale > 1.0 ? 
                            DragGesture()
                                .onChanged { value in
                                    // Move the image based on the finger displacement.
                                    let newWidth = lastOffset.width + value.translation.width
                                    let newHeight = lastOffset.height + value.translation.height
                                    offset = CGSize(width: newWidth, height: newHeight)
                                }
                                .onEnded { _ in
                                    // Save the final position and ensure it's not out of bounds.
                                    lastOffset = offset
                                    validateBoundaries(size: geometry.size)
                                }
                            : nil // Disable if not zoomed.
                        )
                        
                        // 3. Double-Tap Shortcut
                        // Instantly toggles between 1x and 3x zoom.
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
                    // Empty or error state if the image fails to load.
                    Color.clear
                case .empty:
                    // Loading indicator.
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            // Ensure the image container fills the entire screen.
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    // MARK: - Logic

    /// Animates the image back to its original centered position at 1x scale.
    private func resetImageState() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    /// Ensures that the image panning doesn't leave the screen edges empty (boundary control).
    private func validateBoundaries(size: CGSize) {
        if scale <= 1.0 {
            resetImageState()
        }
        // Future implementation: Logic to snap edges back to screen bounds.
    }
}
