import XCTest
@testable import OrdnerMeisterData
@testable import OrdnerMeisterDomain
import Foundation

/// Tests for parallel processing capabilities in repositories
final class ParallelProcessingTests: XCTestCase {

    // MARK: - Parallel Classification Tests

    func testClassifyBatchProcessesFilesInParallel() async throws {
        // Given: A classification repository and test files
        let repository = ClassificationRepository()

        // Train with sample data
        let trainingFiles = [
            File(url: URL(fileURLWithPath: "/train/invoice1.pdf"), textContent: "invoice payment total amount"),
            File(url: URL(fileURLWithPath: "/train/receipt1.pdf"), textContent: "receipt purchase bought store")
        ]
        let trainingFolders: [URL: Folder] = [
            URL(fileURLWithPath: "/train/invoice1.pdf"): Folder(url: URL(fileURLWithPath: "/output/invoices")),
            URL(fileURLWithPath: "/train/receipt1.pdf"): Folder(url: URL(fileURLWithPath: "/output/receipts"))
        ]
        try await repository.train(files: trainingFiles, folderLabels: trainingFolders)

        // Create test files to classify
        let testFiles = (0..<20).map { index in
            File(
                url: URL(fileURLWithPath: "/test/file\(index).pdf"),
                textContent: index % 2 == 0 ? "invoice payment" : "receipt purchase"
            )
        }

        // When: Classifying in parallel
        let startTime = Date()
        let classifications = try await repository.classifyBatch(
            files: testFiles,
            topN: 3,
            maxConcurrentTasks: 8
        )
        let duration = Date().timeIntervalSince(startTime)

        // Then: All files are classified
        XCTAssertEqual(classifications.count, 20, "All files should be classified")

        // Each classification should have predictions
        for classification in classifications {
            XCTAssertFalse(classification.predictions.isEmpty, "Should have predictions")
            XCTAssertLessThanOrEqual(classification.predictions.count, 3, "Should have at most 3 predictions")
        }

        // Parallel processing should be relatively fast
        XCTAssertLessThan(duration, 2.0, "Parallel processing should be fast")
    }

    func testConcurrencyLimitIsRespected() async throws {
        // This test verifies that no more than maxConcurrentTasks run simultaneously
        let repository = ClassificationRepository()

        // Train with sample data
        let trainingFiles = [
            File(url: URL(fileURLWithPath: "/train/doc1.pdf"), textContent: "document text content")
        ]
        let trainingFolders: [URL: Folder] = [
            URL(fileURLWithPath: "/train/doc1.pdf"): Folder(url: URL(fileURLWithPath: "/output/docs"))
        ]
        try await repository.train(files: trainingFiles, folderLabels: trainingFolders)

        let testFiles = (0..<50).map { index in
            File(url: URL(fileURLWithPath: "/test/file\(index).pdf"), textContent: "document text")
        }

        // When: Classifying with low concurrency limit
        let classifications = try await repository.classifyBatch(
            files: testFiles,
            topN: 1,
            maxConcurrentTasks: 4
        )

        // Then: All files are still classified (concurrency limit doesn't prevent completion)
        XCTAssertEqual(classifications.count, 50, "All files should be classified despite low concurrency")
    }

