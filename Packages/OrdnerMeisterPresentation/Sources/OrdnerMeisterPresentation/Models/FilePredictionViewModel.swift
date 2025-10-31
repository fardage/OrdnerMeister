import Foundation
import OrdnerMeisterDomain

/// Presentation model for a single prediction with confidence
public struct PredictionViewModel: Hashable {
    public let folder: URL
    public let confidence: Double

    public init(folder: URL, confidence: Double) {
        self.folder = folder
        self.confidence = confidence
    }
}

/// Presentation model for file classification results
public struct FilePredictionViewModel: Identifiable, Hashable {
    public var id: String { file.absoluteString }

    public let file: URL
    public let predictions: [PredictionViewModel]
    public let dateModified: Date?
    public let fileSize: Int64?

    /// Legacy accessor for backward compatibility - returns just folder URLs
    public var predictedOutputFolders: [URL] {
        predictions.map { $0.folder }
    }

    public init(file: URL, predictions: [PredictionViewModel]) {
        self.file = file
        self.predictions = predictions

        // Fetch file attributes
        let attributes = try? FileManager.default.attributesOfItem(atPath: file.path)
        self.dateModified = attributes?[.modificationDate] as? Date
        self.fileSize = attributes?[.size] as? Int64
    }

    /// Creates a FilePredictionViewModel from a Domain Classification
    public init(from classification: Classification) {
        self.file = classification.file.url
        self.predictions = classification.predictions.map {
            PredictionViewModel(folder: $0.folder.url, confidence: $0.confidence)
        }

        // Fetch file attributes
        let attributes = try? FileManager.default.attributesOfItem(atPath: classification.file.url.path)
        self.dateModified = attributes?[.modificationDate] as? Date
        self.fileSize = attributes?[.size] as? Int64
    }
}
