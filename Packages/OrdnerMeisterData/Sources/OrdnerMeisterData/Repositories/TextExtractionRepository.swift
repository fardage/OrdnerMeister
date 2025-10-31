import Foundation
import PDFKit
import Vision
import AppKit
import OrdnerMeisterDomain

/// Concrete implementation of TextExtractionRepositoryProtocol
public final class TextExtractionRepository: TextExtractionRepositoryProtocol {
    private static let ocrThreshold = 10

    public init() {}

    public func extractText(from url: URL) async throws -> String {
        // Check if file is a PDF before attempting to load
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "pdf" else {
            throw TextExtractionError.unsupportedFileType(fileExtension)
        }

        guard let pdfDocument = PDFDocument(url: url),
              let pdfString = pdfDocument.string else {
            throw TextExtractionError.failedToLoadPDF(url.lastPathComponent)
        }

        // If we have enough text from PDF, use it
        if pdfString.count >= Self.ocrThreshold {
            return pdfString
        }

        // Otherwise, try OCR
        if let ocrText = try await performOCR(on: pdfDocument) {
            return ocrText
        }

        // Fallback to whatever text we have
        return pdfString
    }

    public func extractTextBatch(from urls: [URL]) async throws -> [URL: String] {
        var results: [URL: String] = [:]

        for url in urls {
            do {
                let text = try await extractText(from: url)
                results[url] = text
            } catch {
                // Log but continue with other files
                results[url] = ""
            }
        }

        return results
    }

    // MARK: - Private Methods

    private func performOCR(on pdfDocument: PDFDocument) async throws -> String? {
        guard let image = convertPDFToImage(pdfDocument) else {
            return nil
        }

        return try await recognizeText(in: image)
    }

    private func recognizeText(in image: NSImage) async throws -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results else {
            return nil
        }

        let text = observations
            .compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            .joined(separator: " ")

        return text.isEmpty ? nil : text
    }

    private func convertPDFToImage(_ pdfDocument: PDFDocument) -> NSImage? {
        guard let page = pdfDocument.page(at: 0) else {
            return nil
        }

        if let data = page.dataRepresentation,
           let image = NSImage(data: data) {
            return image
        }

        return nil
    }
}

// MARK: - Errors

public enum TextExtractionError: Error {
    case unsupportedFileType(String)
    case failedToLoadPDF(String)
    case ocrFailed
}
