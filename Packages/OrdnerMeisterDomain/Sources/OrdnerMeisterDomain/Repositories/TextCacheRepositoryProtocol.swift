import Foundation

/// Repository protocol for caching extracted text
public protocol TextCacheRepositoryProtocol {
    /// Get cached text for a file
    func getCachedText(for url: URL) async -> String?

    /// Cache text for a file (saves to disk immediately)
    func cacheText(_ text: String, for url: URL) async throws

    /// Cache text for a file without saving to disk (for batch operations)
    func cacheTextDeferred(_ text: String, for url: URL) async

    /// Flush all deferred cache entries to disk
    func flushCache() async throws

    /// Get all cached entries
    func getAllCached() async -> [URL: String]

    /// Clear all cache
    func clearCache() async throws
}
