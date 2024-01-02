//
//  TreeBuilder.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 30.12.2023.
//

import Foundation
import OSLog

struct TreeBuilder {
    let fileManager: FileManager

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    func buildTree(from nodeURL: URL) throws -> Node {
        Logger.fileProcessing.debug("Processing \(nodeURL)")

        var node = Node(url: nodeURL, children: [:])

        guard checkIsDirectory(url: nodeURL) else {
            return node
        }

        let contents = try fileManager.contentsOfDirectory(at: nodeURL, includingPropertiesForKeys: nil)

        node.children = try contents.reduce(into: [:]) { acc, url in
            acc[url.lastPathComponent] = try buildTree(from: url)
        }

        return node
    }

    private func checkIsDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}
