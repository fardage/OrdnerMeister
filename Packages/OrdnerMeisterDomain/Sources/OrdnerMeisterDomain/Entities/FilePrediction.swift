import Foundation

/// Value object representing a prediction of which folder a file belongs to
public struct FilePrediction: Hashable {
    public let folder: Folder
    public let confidence: Double

    public init(folder: Folder, confidence: Double) {
        self.folder = folder
        self.confidence = confidence
    }
}

/// A file with its classification predictions
public struct Classification: Hashable {
    public let file: File
    public let predictions: [FilePrediction]

    public init(file: File, predictions: [FilePrediction]) {
        self.file = file
        self.predictions = predictions
    }

    /// The top prediction (highest confidence)
    public var topPrediction: FilePrediction? {
        predictions.first
    }
}
