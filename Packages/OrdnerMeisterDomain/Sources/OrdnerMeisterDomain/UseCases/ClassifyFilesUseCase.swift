import Foundation
import OSLog

/// Use case for classifying files from the inbox
public protocol ClassifyFilesUseCaseProtocol {
    func execute() async throws -> (ProcessingResult, [Classification])
}

public final class ClassifyFilesUseCase: ClassifyFilesUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol
    private let fileRepository: FileRepositoryProtocol
    private let textExtractionRepository: TextExtractionRepositoryProtocol
    private let textCacheRepository: TextCacheRepositoryProtocol
    private let classificationRepository: ClassificationRepositoryProtocol
    private let topN: Int
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "Processing")

    public init(
        settingsRepository: SettingsRepositoryProtocol,
        fileRepository: FileRepositoryProtocol,
        textExtractionRepository: TextExtractionRepositoryProtocol,
        textCacheRepository: TextCacheRepositoryProtocol,
        classificationRepository: ClassificationRepositoryProtocol,
        topN: Int = 5
    ) {
        self.settingsRepository = settingsRepository
        self.fileRepository = fileRepository
        self.textExtractionRepository = textExtractionRepository
        self.textCacheRepository = textCacheRepository
        self.classificationRepository = classificationRepository
        self.topN = topN
    }

    public func execute() async throws -> (ProcessingResult, [Classification]) {
        logger.info("Starting file classification process")

        // 1. Get settings
        let settings = settingsRepository.getSettings()

        // 2. Get PDF files from inbox directory (filter to avoid non-PDF errors)
        let fileURLs = try await fileRepository.getFiles(
            from: settings.inboxPath,
            fileExtensions: [".pdf"]
        )

        let totalFiles = fileURLs.count
        logger.info("Found \(totalFiles) PDF files in inbox")

        // 3. Extract text from each file
        var files: [File] = []
        var errors: [ProcessingResult.FileProcessingError] = []

        for fileURL in fileURLs {
            // Check cache first
            let text: String
            if let cachedText = await textCacheRepository.getCachedText(for: fileURL) {
                text = cachedText
            } else {
                do {
                    text = try await textExtractionRepository.extractText(from: fileURL)
                    try await textCacheRepository.cacheText(text, for: fileURL)
                } catch {
                    // Collect error and continue with other files
                    let fileName = fileURL.lastPathComponent
                    logger.warning("Failed to extract text from '\(fileName)': \(error.localizedDescription)")
                    errors.append(ProcessingResult.FileProcessingError(
                        fileName: fileName,
                        fileURL: fileURL,
                        error: error
                    ))
                    continue
                }
            }

            let file = File(url: fileURL, textContent: text)
            files.append(file)
        }

        let successCount = files.count
        logger.info("Text extraction completed: \(successCount) succeeded, \(errors.count) failed")

        // 4. Classify all files
        let classifications = try await classificationRepository.classifyBatch(
            files: files,
            topN: topN
        )

        // 5. Create processing result
        let processingResult = ProcessingResult(
            totalFiles: totalFiles,
            successCount: successCount,
            errors: errors
        )

        logger.info("Classification process completed: \(processingResult.summaryMessage)")

        return (processingResult, classifications)
    }
}
