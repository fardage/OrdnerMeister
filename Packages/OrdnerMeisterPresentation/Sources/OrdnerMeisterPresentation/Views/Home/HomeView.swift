import SwiftUI
import OrdnerMeisterDomain

public struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var showingResultAlert = false
    @State private var showingErrorAlert = false

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            StatusBar(status: viewModel.status)
            ActionableFilesView(
                predictions: viewModel.predictions,
                onPredictionClick: { prediction in
                    Task {
                        await viewModel.onPredictionClick(prediction: prediction)
                    }
                }
            )
            Button("Process Folders") {
                Task {
                    await viewModel.processFolders()
                }
            }
            .disabled(viewModel.status == .busy)
        }
        .padding()
        .alert("Processing Complete", isPresented: $showingResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = viewModel.processingResult {
                Text(resultAlertMessage(for: result))
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
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
        case .error:
            showingErrorAlert = true
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

struct ActionableFilesView: View {
    let predictions: [FilePredictionViewModel]
    let onPredictionClick: (FilePredictionViewModel) -> Void

    var body: some View {
        if predictions.isEmpty {
            Text("No files to process")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(predictions) { prediction in
                FileRowView(
                    prediction: prediction,
                    onClick: { onPredictionClick(prediction) }
                )
            }
        }
    }
}

struct FileRowView: View {
    let prediction: FilePredictionViewModel
    let onClick: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(prediction.file.lastPathComponent)
                    .font(.headline)
                if let destination = prediction.predictedOutputFolders.first {
                    Text("→ \(destination.lastPathComponent)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Move") {
                onClick()
            }
        }
        .padding(.vertical, 4)
    }
}
