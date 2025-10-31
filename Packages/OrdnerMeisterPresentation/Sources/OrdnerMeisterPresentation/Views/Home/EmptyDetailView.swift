import SwiftUI
import OrdnerMeisterDomain

/// Empty state view shown when no file is selected
struct EmptyDetailView: View {
    let status: HomeViewModel.Status
    let onProcessFolders: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon and message
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No File Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select a file from the sidebar to view details")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Process Folders button
            if status == .ready {
                Button(action: {
                    Task {
                        await onProcessFolders()
                    }
                }) {
                    Label("Process Folders", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
