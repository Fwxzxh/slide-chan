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
    /// The anchor point for zooming.
    @State private var zoomAnchor: UnitPoint = .center
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    // The actual image with applied transformation effects.
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale, anchor: zoomAnchor) // Apply zoom level with anchor
                        .offset(offset)     // Apply panning position
                        
                        // 1. Pinch-to-Zoom Gesture (Magnification)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    
                                    // Provide haptic feedback at limits
                                    if (newScale >= 5.0 && scale < 5.0) || (newScale <= 1.0 && scale > 1.0) {
                                        HapticManager.impact(style: .light)
                                    }
                                    
                                    withAnimation(.interactiveSpring()) {
                                        scale = min(max(newScale, 0.8), 6.0) // Allow slightly more/less for rubber banding
                                    }
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    withAnimation(.spring()) {
                                        if scale < 1.0 {
                                            resetImageState()
                                        } else if scale > 5.0 {
                                            scale = 5.0
                                        }
                                    }
                                }
                        )
                        
                        // 2. Drag Gesture (Panning) - Use highPriorityGesture to beat parent/TabView gestures when zoomed
                        .highPriorityGesture(
                            scale > 1.0 ? 
                            DragGesture(minimumDistance: 10) // Small distance to allow double tap recognition
                                .onChanged { value in
                                    // Calculate movement relative to the last confirmed position
                                    let deltaW = value.translation.width - lastOffset.width
                                    let deltaH = value.translation.height - lastOffset.height
                                    
                                    // We use a small animation to keep it fluid
                                    withAnimation(.interactiveSpring()) {
                                        offset.width += deltaW
                                        offset.height += deltaH
                                    }
                                    
                                    lastOffset = value.translation
                                }
                                .onEnded { _ in
                                    // Reset the tracker for the next gesture session
                                    lastOffset = .zero
                                    
                                    withAnimation(.interactiveSpring()) {
                                        validateBoundaries(size: geometry.size)
                                    }
                                }
                            : nil
                        )
                        
                        // 3. Double-Tap Shortcut - Also use highPriority to ensure it works when zoomed
                        .highPriorityGesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { event in
                                    let location = event.location
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        if scale > 1.05 {
                                            resetImageState()
                                        } else {
                                            // Zoom into the tapped area
                                            zoomAnchor = UnitPoint(
                                                x: location.x / geometry.size.width,
                                                y: location.y / geometry.size.height
                                            )
                                            scale = 3.0
                                        }
                                    }
                                }
                        )

                case .failure(_):
                    Color.clear
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped() // Ensure zoomed image doesn't spill over
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Logic

    private func resetImageState() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        zoomAnchor = .center
    }
    
    private func validateBoundaries(size: CGSize) {
        // Simple boundary clamping
        let maxX = (size.width * (scale - 1)) / 2
        let maxY = (size.height * (scale - 1)) / 2
        
        var newOffset = offset
        
        if offset.width > maxX { newOffset.width = maxX }
        if offset.width < -maxX { newOffset.width = -maxX }
        if offset.height > maxY { newOffset.height = maxY }
        if offset.height < -maxY { newOffset.height = -maxY }
        
        offset = newOffset
    }
}

#Preview {
    ZoomableImageView(url: URL(string: "https://picsum.photos/1000/1500")!)
}
