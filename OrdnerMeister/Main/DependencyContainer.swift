import Foundation
import OrdnerMeisterDomain
import OrdnerMeisterData
import OrdnerMeisterPresentation

/// Composition root that creates and wires up all dependencies
@MainActor
final class DependencyContainer {
    // MARK: - Repositories

    private lazy var fileRepository: FileRepositoryProtocol = {
        FileRepository()
    }()

    private lazy var settingsRepository: SettingsRepositoryProtocol = {
        SettingsRepository()
    }()

    private lazy var classificationRepository: ClassificationRepositoryProtocol = {
        ClassificationRepository()
    }()

    private lazy var textCacheRepository: TextCacheRepositoryProtocol = {
        TextCacheRepository()
    }()

    private lazy var textExtractionRepository: TextExtractionRepositoryProtocol = {
        TextExtractionRepository()
    }()

    // MARK: - Use Cases

    private lazy var trainClassifierUseCase: TrainClassifierUseCase = {
        TrainClassifierUseCase(
            settingsRepository: settingsRepository,
            fileRepository: fileRepository,
            textExtractionRepository: textExtractionRepository,
            textCacheRepository: textCacheRepository,
            classificationRepository: classificationRepository
        )
    }()

    private lazy var classifyFilesUseCase: ClassifyFilesUseCase = {
        ClassifyFilesUseCase(
            settingsRepository: settingsRepository,
            fileRepository: fileRepository,
            textExtractionRepository: textExtractionRepository,
            textCacheRepository: textCacheRepository,
            classificationRepository: classificationRepository
        )
    }()

    private lazy var moveFileUseCase: MoveFileUseCase = {
        MoveFileUseCase(fileRepository: fileRepository, getSettingsUseCase: getSettingsUseCase)
    }()

    private lazy var getSettingsUseCase: GetSettingsUseCase = {
        GetSettingsUseCase(settingsRepository: settingsRepository)
    }()

    private lazy var updateSettingsUseCase: UpdateSettingsUseCase = {
        UpdateSettingsUseCase(settingsRepository: settingsRepository)
    }()

    // MARK: - View Models

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            trainClassifierUseCase: trainClassifierUseCase,
            classifyFilesUseCase: classifyFilesUseCase,
            moveFileUseCase: moveFileUseCase,
            getSettingsUseCase: getSettingsUseCase
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            getSettingsUseCase: getSettingsUseCase,
            updateSettingsUseCase: updateSettingsUseCase
        )
    }
}
