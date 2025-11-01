import XCTest
@testable import OrdnerMeisterDomain
import Foundation

/// Tests for progress tracking functionality
final class ProgressTrackingTests: XCTestCase {

    // MARK: - ProcessingStage Tests

    func testTrainingStageProgressCalculation() {
        // Given: A training stage with specific progress
        let stage = ProcessingStage.training(current: 5, total: 10)

        // When: Getting progress
        let progress = stage.progress

        // Then: Progress is calculated correctly
        XCTAssertEqual(progress, 0.5, accuracy: 0.001, "Training should be 50% complete")
    }

    func testClassifyingStageProgressCalculation() {
        // Given: A classifying stage with specific progress
        let stage = ProcessingStage.classifying(current: 7, total: 20)

        // When: Getting progress
        let progress = stage.progress

        // Then: Progress is calculated correctly
        XCTAssertEqual(progress, 0.35, accuracy: 0.001, "Classifying should be 35% complete")
    }

    func testProgressWithZeroTotal() {
        // Given: Stages with zero total (edge case)
        let trainingStage = ProcessingStage.training(current: 0, total: 0)
        let classifyingStage = ProcessingStage.classifying(current: 0, total: 0)

        // When: Getting progress
        let trainingProgress = trainingStage.progress
        let classifyingProgress = classifyingStage.progress

        // Then: Progress is 0 (not NaN or crash)
        XCTAssertEqual(trainingProgress, 0.0, "Progress should be 0 when total is 0")
        XCTAssertEqual(classifyingProgress, 0.0, "Progress should be 0 when total is 0")
    }

    func testProgressBoundaries() {
        // Given: Stages at 0% and 100%
        let zeroProgress = ProcessingStage.training(current: 0, total: 10)
        let fullProgress = ProcessingStage.training(current: 10, total: 10)

        // When: Getting progress
        let zero = zeroProgress.progress
        let full = fullProgress.progress

        // Then: Progress is within [0, 1]
        XCTAssertEqual(zero, 0.0, "Progress at start should be 0")
        XCTAssertEqual(full, 1.0, "Progress at end should be 1.0")
    }

