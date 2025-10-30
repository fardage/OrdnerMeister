import Foundation

/// Repository protocol for file classification using ML/Bayesian algorithms
public protocol ClassificationRepositoryProtocol {
    /// Train the classifier with files from folders
    func train(files: [File], folderLabels: [URL: Folder]) async throws

    /// Classify a single file and return predictions
    func classify(file: File, topN: Int) async throws -> [FilePrediction]

    /// Classify multiple files
    func classifyBatch(files: [File], topN: Int) async throws -> [Classification]

    /// Reset the classifier (clear training data)
    func reset() async throws
}
