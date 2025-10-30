import Foundation

/// Repository protocol for file system operations
public protocol FileRepositoryProtocol {
    /// Build a file tree from a directory
    func buildFileTree(from directory: DirectoryPath, excluding: [DirectoryPath]) async throws -> FileTree

    /// Copy a file to a destination folder
    func copyFile(from source: URL, to destination: URL) async throws

    /// Check if a path exists
    func fileExists(at url: URL) -> Bool

    /// Get all files from a directory (flat list)
    func getFiles(from directory: DirectoryPath) async throws -> [URL]
}
