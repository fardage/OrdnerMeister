import Foundation
import Combine

/// Use case for retrieving application settings
public protocol GetSettingsUseCaseProtocol {
    func execute() -> Settings
    func observe() -> AnyPublisher<Settings, Never>
}

public final class GetSettingsUseCase: GetSettingsUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol

    public init(settingsRepository: SettingsRepositoryProtocol) {
        self.settingsRepository = settingsRepository
    }

    public func execute() -> Settings {
        settingsRepository.getSettings()
    }

    public func observe() -> AnyPublisher<Settings, Never> {
        settingsRepository.observeSettings()
    }
}
