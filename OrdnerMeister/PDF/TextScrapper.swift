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

struct TextScrapper {
    private let pdfKitWrapper: PDFKitWrapping

    init(pdfKitWrapper: PDFKitWrapping = PDFKitWrapper()) {
        self.pdfKitWrapper = pdfKitWrapper
    }

    func extractTextFromFiles(from node: Node) -> DataTable {
        var newNodeWithText = extractTextFromNode(from: node)
        return createDictionary(from: newNodeWithText)
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

    private func createDictionary(from rootNode: Node) -> DataTable {
        var folderURL = [URL]()
        var textualContentList = [String]()
        var queue = [Node]()
        queue.append(rootNode)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if let textualContent = current.textualContent {
                let parentURL = current.url
                    .deletingLastPathComponent()
                folderURL.append(parentURL)
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
