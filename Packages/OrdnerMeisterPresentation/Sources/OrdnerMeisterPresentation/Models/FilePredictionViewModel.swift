import Foundation
import OrdnerMeisterDomain

/// Presentation model for file classification results
public struct FilePredictionViewModel: Identifiable, Hashable {
    public var id: String { file.absoluteString }

    public let file: URL
    public let predictedOutputFolders: [URL]

    public init(file: URL, predictedOutputFolders: [URL]) {
        self.file = file
        self.predictedOutputFolders = predictedOutputFolders
    }

    /// Creates a FilePredictionViewModel from a Domain Classification
    public init(from classification: Classification) {
        self.file = classification.file.url
        self.predictedOutputFolders = classification.predictions.map { $0.folder.url }
    }
}
