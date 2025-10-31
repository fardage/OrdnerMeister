import Foundation

/// Use case for retrieving application settings
public protocol GetSettingsUseCaseProtocol {
    func execute() -> Settings
}

public final class GetSettingsUseCase: GetSettingsUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol

    public init(settingsRepository: SettingsRepositoryProtocol) {
        self.settingsRepository = settingsRepository
    }

    public func execute() -> Settings {
        settingsRepository.getSettings()
    }
}
