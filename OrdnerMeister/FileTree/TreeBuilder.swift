//
//  TreeBuilder.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 30.12.2023.
//

import Foundation
import OSLog

struct TreeBuilder {
    let fileManager: FileManaging

    init(fileManager: FileManaging = FileManager.default) {
        self.fileManager = fileManager
    }

    func buildTree(from nodeURL: URL, ignoredDirectories: [String]? = nil) throws -> Node {
        Logger.fileProcessing.debug("Processing \(nodeURL)")

        var node = Node(url: nodeURL, children: [:])

        guard nodeURL.isDirectory else { return node }

        let contents = try fileManager.contentsOfDirectory(
            at: nodeURL,
            includingPropertiesForKeys: nil,
            options: []
        )

        node.children = try contents.reduce(into: [:]) { acc, url in
            let isIgnored = ignoredDirectories?.contains { $0 == url.absoluteString } ?? false
            guard !isIgnored else { return }
            acc[url.lastPathComponent] = try buildTree(from: url, ignoredDirectories: ignoredDirectories)
        }

        return node
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
