import SwiftUI

public struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

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
