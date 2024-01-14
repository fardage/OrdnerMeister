//
//  TextScrapper.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import OSLog
import PDFKit

struct DataTable: Codable {
    let folderURL: [URL]
    let textualContent: [String]
}

struct TextScrapper {
    private let pdfKitWrapper: PDFKitWrapping

    init(pdfKitWrapper: PDFKitWrapping = PDFKitWrapper()) {
        self.pdfKitWrapper = pdfKitWrapper
    }

    func extractText(from node: Node, using cache: DataTable? = nil, onFolderLevel: Bool = false) -> DataTable {
        let newNodeWithText = extractTextFromNode(from: node, using: cache)
        return createDictionary(from: newNodeWithText, onFolderLevel: onFolderLevel)
    }

    private func extractTextFromNode(from node: Node, using cache: DataTable? = nil) -> Node {
        var newNode = Node(url: node.url, children: [:])

        guard node.children.count != 0 else {
            Logger.fileProcessing.debug("Extrating text from \(node.url)")

            if let urlCacheIndex = cache?.folderURL.firstIndex(of: node.url),
               let cachedText = cache?.textualContent[urlCacheIndex]
            {
                newNode.textualContent = cachedText
                return newNode
            } else {
                newNode.textualContent = extractTextFromPDF(from: node.url)
                return newNode
            }
        }

        let children = node.children.reduce(into: [String: Node]()) { acc, child in
            let name = child.key
            let node = child.value
            acc[name] = extractTextFromNode(from: node)
        }
        newNode.children = children
        return newNode
    }

    private func createDictionary(from rootNode: Node, onFolderLevel: Bool) -> DataTable {
        var folderURL = [URL]()
        var textualContentList = [String]()
        var queue = [Node]()
        queue.append(rootNode)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if let textualContent = current.textualContent {
                let fileURL = current.url
                let parentURL = current.url.deletingLastPathComponent()
                folderURL.append(onFolderLevel ? parentURL : fileURL)
                textualContentList.append(textualContent)
            }

            current.children.forEach { child in
                queue.append(child.value)
            }
        }

        return DataTable(folderURL: folderURL, textualContent: textualContentList)
    }

    private func extractTextFromFile(from file: URL) -> String? {
        if file.pathExtension == "pdf" {
            extractTextFromPDF(from: file)
        } else {
            nil
        }
    }

    private func extractTextFromPDF(from file: URL) -> String? {
        pdfKitWrapper.extractText(from: file)
    }
}
