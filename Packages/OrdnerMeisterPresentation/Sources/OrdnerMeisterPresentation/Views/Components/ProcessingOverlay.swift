import SwiftUI
import OrdnerMeisterDomain

/// An overlay that shows the delightful document sorting animation during processing
public struct ProcessingOverlay: View {
    let isProcessing: Bool
    let progress: ProcessingProgress?

    @State private var isVisible = false

    public init(isProcessing: Bool, progress: ProcessingProgress?) {
        self.isProcessing = isProcessing
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            if isVisible {
                // Semi-transparent backdrop
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Animation card
                VStack(spacing: 0) {
                    DocumentSortingAnimation(
                        progress: progress,
                        isAnimating: isProcessing
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onChange(of: isProcessing) { _, newValue in
            if newValue {
                // Fade in when processing starts
                isVisible = true
            } else {
                // Delay fade out to show completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isVisible = false
                }
            }
        }
        .onAppear {
            isVisible = isProcessing
        }
    }
}

// MARK: - View Extension for Easy Integration

extension View {
    /// Adds a processing overlay with the delightful document sorting animation
    ///
    /// - Parameters:
    ///   - isProcessing: Whether processing is currently active
    ///   - progress: The current processing progress information
    /// - Returns: A view with the processing overlay
    ///
    /// Example:
    /// ```swift
    /// MyView()
    ///     .withProcessingOverlay(
    ///         isProcessing: viewModel.status == .busy,
    ///         progress: viewModel.currentProgress
    ///     )
    /// ```
    public func withProcessingOverlay(
        isProcessing: Bool,
        progress: ProcessingProgress?
    ) -> some View {
        ZStack {
            self
            ProcessingOverlay(
                isProcessing: isProcessing,
                progress: progress
            )
        }
    }
}

// MARK: - Preview

#Preview("Processing Overlay") {
    VStack {
        Text("Your App Content")
            .font(.largeTitle)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .withProcessingOverlay(
        isProcessing: true,
        progress: ProcessingProgress(
            stage: .classifying(current: 8, total: 25),
            currentFileName: "Receipt_StoreX_2024.pdf"
        )
    )
}
