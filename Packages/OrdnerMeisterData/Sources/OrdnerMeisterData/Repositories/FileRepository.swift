import Foundation
import OrdnerMeisterDomain
import OSLog

/// Concrete implementation of FileRepositoryProtocol
public final class FileRepository: FileRepositoryProtocol {
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "FileSystem")

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func buildFileTree(from directory: DirectoryPath, excluding exclusions: [DirectoryPath]) async throws -> FileTree {
        logger.info("Building file tree from: \(directory.url.path)")
        let excludedStrings = exclusions.map { $0.url.absoluteString }

        do {
            let rootNode = try buildNode(from: directory.url, excludedPaths: excludedStrings)
            let tree = FileTree(root: rootNode)
            let fileCount = tree.flattenFiles().count
            let folderCount = tree.flattenFolders().count
            logger.info("File tree built: \(fileCount) files, \(folderCount) folders")
            return tree
        } catch {
            logger.error("Failed to build file tree from '\(directory.url.path)': \(error.localizedDescription)")
            throw error
        }
    }

    public func copyFile(from source: URL, to destination: URL) async throws {
        logger.debug("Copying file from '\(source.lastPathComponent)' to '\(destination.path)'")

        do {
            try fileManager.copyItem(at: source, to: destination)
            logger.info("Successfully copied: \(source.lastPathComponent)")
        } catch {
            logger.error("Failed to copy '\(source.lastPathComponent)': \(error.localizedDescription)")
            throw error
        }
    }

    public func fileExists(at url: URL) -> Bool {
        let exists = fileManager.fileExists(atPath: url.path)
        logger.debug("File existence check for '\(url.lastPathComponent)': \(exists)")
        return exists
    }

    public func getFiles(from directory: DirectoryPath, fileExtensions: [String]? = nil) async throws -> [URL] {
        let tree = try await buildFileTree(from: directory, excluding: [])
        let allFiles = tree.flattenFiles()

        // If no filter specified, return all files
        guard let extensions = fileExtensions, !extensions.isEmpty else {
            logger.info("Retrieved \(allFiles.count) files from: \(directory.url.lastPathComponent)")
            return allFiles
        }

        // Filter files by extension
        let filtered = allFiles.filter { url in
            let fileExtension = "." + url.pathExtension.lowercased()
            let normalizedExtensions = extensions.map { $0.lowercased() }
            return normalizedExtensions.contains(fileExtension)
        }

        logger.info("Retrieved \(filtered.count) files (filtered by \(extensions.joined(separator: ", "))) from: \(directory.url.lastPathComponent)")
        return filtered
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
