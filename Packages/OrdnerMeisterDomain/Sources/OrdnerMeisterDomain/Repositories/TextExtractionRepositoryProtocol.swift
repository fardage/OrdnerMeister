import Foundation

/// Repository protocol for extracting text from files (PDFs, etc.)
public protocol TextExtractionRepositoryProtocol {
    /// Extract text from a file
    func extractText(from url: URL) async throws -> String

    /// Extract text from multiple files
    func extractTextBatch(from urls: [URL]) async throws -> [URL: String]
}
