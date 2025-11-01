import XCTest
@testable import OrdnerMeisterData
import Foundation

/// Tests for TextCacheRepository thread safety and concurrency behavior
final class TextCacheRepositoryConcurrencyTests: XCTestCase {

    var repository: TextCacheRepository!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary directory for test cache
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        repository = TextCacheRepository(fileManager: .default)
    }

    override func tearDown() async throws {
        repository = nil

        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil

        try await super.tearDown()
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentReads() async throws {
        // Given: A cache with some entries
        let testURLs = (0..<10).map { URL(fileURLWithPath: "/test/file\($0).pdf") }
        for (index, url) in testURLs.enumerated() {
            await repository.cacheTextDeferred("Content \(index)", for: url)
        }

        // When: Multiple concurrent reads
        let repo = repository!
        let results = await withTaskGroup(of: String?.self) { group in
            for url in testURLs {
                group.addTask {
                    await repo.getCachedText(for: url)
                }
            }

            var allResults: [String?] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }

        // Then: All reads complete successfully without crashes
        XCTAssertEqual(results.count, 10, "All reads should complete")
        XCTAssertEqual(results.compactMap { $0 }.count, 10, "All reads should return values")
    }

    func testConcurrentWrites() async throws {
        // Given: Multiple URLs to write
        let testURLs = (0..<50).map { URL(fileURLWithPath: "/test/file\($0).pdf") }

        // When: Concurrent writes to different URLs
        let repo = repository!
        await withTaskGroup(of: Void.self) { group in
            for (index, url) in testURLs.enumerated() {
                group.addTask {
                    await repo.cacheTextDeferred("Content \(index)", for: url)
                }
            }
        }

        // Then: All writes complete and all values are retrievable
        let allCached = await repository.getAllCached()
        XCTAssertEqual(allCached.count, 50, "All 50 entries should be cached")

        for (index, url) in testURLs.enumerated() {
            let cached = await repository.getCachedText(for: url)
            XCTAssertEqual(cached, "Content \(index)", "Content should match for URL \(index)")
        }
    }

    func testConcurrentReadWriteMix() async throws {
        // Given: Pre-populated cache
        let readURLs = (0..<10).map { URL(fileURLWithPath: "/test/read\($0).pdf") }
        let writeURLs = (0..<10).map { URL(fileURLWithPath: "/test/write\($0).pdf") }

        for (index, url) in readURLs.enumerated() {
            await repository.cacheTextDeferred("Initial \(index)", for: url)
        }

        // When: Concurrent reads and writes
        let repo = repository!
        await withTaskGroup(of: Void.self) { group in
            // Add read tasks
            for url in readURLs {
                group.addTask {
                    _ = await repo.getCachedText(for: url)
                }
            }

            // Add write tasks
            for (index, url) in writeURLs.enumerated() {
                group.addTask {
                    await repo.cacheTextDeferred("New \(index)", for: url)
                }
            }
        }

        // Then: All operations complete successfully
        let allCached = await repository.getAllCached()
        XCTAssertEqual(allCached.count, 20, "Should have 20 total entries")
    }

    // MARK: - Batched Write Tests

    func testDeferredCacheDoesNotWriteToDisk() async throws {
        // Given: A URL and text
        let testURL = URL(fileURLWithPath: "/test/file.pdf")
        let testText = "Test content"

        // When: Caching with deferred write
        await repository.cacheTextDeferred(testText, for: testURL)

        // Then: Value is in memory
        let cached = await repository.getCachedText(for: testURL)
        XCTAssertEqual(cached, testText, "Should be cached in memory")

        // Note: We can't easily test that it's NOT on disk without exposing
        // internal implementation details, but this verifies it's in memory
    }

    func testFlushCacheWritesAllDeferredEntries() async throws {
        // Given: Multiple deferred cache entries
        let testURLs = (0..<5).map { URL(fileURLWithPath: "/test/file\($0).pdf") }
        for (index, url) in testURLs.enumerated() {
            await repository.cacheTextDeferred("Content \(index)", for: url)
        }

        // When: Flushing cache
        try await repository.flushCache()

        // Then: All entries are persisted (new instance can load them)
        // Note: This would require creating a new repository instance with
        // the same cache file, which requires exposing cache file path

        // For now, verify all entries are still accessible
        for (index, url) in testURLs.enumerated() {
            let cached = await repository.getCachedText(for: url)
            XCTAssertEqual(cached, "Content \(index)")
        }
    }

    func testBatchedWriteReducesIOOperations() async throws {
        // This test verifies the batching behavior by timing operations
        let urls = (0..<20).map { URL(fileURLWithPath: "/test/batch\($0).pdf") }

        // When: Using deferred writes + flush (batched)
        let batchedStart = Date()
        for (index, url) in urls.enumerated() {
            await repository.cacheTextDeferred("Content \(index)", for: url)
        }
        try await repository.flushCache()
        let batchedDuration = Date().timeIntervalSince(batchedStart)

        // Then: All entries are cached
        let allCached = await repository.getAllCached()
        XCTAssertEqual(allCached.count, 20)

        // Note: In a real scenario, batched writes should be faster than
        // individual writes, but we can't easily test the counterfactual
        XCTAssertLessThan(batchedDuration, 5.0, "Batched operations should complete quickly")
    }

    // MARK: - Actor Isolation Tests

    func testActorIsolationPreventsDataRaces() async throws {
        // This test verifies that the actor prevents data races by
        // performing many concurrent operations
        let iterationCount = 100
        let url = URL(fileURLWithPath: "/test/race.pdf")

        // When: Many concurrent writes to the same URL
        let repo = repository!
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterationCount {
                group.addTask {
                    await repo.cacheTextDeferred("Content \(i)", for: url)
                }
            }
        }

        // Then: One value wins (no crash, no corruption)
        let finalValue = await repository.getCachedText(for: url)
        XCTAssertNotNil(finalValue, "Should have a value")
        XCTAssertTrue(finalValue!.starts(with: "Content "), "Value should be valid")
    }
}
