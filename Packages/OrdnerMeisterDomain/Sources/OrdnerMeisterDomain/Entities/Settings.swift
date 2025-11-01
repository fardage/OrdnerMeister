import Foundation

/// File operation behavior when organizing files
public enum FileOperationMode: String, Codable, CaseIterable {
    case copy // Copy file to destination, keep in inbox
    case move // Move file to destination, delete from inbox

    public var displayName: String {
        switch self {
        case .copy: return "Copy (keep in inbox)"
        case .move: return "Move (remove from inbox)"
        }
    }
}

/// Domain entity representing application settings
public struct Settings {
    public let inboxPath: DirectoryPath
    public let outputPath: DirectoryPath
    public let exclusions: [DirectoryPath]
    public let fileOperationMode: FileOperationMode

    public init(
        inboxPath: DirectoryPath,
        outputPath: DirectoryPath,
        exclusions: [DirectoryPath] = [],
        fileOperationMode: FileOperationMode = .copy
    ) {
        self.inboxPath = inboxPath
        self.outputPath = outputPath
        self.exclusions = exclusions
        self.fileOperationMode = fileOperationMode
    }
}
