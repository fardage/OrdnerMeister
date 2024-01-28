//
//  TextStore.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Foundation
import OSLog

public protocol TextStoring {
    func getCache() -> [URL: String]
    func setCache(_ cache: [URL: String])
}

public struct TextStore: TextStoring {
    private static let textCacheFileName = "ordnerMeister.cache"

    private let fileManager: FileManager

    private var cacheFileURL: URL? {
        guard let cacheDirectoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }

        return cacheDirectoryURL.appendingPathComponent(TextStore.textCacheFileName)
    }

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func getCache() -> [URL: String] {
        do {
            guard let cacheFileURL else {
                return [:]
            }

            let cacheFileData = try Data(contentsOf: cacheFileURL)
            let cacheFile = try JSONDecoder().decode(CacheFile.self, from: cacheFileData)

            return cacheFile.data
        } catch {
            Logger.fileProcessing.error("Could not read cache file: \(error.localizedDescription)")
        }

        return [:]
    }

    public func setCache(_ cache: [URL: String]) {
        guard let cacheFileURL else {
            return
        }

        let cacheFile = CacheFile(data: cache)

        do {
            let cacheFileData = try JSONEncoder().encode(cacheFile)
            try cacheFileData.write(to: cacheFileURL)
        } catch {
            Logger.fileProcessing.error("Could not write cache file: \(error.localizedDescription)")
        }
    }
}

private struct CacheFile: Codable {
    let data: [URL: String]
}
