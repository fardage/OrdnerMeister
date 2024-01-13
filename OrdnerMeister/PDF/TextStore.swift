//
//  TextStore.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 13.01.2024.
//

import Foundation
import OSLog

protocol TextStoring {
    func store(_ datatable: DataTable, for directory: URL)
    func retreiveCachedDataTable(for directory: URL) -> DataTable?
}

struct TextStore: TextStoring {
    private let fileManager: FileManager
    static let cacheFileName = ".ordnermeister.cache"

    private var cacheFileURL: URL {
        let homeDirectory = NSHomeDirectory()
        let homeURL = URL(fileURLWithPath: homeDirectory)
        return homeURL.appendingPathComponent(TextStore.cacheFileName)
    }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func store(_ datatable: DataTable, for directory: URL) {
        let existingCacheFile = getCacheFile()

        var cache = existingCacheFile.cache
        cache[directory] = datatable
        write(TextCache(cache: cache))
    }

    func retreiveCachedDataTable(for directory: URL) -> DataTable? {
        let cachedFile = getCacheFile()
        return cachedFile.cache[directory]
    }

    private func write(_ textCache: TextCache) {
        do {
            let data = try JSONEncoder().encode(textCache)
            try data.write(to: cacheFileURL)
        } catch {
            Logger.general.error("Could not encode cache file: \(error.localizedDescription)")
        }
    }

    private func getCacheFile() -> TextCache {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            fileManager.createFile(atPath: cacheFileURL.path, contents: nil, attributes: nil)
            return TextCache(cache: [:])
        }

        if let data = fileManager.contents(atPath: cacheFileURL.path),
           let textCache = try? JSONDecoder().decode(TextCache.self, from: data)
        {
            return textCache
        } else {
            Logger.general.error("Could not decode cache file")
            return TextCache(cache: [:])
        }
    }
}

struct TextCache: Codable {
    let cache: [URL: DataTable]
}
