import Foundation

/// Use case for classifying files from the inbox
public protocol ClassifyFilesUseCaseProtocol {
    func execute() async throws -> [Classification]
}

public final class ClassifyFilesUseCase: ClassifyFilesUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol
    private let fileRepository: FileRepositoryProtocol
    private let textExtractionRepository: TextExtractionRepositoryProtocol
    private let textCacheRepository: TextCacheRepositoryProtocol
    private let classificationRepository: ClassificationRepositoryProtocol
    private let topN: Int

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

    public func execute() async throws -> [Classification] {
        // 1. Get settings
        let settings = settingsRepository.getSettings()

        // 2. Build file tree from inbox directory
        let fileTree = try await fileRepository.buildFileTree(
            from: settings.inboxPath,
            excluding: settings.exclusions
        )

        // 3. Get files from the tree
        let fileURLs = fileTree.flattenFiles()

        // 4. Extract text from each file
        var files: [File] = []
        for fileURL in fileURLs {
            // Check cache first
            let text: String
            if let cachedText = await textCacheRepository.getCachedText(for: fileURL) {
                text = cachedText
            } else {
                text = try await textExtractionRepository.extractText(from: fileURL)
                try await textCacheRepository.cacheText(text, for: fileURL)
            }

            let file = File(url: fileURL, textContent: text)
            files.append(file)
        }

        // 5. Classify all files
        let classifications = try await classificationRepository.classifyBatch(
            files: files,
            topN: topN
        )

        return classifications
    }
}
