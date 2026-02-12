import SwiftUI

struct GlassButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct GlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
}

extension View {
    func glassButtonStyle() -> some View {
        modifier(GlassButton())
    }
    
    func glassCapsuleStyle() -> some View {
        modifier(GlassCapsule())
    }
}
