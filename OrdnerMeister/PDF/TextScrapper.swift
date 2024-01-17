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

    func extractText(from urls: [URL], onFolderLevel: Bool = false) -> DataTable {
        var folderURL = [URL]()
        var textualContent = [String]()

        for url in urls {
            folderURL.append(onFolderLevel ? url.deletingLastPathComponent() : url)
            textualContent.append(extractTextFromPDF(from: url) ?? "")
        }

        textStore.setCache(textCache)

        return DataTable(folderURL: folderURL, textualContent: textualContent)
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
