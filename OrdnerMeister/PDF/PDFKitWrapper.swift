//
//  PDFKitWrapper.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import PDFKit

protocol PDFKitWrapping {
    func extractText(from url: URL) -> String?
}

struct PDFKitWrapper: PDFKitWrapping {
    func extractText(from url: URL) -> String? {
        let pdfDocument = PDFDocument(url: url)
        return pdfDocument?.string
    }
}
