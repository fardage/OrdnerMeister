import Foundation
import Combine
import OrdnerMeisterDomain

/// ViewModel for the home screen that handles file classification and processing
@Observable
public final class HomeViewModel {
    public enum Status {
        case ready
        case busy
        case done
    }

    private let trainClassifierUseCase: TrainClassifierUseCase
    private let classifyFilesUseCase: ClassifyFilesUseCase
    private let moveFileUseCase: MoveFileUseCase

    private var cancellables = Set<AnyCancellable>()

    public private(set) var status: Status = .ready
    public private(set) var predictions: [FilePredictionViewModel] = []

    public init(
        trainClassifierUseCase: TrainClassifierUseCase,
        classifyFilesUseCase: ClassifyFilesUseCase,
        moveFileUseCase: MoveFileUseCase
    ) {
        self.trainClassifierUseCase = trainClassifierUseCase
        self.classifyFilesUseCase = classifyFilesUseCase
        self.moveFileUseCase = moveFileUseCase
    }

    @MainActor
    public func processFolders() async {
        status = .busy
        predictions = []

        do {
            // First, train the classifier on existing files
            try await trainClassifierUseCase.execute()

            // Then, classify files in inbox
            let classifications = try await classifyFilesUseCase.execute()

            // Convert to presentation models
            predictions = classifications.map { FilePredictionViewModel(from: $0) }

            status = .done
        } catch {
            // Handle error
            status = .ready
            print("Error processing folders: \(error)")
        }
    }

    @MainActor
    public func onPredictionClick(prediction: FilePredictionViewModel) async {
        guard let destinationFolder = prediction.predictedOutputFolders.first else {
            return
        }

        do {
            try await moveFileUseCase.execute(
                file: prediction.file,
                to: destinationFolder
            )

            // Remove the prediction from the list after successful move
            predictions.removeAll { $0.id == prediction.id }

            // If no more predictions, mark as ready
            if predictions.isEmpty {
                status = .ready
            }
        } catch {
            print("Error moving file: \(error)")
        }
    }
}
