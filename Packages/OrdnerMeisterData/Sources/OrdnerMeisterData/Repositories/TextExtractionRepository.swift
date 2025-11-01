import Foundation
import PDFKit
import Vision
import AppKit
import OrdnerMeisterDomain
import OSLog

/// Concrete implementation of TextExtractionRepositoryProtocol
/// Safe for concurrent access as it has no mutable state
public final class TextExtractionRepository: TextExtractionRepositoryProtocol, @unchecked Sendable {
    private static let ocrThreshold = 10
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "OCR")

    public init() {}

    public func extractText(from url: URL) async throws -> String {
        let startTime = Date()
        let fileName = url.lastPathComponent

        logger.info("Starting text extraction for: \(fileName)")

        // Check if file is a PDF before attempting to load
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "pdf" else {
            logger.error("Unsupported file type '.\(fileExtension)' for: \(fileName)")
            throw TextExtractionError.unsupportedFileType(fileExtension)
        }

        guard let pdfDocument = PDFDocument(url: url),
              let pdfString = pdfDocument.string else {
            logger.error("Failed to load PDF: \(fileName)")
            throw TextExtractionError.failedToLoadPDF(fileName)
        }

        // If we have enough text from PDF, use it
        if pdfString.count >= Self.ocrThreshold {
            let elapsed = Date().timeIntervalSince(startTime)
            logger.info("Extracted \(pdfString.count) characters from PDF (direct): \(fileName) in \(String(format: "%.2f", elapsed))s")
            return pdfString
        }

        // Otherwise, try OCR
        logger.info("PDF text insufficient (\(pdfString.count) chars), attempting OCR: \(fileName)")
        if let ocrText = try await performOCR(on: pdfDocument) {
            let elapsed = Date().timeIntervalSince(startTime)
            logger.info("Extracted \(ocrText.count) characters via OCR: \(fileName) in \(String(format: "%.2f", elapsed))s")
            return ocrText
        }

        // Fallback to whatever text we have
        logger.warning("OCR failed, using minimal PDF text (\(pdfString.count) chars): \(fileName)")
        let elapsed = Date().timeIntervalSince(startTime)
        logger.info("Completed text extraction (fallback): \(fileName) in \(String(format: "%.2f", elapsed))s")
        return pdfString
    }

    public func extractTextBatch(from urls: [URL], maxConcurrentTasks: Int = 8) async throws -> [URL: String] {
        logger.info("Starting parallel batch text extraction for \(urls.count) files (max \(maxConcurrentTasks) concurrent)")

        return try await withThrowingTaskGroup(of: (URL, String).self) { group in
            var results: [URL: String] = [:]
            var successCount = 0
            var failureCount = 0
            var activeTasks = 0
            var urlIterator = urls.makeIterator()

            // Start initial batch of tasks up to the concurrency limit
            while activeTasks < maxConcurrentTasks, let url = urlIterator.next() {
                group.addTask {
                    // Check for cancellation before starting
                    try Task.checkCancellation()

                    do {
                        let text = try await self.extractText(from: url)
                        return (url, text)
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        self.logger.warning("Batch extraction failed for '\(url.lastPathComponent)': \(error.localizedDescription)")
                        return (url, "") // Return empty string on failure to continue processing
                    }
                }
                activeTasks += 1
            }

            // As tasks complete, add new ones to maintain concurrency
            for try await (url, text) in group {
                // Check for cancellation between iterations
                try Task.checkCancellation()

                results[url] = text
                if !text.isEmpty {
                    successCount += 1
                } else {
                    failureCount += 1
                }

                // Add next task if available
                if let nextURL = urlIterator.next() {
                    group.addTask {
                        // Check for cancellation before starting
                        try Task.checkCancellation()

                        do {
                            let text = try await self.extractText(from: nextURL)
                            return (nextURL, text)
                        } catch is CancellationError {
                            throw CancellationError()
                        } catch {
                            self.logger.warning("Batch extraction failed for '\(nextURL.lastPathComponent)': \(error.localizedDescription)")
                            return (nextURL, "")
                        }
                    }
                } else {
                    activeTasks -= 1
                }
            }

            logger.info("Parallel batch extraction completed: \(successCount) succeeded, \(failureCount) failed out of \(urls.count) files")
            return results
        }
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
            logger.warning("Failed to convert NSImage to CGImage for OCR")
            return nil
        }

        let request = VNRecognizeTextRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            logger.error("Vision framework OCR failed: \(error.localizedDescription)")
            throw error
        }

        guard let observations = request.results else {
            logger.warning("No OCR results returned")
            return nil
        }

        let text = observations
            .compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            .joined(separator: " ")

        if text.isEmpty {
            logger.info("OCR completed but extracted no text (\(observations.count) observations)")
        } else {
            logger.debug("OCR recognized \(observations.count) text regions")
        }

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
