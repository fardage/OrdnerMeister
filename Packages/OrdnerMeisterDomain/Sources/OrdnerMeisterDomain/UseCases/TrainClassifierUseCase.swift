import Foundation

/// Use case for training the file classifier
public protocol TrainClassifierUseCaseProtocol {
    func execute() async throws
}

public final class TrainClassifierUseCase: TrainClassifierUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol
    private let fileRepository: FileRepositoryProtocol
    private let textExtractionRepository: TextExtractionRepositoryProtocol
    private let textCacheRepository: TextCacheRepositoryProtocol
    private let classificationRepository: ClassificationRepositoryProtocol

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

    public func execute() async throws {
        // 1. Get settings
        let settings = settingsRepository.getSettings()

        // 2. Build file tree from output directory
        let fileTree = try await fileRepository.buildFileTree(
            from: settings.outputPath,
            excluding: settings.exclusions
        )

        // 3. Get folders from the tree
        let folderURLs = fileTree.flattenFolders()

        // 4. For each folder, get files and extract text
        var filesToTrain: [File] = []
        var folderLabels: [URL: Folder] = [:]

        for folderURL in folderURLs where folderURL != settings.outputPath.url {
            let folder = Folder(url: folderURL)
            let fileURLs = try await fileRepository.getFiles(from: try DirectoryPath(url: folderURL))

            // Extract text from files in this folder
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
                filesToTrain.append(file)
                folderLabels[fileURL] = folder
            }
        }

        // 5. Train the classifier
        try await classificationRepository.train(files: filesToTrain, folderLabels: folderLabels)
    }
}
