import SwiftUI
import OrdnerMeisterDomain

/// Bottom status indicator that appears during processing (Apple Mail-style)
struct BottomStatusIndicator: View {
    let status: HomeViewModel.Status
    let showCompletion: Bool

    var body: some View {
        if shouldShow {
            HStack(spacing: 8) {
                if status == .busy {
                    ProgressView()
                        .controlSize(.small)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if showCompletion {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Processing Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
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
}
