import SwiftUI

/// A unified component for displaying a post ID with a consistent style.
/// Used across ThreadRow, ThreadDetailView, and Gallery.
struct PostIDBadge: View {
    /// The numeric ID of the post.
    let postNumber: Int
    
    var body: some View {
        Text("#\(String(postNumber))")
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(Theme.radiusXS)
    }
}

#Preview {
    VStack(spacing: 20) {
        PostIDBadge(postNumber: 12345678)
        PostIDBadge(postNumber: 286139106)
    }
    .padding()
    .background(Color.black)
}
