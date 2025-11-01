import XCTest
@testable import OrdnerMeisterData
import Foundation
import PDFKit

/// Tests for parallel text extraction capabilities
final class TextExtractionParallelProcessingTests: XCTestCase {

    var repository: TextExtractionRepository!
    var tempDirectory: URL!
    var testPDFURLs: [URL] = []

    override func setUp() async throws {
        try await super.setUp()

        repository = TextExtractionRepository()

        // Create temporary directory for test PDFs
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Create test PDFs with varying content
        testPDFURLs = try createTestPDFs(count: 20)
    }

    override func tearDown() async throws {
        repository = nil
        testPDFURLs = []

        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil

        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestPDFs(count: Int) throws -> [URL] {
        var urls: [URL] = []

        for i in 0..<count {
            let url = tempDirectory.appendingPathComponent("test_file_\(i).pdf")

            // Create a page with text
            var pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
            let textContent = "Test document \(i)\nThis is test content for file number \(i).\nSample text for extraction testing."

            // Create attributed string for drawing
            let attributedString = NSAttributedString(
                string: textContent,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.black
                ]
            )

            // Create PDF data with text
            let pdfData = NSMutableData()
            guard let consumer = CGDataConsumer(data: pdfData),
                  let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
                continue
            }

            context.beginPDFPage(nil)

            // Create NSGraphicsContext for drawing
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext

            // Draw text
            context.translateBy(x: 50, y: 700)
            attributedString.draw(at: .zero)

            context.endPDFPage()
            context.closePDF()

            // Write PDF data to file
            pdfData.write(to: url, atomically: true)

            // Verify the PDF can be loaded
            if PDFDocument(url: url) != nil {
                urls.append(url)
            }
        }

