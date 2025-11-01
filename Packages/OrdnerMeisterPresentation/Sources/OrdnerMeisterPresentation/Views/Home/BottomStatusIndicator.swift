import SwiftUI
import OrdnerMeisterDomain

/// Bottom status indicator that appears during processing (Apple Mail-style)
struct BottomStatusIndicator: View {
    let status: HomeViewModel.Status
    let showCompletion: Bool
    let currentProgress: ProcessingProgress?
    let onCancel: () -> Void

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if status == .busy {
                        ProgressView()
                            .controlSize(.small)

                        VStack(alignment: .leading, spacing: 2) {
                            // Main status text
                            Text(progressText)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Current file name (if available)
                            if let fileName = currentProgress?.currentFileName {
                                Text(fileName)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    } else if showCompletion {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Processing Complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Cancel button (only when busy)
                    if status == .busy {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }

                // Progress bar (only when processing with progress info)
                if status == .busy, let progress = currentProgress {
                    ProgressView(value: progress.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var shouldShow: Bool {
        status == .busy || showCompletion
    }

    private var progressText: String {
        guard let progress = currentProgress else {
            return "Processing..."
        }

        switch progress.stage {
        case .training(let current, let total):
            return "Training classifier (\(current)/\(total))"
        case .classifying(let current, let total):
            return "Classifying files (\(current)/\(total))"
        }
    }
}
