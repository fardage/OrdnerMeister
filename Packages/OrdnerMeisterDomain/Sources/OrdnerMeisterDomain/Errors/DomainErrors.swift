import Foundation

// MARK: - File System Errors

/// Errors related to file system operations
public enum FileSystemError: Error, LocalizedError {
    case fileNotFound(URL)
    case directoryNotFound(URL)
    case permissionDenied(URL)
    case copyFailed(source: URL, destination: URL, underlyingError: Error?)
    case deleteFailed(URL, underlyingError: Error?)
    case moveFailed(source: URL, destination: URL, underlyingError: Error?)
    case fileAlreadyExists(URL)
    case diskFull
    case unknownFileSystemError(Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .directoryNotFound(let url):
            return "Directory not found: \(url.path)"
        case .permissionDenied(let url):
            return "Permission denied for: \(url.lastPathComponent)"
        case .copyFailed(let source, let destination, let error):
            if let error = error {
                return "Failed to copy '\(source.lastPathComponent)' to '\(destination.lastPathComponent)': \(error.localizedDescription)"
            }
            return "Failed to copy '\(source.lastPathComponent)' to '\(destination.lastPathComponent)'"
        case .deleteFailed(let url, let error):
            if let error = error {
                return "Failed to delete '\(url.lastPathComponent)': \(error.localizedDescription)"
            }
            return "Failed to delete '\(url.lastPathComponent)'"
        case .moveFailed(let source, let destination, let error):
            if let error = error {
                return "Failed to move '\(source.lastPathComponent)' to '\(destination.lastPathComponent)': \(error.localizedDescription)"
            }
            return "Failed to move '\(source.lastPathComponent)' to '\(destination.lastPathComponent)'"
        case .fileAlreadyExists(let url):
            return "File already exists: \(url.lastPathComponent)"
        case .diskFull:
            return "Disk is full. Please free up space and try again."
        case .unknownFileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Processing Errors

/// Errors related to batch file processing operations
public enum ProcessingError: Error, LocalizedError {
    case noFilesFound(directory: URL)
    case batchProcessingFailed(processedCount: Int, totalCount: Int)
    case partialFailure(successCount: Int, failureCount: Int, errors: [Error])
    case cancelled
    case unknownProcessingError(Error)

    public var errorDescription: String? {
        switch self {
        case .noFilesFound(let directory):
            return "No files found in: \(directory.lastPathComponent)"
        case .batchProcessingFailed(let processed, let total):
            return "Batch processing failed: processed \(processed) of \(total) files"
        case .partialFailure(let success, let failure, _):
            return "Processing completed with errors: \(success) succeeded, \(failure) failed"
        case .cancelled:
            return "Operation was cancelled"
        case .unknownProcessingError(let error):
            return "Processing error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Classifier Errors

/// Errors related to classification operations
public enum ClassifierError: Error, LocalizedError {
    case notTrained
    case trainingFailed(reason: String?)
    case classificationFailed(fileName: String, underlyingError: Error?)
    case insufficientTrainingData(fileCount: Int, minimumRequired: Int)
    case invalidModel
    case modelLoadFailed(Error)
    case modelSaveFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .notTrained:
            return "Classifier has not been trained. Please train the classifier before classifying files."
        case .trainingFailed(let reason):
            if let reason = reason {
                return "Training failed: \(reason)"
            }
            return "Training failed"
        case .classificationFailed(let fileName, let error):
            if let error = error {
                return "Failed to classify '\(fileName)': \(error.localizedDescription)"
            }
            return "Failed to classify '\(fileName)'"
        case .insufficientTrainingData(let count, let required):
            return "Insufficient training data: found \(count) files, need at least \(required)"
        case .invalidModel:
            return "The classifier model is invalid or corrupted"
        case .modelLoadFailed(let error):
            return "Failed to load classifier model: \(error.localizedDescription)"
        case .modelSaveFailed(let error):
            return "Failed to save classifier model: \(error.localizedDescription)"
        }
    }
}

// MARK: - Text Extraction Errors

/// Errors related to text extraction and OCR
public enum TextExtractionError: Error, LocalizedError {
    case unsupportedFileType(String)
    case failedToLoadPDF(String)
    case ocrFailed(fileName: String, underlyingError: Error?)
    case emptyDocument(String)
    case corruptedFile(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext)"
        case .failedToLoadPDF(let fileName):
            return "Failed to load PDF: \(fileName)"
        case .ocrFailed(let fileName, let error):
            if let error = error {
                return "OCR failed for '\(fileName)': \(error.localizedDescription)"
            }
            return "OCR failed for '\(fileName)'"
        case .emptyDocument(let fileName):
            return "Document is empty or contains no text: \(fileName)"
        case .corruptedFile(let fileName):
            return "File appears to be corrupted: \(fileName)"
        }
    }
}

// MARK: - Cache Errors

/// Errors related to text cache operations
public enum CacheError: Error, LocalizedError {
    case cacheReadFailed(URL, Error)
    case cacheWriteFailed(URL, Error)
    case cacheCorrupted(URL)
    case cacheMissing(URL)

    public var errorDescription: String? {
        switch self {
        case .cacheReadFailed(let url, let error):
            return "Failed to read cache for '\(url.lastPathComponent)': \(error.localizedDescription)"
        case .cacheWriteFailed(let url, let error):
            return "Failed to write cache for '\(url.lastPathComponent)': \(error.localizedDescription)"
        case .cacheCorrupted(let url):
            return "Cache corrupted for: \(url.lastPathComponent)"
        case .cacheMissing(let url):
            return "Cache missing for: \(url.lastPathComponent)"
        }
    }
}

// MARK: - Settings Errors

/// Errors related to settings operations
public enum SettingsError: Error, LocalizedError {
    case invalidPath(String)
    case pathNotAccessible(URL)
    case saveFailed(key: String, Error)
    case loadFailed(key: String, Error)

    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .pathNotAccessible(let url):
            return "Path is not accessible: \(url.path)"
        case .saveFailed(let key, let error):
            return "Failed to save setting '\(key)': \(error.localizedDescription)"
        case .loadFailed(let key, let error):
            return "Failed to load setting '\(key)': \(error.localizedDescription)"
        }
    }
}