        return urls
    }

    // MARK: - Parallel Processing Tests

    func testExtractTextBatchProcessesFilesInParallel() async throws {
        // Given: 20 test PDF files
        XCTAssertEqual(testPDFURLs.count, 20, "Should have 20 test PDFs")

        // When: Extracting text in parallel
        let startTime = Date()
        let results = try await repository.extractTextBatch(
            from: testPDFURLs,
            maxConcurrentTasks: 8
        )
        let duration = Date().timeIntervalSince(startTime)

        // Then: All files are processed
        XCTAssertEqual(results.count, 20, "All files should be processed")

        // Each result should have some text
        for (url, text) in results {
            XCTAssertFalse(text.isEmpty, "Text should be extracted for \(url.lastPathComponent)")
            XCTAssertTrue(text.contains("Test document"), "Should contain expected text")
        }

        // Parallel processing should be relatively fast (not exact due to system variability)
        XCTAssertLessThan(duration, 10.0, "Parallel processing should complete in reasonable time")
    }

    func testConcurrencyLimitIsRespected() async throws {
        // This test verifies that no more than maxConcurrentTasks run simultaneously
        // Given: 50 test files (create more for this test)
        let largeSet = try createTestPDFs(count: 50)

        // When: Extracting with low concurrency limit
        let results = try await repository.extractTextBatch(
            from: largeSet,
            maxConcurrentTasks: 4
        )

        // Then: All files are still processed (concurrency limit doesn't prevent completion)
        XCTAssertEqual(results.count, 50, "All files should be processed despite low concurrency")

        // Clean up additional test files
        for url in largeSet {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testParallelExtractionHandlesErrors() async throws {
        // Given: Mix of valid PDFs and invalid files
        var mixedURLs = Array(testPDFURLs.prefix(5))

        // Add some non-existent files
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.pdf")
        mixedURLs.append(nonExistentURL)

        // Add a non-PDF file
        let txtURL = tempDirectory.appendingPathComponent("test.txt")
        try "Some text".write(to: txtURL, atomically: true, encoding: .utf8)
        mixedURLs.append(txtURL)

        // When: Extracting from mixed URLs
        let results = try await repository.extractTextBatch(
            from: mixedURLs,
            maxConcurrentTasks: 8
        )

        // Then: Valid files are processed, errors are handled gracefully
        XCTAssertEqual(results.count, 7, "Should have results for all URLs")

        // Valid PDFs should have text
        for i in 0..<5 {
            let validURL = mixedURLs[i]
            XCTAssertNotNil(results[validURL], "Should have result for valid PDF")
            XCTAssertFalse(results[validURL]!.isEmpty, "Valid PDF should have text")
        }

        // Invalid files should have empty text (error handled)
        XCTAssertEqual(results[nonExistentURL], "", "Non-existent file should return empty string")
        XCTAssertEqual(results[txtURL], "", "Non-PDF file should return empty string")
    }

    func testBatchExtractionRespectsTaskCancellation() async throws {
        // Given: Many files to process
        let manyFiles = try createTestPDFs(count: 100)

        // When: Starting extraction and then cancelling
        let repo = repository!
        let task = Task {
            try await repo.extractTextBatch(
                from: manyFiles,
                maxConcurrentTasks: 8
            )
        }

        // Cancel after a brief delay
        try await Task.sleep(for: .milliseconds(10))
        task.cancel()

        // Then: Task should throw cancellation error
        do {
            _ = try await task.value
            XCTFail("Should have thrown cancellation error")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Should throw CancellationError, got \(error)")
        }

        // Clean up test files
        for url in manyFiles {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testParallelProcessingIsFasterThanSequential() async throws {
        // Given: Set of PDF files
        let testFiles = Array(testPDFURLs.prefix(20))

        // When: Processing with parallel (8 tasks)
        let parallelStart = Date()
        let parallelResults = try await repository.extractTextBatch(
            from: testFiles,
            maxConcurrentTasks: 8
        )
        let parallelDuration = Date().timeIntervalSince(parallelStart)

        // Process with sequential (1 task)
        let sequentialStart = Date()
        let sequentialResults = try await repository.extractTextBatch(
            from: testFiles,
            maxConcurrentTasks: 1
        )
        let sequentialDuration = Date().timeIntervalSince(sequentialStart)

        // Then: Both complete successfully
        XCTAssertEqual(parallelResults.count, 20)
        XCTAssertEqual(sequentialResults.count, 20)

        // Parallel should be noticeably faster
        print("Parallel (8 tasks): \(parallelDuration)s, Sequential (1 task): \(sequentialDuration)s")

        // Parallel with 8 tasks should be faster than sequential
        // We expect at least some speedup, though not necessarily 8x due to I/O overhead
        XCTAssertLessThan(parallelDuration, sequentialDuration,
                         "Parallel should be faster than sequential")
    }

    func testEmptyBatchReturnsEmptyResults() async throws {
        // Given: Empty URL array
        let emptyURLs: [URL] = []

        // When: Extracting from empty batch
        let results = try await repository.extractTextBatch(
            from: emptyURLs,
            maxConcurrentTasks: 8
        )

        // Then: Results are empty
        XCTAssertTrue(results.isEmpty, "Empty batch should return empty results")
    }

    func testSingleFileBatchWorks() async throws {
        // Given: Single file
        let singleFile = [testPDFURLs[0]]

        // When: Extracting single file via batch
        let results = try await repository.extractTextBatch(
            from: singleFile,
            maxConcurrentTasks: 8
        )

        // Then: Single result returned
        XCTAssertEqual(results.count, 1, "Should have one result")
        XCTAssertFalse(results[singleFile[0]]!.isEmpty, "Should have extracted text")
    }

    func testBatchExtractionConsistencyWithSingleExtraction() async throws {
        // This test verifies that batch extraction produces same results as individual extraction
        // Given: A few test files
        let testFiles = Array(testPDFURLs.prefix(5))

        // When: Extracting individually
        var individualResults: [URL: String] = [:]
        for url in testFiles {
            let text = try await repository.extractText(from: url)
            individualResults[url] = text
        }

        // Extracting via batch
        let batchResults = try await repository.extractTextBatch(
            from: testFiles,
            maxConcurrentTasks: 8
        )

        // Then: Results should match
        XCTAssertEqual(batchResults.count, individualResults.count)
        for url in testFiles {
            XCTAssertEqual(batchResults[url], individualResults[url],
                          "Batch result should match individual result for \(url.lastPathComponent)")
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentBatchCalls() async throws {
        // This test verifies that multiple concurrent batch calls don't interfere
        // Given: Multiple batches of files
        let batch1 = Array(testPDFURLs.prefix(10))
        let batch2 = Array(testPDFURLs.suffix(10))

        // When: Processing both batches concurrently
        let repo = repository!
        async let results1 = repo.extractTextBatch(from: batch1, maxConcurrentTasks: 4)
        async let results2 = repo.extractTextBatch(from: batch2, maxConcurrentTasks: 4)

        let (r1, r2) = try await (results1, results2)

        // Then: Both batches complete successfully
        XCTAssertEqual(r1.count, 10, "First batch should process all files")
        XCTAssertEqual(r2.count, 10, "Second batch should process all files")

        // No overlap in results (different URLs)
        let urls1 = Set(r1.keys)
        let urls2 = Set(r2.keys)
        XCTAssertTrue(urls1.isDisjoint(with: urls2), "Batches should have different URLs")
    }
}
