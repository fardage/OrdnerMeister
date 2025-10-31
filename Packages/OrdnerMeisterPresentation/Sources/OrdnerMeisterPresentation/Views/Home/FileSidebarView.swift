import SwiftUI
import OrdnerMeisterDomain

/// Sidebar view showing list of files to process with StatusBar header
struct FileSidebarView: View {
    let predictions: [FilePredictionViewModel]
    let status: HomeViewModel.Status
    @Binding var selectedPredictionId: String?
    let onPredictionClick: (FilePredictionViewModel) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // StatusBar in header
            StatusBar(status: status)
                .padding(.horizontal)
                .padding(.top)

            // File list
            if predictions.isEmpty {
                ContentUnavailableView(
                    "No Files to Process",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Click 'Process Folders' to scan for files")
                )
            } else {
                List(predictions, selection: $selectedPredictionId) { prediction in
                    FileSidebarRow(
                        prediction: prediction,
                        onMove: { onPredictionClick(prediction) }
                    )
                    .tag(prediction.id)
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Files")
    }
}

/// Row view for each file in the sidebar
struct FileSidebarRow: View {
    let prediction: FilePredictionViewModel
    let onMove: () -> Void

    var body: some View {
        HStack {
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

            Spacer()

            Button("Move") {
                onMove()
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
