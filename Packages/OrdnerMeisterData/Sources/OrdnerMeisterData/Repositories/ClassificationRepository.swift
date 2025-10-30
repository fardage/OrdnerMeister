import Foundation
import Bayes
import NaturalLanguage
import OrdnerMeisterDomain

/// Concrete implementation of ClassificationRepositoryProtocol using Bayesian classification
public final class ClassificationRepository: ClassificationRepositoryProtocol {
    private var bayesianClassifier: BayesianClassifier<URL, String>?

    public init() {}

    public func train(files: [File], folderLabels: [URL: Folder]) async throws {
        var eventSpace = EventSpace<URL, String>()

        for file in files {
            guard let folder = folderLabels[file.url] else { continue }

            let tokens = file.textContent.tokenize()
            eventSpace.observe(folder.url, features: tokens)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)
    }

    public func classify(file: File, topN: Int) async throws -> [FilePrediction] {
        guard let classifier = bayesianClassifier else {
            throw ClassificationError.notTrained
        }

        let tokens = file.textContent.tokenize()
        let categoryProbabilities = classifier.categoryProbabilities(tokens)

        let sorted = categoryProbabilities.sorted { $0.value > $1.value }
        let topResults = Array(sorted.prefix(topN))

        return topResults.map { (folderURL, confidence) in
            FilePrediction(folder: Folder(url: folderURL), confidence: confidence)
        }
    }

    public func classifyBatch(files: [File], topN: Int) async throws -> [Classification] {
        var classifications: [Classification] = []

        for file in files {
            let predictions = try await classify(file: file, topN: topN)
            classifications.append(Classification(file: file, predictions: predictions))
        }

        return classifications
    }

    public func reset() async throws {
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
