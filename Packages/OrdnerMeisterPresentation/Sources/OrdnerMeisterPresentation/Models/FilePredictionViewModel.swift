import Foundation
import OrdnerMeisterDomain

/// Presentation model for file classification results
public struct FilePredictionViewModel: Identifiable, Hashable {
    public var id: String { file.absoluteString }

    public let file: URL
    public let predictedOutputFolders: [URL]
    public let dateModified: Date?
    public let fileSize: Int64?

    public init(file: URL, predictedOutputFolders: [URL]) {
        self.file = file
        self.predictedOutputFolders = predictedOutputFolders

        // Fetch file attributes
        let attributes = try? FileManager.default.attributesOfItem(atPath: file.path)
        self.dateModified = attributes?[.modificationDate] as? Date
        self.fileSize = attributes?[.size] as? Int64
    }

    /// Creates a FilePredictionViewModel from a Domain Classification
    public init(from classification: Classification) {
        self.file = classification.file.url
        self.predictedOutputFolders = classification.predictions.map { $0.folder.url }

        // Fetch file attributes
        let attributes = try? FileManager.default.attributesOfItem(atPath: classification.file.url.path)
        self.dateModified = attributes?[.modificationDate] as? Date
        self.fileSize = attributes?[.size] as? Int64
    }
}