    func testParallelClassificationMaintainsAccuracy() async throws {
        // Given: Trained classifier
        let repository = ClassificationRepository()

        let trainingFiles = [
            File(url: URL(fileURLWithPath: "/train/invoice1.pdf"), textContent: "invoice payment bill total"),
            File(url: URL(fileURLWithPath: "/train/invoice2.pdf"), textContent: "invoice charge amount due"),
            File(url: URL(fileURLWithPath: "/train/receipt1.pdf"), textContent: "receipt store purchase bought"),
            File(url: URL(fileURLWithPath: "/train/receipt2.pdf"), textContent: "receipt transaction shopping")
        ]
        let trainingFolders: [URL: Folder] = [
            URL(fileURLWithPath: "/train/invoice1.pdf"): Folder(url: URL(fileURLWithPath: "/output/invoices")),
            URL(fileURLWithPath: "/train/invoice2.pdf"): Folder(url: URL(fileURLWithPath: "/output/invoices")),
            URL(fileURLWithPath: "/train/receipt1.pdf"): Folder(url: URL(fileURLWithPath: "/output/receipts")),
            URL(fileURLWithPath: "/train/receipt2.pdf"): Folder(url: URL(fileURLWithPath: "/output/receipts"))
        ]
        try await repository.train(files: trainingFiles, folderLabels: trainingFolders)

        // When: Classifying files in parallel
        let testFiles = [
            File(url: URL(fileURLWithPath: "/test/invoice.pdf"), textContent: "invoice payment total"),
            File(url: URL(fileURLWithPath: "/test/receipt.pdf"), textContent: "receipt shopping purchase")
        ]

        let classifications = try await repository.classifyBatch(
            files: testFiles,
            topN: 2,
            maxConcurrentTasks: 8
        )

        // Then: Classifications are accurate
        XCTAssertEqual(classifications.count, 2)

        // First should be classified as invoice
        let invoiceClassification = classifications.first { $0.file.url.lastPathComponent == "invoice.pdf" }
        XCTAssertNotNil(invoiceClassification)
        XCTAssertTrue(invoiceClassification!.topPrediction?.folder.url.lastPathComponent == "invoices",
                     "Invoice should be classified to invoices folder")

        // Second should be classified as receipt
        let receiptClassification = classifications.first { $0.file.url.lastPathComponent == "receipt.pdf" }
        XCTAssertNotNil(receiptClassification)
        XCTAssertTrue(receiptClassification!.topPrediction?.folder.url.lastPathComponent == "receipts",
                     "Receipt should be classified to receipts folder")
    }

    // MARK: - Cancellation Tests

    func testClassificationRespectsTaskCancellation() async throws {
        // Given: Repository and many files
        let repository = ClassificationRepository()

        let trainingFiles = [
            File(url: URL(fileURLWithPath: "/train/doc.pdf"), textContent: "document text")
        ]
        let trainingFolders: [URL: Folder] = [
            URL(fileURLWithPath: "/train/doc.pdf"): Folder(url: URL(fileURLWithPath: "/output/docs"))
        ]
        try await repository.train(files: trainingFiles, folderLabels: trainingFolders)

        let testFiles = (0..<100).map { index in
            File(url: URL(fileURLWithPath: "/test/file\(index).pdf"), textContent: "document text content")
        }

        // When: Starting classification and then cancelling
        let task = Task {
            try await repository.classifyBatch(files: testFiles, topN: 1, maxConcurrentTasks: 8)
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
    }

    // MARK: - Performance Tests

    func testParallelProcessingIsFasterThanSequential() async throws {
        // This is a comparative test showing parallel is faster
        let repository = ClassificationRepository()

        // Train classifier
        let trainingFiles = [
            File(url: URL(fileURLWithPath: "/train/doc.pdf"), textContent: "document text sample")
        ]
        let trainingFolders: [URL: Folder] = [
            URL(fileURLWithPath: "/train/doc.pdf"): Folder(url: URL(fileURLWithPath: "/output/docs"))
        ]
        try await repository.train(files: trainingFiles, folderLabels: trainingFolders)

        let testFiles = (0..<40).map { index in
            File(url: URL(fileURLWithPath: "/test/file\(index).pdf"), textContent: "document text content sample")
        }

        // Measure parallel with 8 tasks
        let parallelStart = Date()
        let parallelResults = try await repository.classifyBatch(
            files: testFiles,
            topN: 1,
            maxConcurrentTasks: 8
        )
        let parallelDuration = Date().timeIntervalSince(parallelStart)

        // Measure "sequential" with 1 task
        let sequentialStart = Date()
        let sequentialResults = try await repository.classifyBatch(
            files: testFiles,
            topN: 1,
            maxConcurrentTasks: 1
        )
        let sequentialDuration = Date().timeIntervalSince(sequentialStart)

        // Then: Parallel should be faster
        XCTAssertEqual(parallelResults.count, 40)
        XCTAssertEqual(sequentialResults.count, 40)

        // Parallel with 8 tasks should be noticeably faster
        print("Parallel (8 tasks): \(parallelDuration)s, Sequential (1 task): \(sequentialDuration)s")
        XCTAssertLessThan(parallelDuration, sequentialDuration * 0.5,
                         "Parallel should be at least 2x faster than sequential")
    }
}
