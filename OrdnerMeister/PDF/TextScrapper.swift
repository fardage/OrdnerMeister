//
//  TextScrapper.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import PDFKit

struct TextScrapper {
    private let pdfKitWrapper: PDFKitWrapping

    init(pdfKitWrapper: PDFKitWrapping = PDFKitWrapper()) {
        self.pdfKitWrapper = pdfKitWrapper
    }

    func extractTextFromFiles(from node: Node) -> Node {
        var newNode = Node(url: node.url, children: [:])

        guard node.children.count != 0 else {
            let text = extractTextFromFile(from: node.url)
            newNode.textualContent = text
            return newNode
        }

        let children = node.children.reduce(into: [String: Node]()) { acc, child in
            let name = child.key
            let node = child.value
            acc[name] = extractTextFromFiles(from: node)
        }
        newNode.children = children
        return newNode
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
