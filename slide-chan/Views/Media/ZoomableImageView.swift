import SwiftUI

struct ZoomableImageView: View {
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
                        // GESTO DE PINCH (Magnificación)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    // Limitar zoom máximo y mínimo
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale <= 1.0 {
                                        resetImageState()
                                    }
                                }
                        )
                        // GESTO DE ARRASTRE (Solo si hay zoom)
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
                        // GESTO DE DOBLE TAP
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
    
    private func resetImageState() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    private func validateBoundaries(size: CGSize) {
        // Lógica para evitar que la imagen se pierda al arrastrar
        // Si el zoom es 1, siempre reseteamos
        if scale <= 1.0 {
            resetImageState()
        }
    }
}
