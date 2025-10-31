import Foundation
import OrdnerMeisterDomain

/// Concrete implementation of FileRepositoryProtocol
public final class FileRepository: FileRepositoryProtocol {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func buildFileTree(from directory: DirectoryPath, excluding exclusions: [DirectoryPath]) async throws -> FileTree {
        let excludedStrings = exclusions.map { $0.url.absoluteString }
        let rootNode = try buildNode(from: directory.url, excludedPaths: excludedStrings)
        return FileTree(root: rootNode)
    }

    public func copyFile(from source: URL, to destination: URL) async throws {
        try fileManager.copyItem(at: source, to: destination)
    }

    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    public func getFiles(from directory: DirectoryPath, fileExtensions: [String]? = nil) async throws -> [URL] {
        let tree = try await buildFileTree(from: directory, excluding: [])
        let allFiles = tree.flattenFiles()

        // If no filter specified, return all files
        guard let extensions = fileExtensions, !extensions.isEmpty else {
            return allFiles
        }

        // Filter files by extension
        return allFiles.filter { url in
            let fileExtension = "." + url.pathExtension.lowercased()
            let normalizedExtensions = extensions.map { $0.lowercased() }
            return normalizedExtensions.contains(fileExtension)
        }
    }

    // MARK: - Private Helper Methods

    private func buildNode(from url: URL, excludedPaths: [String]) throws -> FileNode {
        let isDirectory = url.isDirectory

        guard isDirectory else {
            return FileNode(url: url, isDirectory: false, children: [])
        }

        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let children: [FileNode] = try contents.compactMap { childURL in
            // Skip if excluded
            let isExcluded = excludedPaths.contains(childURL.absoluteString)
            guard !isExcluded else { return nil }

            return try buildNode(from: childURL, excludedPaths: excludedPaths)
        }

        return FileNode(url: url, isDirectory: true, children: children)
    }
}

// MARK: - URL Extension

private extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
