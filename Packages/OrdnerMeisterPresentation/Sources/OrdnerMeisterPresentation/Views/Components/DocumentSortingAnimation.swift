import SwiftUI
import OrdnerMeisterDomain

/// A delightful loading animation showing documents flying into a folder
public struct DocumentSortingAnimation: View {
    let progress: ProcessingProgress?
    let isAnimating: Bool

    @State private var documentPositions: [DocumentState] = []
    @State private var folderScale: CGFloat = 1.0
    @State private var folderGlow: Double = 0.0
    @State private var animationTimer: Timer?

    private let numberOfDocuments = 5

    public init(progress: ProcessingProgress?, isAnimating: Bool) {
        self.progress = progress
        self.isAnimating = isAnimating
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Main animation area
            ZStack {
                // Folder icon (destination)
                FolderIcon()
                    .frame(width: 80, height: 80)
                    .scaleEffect(folderScale)
                    .shadow(color: .accentColor.opacity(folderGlow), radius: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: folderScale)
                    .animation(.easeInOut(duration: 0.4), value: folderGlow)

                // Floating documents
                ForEach(documentPositions.indices, id: \.self) { index in
                    DocumentIcon(
                        color: documentColor(for: index),
                        rotation: documentPositions[index].rotation
                    )
                    .frame(width: 30, height: 36)
                    .offset(documentPositions[index].offset)
                    .opacity(documentPositions[index].opacity)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.7)
                        .delay(Double(index) * 0.1),
                        value: documentPositions[index].offset
                    )
                    .animation(
                        .easeInOut(duration: 0.3)
                        .delay(Double(index) * 0.1),
                        value: documentPositions[index].opacity
                    )
                }
            }
            .frame(height: 200)

            // Progress text
            VStack(spacing: 8) {
                Text(progressText)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let fileName = progress?.currentFileName {
                    Text(fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 300)
                }

                // Progress bar
                if let progressValue = progress?.progress {
                    ProgressView(value: progressValue, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                        .tint(.accentColor)
                }
            }
        }
        .padding(40)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    // MARK: - Animation Logic

    private func startAnimation() {
        guard isAnimating else { return }

        // Initialize document positions
        documentPositions = (0..<numberOfDocuments).map { _ in
            DocumentState.random()
        }

        // Start the animation loop
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                animateDocumentCycle()
            }
        }

        // Trigger first animation immediately
        animateDocumentCycle()
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func animateDocumentCycle() {
        // Pick a random document to animate
        guard let index = documentPositions.indices.randomElement() else { return }

        // Phase 1: Float in from a random position
        let startOffset = CGSize(
            width: CGFloat.random(in: -150...150),
            height: CGFloat.random(in: -100...(-50))
        )

        documentPositions[index].offset = startOffset
        documentPositions[index].opacity = 1.0
        documentPositions[index].rotation = Double.random(in: -15...15)

        // Phase 2: Swirl towards the folder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            documentPositions[index].offset = CGSize(
                width: CGFloat.random(in: -30...30),
                height: CGFloat.random(in: -30...30)
            )
            documentPositions[index].rotation = Double.random(in: -5...5)
        }

        // Phase 3: Fly into the folder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            documentPositions[index].offset = .zero
            documentPositions[index].opacity = 0.0
            documentPositions[index].rotation = 0

            // Folder reaction - pulse and glow
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                folderScale = 1.1
                folderGlow = 0.8
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    folderScale = 1.0
                    folderGlow = 0.0
                }
            }
        }

        // Reset for next cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            documentPositions[index] = DocumentState.random()
        }
    }

    private var progressText: String {
        guard let progress = progress else {
            return "Organizing your documents..."
        }

        switch progress.stage {
        case .training(let current, let total):
            return "Learning your filing system (\(current)/\(total))"
        case .classifying(let current, let total):
            return "Sorting your documents (\(current)/\(total))"
        }
    }

    private func documentColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue,
            .green,
            .orange,
            .purple,
            .pink
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Supporting Types

private struct DocumentState {
    var offset: CGSize
    var opacity: Double
    var rotation: Double

    static func random() -> DocumentState {
        DocumentState(
            offset: CGSize(
                width: CGFloat.random(in: -150...150),
                height: CGFloat.random(in: -100...(-50))
            ),
            opacity: 0.0,
            rotation: Double.random(in: -15...15)
        )
    }
}

// MARK: - Document Icon

private struct DocumentIcon: View {
    let color: Color
    let rotation: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main document body
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Folded corner
            Path { path in
                path.move(to: CGPoint(x: 20, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 10))
                path.closeSubpath()
            }
            .fill(color.opacity(0.9))

            // Document lines
            VStack(spacing: 3) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 2)
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 14)
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Folder Icon

private struct FolderIcon: View {
    var body: some View {
        ZStack {
            // Folder back
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.6),
                            Color.accentColor.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 50)
                .offset(y: 5)

            // Folder tab
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.7))
                .frame(width: 30, height: 8)
                .offset(x: -15, y: -20)

            // Folder front
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.7),
                            Color.accentColor.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 55)

            // Folder opening highlight
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 80, height: 55)
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview("Animating") {
    DocumentSortingAnimation(
        progress: ProcessingProgress(
            stage: .classifying(current: 12, total: 50),
            currentFileName: "Invoice_2024_Q3.pdf"
        ),
        isAnimating: true
    )
    .frame(width: 400, height: 400)
}

#Preview("Dark Mode") {
    DocumentSortingAnimation(
        progress: ProcessingProgress(
            stage: .training(current: 5, total: 20),
            currentFileName: "Contract_Signed.pdf"
        ),
        isAnimating: true
    )
    .frame(width: 400, height: 400)
    .preferredColorScheme(.dark)
}
