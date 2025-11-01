import Foundation
import OSLog

/// Use case for classifying files from the inbox
public protocol ClassifyFilesUseCaseProtocol {
    func execute() async throws -> (ProcessingResult, [Classification])

    /// Execute with real-time progress updates
    /// - Returns: Tuple of (progress stream, result task)
    func executeWithProgress() -> (stream: AsyncStream<ProcessingProgress>, task: Task<(ProcessingResult, [Classification]), Error>)
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
                    await textCacheRepository.cacheTextDeferred(text, for: fileURL)
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

        // Flush cache to disk once (batch write)
        try await textCacheRepository.flushCache()

        // 4. Classify all files in parallel
        let classifications = try await classificationRepository.classifyBatch(
            files: files,
            topN: topN,
            maxConcurrentTasks: 8
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

    public func executeWithProgress() -> (stream: AsyncStream<ProcessingProgress>, task: Task<(ProcessingResult, [Classification]), Error>) {
        var continuation: AsyncStream<ProcessingProgress>.Continuation?

        let stream = AsyncStream<ProcessingProgress> { cont in
            continuation = cont
        }

        let task = Task<(ProcessingResult, [Classification]), Error> {
            guard let cont = continuation else {
                throw NSError(domain: "ClassifyFilesUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize progress stream"])
            }

            defer { cont.finish() }

            logger.info("Starting file classification process with progress tracking")

            // 1. Get settings
            let settings = settingsRepository.getSettings()

            // 2. Get PDF files from inbox directory
            let fileURLs = try await fileRepository.getFiles(
                from: settings.inboxPath,
                fileExtensions: [".pdf"]
            )

            let totalFiles = fileURLs.count
            logger.info("Found \(totalFiles) PDF files in inbox")

            // 3. Extract text from each file with progress updates
            var files: [File] = []
            var errors: [ProcessingResult.FileProcessingError] = []
            var processedCount = 0

            for fileURL in fileURLs {
                processedCount += 1
                let fileName = fileURL.lastPathComponent

                // Emit progress for text extraction
                cont.yield(ProcessingProgress(
                    stage: .classifying(current: processedCount, total: totalFiles),
                    currentFileName: fileName
                ))

                // Check cache first
                let text: String
                if let cachedText = await textCacheRepository.getCachedText(for: fileURL) {
                    text = cachedText
                } else {
                    do {
                        text = try await textExtractionRepository.extractText(from: fileURL)
                        await textCacheRepository.cacheTextDeferred(text, for: fileURL)
                    } catch {
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

            // Flush cache to disk once (batch write)
            try await textCacheRepository.flushCache()

            // 4. Classify all files in parallel
            let classifications = try await classificationRepository.classifyBatch(
                files: files,
                topN: topN,
                maxConcurrentTasks: 8
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

        return (stream, task)
    }
}
