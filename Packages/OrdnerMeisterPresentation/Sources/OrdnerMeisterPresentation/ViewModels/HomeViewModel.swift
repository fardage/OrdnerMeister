import Foundation
import Combine
import OrdnerMeisterDomain
import OSLog

/// ViewModel for the home screen that handles file classification and processing
@Observable
public final class HomeViewModel {
    public enum Status: Equatable {
        case ready
        case busy
        case done
        case error(String)
    }

    private let trainClassifierUseCase: TrainClassifierUseCase
    private let classifyFilesUseCase: ClassifyFilesUseCase
    private let moveFileUseCase: MoveFileUseCase
    private let getSettingsUseCase: GetSettingsUseCase
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "view")

    private var cancellables = Set<AnyCancellable>()
    private var completionTimer: Task<Void, Never>?

    public private(set) var status: Status = .ready
    public private(set) var predictions: [FilePredictionViewModel] = []
    public private(set) var processingResult: ProcessingResult?
    public private(set) var lastError: Error?
    public private(set) var showError: Bool = false
    public private(set) var showCompletionStatus: Bool = false
    public var selectedPredictionId: String?

    public var selectedPrediction: FilePredictionViewModel? {
        guard let selectedId = selectedPredictionId else { return nil }
        return predictions.first { $0.id == selectedId }
    }

    public var inboxPath: String {
        let settings = getSettingsUseCase.execute()
        return settings.inboxPath.url.lastPathComponent
    }

    public init(
        trainClassifierUseCase: TrainClassifierUseCase,
        classifyFilesUseCase: ClassifyFilesUseCase,
        moveFileUseCase: MoveFileUseCase,
        getSettingsUseCase: GetSettingsUseCase
    ) {
        self.trainClassifierUseCase = trainClassifierUseCase
        self.classifyFilesUseCase = classifyFilesUseCase
        self.moveFileUseCase = moveFileUseCase
        self.getSettingsUseCase = getSettingsUseCase
    }

    @MainActor
    public func processFolders() async {
        status = .busy
        predictions = []
        processingResult = nil
        lastError = nil

        logger.info("Starting folder processing workflow")

        do {
            // First, train the classifier on existing files
            logger.info("Training classifier...")
            let trainingResult = try await trainClassifierUseCase.execute()
            logger.info("Training completed: \(trainingResult.summaryMessage)")

            // Check if training had failures
            if trainingResult.hasFailures {
                logger.warning("Training completed with \(trainingResult.failureCount) errors")
            }

            // Then, classify files in inbox
            logger.info("Classifying files...")
            let (classificationResult, classifications) = try await classifyFilesUseCase.execute()
            logger.info("Classification completed: \(classificationResult.summaryMessage)")

            // Store the processing result
            processingResult = classificationResult

            // Convert to presentation models
            predictions = classifications.map { FilePredictionViewModel(from: $0) }

            // Determine status based on results
            if classificationResult.hasFailures {
                status = .done // Show results even with partial failures
                logger.warning("Processing completed with errors")
            } else {
                status = .done
                logger.info("Processing completed successfully")
            }

            // Show completion status briefly, then hide
            showCompletionIndicator()
        } catch {
            // Handle critical error
            lastError = error
            showError = true
            status = .error(error.localizedDescription)
            logger.error("Error processing folders: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func showCompletionIndicator() {
        // Cancel any existing timer
        completionTimer?.cancel()

        // Show completion status
        showCompletionStatus = true

        // Hide after 2.5 seconds
        completionTimer = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                showCompletionStatus = false
                status = .ready
            }
        }
    }

    @MainActor
    public func dismissError() {
        showError = false
        lastError = nil
    }

    @MainActor
    public func onPredictionClick(prediction: FilePredictionViewModel) async {
        guard let destinationFolder = prediction.predictedOutputFolders.first else {
            logger.warning("No destination folder for prediction: \(prediction.file.lastPathComponent)")
            return
        }

        let fileName = prediction.file.lastPathComponent
        logger.info("User confirmed move for: \(fileName)")

        do {
            try await moveFileUseCase.execute(
                file: prediction.file,
                to: destinationFolder
            )

            // Remove the prediction from the list after successful move
            predictions.removeAll { $0.id == prediction.id }

            // Clear selection if the removed file was selected
            if selectedPredictionId == prediction.id {
                selectedPredictionId = nil
            }

            // If no more predictions, mark as ready
            if predictions.isEmpty {
                status = .ready
                logger.info("All files processed, returning to ready state")
            }
        } catch {
            lastError = error
            showError = true
            logger.error("Error moving file '\(fileName)': \(error.localizedDescription)")
            // Don't change status - allow user to retry or skip
        }
    }
}
