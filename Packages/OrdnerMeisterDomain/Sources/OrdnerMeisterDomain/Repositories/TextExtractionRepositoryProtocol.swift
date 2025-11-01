import Foundation

/// Repository protocol for extracting text from files (PDFs, etc.)
public protocol TextExtractionRepositoryProtocol {
    /// Extract text from a file
    func extractText(from url: URL) async throws -> String

    /// Extract text from multiple files in parallel
    /// - Parameters:
    ///   - urls: URLs of files to extract text from
    ///   - maxConcurrentTasks: Maximum number of concurrent extraction tasks (default: 8)
    /// - Returns: Dictionary mapping URLs to extracted text
    func extractTextBatch(from urls: [URL], maxConcurrentTasks: Int) async throws -> [URL: String]
}
