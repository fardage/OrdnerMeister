import SwiftUI
import OrdnerMeisterDomain

/// Sidebar view showing list of files to process (Apple Notes-style)
struct FileSidebarView: View {
    let predictions: [FilePredictionViewModel]
    let status: HomeViewModel.Status
    let showCompletionStatus: Bool
    let currentProgress: ProcessingProgress?
    let inboxPath: String
    @Binding var selectedPredictionId: String?
    let onPredictionClick: (FilePredictionViewModel) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Inbox folder header (always visible, like Apple Notes)
            InboxFolderHeader(
                folderName: inboxPath,
                fileCount: predictions.count
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // File list
            if predictions.isEmpty {
                Spacer()
            } else {
                List(predictions, selection: $selectedPredictionId) { prediction in
                    FileSidebarRow(prediction: prediction)
                        .tag(prediction.id)
                        .listRowSeparator(.visible)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                onPredictionClick(prediction)
                            } label: {
                                Label("Move", systemImage: "arrow.right.square")
                            }
                            .tint(.blue)
                        }
                }
                .listStyle(.sidebar)
            }

            // Bottom status indicator (Apple Mail-style)
            BottomStatusIndicator(
                status: status,
                showCompletion: showCompletionStatus,
                currentProgress: currentProgress,
                onCancel: onCancel
            )
            .animation(.easeInOut(duration: 0.3), value: status)
            .animation(.easeInOut(duration: 0.3), value: showCompletionStatus)
            .animation(.easeInOut(duration: 0.3), value: currentProgress?.progress)
        }
        .navigationTitle("Files")
    }
}

/// Inbox folder header showing folder name and file count
struct InboxFolderHeader: View {
    let folderName: String
    let fileCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(folderName)
                    .font(.headline)
                Text("\(fileCount) \(fileCount == 1 ? "file" : "files") available to sort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

/// Row view for each file in the sidebar
struct FileSidebarRow: View {
    let prediction: FilePredictionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(prediction.file.lastPathComponent)
                .font(.headline)

            if let date = prediction.dateModified {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let destination = prediction.predictedOutputFolders.first {
                Text("→ \(destination.lastPathComponent)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
