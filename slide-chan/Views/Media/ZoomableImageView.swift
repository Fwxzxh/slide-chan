import SwiftUI

/// A view wrapper that adds interactive pinch-to-zoom and panning capabilities to an image.
/// It uses standard iOS gestures to allow users to inspect high-resolution media.
struct ZoomableImageView: View {
    // MARK: - Properties
    
    /// The remote URL of the image to download and display.
    let url: URL
    /// The original dimensions of the image, used for precise boundary calculations.
    let imageSize: CGSize?
    /// External binding to report the current scale to parents.
    @Binding var externalScale: CGFloat
    
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
                        .scaleEffect(scale) // Always scale from center for predictable panning
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
                                        scale = min(max(newScale, 0.8), 6.0)
                                    }
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    withAnimation(.spring()) {
                                        if scale < 1.0 {
                                            resetImageState()
                                        } else {
                                            if scale > 5.0 { scale = 5.0 }
                                            validateBoundaries(size: geometry.size)
                                        }
                                    }
                                }
                        )
                        
                        // 2. Drag Gesture (Panning)
                        .highPriorityGesture(
                            scale > 1.0 ? 
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    let deltaW = value.translation.width - lastOffset.width
                                    let deltaH = value.translation.height - lastOffset.height
                                    
                                    lastOffset = value.translation
                                    
                                    withAnimation(.interactiveSpring()) {
                                        offset.width += deltaW
                                        offset.height += deltaH
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = .zero
                                    withAnimation(.interactiveSpring()) {
                                        validateBoundaries(size: geometry.size)
                                    }
                                }
                            : nil
                        )
                        
                        // 3. Double-Tap Shortcut
                        .highPriorityGesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { event in
                                    let location = event.location
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        if scale > 1.05 {
                                            resetImageState()
                                        } else {
                                            scale = 3.0
                                            // Calculate offset to center the tapped point
                                            let centerX = geometry.size.width / 2
                                            let centerY = geometry.size.height / 2
                                            let dx = location.x - centerX
                                            let dy = location.y - centerY
                                            
                                            // We want the point at (dx, dy) to be at (0, 0)
                                            // When scaling around center, point at dx moves to dx * scale
                                            // So we need offset = -dx * scale
                                            offset = CGSize(width: -dx * scale, height: -dy * scale)
                                            validateBoundaries(size: geometry.size)
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
            .onChange(of: scale) { _, newValue in
                externalScale = newValue
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Logic

    private func resetImageState() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
    }
    
    private func validateBoundaries(size: CGSize) {
        // Calculate the actual size of the image as it fits in the container (.fit mode)
        let aspect = imageSize.flatMap { $0.width > 0 && $0.height > 0 ? $0.width / $0.height : nil } ?? (size.width / size.height)
        
        let fittedWidth: CGFloat
        let fittedHeight: CGFloat
        
        if (size.width / size.height) > aspect {
            // Container is relatively wider than the image
            fittedHeight = size.height
            fittedWidth = size.height * aspect
        } else {
            // Container is relatively taller than the image
            fittedWidth = size.width
            fittedHeight = size.width / aspect
        }
        
        // The total size of the content after applying the scale
        let scaledWidth = fittedWidth * scale
        let scaledHeight = fittedHeight * scale
        
        // maxX and maxY represent how much we can pan from the center before showing empty space.
        // If the scaled dimension is smaller than the container, we keep it at 0 (centered).
        let maxX = max(0, (scaledWidth - size.width) / 2)
        let maxY = max(0, (scaledHeight - size.height) / 2)
        
        var newOffset = offset
        
        if offset.width > maxX { newOffset.width = maxX }
        if offset.width < -maxX { newOffset.width = -maxX }
        if offset.height > maxY { newOffset.height = maxY }
        if offset.height < -maxY { newOffset.height = -maxY }
        
        offset = newOffset
    }
}

#Preview {
    ZoomableImageView(
        url: URL(string: "https://picsum.photos/1000/1500")!,
        imageSize: CGSize(width: 1000, height: 1500),
        externalScale: .constant(1.0)
    )
}