    func testProgressMonotonicallyIncreases() {
        // Given: A sequence of progressing stages
        let stages = (0...10).map { ProcessingStage.training(current: $0, total: 10) }

        // When: Getting progress for each
        let progressValues = stages.map { $0.progress }

        // Then: Progress never decreases
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i-1],
                                      "Progress should never decrease")
        }
    }

    // MARK: - ProcessingStage Equality Tests

    func testTrainingStageEquality() {
        // Given: Identical training stages
        let stage1 = ProcessingStage.training(current: 5, total: 10)
        let stage2 = ProcessingStage.training(current: 5, total: 10)
        let stage3 = ProcessingStage.training(current: 6, total: 10)

        // Then: Equality works correctly
        XCTAssertEqual(stage1, stage2, "Identical stages should be equal")
        XCTAssertNotEqual(stage1, stage3, "Different current values should not be equal")
    }

    func testClassifyingStageEquality() {
        // Given: Identical classifying stages
        let stage1 = ProcessingStage.classifying(current: 3, total: 7)
        let stage2 = ProcessingStage.classifying(current: 3, total: 7)
        let stage3 = ProcessingStage.classifying(current: 3, total: 8)

        // Then: Equality works correctly
        XCTAssertEqual(stage1, stage2, "Identical stages should be equal")
        XCTAssertNotEqual(stage1, stage3, "Different totals should not be equal")
    }

    func testDifferentStageTypesNotEqual() {
        // Given: Training and classifying stages with same values
        let trainingStage = ProcessingStage.training(current: 5, total: 10)
        let classifyingStage = ProcessingStage.classifying(current: 5, total: 10)

        // Then: Different stage types are not equal
        XCTAssertNotEqual(trainingStage, classifyingStage,
                         "Training and classifying stages should never be equal")
    }

    // MARK: - ProcessingProgress Tests

    func testProcessingProgressCreation() {
        // Given: A processing progress with all fields
        let stage = ProcessingStage.training(current: 3, total: 10)
        let fileName = "test_document.pdf"

        // When: Creating progress
        let progress = ProcessingProgress(stage: stage, currentFileName: fileName)

        // Then: All fields are set correctly
        XCTAssertEqual(progress.stage, stage)
        XCTAssertEqual(progress.currentFileName, fileName)
        XCTAssertEqual(progress.stage.progress, 0.3, accuracy: 0.001)
    }

    func testProcessingProgressWithNilFileName() {
        // Given: Progress without a filename
        let stage = ProcessingStage.classifying(current: 7, total: 20)

        // When: Creating progress with nil filename
        let progress = ProcessingProgress(stage: stage, currentFileName: nil)

        // Then: Progress is valid with nil filename
        XCTAssertNotNil(progress)
        XCTAssertNil(progress.currentFileName)
        XCTAssertEqual(progress.stage, stage)
    }

    func testProcessingProgressEquality() {
        // Given: Two identical progress objects
        let stage = ProcessingStage.training(current: 5, total: 10)
        let progress1 = ProcessingProgress(stage: stage, currentFileName: "test.pdf")
        let progress2 = ProcessingProgress(stage: stage, currentFileName: "test.pdf")

        // Then: They are equal
        XCTAssertEqual(progress1, progress2, "Identical progress objects should be equal")
    }

    func testProcessingProgressInequalityByStage() {
        // Given: Progress objects with different stages
        let stage1 = ProcessingStage.training(current: 5, total: 10)
        let stage2 = ProcessingStage.training(current: 6, total: 10)
        let progress1 = ProcessingProgress(stage: stage1, currentFileName: "test.pdf")
        let progress2 = ProcessingProgress(stage: stage2, currentFileName: "test.pdf")

        // Then: They are not equal
        XCTAssertNotEqual(progress1, progress2, "Different stages should make progress unequal")
    }

    func testProcessingProgressInequalityByFileName() {
        // Given: Progress objects with different filenames
        let stage = ProcessingStage.classifying(current: 3, total: 10)
        let progress1 = ProcessingProgress(stage: stage, currentFileName: "file1.pdf")
        let progress2 = ProcessingProgress(stage: stage, currentFileName: "file2.pdf")

        // Then: They are not equal
        XCTAssertNotEqual(progress1, progress2, "Different filenames should make progress unequal")
    }

    func testProcessingProgressInequalityByNilFilename() {
        // Given: One progress with filename, one without
        let stage = ProcessingStage.training(current: 5, total: 10)
        let progress1 = ProcessingProgress(stage: stage, currentFileName: "test.pdf")
        let progress2 = ProcessingProgress(stage: stage, currentFileName: nil)

        // Then: They are not equal
        XCTAssertNotEqual(progress1, progress2, "Nil vs non-nil filename should make progress unequal")
    }

    // MARK: - Sendable Conformance Tests

    func testProcessingStageSendable() async {
        // Given: A processing stage
        let stage = ProcessingStage.training(current: 5, total: 10)

        // When: Passing across concurrency boundary
        let result = await withCheckedContinuation { continuation in
            Task {
                continuation.resume(returning: stage)
            }
        }

        // Then: Stage is transferred correctly (Sendable works)
        XCTAssertEqual(result, stage)
    }

    func testProcessingProgressSendable() async {
        // Given: A processing progress
        let progress = ProcessingProgress(
            stage: .classifying(current: 7, total: 20),
            currentFileName: "document.pdf"
        )

        // When: Passing across concurrency boundary
        let result = await withCheckedContinuation { continuation in
            Task {
                continuation.resume(returning: progress)
            }
        }

        // Then: Progress is transferred correctly (Sendable works)
        XCTAssertEqual(result, progress)
    }

    // MARK: - Real-world Scenarios

    func testTypicalTrainingProgressSequence() {
        // Given: A typical training sequence of 10 files
        let totalFiles = 10
        var progressSequence: [ProcessingProgress] = []

        // When: Simulating processing each file
        for current in 1...totalFiles {
            let progress = ProcessingProgress(
                stage: .training(current: current, total: totalFiles),
                currentFileName: "file\(current).pdf"
            )
            progressSequence.append(progress)
        }

        // Then: Progress goes from 10% to 100%
        XCTAssertEqual(progressSequence.first!.stage.progress, 0.1, accuracy: 0.001)
        XCTAssertEqual(progressSequence.last!.stage.progress, 1.0, accuracy: 0.001)

        // All filenames are present
        XCTAssertTrue(progressSequence.allSatisfy { $0.currentFileName != nil })

        // Progress is monotonic
        for i in 1..<progressSequence.count {
            XCTAssertGreaterThanOrEqual(
                progressSequence[i].stage.progress,
                progressSequence[i-1].stage.progress
            )
        }
    }

    func testTypicalClassifyingProgressSequence() {
        // Given: A typical classification sequence of 20 files
        let totalFiles = 20
        var progressSequence: [ProcessingProgress] = []

        // When: Simulating classification of each file
        for current in 1...totalFiles {
            let progress = ProcessingProgress(
                stage: .classifying(current: current, total: totalFiles),
                currentFileName: "inbox_file\(current).pdf"
            )
            progressSequence.append(progress)
        }

        // Then: Progress goes from 5% to 100%
        XCTAssertEqual(progressSequence.first!.stage.progress, 0.05, accuracy: 0.001)
        XCTAssertEqual(progressSequence.last!.stage.progress, 1.0, accuracy: 0.001)

        // All progress updates are classifying stage
        XCTAssertTrue(progressSequence.allSatisfy {
            if case .classifying = $0.stage { return true }
            return false
        })
    }

    func testProgressPercentageFormatting() {
        // Given: Various progress stages
        let testCases: [(stage: ProcessingStage, expected: Double)] = [
            (.training(current: 0, total: 10), 0.0),
            (.training(current: 1, total: 10), 0.1),
            (.training(current: 5, total: 10), 0.5),
            (.training(current: 10, total: 10), 1.0),
            (.classifying(current: 7, total: 14), 0.5),
            (.classifying(current: 1, total: 3), 0.333333)
        ]

        // When: Getting progress values
        for (stage, expected) in testCases {
            let progress = stage.progress

            // Then: Progress matches expected value
            XCTAssertEqual(progress, expected, accuracy: 0.001,
                          "Progress calculation incorrect for \(stage)")
        }
    }
}
