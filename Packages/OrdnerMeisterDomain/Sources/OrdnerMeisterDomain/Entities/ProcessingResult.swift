import Foundation

/// Result of a batch file processing operation
public struct ProcessingResult: Sendable {
    /// Total number of files attempted to process
    public let totalFiles: Int

    /// Number of files successfully processed
    public let successCount: Int

    /// List of errors that occurred during processing
    public let errors: [FileProcessingError]

    /// Number of files that failed to process
    public var failureCount: Int {
        errors.count
    }

    /// Whether any files failed to process
    public var hasFailures: Bool {
        failureCount > 0
    }

    /// Human-readable summary message
    public var summaryMessage: String {
        // Handle empty case
        if totalFiles == 0 {
            return "No files to process"
        }

        // All succeeded
        if failureCount == 0 {
            if totalFiles == 1 {
                return "Successfully processed 1 file"
            }
            return "Successfully processed all \(totalFiles) files"
        }

        // All failed
        if successCount == 0 {
            if totalFiles == 1 {
                return "Failed to process 1 file"
            }
            return "Failed to process all \(totalFiles) files"
        }

        // Partial success
        return "Processed \(successCount) of \(totalFiles) files successfully (\(failureCount) failed)"
    }

    public init(totalFiles: Int, successCount: Int, errors: [FileProcessingError]) {
        self.totalFiles = totalFiles
        self.successCount = successCount
        self.errors = errors
    }

    /// Error information for a single file that failed to process
    public struct FileProcessingError: Sendable {
        /// Name of the file that failed
        public let fileName: String

        /// URL of the file that failed
        public let fileURL: URL

        /// The error that occurred
        public let error: Error

        public init(fileName: String, fileURL: URL, error: Error) {
            self.fileName = fileName
            self.fileURL = fileURL
            self.error = error
        }
    }
}
