import Foundation

/// Domain entity representing a hierarchical file tree structure
public struct FileTree {
    public let root: FileNode

    public init(root: FileNode) {
        self.root = root
    }

    /// Flatten the tree to a list of all file URLs
    public func flattenFiles() -> [URL] {
        root.flattenFiles()
    }

    /// Flatten the tree to a list of all folder URLs
    public func flattenFolders() -> [URL] {
        root.flattenFolders()
    }
}

/// A node in the file tree
public struct FileNode {
    public let url: URL
    public let isDirectory: Bool
    public let children: [FileNode]

    public init(url: URL, isDirectory: Bool, children: [FileNode] = []) {
        self.url = url
        self.isDirectory = isDirectory
        self.children = children
    }

    func flattenFiles() -> [URL] {
        if isDirectory {
            return children.flatMap { $0.flattenFiles() }
        } else {
            return [url]
        }
    }

    func flattenFolders() -> [URL] {
        if isDirectory {
            return [url] + children.flatMap { $0.flattenFolders() }
        } else {
            return []
        }
    }
}
