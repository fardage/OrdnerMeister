import Foundation

/// Represents the current stage of file processing
public enum ProcessingStage: Sendable, Equatable {
    case training(current: Int, total: Int)
    case classifying(current: Int, total: Int)

    public var description: String {
        switch self {
        case .training(let current, let total):
            return "Training classifier (\(current)/\(total))"
        case .classifying(let current, let total):
            return "Classifying files (\(current)/\(total))"
        }
    }

    public var progress: Double {
        switch self {
        case .training(let current, let total):
            return total > 0 ? Double(current) / Double(total) : 0.0
        case .classifying(let current, let total):
            return total > 0 ? Double(current) / Double(total) : 0.0
        }
    }
}

/// Progress update during file processing
public struct ProcessingProgress: Sendable, Equatable {
    public let stage: ProcessingStage
    public let currentFileName: String?

    public init(stage: ProcessingStage, currentFileName: String? = nil) {
        self.stage = stage
        self.currentFileName = currentFileName
    }

    /// Overall progress as a percentage (0.0 to 1.0)
    public var progress: Double {
        stage.progress
    }

    /// Human-readable description of current progress
    public var description: String {
        var desc = stage.description
        if let fileName = currentFileName {
            desc += " - \(fileName)"
        }
        return desc
    }
}
