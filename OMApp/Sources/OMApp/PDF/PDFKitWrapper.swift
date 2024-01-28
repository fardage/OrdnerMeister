//
//  PDFKitWrapper.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import OSLog
import PDFKit
import Vision

public protocol PDFKitWrapping {
    func extractText(from url: URL) -> String?
}

public struct PDFKitWrapper: PDFKitWrapping {
    private static let triggerOCRThreshold = 10

    public init() {}

    public func extractText(from url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url),
              let pdfString = pdfDocument.string
        else {
            return nil
        }

        guard pdfString.count < PDFKitWrapper.triggerOCRThreshold else {
            return pdfString
        }

        return getOCRText(from: pdfDocument)
    }

    private func getOCRText(from pdf: PDFDocument) -> String? {
        guard let image = convertPDFtoImage(pdf: pdf) else {
            return nil
        }
        return recognizeText(in: image)
    }

    private func recognizeText(in image: NSImage) -> String? {
        let textRecognitionRequest = VNRecognizeTextRequest()

        guard let cgImage =
            image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch {
            Logger.fileProcessing.error("\(error)")
            return nil
        }

        guard let observations = textRecognitionRequest.results else {
            return nil
        }

        return observations
            .compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            .joined(separator: " ")
    }

    private func convertPDFtoImage(pdf: PDFDocument) -> NSImage? {
        guard let page = pdf.page(at: 0) else {
            return nil
        }

        if let data = page.dataRepresentation,
           let image = NSImage(data: data)
        {
            return image
        }

        return nil
    }
}
