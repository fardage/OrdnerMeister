import Foundation
import OrdnerMeisterDomain
import OSLog

/// Concrete implementation of TextCacheRepositoryProtocol
public final class TextCacheRepository: TextCacheRepositoryProtocol {
    private static let cacheFileName = "ordnerMeister.cache"

    private let fileManager: FileManager
    private var cache: [URL: String] = [:]
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "FileSystem")

    private var cacheFileURL: URL? {
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            logger.error("Could not locate caches directory")
            return nil
        }
        return cacheDirectory.appendingPathComponent(Self.cacheFileName)
    }

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        // Cache will be loaded on first access
    }

    private func ensureCacheLoaded() async {
        guard cache.isEmpty else { return }
        await loadCache()
    }

    public func getCachedText(for url: URL) async -> String? {
        await ensureCacheLoaded()
        let cached = cache[url]
        if cached != nil {
            logger.debug("Cache hit for: \(url.lastPathComponent)")
        } else {
            logger.debug("Cache miss for: \(url.lastPathComponent)")
        }
        return cached
    }

    public func cacheText(_ text: String, for url: URL) async throws {
        cache[url] = text
        logger.debug("Caching text for: \(url.lastPathComponent) (\(text.count) characters)")

        do {
            try await saveCache()
        } catch {
            logger.error("Failed to save cache for '\(url.lastPathComponent)': \(error.localizedDescription)")
            throw error
        }
    }

    public func getAllCached() async -> [URL: String] {
        await ensureCacheLoaded()
        let count = cache.count
        logger.info("Retrieved all cached text: \(count) entries")
        return cache
    }

    public func clearCache() async throws {
        let count = cache.count
        cache = [:]

        if let cacheFileURL = cacheFileURL {
            do {
                if fileManager.fileExists(atPath: cacheFileURL.path) {
                    try fileManager.removeItem(at: cacheFileURL)
                    logger.info("Cache cleared: removed \(count) entries and deleted cache file")
                } else {
                    logger.info("Cache cleared: removed \(count) entries (no file to delete)")
                }
            } catch {
                logger.error("Failed to delete cache file: \(error.localizedDescription)")
                throw error
            }
        } else {
            logger.warning("Cache cleared but could not delete file (no cache URL)")
        }
    }

    // MARK: - Private Methods

    private func loadCache() async {
        guard let cacheFileURL = cacheFileURL else {
            logger.warning("Cannot load cache: no cache URL available")
            return
        }

        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            logger.info("No existing cache file found, starting with empty cache")
            cache = [:]
            return
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let cacheFile = try JSONDecoder().decode(CacheFile.self, from: data)
            cache = cacheFile.data
            let count = cache.count
            logger.info("Loaded cache: \(count) entries")
        } catch let error as DecodingError {
            logger.error("Cache file corrupted (decoding error), starting fresh: \(error.localizedDescription)")
            cache = [:]
        } catch {
            logger.error("Failed to load cache file: \(error.localizedDescription), starting fresh")
            cache = [:]
        }
    }

    private func saveCache() async throws {
        guard let cacheFileURL = cacheFileURL else {
            logger.error("Cannot save cache: no cache URL available")
            throw NSError(domain: "TextCacheRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cache URL not available"])
        }

        do {
            let cacheFile = CacheFile(data: cache)
            let data = try JSONEncoder().encode(cacheFile)
            try data.write(to: cacheFileURL, options: .atomic)
            let count = cache.count
            logger.debug("Saved cache: \(count) entries")
        } catch {
            logger.error("Failed to save cache: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Cache File Structure

private struct CacheFile: Codable {
    let data: [URL: String]
}
