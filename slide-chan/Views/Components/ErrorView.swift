import SwiftUI

/// A reusable view for displaying error messages with a retry option.
struct ErrorView: View {
    /// The error message to display.
    let message: String
    /// The action to perform when the retry button is tapped.
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ErrorView(message: "Failed to load content from 4chan. Please check your connection.") {
        print("Retry tapped")
    }
}
