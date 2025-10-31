import SwiftUI
import OrdnerMeisterDomain
import AppKit

/// Detail view showing selected file information and actions (macOS Mail-style)
struct FileDetailView: View {
    let prediction: FilePredictionViewModel
    let onMove: (URL) -> Void

    @State private var selectedPredictionIndex: Int = 0

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

            // Suggested Folders section (up to 3)
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggested Folders")
                    .font(.headline)

                if prediction.predictions.isEmpty {
                    Text("No prediction available")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(prediction.predictions.prefix(3).enumerated()), id: \.offset) { index, pred in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: index == 0 ? "folder.fill" : "folder")
                                        .foregroundStyle(selectedPredictionIndex == index ? .blue : .secondary)

                                    Text(pred.folder.lastPathComponent)
                                        .font(.body)
                                        .fontWeight(selectedPredictionIndex == index ? .semibold : .regular)

                                    Spacer()

                                    // Confidence percentage
                                    Text("\(Int(pred.confidence * 100))%")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }

                                // Folder path
                                Text(pred.folder.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                // Confidence bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(height: 4)

                                        // Confidence fill
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(selectedPredictionIndex == index ? Color.blue : Color.secondary)
                                            .frame(width: geometry.size.width * pred.confidence, height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedPredictionIndex == index ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPredictionIndex == index ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture {
                                selectedPredictionIndex = index
                            }
                        }
                    }
                }
            }
            .padding()

            Divider()

            // PDF Preview - fills remaining space
            PDFPreviewView(fileURL: prediction.file)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))

            // Bottom action bar
            if !prediction.predictions.isEmpty {
                Divider()

                HStack(spacing: 12) {
                    Button(action: {
                        showFolderPicker()
                    }) {
                        Label("Choose Other Folder...", systemImage: "folder")
                    }

                    Spacer()

                    Button(action: {
                        let selectedFolder = prediction.predictions[selectedPredictionIndex].folder
                        onMove(selectedFolder)
                    }) {
                        Label("Move to Selected Folder", systemImage: "arrow.right.square.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
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

    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.title = "Choose Destination Folder"
        panel.message = "Select a folder to move the file to"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let selectedURL = panel.url {
                onMove(selectedURL)
            }
        }
    }
}
