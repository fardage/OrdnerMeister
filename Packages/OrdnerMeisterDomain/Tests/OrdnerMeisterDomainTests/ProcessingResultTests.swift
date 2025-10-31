import Testing
import Foundation
@testable import OrdnerMeisterDomain

/// Tests for ProcessingResult
@Suite("ProcessingResult Tests")
struct ProcessingResultTests {

    @Test("ProcessingResult calculates counts correctly with all successes")
    func testAllSuccesses() {
        let result = ProcessingResult(
            totalFiles: 5,
            successCount: 5,
            errors: []
        )

        #expect(result.totalFiles == 5)
        #expect(result.successCount == 5)
        #expect(result.failureCount == 0)
        #expect(result.hasFailures == false)
    }

    @Test("ProcessingResult calculates failure count correctly")
    func testWithFailures() {
        let error1 = ProcessingResult.FileProcessingError(
            fileName: "test1.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test1.pdf"),
            error: NSError(domain: "test", code: 1)
        )
        let error2 = ProcessingResult.FileProcessingError(
            fileName: "test2.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test2.pdf"),
            error: NSError(domain: "test", code: 2)
        )

        let result = ProcessingResult(
            totalFiles: 5,
            successCount: 3,
            errors: [error1, error2]
        )

        #expect(result.totalFiles == 5)
        #expect(result.successCount == 3)
        #expect(result.failureCount == 2)
        #expect(result.hasFailures == true)
        #expect(result.errors.count == 2)
    }

    @Test("ProcessingResult generates correct summary message for all successes")
    func testSummaryMessageAllSuccess() {
        let result = ProcessingResult(
            totalFiles: 10,
            successCount: 10,
            errors: []
        )

        #expect(result.summaryMessage == "Successfully processed all 10 files")
    }

    @Test("ProcessingResult generates correct summary message for partial success")
    func testSummaryMessagePartialSuccess() {
        let error = ProcessingResult.FileProcessingError(
            fileName: "test.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            error: NSError(domain: "test", code: 1)
        )

        let result = ProcessingResult(
            totalFiles: 10,
            successCount: 8,
            errors: [error, error]
        )

        #expect(result.summaryMessage == "Processed 8 of 10 files successfully (2 failed)")
    }

    @Test("ProcessingResult generates correct summary message for total failure")
    func testSummaryMessageTotalFailure() {
        let errors = (1...5).map { i in
            ProcessingResult.FileProcessingError(
                fileName: "test\(i).pdf",
                fileURL: URL(fileURLWithPath: "/tmp/test\(i).pdf"),
                error: NSError(domain: "test", code: i)
            )
        }

        let result = ProcessingResult(
            totalFiles: 5,
            successCount: 0,
            errors: errors
        )

        #expect(result.summaryMessage == "Failed to process all 5 files")
    }

    @Test("ProcessingResult generates correct summary message for single file success")
    func testSummaryMessageSingleFileSuccess() {
        let result = ProcessingResult(
            totalFiles: 1,
            successCount: 1,
            errors: []
        )

        #expect(result.summaryMessage == "Successfully processed 1 file")
    }

    @Test("ProcessingResult generates correct summary message for single file failure")
    func testSummaryMessageSingleFileFailure() {
        let error = ProcessingResult.FileProcessingError(
            fileName: "test.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            error: NSError(domain: "test", code: 1)
        )

        let result = ProcessingResult(
            totalFiles: 1,
            successCount: 0,
            errors: [error]
        )

        #expect(result.summaryMessage == "Failed to process 1 file")
    }

    @Test("FileProcessingError contains correct information")
    func testFileProcessingError() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let error = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        let fileError = ProcessingResult.FileProcessingError(
            fileName: "test.pdf",
            fileURL: url,
            error: error
        )

        #expect(fileError.fileName == "test.pdf")
        #expect(fileError.fileURL == url)
        #expect((fileError.error as NSError).code == 42)
    }

    @Test("ProcessingResult handles empty files correctly")
    func testEmptyProcessing() {
        let result = ProcessingResult(
            totalFiles: 0,
            successCount: 0,
            errors: []
        )

        #expect(result.totalFiles == 0)
        #expect(result.successCount == 0)
        #expect(result.failureCount == 0)
        #expect(result.hasFailures == false)
        #expect(result.summaryMessage == "No files to process")
    }
}
