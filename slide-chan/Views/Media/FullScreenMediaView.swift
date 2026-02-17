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
    /// Haptic feedback during drag.
    @State private var hasTriggeredHaptic = false
    /// Controls the visibility of the toolbar and page counter.
    @State private var showControls = true
    /// Current vertical drag offset for swipe-to-dismiss.
    @State private var dragOffset: CGSize = .zero
    /// Status message for save operations.
    @State private var toastMessage: String?
    /// Prevents the view from snapping back during dismissal
    @State private var isDismissing = false
    /// Tracks if we have "locked" into a vertical dismissal gesture to avoid horizontal interference
    @State private var isVerticalDragActive = false

    /// Scale factor for swipe-to-dismiss animation.
    private var dragScale: CGFloat {
        let maxDrag = 500.0
        let currentDrag = abs(dragOffset.height)
        return max(0.8, 1.0 - (currentDrag / maxDrag) * 0.2)
    }
    
    /// Opacity for the black background based on drag distance.
    private var backgroundOpacity: Double {
        let maxDrag = 500.0
        let currentDrag = abs(dragOffset.height)
        return max(0.0, 1.0 - (currentDrag / maxDrag))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background that fades out during drag
                    Color.black
                        .opacity(backgroundOpacity)
                        .ignoresSafeArea()
                    
                    Group {
                        // Modern paging carousel using ScrollView (iOS 17+)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 0) {
                                ForEach(allMediaPosts.indices, id: \.self) { index in
                                    MediaView(post: allMediaPosts[index], board: board, isFullScreen: true)
                                        .containerRelativeFrame(.horizontal) // Forces each page to be exactly screen width
                                        .id(index)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                                        }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging) // Mimics TabView paging but more efficiently
                        .scrollPosition(id: Binding(
                            get: { currentIndex },
                            set: { if let val = $0 { currentIndex = val } }
                        ))
                        .ignoresSafeArea()

                        // Toast overlay
                        if let toast = toastMessage {
                            VStack {
                                Spacer()
                                Text(toast)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .glassEffect()
                                Spacer()
                            }
                            .zIndex(2)
                        }

                        // Manual Bottom Bar Overlay (to avoid UIKitToolbar errors)
                        VStack {
                            Spacer()
                            HStack {
                                if let filename = allMediaPosts[currentIndex].filename {
                                    Text(filename + (allMediaPosts[currentIndex].ext ?? ""))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .glassEffect()
                                }
                                
                                Spacer()
                                
                                Text("\(currentIndex + 1) / \(allMediaPosts.count)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .glassEffect()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20) 
                        }
                        .opacity(showControls ? 1 : 0)
                        .allowsHitTesting(false)
                    }
                    .opacity(isDismissing ? 0 : (dragOffset == .zero ? 1.0 : Double(dragScale)))
                    .scaleEffect(dragScale)
                    .offset(dragOffset)
                }
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            if isDismissing { return }
                            
                            // Decide if we should lock into a vertical dismissal
                            if !isVerticalDragActive {
                                let horizontalAmount = abs(gesture.translation.width)
                                let verticalAmount = abs(gesture.translation.height)
                                
                                // Bias: Vertical needs to be at least as strong as horizontal to start dismissal
                                // This helps prevent accidental dismissal while paging
                                if verticalAmount > horizontalAmount && verticalAmount > 10 {
                                    isVerticalDragActive = true
                                }
                            }
                            
                            if isVerticalDragActive {
                                dragOffset = gesture.translation

                                if abs(dragOffset.height) > 80 && !hasTriggeredHaptic {
                                    HapticManager.impact(style: .medium)
                                    hasTriggeredHaptic = true
                                } else if abs(dragOffset.height) < 80 {
                                    hasTriggeredHaptic = false
                                }

                                if showControls {
                                    withAnimation(.easeInOut(duration: 0.2)) { showControls = false }
                                }
                            }
                        }
                        .onEnded { gesture in
                            if isDismissing { return }
                            
                            if isVerticalDragActive {
                                let velocity = gesture.predictedEndTranslation.height - gesture.translation.height
                                
                                // Dismiss if dragged far enough OR if swiped with enough velocity
                                if abs(dragOffset.height) > 100 || abs(velocity) > 300 {
                                    isDismissing = true
                                    HapticManager.impact(style: .light)
                                    
                                    // Animate the view away in the direction of the swipe
                                    // Using a slightly slower spring for a more dramatic/visible exit
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                        if dragOffset.height > 0 {
                                            dragOffset.height = geometry.size.height + 100
                                        } else {
                                            dragOffset.height = -geometry.size.height - 100
                                        }
                                    }
                                    
                                    // Delay dismissal to let the animation play out visibly
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dismiss()
                                    }
                                } else {
                                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                        if !showControls { showControls = true }
                                    }
                                }
                            }
                            
                            isVerticalDragActive = false
                        }
                )

            }
            .toolbar(showControls ? .visible : .hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top Leading
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.bold())
                    }
                }

                // Top Trailing
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 20)  {
                        Button {
                            copyImageLink()
                        } label: {
                            Image(systemName: "link")
                        }

                        Button {
                            saveMedia()
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Button {
                            shareMedia()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .padding(6)
                }
            }
        }
    }



    // MARK: - Actions

    private func copyImageLink() {
        if let url = allMediaPosts[currentIndex].imageUrl(board: board) {
            UIPasteboard.general.url = url
            HapticManager.notification(type: .success)
            showToast("Link copied!")
        }
    }

    private func saveMedia() {
        guard let url = allMediaPosts[currentIndex].imageUrl(board: board) else { return }
        let isVideo = allMediaPosts[currentIndex].ext == ".webm" || allMediaPosts[currentIndex].ext == ".mp4"

        HapticManager.impact(style: .medium)
        showToast("Saving...")

        MediaSaver.shared.downloadAndSaveMedia(url: url, isVideo: isVideo) { success, error in
            if success {
                HapticManager.notification(type: .success)
                showToast("Saved to Photos!")
            } else {
                HapticManager.notification(type: .error)
                showToast("Failed to save.")
                print("Save error: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }

    private func shareMedia() {
        guard let url = allMediaPosts[currentIndex].imageUrl(board: board) else { return }
        HapticManager.impact(style: .light)

        URLSession.shared.dataTask(with: url) { data, _, _ in
            let activityItems: [Any] = data.flatMap { [UIImage(data: $0) as Any] } ?? [url]

            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first(where: { $0.isKeyWindow }) {

                    var topVC = window.rootViewController
                    while let presented = topVC?.presentedViewController {
                        topVC = presented
                    }

                    if let popoverController = av.popoverPresentationController {
                        popoverController.sourceView = topVC?.view
                    }

                    topVC?.present(av, animated: true)
                }
            }
        }.resume()
    }

    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

#Preview {
    FullScreenMediaView(
        allMediaPosts: [
            .mock,
            .mockNoSubject,
            .mockManyStats
        ],
        board: "preview",
        currentIndex: .constant(0)
    )
}
