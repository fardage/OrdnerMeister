import SwiftUI
import OrdnerMeisterDomain

/// Detail view showing selected file information and actions
struct FileDetailView: View {
    let prediction: FilePredictionViewModel
    let onMove: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // File header
                VStack(alignment: .leading, spacing: 8) {
                    Text(prediction.file.lastPathComponent)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(prediction.file.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Divider()

                // File metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Information")
                        .font(.headline)

                    InfoRow(label: "Modified", value: formatDate(prediction.dateModified))
                    InfoRow(label: "Size", value: formatFileSize(prediction.fileSize))
                    InfoRow(label: "Type", value: prediction.file.pathExtension.uppercased())
                }

                Divider()

                // Predicted destination
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Folder")
                        .font(.headline)

                    if let destination = prediction.predictedOutputFolders.first {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.blue)
                            Text(destination.lastPathComponent)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)

                        Text(destination.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No prediction available")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Actions
                VStack(spacing: 12) {
                    Button(action: onMove) {
                        Label("Move to Suggested Folder", systemImage: "arrow.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prediction.predictedOutputFolders.isEmpty)

                    Button(action: {
                        // TODO: Implement custom folder picker in future
                    }) {
                        Label("Choose Different Folder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(true) // Will be enabled in future tasks
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("File Details")
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatFileSize(_ size: Int64?) -> String {
        guard let size = size else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

/// Helper view for displaying info rows
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
