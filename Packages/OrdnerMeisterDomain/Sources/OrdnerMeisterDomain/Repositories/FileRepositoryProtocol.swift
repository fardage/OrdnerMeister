import Foundation

/// Repository protocol for file system operations
public protocol FileRepositoryProtocol {
    /// Build a file tree from a directory
    func buildFileTree(from directory: DirectoryPath, excluding: [DirectoryPath]) async throws -> FileTree

    /// Copy a file to a destination folder
    func copyFile(from source: URL, to destination: URL) async throws

    /// Delete a file at the specified URL
    func deleteFile(at url: URL) async throws

    /// Check if a path exists
    func fileExists(at url: URL) -> Bool

    /// Get all files from a directory (flat list)
    /// - Parameters:
    ///   - directory: The directory to scan
    ///   - fileExtensions: Optional array of file extensions to filter (e.g., [".pdf", ".txt"]). If nil, returns all files.
    func getFiles(from directory: DirectoryPath, fileExtensions: [String]?) async throws -> [URL]
}
