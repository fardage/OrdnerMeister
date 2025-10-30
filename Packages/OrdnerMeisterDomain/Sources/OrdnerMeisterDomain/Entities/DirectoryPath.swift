import Foundation

/// Value object representing a validated directory path
public struct DirectoryPath: Hashable, Codable {
    public let url: URL

    public init(url: URL) throws {
        // Validate that it's a directory
        guard url.hasDirectoryPath else {
            throw DirectoryPathError.notADirectory(url)
        }
        self.url = url
    }

    public init(string: String) throws {
        let url = URL(fileURLWithPath: string)
        try self.init(url: url)
    }

    public var path: String {
        url.path
    }
}

public enum DirectoryPathError: Error {
    case notADirectory(URL)
}
