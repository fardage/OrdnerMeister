import Foundation

/// Repository protocol for caching extracted text
public protocol TextCacheRepositoryProtocol {
    /// Get cached text for a file
    func getCachedText(for url: URL) async -> String?

    /// Cache text for a file
    func cacheText(_ text: String, for url: URL) async throws

    /// Get all cached entries
    func getAllCached() async -> [URL: String]

    /// Clear all cache
    func clearCache() async throws
}
