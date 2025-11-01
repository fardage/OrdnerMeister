import Foundation

/// Repository protocol for file classification using ML/Bayesian algorithms
public protocol ClassificationRepositoryProtocol {
    /// Train the classifier with files from folders
    func train(files: [File], folderLabels: [URL: Folder]) async throws

    /// Classify a single file and return predictions
    func classify(file: File, topN: Int) async throws -> [FilePrediction]

    /// Classify multiple files in parallel
    /// - Parameters:
    ///   - files: Files to classify
    ///   - topN: Number of top predictions to return per file
    ///   - maxConcurrentTasks: Maximum number of concurrent classification tasks (default: 8)
    /// - Returns: Array of classifications for each file
    func classifyBatch(files: [File], topN: Int, maxConcurrentTasks: Int) async throws -> [Classification]

    /// Reset the classifier (clear training data)
    func reset() async throws
}
