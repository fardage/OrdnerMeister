import SwiftUI
import OrdnerMeisterDomain

/// Detail view showing selected file information and actions (macOS Mail-style)
struct FileDetailView: View {
    let prediction: FilePredictionViewModel
    let onMove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Compact header (Mail-style)
            VStack(alignment: .leading, spacing: 8) {
                Text(prediction.file.lastPathComponent)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(prediction.file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                // Compact metadata row
                Text(compactMetadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Suggested Folder section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Folder")
                            .font(.headline)

                        if let destination = prediction.predictedOutputFolders.first {
                            HStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .foregroundStyle(.blue)
                                Text(destination.lastPathComponent)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }

                            Text(destination.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No prediction available")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // PDF Preview
                    PDFPreviewView(fileURL: prediction.file)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 300)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    // TODO: Implement custom folder picker in future
                }) {
                    Label("Choose Folder", systemImage: "folder")
                }
                .disabled(true) // Will be enabled in future tasks

                Button(action: onMove) {
                    Label("Move to Suggested Folder", systemImage: "arrow.right.square")
                }
                .disabled(prediction.predictedOutputFolders.isEmpty)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .navigationTitle("File Details")
    }

    private var compactMetadata: String {
        let date = formatDate(prediction.dateModified)
        let size = formatFileSize(prediction.fileSize)
        let type = prediction.file.pathExtension.uppercased()
        return "Modified: \(date) • Size: \(size) • Type: \(type)"
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
