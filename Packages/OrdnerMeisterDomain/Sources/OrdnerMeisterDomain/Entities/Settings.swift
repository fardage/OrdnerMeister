import Foundation

/// Domain entity representing application settings
public struct Settings {
    public let inboxPath: DirectoryPath
    public let outputPath: DirectoryPath
    public let exclusions: [DirectoryPath]

    public init(
        inboxPath: DirectoryPath,
        outputPath: DirectoryPath,
        exclusions: [DirectoryPath] = []
    ) {
        self.inboxPath = inboxPath
        self.outputPath = outputPath
        self.exclusions = exclusions
    }
}
