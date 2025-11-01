import Foundation
import Bayes
import NaturalLanguage
import OrdnerMeisterDomain
import OSLog

/// Concrete implementation of ClassificationRepositoryProtocol using Bayesian classification
/// Thread-safe actor that protects the Bayesian classifier from concurrent access
public actor ClassificationRepository: ClassificationRepositoryProtocol {
    private var bayesianClassifier: BayesianClassifier<URL, String>?
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "Classifier")

    public init() {}

    public func train(files: [File], folderLabels: [URL: Folder]) async throws {
        logger.info("Starting classifier training with \(files.count) files")

        // Group files by folder for logging
        var folderCounts: [String: Int] = [:]
        for file in files {
            if let folder = folderLabels[file.url] {
                let folderName = folder.url.lastPathComponent
                folderCounts[folderName, default: 0] += 1
            }
        }

        logger.info("Training data distribution: \(folderCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")

        var eventSpace = EventSpace<URL, String>()
        var totalTokens = 0

        for file in files {
            guard let folder = folderLabels[file.url] else {
                logger.warning("No folder label found for file: \(file.url.lastPathComponent)")
                continue
            }

            let tokens = file.textContent.tokenize()
            totalTokens += tokens.count
            eventSpace.observe(folder.url, features: tokens)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)

        logger.info("Classifier training completed: \(files.count) files, \(folderCounts.count) folders, \(totalTokens) total tokens")
    }

    public func classify(file: File, topN: Int) async throws -> [FilePrediction] {
        guard let classifier = bayesianClassifier else {
            logger.error("Attempted to classify before training: \(file.url.lastPathComponent)")
            throw ClassificationError.notTrained
        }

        let fileName = file.url.lastPathComponent
        logger.debug("Classifying file: \(fileName)")

        let tokens = file.textContent.tokenize()
        let logProbabilities = classifier.categoryProbabilities(tokens)

        // Convert log probabilities to actual probabilities using softmax normalization
        // This prevents numerical overflow and ensures probabilities sum to 1.0
        let maxLogProb = logProbabilities.values.max() ?? 0.0
        let expProbs = logProbabilities.mapValues { exp($0 - maxLogProb) }
        let sumExpProbs = expProbs.values.reduce(0.0, +)
        let normalizedProbs = expProbs.mapValues { $0 / sumExpProbs }

        let sorted = normalizedProbs.sorted { $0.value > $1.value }
        let topResults = Array(sorted.prefix(topN))

        if let topPrediction = topResults.first {
            let folderName = topPrediction.0.lastPathComponent
            logger.info("Classified '\(fileName)' -> '\(folderName)' (confidence: \(String(format: "%.2f%%", topPrediction.1 * 100)))")
        }

        return topResults.map { (folderURL, confidence) in
            FilePrediction(folder: Folder(url: folderURL), confidence: confidence)
        }
    }

    public func classifyBatch(files: [File], topN: Int, maxConcurrentTasks: Int = 8) async throws -> [Classification] {
        logger.info("Starting parallel batch classification for \(files.count) files (max \(maxConcurrentTasks) concurrent)")

        return try await withThrowingTaskGroup(of: Classification.self) { group in
            var classifications: [Classification] = []
            var activeTasks = 0
            var fileIterator = files.makeIterator()

            // Start initial batch of tasks up to the concurrency limit
            while activeTasks < maxConcurrentTasks, let file = fileIterator.next() {
                group.addTask {
                    // Check for cancellation before starting
                    try Task.checkCancellation()

                    let predictions = try await self.classify(file: file, topN: topN)
                    return Classification(file: file, predictions: predictions)
                }
                activeTasks += 1
            }

            // As tasks complete, add new ones to maintain concurrency
            for try await classification in group {
                // Check for cancellation between iterations
                try Task.checkCancellation()

                classifications.append(classification)

                // Add next task if available
                if let nextFile = fileIterator.next() {
                    group.addTask {
                        // Check for cancellation before starting
                        try Task.checkCancellation()

                        let predictions = try await self.classify(file: nextFile, topN: topN)
                        return Classification(file: nextFile, predictions: predictions)
                    }
                } else {
                    activeTasks -= 1
                }
            }

            logger.info("Parallel batch classification completed for \(files.count) files")
            return classifications
        }
    }

    public func reset() async throws {
        logger.info("Resetting classifier")
        bayesianClassifier = nil
    }
}

// MARK: - Tokenizer

private extension String {
    func tokenize() -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self

        var tokens = [String]()

        tokenizer.enumerateTokens(in: startIndex ..< endIndex) { tokenRange, _ -> Bool in
            let token = String(self[tokenRange].lowercased())
            tokens.append(token)
            return true
        }

        return tokens
    }
}

// MARK: - Errors

public enum ClassificationError: Error {
    case notTrained
}
