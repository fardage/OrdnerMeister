//
//  TextScrapper.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import OSLog
import PDFKit

struct DataTable {
    let folderURL: [URL]
    let textualContent: [String]
}

class TextScrapper {
    private let pdfKitWrapper: PDFKitWrapping
    private var textStore: TextStoring
    private var textCache: [URL: String]

    init(pdfKitWrapper: PDFKitWrapping = PDFKitWrapper(), textStore: TextStoring = TextStore()) {
        self.pdfKitWrapper = pdfKitWrapper
        self.textStore = textStore
        textCache = textStore.getCache()
    }

    func extractText(from node: Node, onFolderLevel: Bool = false) -> DataTable {
        var newNodeWithText = extractTextFromNode(from: node)
        textStore.setCache(textCache)
        return createDictionary(from: newNodeWithText, onFolderLevel: onFolderLevel)
    }

    private func extractTextFromNode(from node: Node) -> Node {
        var newNode = Node(url: node.url, children: [:])

        guard node.children.count != 0 else {
            Logger.fileProcessing.debug("Extrating text from \(node.url)")
            let text = extractTextFromFile(from: node.url)
            newNode.textualContent = text
            return newNode
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
        if let cachedText = textCache[file] {
            return cachedText
        }

        if file.pathExtension == "pdf" {
            let extractText = extractTextFromPDF(from: file)
            textCache[file] = extractText
            return extractText
        } else {
            return nil
        }
    }

    private func extractTextFromPDF(from file: URL) -> String? {
        pdfKitWrapper.extractText(from: file)
    }
}
