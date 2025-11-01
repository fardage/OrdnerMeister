import SwiftUI
import OrdnerMeisterDomain

public struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var showingResultAlert = false
    @Environment(\.openSettings) private var openSettings

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar: File list with inbox header and bottom status
            FileSidebarView(
                predictions: viewModel.predictions,
                status: viewModel.status,
                showCompletionStatus: viewModel.showCompletionStatus,
                currentProgress: viewModel.currentProgress,
                inboxPath: viewModel.inboxPath,
                selectedPredictionId: $viewModel.selectedPredictionId,
                onPredictionClick: { prediction in
                    Task {
                        await viewModel.onPredictionClick(prediction: prediction)
                    }
                },
                onCancel: {
                    viewModel.cancelProcessing()
                }
            )
        } detail: {
            // Detail: File details or empty state
            if let selectedPrediction = viewModel.selectedPrediction {
                FileDetailView(
                    prediction: selectedPrediction,
                    onMove: { selectedFolder in
                        Task {
                            await viewModel.moveFile(prediction: selectedPrediction, to: selectedFolder)
                        }
                    }
                )
            } else {
                EmptyDetailView(
                    status: viewModel.status,
                    onProcessFolders: {
                        await viewModel.processFolders()
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    openSettings()
                }) {
                    Label("Settings", systemImage: "gear")
                }
                .help("Open Settings")
            }
        }
        .alert("Processing Complete", isPresented: $showingResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = viewModel.processingResult {
                Text(resultAlertMessage(for: result))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.showError },
            set: { if !$0 { Task { @MainActor in viewModel.dismissError() } } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: viewModel.status) { oldValue, newValue in
            handleStatusChange(newValue)
        }
    }

    private func handleStatusChange(_ newStatus: HomeViewModel.Status) {
        switch newStatus {
        case .done:
            showingResultAlert = true
        default:
            break
        }
    }

    private func resultAlertMessage(for result: ProcessingResult) -> String {
        var message = result.summaryMessage

        if result.hasFailures {
            message += "\n\nFailed files:"
            for error in result.errors.prefix(5) {
                message += "\n• \(error.fileName)"
            }
            if result.errors.count > 5 {
                message += "\n• and \(result.errors.count - 5) more..."
            }
        }

        return message
    }
}

struct StatusBar: View {
    let status: HomeViewModel.Status

    var body: some View {
        HStack {
            Text(statusText)
                .font(.headline)
            Spacer()
            if status == .busy {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding()
        .background(statusColor)
        .cornerRadius(8)
    }

    private var statusText: String {
        switch status {
        case .ready:
            return "Ready"
        case .busy:
            return "Processing..."
        case .done:
            return "Done"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var statusColor: Color {
        switch status {
        case .ready:
            return Color.gray.opacity(0.2)
        case .busy:
            return Color.blue.opacity(0.2)
        case .done:
            return Color.green.opacity(0.2)
        case .error:
            return Color.red.opacity(0.2)
        }
    }
}

