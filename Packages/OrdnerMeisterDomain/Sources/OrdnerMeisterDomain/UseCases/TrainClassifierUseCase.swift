import Foundation
import OSLog

/// Use case for training the file classifier
public protocol TrainClassifierUseCaseProtocol {
    func execute() async throws -> ProcessingResult
}

public final class TrainClassifierUseCase: TrainClassifierUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol
    private let fileRepository: FileRepositoryProtocol
    private let textExtractionRepository: TextExtractionRepositoryProtocol
    private let textCacheRepository: TextCacheRepositoryProtocol
    private let classificationRepository: ClassificationRepositoryProtocol
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "Processing")

    public init(
        settingsRepository: SettingsRepositoryProtocol,
        fileRepository: FileRepositoryProtocol,
        textExtractionRepository: TextExtractionRepositoryProtocol,
        textCacheRepository: TextCacheRepositoryProtocol,
        classificationRepository: ClassificationRepositoryProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.fileRepository = fileRepository
        self.textExtractionRepository = textExtractionRepository
        self.textCacheRepository = textCacheRepository
        self.classificationRepository = classificationRepository
    }

    public func execute() async throws -> ProcessingResult {
        logger.info("Starting classifier training process")

        // 1. Get settings
        let settings = settingsRepository.getSettings()

        // 2. Build file tree from output directory
        let fileTree = try await fileRepository.buildFileTree(
            from: settings.outputPath,
            excluding: settings.exclusions
        )

        // 3. Get folders from the tree
        let folderURLs = fileTree.flattenFolders()
        logger.info("Found \(folderURLs.count) folders for training")

        // 4. For each folder, get files and extract text
        var filesToTrain: [File] = []
        var folderLabels: [URL: Folder] = [:]
        var errors: [ProcessingResult.FileProcessingError] = []
        var totalFiles = 0

        for folderURL in folderURLs where folderURL != settings.outputPath.url {
            let folder = Folder(url: folderURL)
            // Only get PDF files to avoid errors with non-PDF files
            let fileURLs = try await fileRepository.getFiles(
                from: try DirectoryPath(url: folderURL),
                fileExtensions: [".pdf"]
            )

            totalFiles += fileURLs.count

            // Extract text from files in this folder
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
                filesToTrain.append(file)
                folderLabels[fileURL] = folder
            }
        }

        let successCount = filesToTrain.count
        logger.info("Text extraction completed: \(successCount) succeeded, \(errors.count) failed out of \(totalFiles) files")

        // 5. Train the classifier
        try await classificationRepository.train(files: filesToTrain, folderLabels: folderLabels)

        // 6. Create processing result
        let processingResult = ProcessingResult(
            totalFiles: totalFiles,
            successCount: successCount,
            errors: errors
        )

        logger.info("Training process completed: \(processingResult.summaryMessage)")

        return processingResult
    }
}
