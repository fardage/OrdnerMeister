import Foundation
import OrdnerMeisterDomain

/// Concrete implementation of TextCacheRepositoryProtocol
public final class TextCacheRepository: TextCacheRepositoryProtocol {
    private static let cacheFileName = "ordnerMeister.cache"

    private let fileManager: FileManager
    private var cache: [URL: String] = [:]

    private var cacheFileURL: URL? {
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
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
        return cache[url]
    }

    public func cacheText(_ text: String, for url: URL) async throws {
        cache[url] = text
        try await saveCache()
    }

    public func getAllCached() async -> [URL: String] {
        await ensureCacheLoaded()
        return cache
    }

    public func clearCache() async throws {
        cache = [:]
        if let cacheFileURL = cacheFileURL {
            try? fileManager.removeItem(at: cacheFileURL)
        }
    }

    // MARK: - Private Methods

    private func loadCache() async {
        guard let cacheFileURL = cacheFileURL else { return }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let cacheFile = try JSONDecoder().decode(CacheFile.self, from: data)
            cache = cacheFile.data
        } catch {
            // Cache file doesn't exist or is corrupted, start fresh
            cache = [:]
        }
    }

    private func saveCache() async throws {
        guard let cacheFileURL = cacheFileURL else { return }

        let cacheFile = CacheFile(data: cache)
        let data = try JSONEncoder().encode(cacheFile)
        try data.write(to: cacheFileURL)
    }
}

// MARK: - Cache File Structure

private struct CacheFile: Codable {
    let data: [URL: String]
}
